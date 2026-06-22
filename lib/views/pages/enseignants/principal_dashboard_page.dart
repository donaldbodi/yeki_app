// lib/views/pages/enseignants/principal_dashboard_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// ENSEIGNANT PRINCIPAL DASHBOARD — CORRIGÉ ET COMPLET (Version finale)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MODÈLES DE DONNÉES
// ═══════════════════════════════════════════════════════════════════════════

class DashboardStats {
  final int nbCours;
  final int nbLecons;
  final int nbDevoirs;
  final int nbApprenants;
  final double tauxRenduGlobal;
  final double moyenneGlobale;
  final int nbRetards;
  final String nom;

  DashboardStats({
    required this.nbCours,
    required this.nbLecons,
    required this.nbDevoirs,
    required this.nbApprenants,
    required this.tauxRenduGlobal,
    required this.moyenneGlobale,
    required this.nbRetards,
    required this.nom,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return DashboardStats(
      nbCours: stats['nb_cours'] as int? ?? 0,
      nbLecons: stats['nb_lecons'] as int? ?? 0,
      nbDevoirs: stats['nb_devoirs'] as int? ?? 0,
      nbApprenants: stats['nb_apprenants'] as int? ?? 0,
      tauxRenduGlobal: (stats['taux_rendu_global'] as num? ?? 0).toDouble(),
      moyenneGlobale: (stats['moyenne_globale'] as num? ?? 0).toDouble(),
      nbRetards: stats['nb_retards'] as int? ?? 0,
      nom: json['nom'] as String? ?? 'Enseignant Principal',
    );
  }
}

class DevoirParCours {
  final int coursId;
  final String coursTitre;
  final int nbDevoirs;
  final double tauxRendu;
  final List<DetailDevoir> detailsDevoirs;

  DevoirParCours({
    required this.coursId,
    required this.coursTitre,
    required this.nbDevoirs,
    required this.tauxRendu,
    required this.detailsDevoirs,
  });

  factory DevoirParCours.fromJson(Map<String, dynamic> json) {
    return DevoirParCours(
      coursId: json['cours_id'] as int? ?? 0,
      coursTitre: json['cours_titre'] as String? ?? '',
      nbDevoirs: json['nb_devoirs'] as int? ?? 0,
      tauxRendu: (json['taux_rendu'] as num? ?? 0).toDouble(),
      detailsDevoirs: (json['details_devoirs'] as List? ?? [])
          .map((d) => DetailDevoir.fromJson(d))
          .toList(),
    );
  }
}

class DetailDevoir {
  final int id;
  final String titre;
  final DateTime dateLimite;
  final int nbRendus;
  final int nbRetards;
  final double tauxRendu;
  final double noteMoyenne;
  final String typeCorrection;

  DetailDevoir({
    required this.id,
    required this.titre,
    required this.dateLimite,
    required this.nbRendus,
    required this.nbRetards,
    required this.tauxRendu,
    required this.noteMoyenne,
    required this.typeCorrection,
  });

  factory DetailDevoir.fromJson(Map<String, dynamic> json) {
    return DetailDevoir(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      dateLimite: DateTime.parse(json['date_limite'] as String),
      nbRendus: json['nb_rendus'] as int? ?? 0,
      nbRetards: json['nb_retards'] as int? ?? 0,
      tauxRendu: (json['taux_rendu'] as num? ?? 0).toDouble(),
      noteMoyenne: (json['note_moyenne'] as num? ?? 0).toDouble(),
      typeCorrection: json['type_correction'] as String? ?? 'auto',
    );
  }
}

class ApprenantRisque {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final double tauxRendu;
  final double moyenne;
  final String raison;

  ApprenantRisque({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.tauxRendu,
    required this.moyenne,
    required this.raison,
  });

  factory ApprenantRisque.fromJson(Map<String, dynamic> json) {
    return ApprenantRisque(
      id: json['id'] as int? ?? 0,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      tauxRendu: (json['taux_rendu'] as num? ?? 0).toDouble(),
      moyenne: (json['moyenne'] as num? ?? 0).toDouble(),
      raison: json['raison'] as String? ?? '',
    );
  }
}

class TendanceRendu {
  final DateTime date;
  final int nbRendus;

  TendanceRendu({required this.date, required this.nbRendus});

  factory TendanceRendu.fromJson(Map<String, dynamic> json) {
    return TendanceRendu(
      date: DateTime.parse(json['date'] as String),
      nbRendus: json['nb_rendus'] as int? ?? 0,
    );
  }
}

class RenduDetail {
  final int id;
  final String apprenant;
  final String devoir;
  final DateTime dateRendu;
  final double? note;
  final bool estEnRetard;

  RenduDetail({
    required this.id,
    required this.apprenant,
    required this.devoir,
    required this.dateRendu,
    this.note,
    required this.estEnRetard,
  });

  factory RenduDetail.fromJson(Map<String, dynamic> json) {
    return RenduDetail(
      id: json['id'] as int? ?? 0,
      apprenant: json['apprenant'] as String? ?? '',
      devoir: json['devoir'] as String? ?? '',
      dateRendu: DateTime.parse(json['date_rendu'] as String),
      note: json['note'] != null ? (json['note'] as num).toDouble() : null,
      estEnRetard: json['est_en_retard'] as bool? ?? false,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE
// ═══════════════════════════════════════════════════════════════════════════

class DashboardPrincipalPage extends StatefulWidget {
  final String nomEnseignant;
  final String roleEnseignant;
  final List<dynamic>? extraInfo;

  const DashboardPrincipalPage({
    super.key,
    required this.nomEnseignant,
    required this.roleEnseignant,
    this.extraInfo,
  });

  @override
  State<DashboardPrincipalPage> createState() => _DashboardPrincipalPageState();
}

class _DashboardPrincipalPageState extends State<DashboardPrincipalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _cours = [];
  List<Map<String, dynamic>> _enseignantsSecondaires = [];
  
  // Données dynamiques pour le suivi
  DashboardStats? _stats;
  List<DevoirParCours> _devoirsParCours = [];
  List<ApprenantRisque> _apprenantsRisque = [];
  List<TendanceRendu> _tendanceRendus = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _chargerDonnees();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── AUTHENTIFICATION ────────────────────────────────────────────────
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // ─── CHARGEMENT DES DONNÉES ──────────────────────────────────────────
  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _chargerDashboardStats(),
      _chargerCours(),
      _chargerEnseignantsSecondaires(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _chargerDashboardStats() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/principal/dashboard_stats/'),
        headers: headers,
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _stats = DashboardStats.fromJson(data);
          _devoirsParCours = (data['devoirs_par_cours'] as List? ?? [])
              .map((d) => DevoirParCours.fromJson(d))
              .toList();
          _apprenantsRisque = (data['apprenants_risque'] as List? ?? [])
              .map((a) => ApprenantRisque.fromJson(a))
              .toList();
          _tendanceRendus = (data['tendance_rendus'] as List? ?? [])
              .map((t) => TendanceRendu.fromJson(t))
              .toList();
        });
      } else {
        if (mounted) {
          ErrorHandler.showError(context, 'Erreur chargement statistiques (${res.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement dashboard stats: $e');
    }
  }

  Future<void> _chargerCours() async {
    final List<Map<String, dynamic>> cours = [];
    if (widget.extraInfo != null) {
      for (var c in widget.extraInfo!) {
        if (c is Map) {
          cours.add(Map<String, dynamic>.from(c));
        }
      }
    }
    setState(() => _cours = cours);
  }

  Future<void> _chargerEnseignantsSecondaires() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/enseignants_secondaires/'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          if (body is List) {
            _enseignantsSecondaires = body.map((e) => Map<String, dynamic>.from(e)).toList();
          } else if (body is Map) {
            for (final key in ['results', 'data', 'enseignants']) {
              if (body[key] is List) {
                _enseignantsSecondaires = (body[key] as List)
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();
                break;
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement enseignants secondaires: $e');
    }
  }

  // ─── ACTIONS SUR LES ENSEIGNANTS ─────────────────────────────────────
  Future<void> _ajouterEnseignantSecondaire(int coursId) async {
    List<int> selectedIds = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final cours = _cours.firstWhere(
            (c) => c['id'] == coursId,
            orElse: () => {},
          );
          final existants = (cours['enseignants'] as List? ?? [])
              .map((e) => e is Map ? e['id'] : e)
              .toSet();
          final candidats = _enseignantsSecondaires
              .where((e) => !existants.contains(e['id']))
              .toList();

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.72,
            decoration: const BoxDecoration(
              color: YekiColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              Text('Assigner des assistants',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('${candidats.length} enseignant(s) disponible(s)',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 20),
              Expanded(
                child: candidats.isEmpty
                    ? const Center(
                        child: Text('Tous les enseignants sont déjà assignés.',
                            style: TextStyle()),
                      )
                    : ListView.builder(
                        itemCount: candidats.length,
                        itemBuilder: (_, i) {
                          final ens = candidats[i];
                          final isSelected = selectedIds.contains(ens['id']);
                          final username = ens['user']?['username'] ?? ens['username'] ?? '';
                          final email = ens['user']?['email'] ?? ens['email'] ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? YekiColors.primaryDark.withValues(alpha: 0.05) : YekiColors.backgroundLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? YekiColors.primaryDark.withValues(alpha: 0.3) : YekiColors.borderLight,
                                width: 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              activeColor: YekiColors.primaryDark,
                              checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              title: Text(username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: email.isNotEmpty ? Text(email, style: const TextStyle(fontSize: 12)) : null,
                              value: isSelected,
                              onChanged: (v) => setS(() {
                                if (v == true) {
                                  selectedIds.add(ens['id'] as int);
                                } else {
                                  selectedIds.remove(ens['id']);
                                }
                              }),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              YekiButton(
                label: 'Ajouter ${selectedIds.length} sélection(s)',
                onPressed: selectedIds.isEmpty ? null : () async {
                  setS(() => _isLoading = true);
                  final headers = await _authHeaders();
                  bool success = true;

                  for (final id in selectedIds) {
                    try {
                      final res = await http.post(
                        Uri.parse('${ApiConstants.baseUrl}/cours/$coursId/add-enseignant/'),
                        headers: headers,
                        body: jsonEncode({'enseignant_id': id}),
                      );
                      if (res.statusCode != 200 && res.statusCode != 201) success = false;
                    } catch (_) {
                      success = false;
                    }
                  }

                  if (success) {
                    setState(() {
                      for (var c in _cours) {
                        if (c['id'] == coursId) {
                          final List sec = List.from(c['enseignants'] as List? ?? []);
                          for (final id in selectedIds) {
                            final added = _enseignantsSecondaires.firstWhere((e) => e['id'] == id, orElse: () => {});
                            if (added.isNotEmpty) sec.add(added);
                          }
                          c['enseignants'] = sec;
                        }
                      }
                    });
                    if (ctx.mounted) {
                      ErrorHandler.showSuccess(ctx, 'Enseignant(s) ajouté(s) avec succès !');
                    }
                  } else {
                    if (ctx.mounted) {
                      ErrorHandler.showError(ctx, 'Certains ajouts ont échoué.');
                    }
                  }

                  setS(() => _isLoading = false);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                isLoading: _isLoading,
              ),
            ]),
          );
        },
      ),
    );
  }

  Future<void> _retirerEnseignant(int coursId, int enseignantId, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text("Retirer l'assistant", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous retirer "$nom" de ce cours ?', style: const TextStyle()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: YekiColors.error, foregroundColor: YekiColors.white, elevation: 0),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final headers = await _authHeaders();
    try {
      final res = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/cours/$coursId/remove-enseignant/'),
        headers: headers,
        body: jsonEncode({'enseignant_id': enseignantId}),
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          for (var c in _cours) {
            if (c['id'] == coursId) {
              final List sec = List.from(c['enseignants'] as List? ?? []);
              sec.removeWhere((e) => (e is Map ? e['id'] : e) == enseignantId);
              c['enseignants'] = sec;
            }
          }
        });
        if (mounted) {
          ErrorHandler.showSuccess(context, 'Enseignant retiré avec succès.');
        }
      } else {
        final err = jsonDecode(res.body);
        if (mounted) {
          ErrorHandler.showError(context, err['detail'] ?? 'Erreur lors du retrait.');
        }
      }
    } catch (_) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur réseau.');
      }
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      body: _isLoading
          ? const Center(child: YekiLoader())
          : NestedScrollView(
              headerSliverBuilder: (_, _) => [
                _buildAppBar(),
                _buildTabBar(),
              ],
              body: TabBarView(
                controller: _tabCtrl,
                children: [_tabCours(), _tabSuivi(), _tabStats()],
              ),
            ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    final stats = _stats;
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: YekiColors.purple,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [YekiColors.purple, YekiColors.purple.withValues(alpha: 0.85)],
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
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "ENSEIGNANT PRINCIPAL",
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
                    (stats?.nom.isNotEmpty ?? false)
                        ? stats!.nom
                        : (widget.nomEnseignant.isNotEmpty
                              ? widget.nomEnseignant
                              : 'Enseignant Principal'),
                    style: const TextStyle(
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
                      color: YekiColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Enseignant Principal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _miniStatBadge('${stats?.nbCours ?? 0}', 'cours', Icons.book),
                      const SizedBox(width: 16),
                      _miniStatBadge('${stats?.nbApprenants ?? 0}', 'apprenants', Icons.people),
                      const SizedBox(width: 16),
                      _miniStatBadge('${stats?.nbLecons ?? 0}', 'leçons', Icons.article),
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
          onPressed: _chargerDonnees,
        ),
      ],
    );
  }

  // ─── TAB BAR ──────────────────────────────────────────────────────────
  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          labelColor: YekiColors.purple,
          unselectedLabelColor: YekiColors.textLight,
          indicatorColor: YekiColors.purple,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Mes Cours'),
            Tab(text: 'Suivi'),
            Tab(text: 'Statistiques'),
          ],
        ),
        backgroundColor: YekiColors.white,
      ),
    );
  }

  // ─── TAB 1 : COURS ────────────────────────────────────────────────────
  Widget _tabCours() {
    if (_cours.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: YekiColors.purple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: YekiColors.purple.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(Icons.book_outlined, size: 48, color: YekiColors.purple),
          ),
          const SizedBox(height: 16),
          const Text('Aucun cours assigné',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Les cours vous seront attribués par votre cadre',
              style: TextStyle(fontSize: 13)),
        ]),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _cours.map(_buildCoursCard).toList(),
    );
  }

  Widget _buildCoursCard(Map<String, dynamic> c) {
    final assistants = (c['enseignants'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final int lecons = (c['nb_lecons'] as num? ?? 0).toInt();
    final int devoirs = (c['nb_devoirs'] as num? ?? 0).toInt();
    final int apprenants = (c['nb_apprenants'] as num? ?? 0).toInt();
    final Color cardColor = _hexColor(c['color_code'] as String? ?? '#2884A0');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Column(children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardColor.withValues(alpha: 0.2), width: 0.8),
              ),
              child: Icon(Icons.book, color: cardColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(c['niveau'] ?? '', style: const TextStyle(fontSize: 12)),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            _badge2(Icons.article, '$lecons Leçons', Colors.blue),
            const SizedBox(width: 8),
            _badge2(Icons.assignment, '$devoirs Devoirs', YekiColors.warning),
            const SizedBox(width: 8),
            _badge2(Icons.people, '$apprenants Élèves', Colors.teal),
          ]),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text('Équipe (${assistants.length} assistant(s))',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            leading: Icon(Icons.people_outline, color: cardColor, size: 20),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (assistants.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Aucun assistant assigné.', style: const TextStyle(fontSize: 13)),
                ),
              ...assistants.map((e) {
                final username = e['user']?['username'] ?? e['username'] ?? 'Assistant';
                final email = e['user']?['email'] ?? e['email'] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: YekiColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: YekiColors.borderLight, width: 1),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: YekiColors.purple.withValues(alpha: 0.1),
                      child: Text(username.isNotEmpty ? username[0].toUpperCase() : 'A',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 11)),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: YekiColors.error, size: 20),
                      tooltip: 'Retirer',
                      onPressed: () => _retirerEnseignant(c['id'] as int, e['id'] as int, username),
                    ),
                  ]),
                );
              }),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => _ajouterEnseignantSecondaire(c['id'] as int),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter un assistant'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: YekiColors.primaryDark,
                  side: BorderSide(color: YekiColors.primaryDark.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  // ─── TAB 2 : SUIVI ────────────────────────────────────────────────────
  Widget _tabSuivi() {
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: YekiColors.purple,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKPIRow(),
            const SizedBox(height: 24),
            _sectionTitle('Tendance des rendus (7 jours)'),
            const SizedBox(height: 12),
            _buildTendanceChart(),
            const SizedBox(height: 24),
            _sectionTitle('Devoirs par cours'),
            const SizedBox(height: 12),
            _buildDevoirsParCours(),
            const SizedBox(height: 24),
            _sectionTitle('Élèves à risque'),
            const SizedBox(height: 12),
            _buildApprenantsRisque(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIRow() {
    final stats = _stats;
    if (stats == null) return const SizedBox();

    return Row(children: [
      _kpiCard('Rendu', '${stats.tauxRenduGlobal.toStringAsFixed(0)}%', 
          Icons.assignment_turned_in, YekiColors.success),
      const SizedBox(width: 12),
      _kpiCard('Moyenne', stats.moyenneGlobale.toStringAsFixed(1), 
          Icons.analytics, YekiColors.primaryDark),
      const SizedBox(width: 12),
      _kpiCard('Retards', stats.nbRetards.toString(), 
          Icons.timer_outlined, YekiColors.warning),
    ]);
  }

  Widget _buildTendanceChart() {
    if (_tendanceRendus.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YekiColors.borderLight, width: 1),
        ),
        child: const Center(child: Text('Aucune donnée de tendance disponible')),
      );
    }

    // Trier par date croissante
    final List<TendanceRendu> sorted = List<TendanceRendu>.from(_tendanceRendus)..sort((TendanceRendu a, TendanceRendu b) =>a.date.compareTo(b.date),);
    final int maxValue = sorted.fold<int>(0,(max, t) => t.nbRendus.toInt() > max ? t.nbRendus.toInt(): max,);
    final double maxDisplay = maxValue > 0 ? maxValue.toDouble() : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Derniers 7 jours', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('Total: ${sorted.fold<int>(0,(sum, t) => sum + t.nbRendus.toInt())} rendus',
                  style: const TextStyle(fontSize: 12, color: YekiColors.textLight)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sorted.map((t) {
                final double height = (t.nbRendus / maxDisplay) * 80.0;
                final bool isToday = t.date.day == DateTime.now().day &&
                    t.date.month == DateTime.now().month &&
                    t.date.year == DateTime.now().year;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (t.nbRendus > 0)
                        Text(
                          t.nbRendus.toString(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: isToday ? YekiColors.purple : YekiColors.purple.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM').format(t.date),
                        style: const TextStyle(fontSize: 10, color: YekiColors.textLight),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevoirsParCours() {
    if (_devoirsParCours.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YekiColors.borderLight, width: 1),
        ),
        child: const Center(child: Text('Aucun devoir créé')),
      );
    }

    return Column(
      children: _devoirsParCours.map((dpc) => _buildDevoirParCoursCard(dpc)).toList(),
    );
  }

  Widget _buildDevoirParCoursCard(DevoirParCours dpc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dpc.coursTitre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${dpc.nbDevoirs} devoir(s) · Taux: ${dpc.tauxRendu.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: YekiColors.textLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: dpc.tauxRendu >= 70 
                      ? YekiColors.success.withValues(alpha: 0.1)
                      : dpc.tauxRendu >= 40
                          ? YekiColors.warning.withValues(alpha: 0.1)
                          : YekiColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dpc.tauxRendu.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: dpc.tauxRendu >= 70 
                        ? YekiColors.success
                        : dpc.tauxRendu >= 40
                            ? YekiColors.warning
                            : YekiColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (dpc.detailsDevoirs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucun devoir pour ce cours'),
              )
            else
              ...dpc.detailsDevoirs.map((dd) => _buildDetailDevoirCard(dd, dpc.coursId)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailDevoirCard(DetailDevoir dd, int coursId) {
    final bool isOverdue = dd.dateLimite.isBefore(DateTime.now());
    final Color color = dd.tauxRendu >= 70 
        ? YekiColors.success
        : dd.tauxRendu >= 40
            ? YekiColors.warning
            : YekiColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: YekiColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: InkWell(
        onTap: () => _showRendusDetails(dd),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dd.titre,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        'Limite: ${DateFormat('dd/MM/yyyy').format(dd.dateLimite)} ${isOverdue ? '(En retard)' : ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue ? YekiColors.error : YekiColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${dd.tauxRendu.toStringAsFixed(0)}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniBadge('${dd.nbRendus} rendus', Icons.check_circle, Colors.blue),
                const SizedBox(width: 8),
                _miniBadge('${dd.nbRetards} retards', Icons.warning, YekiColors.warning),
                const SizedBox(width: 8),
                _miniBadge('Moy: ${dd.noteMoyenne.toStringAsFixed(1)}/20', Icons.grade, YekiColors.accent),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.touch_app, size: 12, color: YekiColors.textLight),
                const SizedBox(width: 4),
                Text('Toucher pour voir les détails', 
                    style: TextStyle(fontSize: 10, color: YekiColors.textLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRendusDetails(DetailDevoir dd) async {
    final headers = await _authHeaders();
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/principal/rendus_devoirs/?devoir_id=${dd.id}'),
        headers: headers,
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rendus = (data['rendus'] as List? ?? [])
            .map((r) => RenduDetail.fromJson(r))
            .toList();
        
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (ctx) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: YekiColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                Text(
                  dd.titre,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${rendus.length} rendus · ${dd.tauxRendu.toStringAsFixed(0)}% de taux',
                  style: const TextStyle(fontSize: 14, color: YekiColors.textLight),
                ),
                const SizedBox(height: 16),
                if (rendus.isEmpty)
                  const Center(child: Text('Aucun rendu pour ce devoir'))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: rendus.length,
                      itemBuilder: (_, i) {
                        final r = rendus[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: YekiColors.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: YekiColors.borderLight, width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.apprenant,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      '${DateFormat('dd/MM/yyyy HH:mm').format(r.dateRendu)}${r.estEnRetard ? ' (En retard)' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: r.estEnRetard ? YekiColors.error : YekiColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (r.note != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (r.note! >= 10 ? YekiColors.success : YekiColors.error)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${r.note!.toStringAsFixed(1)}/20',
                                    style: TextStyle(
                                      color: r.note! >= 10 ? YekiColors.success : YekiColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      } else {
        if (mounted) {
          ErrorHandler.showError(context, 'Erreur chargement des rendus (${res.statusCode})');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur réseau');
      }
    }
  }

  Widget _buildApprenantsRisque() {
    if (_apprenantsRisque.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YekiColors.borderLight, width: 1),
        ),
        child: const Center(child: Text('Aucun élève à risque')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Column(
        children: _apprenantsRisque.map((ar) => _buildApprenantRisqueTile(ar)).toList(),
      ),
    );
  }

  Widget _buildApprenantRisqueTile(ApprenantRisque ar) {
    final Color color = ar.tauxRendu < 50 ? YekiColors.error : YekiColors.warning;
    final IconData icon = ar.tauxRendu < 50 ? Icons.priority_high : Icons.warning_amber_rounded;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: YekiColors.borderLight)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Text(
              ar.prenom.isNotEmpty ? ar.prenom[0].toUpperCase() : '?',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ar.prenom} ${ar.nom}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Row(
                  children: [
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      ar.raison,
                      style: TextStyle(fontSize: 11, color: color),
                    ),
                  ],
                ),
                Text(
                  'Rendu: ${ar.tauxRendu.toStringAsFixed(0)}% · Moy: ${ar.moyenne.toStringAsFixed(1)}/20',
                  style: const TextStyle(fontSize: 11, color: YekiColors.textLight),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // Action pour contacter l'apprenant
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: YekiColors.purple,
              side: BorderSide(color: YekiColors.purple.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Contacter', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ─── TAB 3 : STATISTIQUES ─────────────────────────────────────────────
  Widget _tabStats() {
    final stats = _stats;
    if (stats == null) return const Center(child: Text('Aucune statistique disponible'));

    final items = [
      _StatInfo('Cours', '${stats.nbCours}', Icons.book, YekiColors.purple),
      _StatInfo('Apprenants', '${stats.nbApprenants}', Icons.people, Colors.teal),
      _StatInfo('Leçons', '${stats.nbLecons}', Icons.article, Colors.blue),
      _StatInfo('Devoirs', '${stats.nbDevoirs}', Icons.assignment_outlined, YekiColors.warning),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: items.map(_buildStatCard).toList(),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Performance globale'),
        const SizedBox(height: 12),
        _buildPerformanceCard(stats),
      ]),
    );
  }

  Widget _buildStatCard(_StatInfo item) => Container(
    decoration: BoxDecoration(
      color: YekiColors.white,
      borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withValues(alpha: 0.2), width: 0.8),
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        const SizedBox(height: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: item.color)),
          Text(item.label, style: const TextStyle(fontSize: 12)),
        ]),
      ],
    ),
  );

  Widget _buildPerformanceCard(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [YekiColors.purple, YekiColors.purple.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.bar_chart, color: YekiColors.white, size: 20),
          SizedBox(width: 8),
          Text('Résumé de vos cours', style: TextStyle(color: YekiColors.white, fontSize: 14)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _perfItem('${stats.nbCours}', 'Cours actifs')),
          Expanded(child: _perfItem('${stats.nbLecons}', 'Leçons publiées')),
          Expanded(child: _perfItem('${stats.nbDevoirs}', 'Devoirs créés')),
        ]),
      ]),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────
  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return YekiColors.purple;
    }
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(8)),
    ),
  );

  Widget _miniStatBadge(String value, String label, IconData icon) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: YekiColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: YekiColors.white, size: 12),
          const SizedBox(width: 5),
          Text('$value $label', style: const TextStyle(color: YekiColors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _badge2(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold));

  Widget _kpiCard(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YekiColors.borderLight, width: 1),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10)),
          ]),
        ),
      );

  Widget _perfItem(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(color: YekiColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: YekiColors.white, fontSize: 11), textAlign: TextAlign.center),
  ]);

  Widget _miniBadge(String text, IconData icon, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 11, color: color)),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CLASSES AUXILIAIRES
// ═══════════════════════════════════════════════════════════════════════════

class _StatInfo {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatInfo(this.label, this.value, this.icon, this.color);
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  const _TabBarDelegate(this.tabBar, {this.backgroundColor = YekiColors.white});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) =>
      Container(color: backgroundColor, child: tabBar);

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => old.tabBar != tabBar;
}