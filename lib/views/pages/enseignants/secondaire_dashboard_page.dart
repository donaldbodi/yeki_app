// lib/views/pages/enseignants/secondaire_dashboard_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// ENSEIGNANT SECONDAIRE DASHBOARD — CORRIGÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

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
        Uri.parse(ApiConstants.enseignantDashboard),
        headers: ApiHeaders.auth(token),
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
        ErrorHandler.showError(context, 'Erreur chargement (${res.statusCode})');
      }
    } catch (e) {
      setState(() => _loading = false);
      ErrorHandler.showError(context, 'Erreur réseau');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      body: _loading
          ? const Center(child: YekiLoader())
          : RefreshIndicator(
              onRefresh: _charger,
              color: YekiColors.primaryDark,
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
      backgroundColor: YekiColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [YekiColors.primaryDark, YekiColors.primaryDark.withValues(alpha: 0.85)],
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
                      color: YekiColors.accent.withValues(alpha: 0.15),
                      borderRadius: YekiRadius.borderRadiusLg,
                    ),
                    child: const Text(
                      "ENSEIGNANT SECONDAIRE",
                      style: TextStyle(
                        color: YekiColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nomEnseignant.isEmpty ? 'Enseignant Secondaire' : _nomEnseignant,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: YekiColors.white.withValues(alpha: 0.15),
                      borderRadius: YekiRadius.borderRadiusXl,
                    ),
                    child: const Text('Enseignant Secondaire', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
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
          icon: const Icon(Icons.refresh, color: YekiColors.white),
          onPressed: _charger,
        ),
      ],
    );
  }

  Widget _miniStatBadge(String value, String label, IconData icon) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: YekiColors.white.withValues(alpha: 0.12),
          borderRadius: YekiRadius.borderRadiusSm,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: YekiColors.white, size: 12),
          const SizedBox(width: 5),
          Text('$value $label', style: const TextStyle(color: YekiColors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _buildStatCards() {
    final nbCours = _stats['nb_cours'] ?? _cours.length;
    final nbApprenants = _stats['nb_apprenants'] ?? 0;
    final nbLecons = _stats['nb_lecons'] ?? 0;
    final nbExercices = _stats['nb_exercices'] ?? 0;

    final items = [
      _StatItem('Cours assignés', nbCours.toString(), Icons.book_outlined, YekiColors.primaryDark),
      _StatItem('Apprenants', nbApprenants.toString(), Icons.people_outline, const Color(0xFF008088)),
      _StatItem('Leçons', nbLecons.toString(), Icons.play_lesson_outlined, YekiColors.purple),
      _StatItem('Exercices', nbExercices.toString(), Icons.edit_note_rounded, YekiColors.warning),
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
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusLg,
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: YekiRadius.borderRadiusMd,
              border: Border.all(color: item.color.withValues(alpha: 0.2), width: 0.8),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: item.color)),
              Text(item.label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: YekiColors.primaryDark, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCoursCard(Map cours) {
    final taux = (cours['taux_completion'] as num? ?? 0).toDouble();
    final nbApp = cours['nb_apprenants'] ?? 0;
    final nbLecons = cours['nb_lecons'] ?? 0;
    final departement = cours['departement']?.toString() ?? '';

    final colorHex = (cours['color_code'] as String? ?? '#2884A0').replaceAll('#', '');
    Color courseColor;
    try {
      courseColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      courseColor = YekiColors.primaryDark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: YekiRadius.borderRadiusXl,
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: InkWell(
        borderRadius: YekiRadius.borderRadiusXl,
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
                      color: courseColor.withValues(alpha: 0.1),
                      borderRadius: YekiRadius.borderRadiusLg,
                      border: Border.all(color: courseColor.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Icon(Icons.book, color: courseColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cours['titre']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        if (departement.isNotEmpty)
                          Text(departement, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20),
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
                      borderRadius: YekiRadius.borderRadiusSm,
                      child: LinearProgressIndicator(
                        value: taux / 100,
                        backgroundColor: YekiColors.borderLight,
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
              const Text('Taux de complétion', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String val, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: YekiColors.textLight),
        const SizedBox(width: 4),
        Text('$val ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _ouvrirCours(Map cours) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EnseignantHomePage(),
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