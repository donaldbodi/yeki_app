import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';

// ─────────────────────────────────────────────────────────────────
// DASHBOARD ENSEIGNANT SECONDAIRE
// Visualise les statistiques des cours qui lui sont assignés
// ─────────────────────────────────────────────────────────────────

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';
const Color _primary  = Color(0xFF2884A0);
const Color _dark     = Color(0xFF0D1B2A);
const Color _bg       = Color(0xFFF4F9FB);

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
    if (token == null) { setState(() => _loading = false); return; }
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignant/dashboard/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _stats = data['stats'] ?? {};
          _cours = data['cours'] ?? [];
          _nomEnseignant = data['nom'] ?? '';
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
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
                        const SizedBox(height: 14),
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
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A5F7A), _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Tableau de bord', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    _nomEnseignant.isEmpty ? 'Enseignant Secondaire' : _nomEnseignant,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Enseignant Secondaire', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
        title: const Text('Mon Dashboard', style: TextStyle(fontSize: 16, color: Colors.white)),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _charger,
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    final items = [
      _StatItem('Cours assignés', (_stats['nb_cours'] ?? _cours.length).toString(), Icons.book_outlined, const Color(0xFF2884A0)),
      _StatItem('Apprenants', (_stats['nb_apprenants'] ?? 0).toString(), Icons.people_outline, const Color(0xFF008088)),
      _StatItem('Leçons', (_stats['nb_lecons'] ?? 0).toString(), Icons.play_lesson_outlined, const Color(0xFF6A1B9A)),
      _StatItem('Exercices', (_stats['nb_exercices'] ?? 0).toString(), Icons.edit_note_rounded, const Color(0xFFE65100)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: item.color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: item.color)),
              Text(item.label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _dark)),
      ],
    );
  }

  Widget _buildCoursCard(Map cours) {
    final taux = (cours['taux_completion'] as num? ?? 0).toDouble();
    final nbApp = cours['nb_apprenants'] ?? 0;
    final nbLecons = cours['nb_lecons'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
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
                    decoration: BoxDecoration(color: _primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.book, color: _primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cours['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _dark)),
                        const SizedBox(height: 2),
                        Text(cours['departement'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 14),
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
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: taux / 100,
                        backgroundColor: Colors.grey.shade100,
                        color: _primary,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${taux.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _primary)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Taux de complétion', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String val, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text('$val ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dark)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
