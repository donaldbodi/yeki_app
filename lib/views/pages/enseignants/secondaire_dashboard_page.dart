// lib/views/pages/enseignants/secondaire_dashboard_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';

// Palette harmonisée
const Color _primary = Color(0xFF2884A0);
//const Color _primaryLight = Color(0xFF39A0C2);
const Color _textDark = Color(0xFF1A1C1E);
//const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _borderLight = Color(0xFFE0E4E8);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
//const Color _green = Color(0xFF10B981);
const Color _orange = Color(0xFFF97316);
const Color _purple = Color(0xFF8B5CF6);
const Color _teal = Color(0xFF008088);

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';

class SecondaireDashboardPage extends StatefulWidget {
  const SecondaireDashboardPage({super.key});

  @override
  State<SecondaireDashboardPage> createState() => _SecondaireDashboardPageState();
}

class _SecondaireDashboardPageState extends State<SecondaireDashboardPage> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List _cours = [];
  String _nomEnseignant = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignant/dashboard/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _stats = data['stats'] != null ? Map<String, dynamic>.from(data['stats']) : {};
          _cours = data['cours'] != null ? List.from(data['cours']) : [];
          _nomEnseignant = data['nom']?.toString() ?? '';
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        _showError('Erreur chargement (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _loading = false);
      _showError('Erreur réseau');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _charger,
              color: _primary,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStatCards(),
                        const SizedBox(height: 28),
                        _buildSectionTitle('Mes cours assignés', Icons.school_outlined),
                        const SizedBox(height: 16),
                        ..._cours.map((c) => _buildCoursCard(c)).toList(),
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _primary,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primary.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "ENSEIGNANT SECONDAIRE",
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nomEnseignant.isEmpty ? 'Enseignant Secondaire' : _nomEnseignant,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Enseignant Secondaire',
                      style: TextStyle(
                        color: _white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _miniStatBadge('${_stats['nb_cours'] ?? _cours.length}', 'cours', Icons.book),
                      const SizedBox(width: 16),
                      _miniStatBadge('${_stats['nb_apprenants'] ?? 0}', 'apprenants', Icons.people),
                      const SizedBox(width: 16),
                      _miniStatBadge('${_stats['nb_lecons'] ?? 0}', 'leçons', Icons.play_lesson),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: _white),
          onPressed: _charger,
        ),
      ],
    );
  }

  Widget _miniStatBadge(String value, String label, IconData icon) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: _white, size: 12),
          const SizedBox(width: 5),
          Text('$value $label',
              style: const TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _buildStatCards() {
    final nbCours = _stats['nb_cours'] ?? _cours.length;
    final nbApprenants = _stats['nb_apprenants'] ?? 0;
    final nbLecons = _stats['nb_lecons'] ?? 0;
    final nbExercices = _stats['nb_exercices'] ?? 0;

    final items = [
      _StatItem('Cours assignés', nbCours.toString(), Icons.book_outlined, _primary),
      _StatItem('Apprenants', nbApprenants.toString(), Icons.people_outline, _teal),
      _StatItem('Leçons', nbLecons.toString(), Icons.play_lesson_outlined, _purple),
      _StatItem('Exercices', nbExercices.toString(), Icons.edit_note_rounded, _orange),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.5,
      children: items.map((i) => _buildStatCard(i)).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderLight, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.color.withOpacity(0.2), width: 0.8),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: item.color)),
              Text(item.label,
                  style: const TextStyle(fontSize: 12, color: _textLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _primary, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
      ],
    );
  }

  Widget _buildCoursCard(Map cours) {
    final taux = (cours['taux_completion'] as num? ?? 0).toDouble();
    final nbApp = cours['nb_apprenants'] ?? 0;
    final nbLecons = cours['nb_lecons'] ?? 0;
    final departement = cours['departement']?.toString() ?? '';

    // Couleur du cours
    final colorHex = (cours['color_code'] as String? ?? '#2884A0').replaceAll('#', '');
    Color courseColor;
    try {
      courseColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      courseColor = _primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _ouvrirCours(cours),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: courseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: courseColor.withOpacity(0.2), width: 0.8),
                    ),
                    child: Icon(Icons.book, color: courseColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cours['titre']?.toString() ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15, color: _textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (departement.isNotEmpty)
                          Text(departement,
                              style: const TextStyle(fontSize: 12, color: _textLight)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: _textLight),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _miniStat(Icons.people_outline, '$nbApp', 'apprenants'),
                  const SizedBox(width: 16),
                  _miniStat(Icons.play_lesson_outlined, '$nbLecons', 'leçons'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: taux / 100,
                        backgroundColor: _borderLight,
                        color: courseColor,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${taux.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: courseColor)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Taux de complétion',
                  style: TextStyle(fontSize: 11, color: _textLight)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String val, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _textLight),
        const SizedBox(width: 4),
        Text('$val ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _textDark)),
        Text(label, style: const TextStyle(fontSize: 12, color: _textLight)),
      ],
    );
  }

  void _ouvrirCours(Map cours) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnseignantHomePage(),
      ),
    );
  }
}

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}