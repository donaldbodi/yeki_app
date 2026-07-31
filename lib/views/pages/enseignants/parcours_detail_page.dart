// lib/views/pages/enseignants/parcours_detail_page.dart
//
// Extrait de admin_general_page.dart en P9.6 (déplacement + imports
// corrigés uniquement — aucune refonte Yk*/repository ici, hors périmètre
// du ticket qui ne cible que AdminGeneralPage et son poids).
// Affiche les départements d'un parcours (administration générale).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_client.dart';
import 'package:yeki/core/router/route_names.dart';

class ParcoursDetailPage extends StatefulWidget {
  final int parcoursId;
  final String parcoursNom;
  final String parcoursType;

  const ParcoursDetailPage({
    super.key,
    required this.parcoursId,
    required this.parcoursNom,
    required this.parcoursType,
  });

  @override
  State<ParcoursDetailPage> createState() => _ParcoursDetailPageState();
}

class _ParcoursDetailPageState extends State<ParcoursDetailPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _departements = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final data = await ApiClient().get('/parcours/${widget.parcoursId}/departements/');
      if (mounted) {
        setState(() {
          _departements = List<Map<String, dynamic>>.from(data as List);
          // CORRECTION: utiliser fold<double> puis convertir en int
          _stats = {
            'nb_departements': _departements.length,
            'nb_cours': _departements.fold<double>(0, (sum, d) => sum + ((d['nb_cours'] ?? 0) as num).toDouble()).toInt(),
            'nb_apprenants': _departements.fold<double>(0, (sum, d) => sum + ((d['nb_apprenants'] ?? 0) as num).toDouble()).toInt(),
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _ouvrirDetailDepartement(Map<String, dynamic> dept) {
    context.pushNamed(
      AppRoute.adminDepartementDetail,
      pathParameters: {'departementId': dept['id'].toString()},
      queryParameters: {
        'departementNom': dept['nom']?.toString() ?? '',
        'parcoursNom': widget.parcoursNom,
      },
      extra: dept,
    );
  }

  Color _getDeptColor(BuildContext context, Map<String, dynamic> dept) {
    final couleur = dept['couleur'] ?? '#2884A0';
    try {
      return Color(int.parse('FF${couleur.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return YkColors.accent(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = YkColors.accent(context);
    return Scaffold(
      backgroundColor: YkColors.background(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.parcoursNom,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YkColors.textPrimary(context)),
            ),
            Text(
              '${_stats['nb_departements']} départements',
              style: TextStyle(fontSize: 12, color: YkColors.textSecondary(context)),
            ),
          ],
        ),
        backgroundColor: YkColors.surface(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accent),
            onPressed: _charger,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: accent))
          : RefreshIndicator(
              onRefresh: _charger,
              color: accent,
              child: _departements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.domain_outlined, size: 48, color: accent),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun département',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YkColors.textPrimary(context)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _departements.length,
                      itemBuilder: (_, i) => _buildDepartementCard(context, _departements[i]),
                    ),
            ),
    );
  }

  Widget _buildDepartementCard(BuildContext context, Map<String, dynamic> dept) {
    final color = _getDeptColor(context, dept);
    final taux = (dept['taux_moyen'] as num?)?.toDouble() ?? 0.0;
    final nbCours = dept['nb_cours'] ?? 0;
    final nbApp = dept['nb_apprenants'] ?? 0;
    final typeDept = dept['type_departement'] ?? 'cursus';

    return GestureDetector(
      onTap: () => _ouvrirDetailDepartement(dept),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: YkColors.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YkColors.border(context), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Icon(
                      _getTypeIcon(typeDept),
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept['nom'] ?? 'Département',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: YkColors.textPrimary(context)),
                        ),
                        Text(
                          _getTypeLabel(typeDept),
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$nbCours cours',
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dept['description'] != null && dept['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        dept['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: YkColors.textSecondary(context), height: 1.4),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.people_rounded, '$nbApp apprenants', YkColors.info),
                      _infoChip(Icons.book_rounded, '$nbCours cours', YkColors.accent(context)),
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
                            backgroundColor: YkColors.border(context),
                            color: color,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${taux.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'prepa_concours':
        return Icons.emoji_events_rounded;
      case 'formation_metier':
        return Icons.work_rounded;
      case 'formation_classique':
        return Icons.account_balance_rounded;
      default:
        return Icons.domain_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'prepa_concours':
        return 'Prépa Concours';
      case 'formation_metier':
        return 'Formation Métier';
      case 'formation_classique':
        return 'Formation Classique';
      default:
        return 'Département';
    }
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
