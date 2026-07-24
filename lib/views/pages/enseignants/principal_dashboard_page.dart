// lib/views/pages/enseignants/principal_dashboard_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// ENSEIGNANT PRINCIPAL DASHBOARD — DESIGN SYSTÈME YEKI
// VERSION ROBUSTE AVEC GESTION DES ERREURS ET NULL SAFETY
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';
import 'package:intl/intl.dart';
import 'package:yeki/core/router/route_names.dart';

// ═══════════════════════════════════════════════════════════════════════════
// MODÈLES DE DONNÉES — AVEC GESTION DES NULL
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
    final detailsRaw = json['details_devoirs'] as List?;
    List<DetailDevoir> detailsDevoirs = [];
    
    if (detailsRaw != null) {
      for (final d in detailsRaw) {
        try {
          if (d is Map<String, dynamic>) {
            detailsDevoirs.add(DetailDevoir.fromJson(d));
          }
        } catch (e) {
          debugPrint('Erreur parsing devoir: $e');
        }
      }
    }

    return DevoirParCours(
      coursId: json['cours_id'] as int? ?? 0,
      coursTitre: json['cours_titre'] as String? ?? '',
      nbDevoirs: json['nb_devoirs'] as int? ?? 0,
      tauxRendu: (json['taux_rendu'] as num? ?? 0).toDouble(),
      detailsDevoirs: detailsDevoirs,
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
    // Gestion robuste de la date limite
    final rawDate = json['date_limite'];
    DateTime dateLimite;
    
    if (rawDate != null && rawDate is String) {
      try {
        dateLimite = DateTime.parse(rawDate);
      } catch (e) {
        debugPrint('Erreur parsing date: $e');
        dateLimite = DateTime.now();
      }
    } else {
      dateLimite = DateTime.now();
    }

    return DetailDevoir(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      dateLimite: dateLimite,
      nbRendus: json['nb_rendus'] as int? ?? 0,
      nbRetards: json['nb_retards'] as int? ?? 0,
      tauxRendu: (json['taux_rendu'] as num? ?? 0).toDouble(),
      noteMoyenne: (json['note_moyenne'] as num? ?? 0).toDouble(),
      typeCorrection: json['type_correction'] as String? ?? 'auto',
    );
  }
}

class TendanceRendu {
  final DateTime date;
  final int nbRendus;

  TendanceRendu({required this.date, required this.nbRendus});

  factory TendanceRendu.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    DateTime date;
    
    if (rawDate != null && rawDate is String) {
      try {
        date = DateTime.parse(rawDate);
      } catch (e) {
        debugPrint('Erreur parsing date tendance: $e');
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

    return TendanceRendu(
      date: date,
      nbRendus: json['nb_rendus'] as int? ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE
// ═══════════════════════════════════════════════════════════════════════════

/// Autonome : fetch ses propres cours/statistiques (déjà le cas avant
/// P3.3 — `nomEnseignant`/`roleEnseignant`/`extraInfo` n'étaient déjà
/// utilisés nulle part dans le corps du widget, uniquement transmis puis
/// jamais lus).
class DashboardPrincipalPage extends StatefulWidget {
  const DashboardPrincipalPage({super.key});

  @override
  State<DashboardPrincipalPage> createState() => _DashboardPrincipalPageState();
}

class _DashboardPrincipalPageState extends State<DashboardPrincipalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _cours = [];
  
  // Données dynamiques
  DashboardStats? _stats;
  List<DevoirParCours> _devoirsParCours = [];
  List<Map<String, dynamic>> _apprenantsRisque = [];
  List<TendanceRendu> _tendanceRendus = [];
  
  bool _isLoading = true;
  String _errorMessage = '';

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
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    // Charger indépendamment pour éviter qu'une erreur bloque tout
    try {
      await _chargerDashboardStats();
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
    }
    
    try {
      await _chargerCours();
    } catch (e) {
      debugPrint('Erreur chargement cours: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _chargerDashboardStats() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse(ApiConstants.principalDashboard),
        headers: headers,
      );
      
      debugPrint('Dashboard stats status: ${res.statusCode}');
      debugPrint('Dashboard stats body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}...');
      
      if (res.statusCode == 200 && mounted) {
        try {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          
          setState(() {
            _stats = DashboardStats.fromJson(data);
            
            // Gestion robuste des listes
            final devoirsRaw = data['devoirs_par_cours'];
            if (devoirsRaw is List) {
              _devoirsParCours = devoirsRaw
                  .whereType<Map<String, dynamic>>()
                  .map((d) => DevoirParCours.fromJson(d))
                  .where((d) => d.coursId > 0)
                  .toList();
            }
            
            final apprenantsRaw = data['apprenants_risque'];
            if (apprenantsRaw is List) {
              _apprenantsRisque = apprenantsRaw
                  .whereType<Map<String, dynamic>>()
                  .toList();
            }
            
            final tendanceRaw = data['tendance_rendus'];
            if (tendanceRaw is List) {
              _tendanceRendus = tendanceRaw
                  .whereType<Map<String, dynamic>>()
                  .map((t) => TendanceRendu.fromJson(t))
                  .where((t) => t.date.year > 2000) // Filtrer les dates invalides
                  .toList();
            }
          });
        } catch (e) {
          debugPrint('Erreur parsing stats: $e');
        }
      } else if (res.statusCode == 403) {
        setState(() {
          _errorMessage = 'Accès non autorisé.';
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _errorMessage = 'Endpoint non trouvé.';
        });
      } else if (res.statusCode != 200) {
        setState(() {
          _errorMessage = 'Erreur ${res.statusCode}';
        });
      }
    } catch (e) {
      debugPrint('Exception dans _chargerDashboardStats: $e');
      setState(() {
        _errorMessage = 'Erreur réseau: ${e.toString()}';
      });
    }
  }

  Future<void> _chargerCours() async {
    try {
      final headers = await _authHeaders();
      final res = await http.get(
        Uri.parse(ApiConstants.enseignantPrincipalCours),
        headers: headers,
      );
      
      debugPrint('Cours status: ${res.statusCode}');
      
      if (res.statusCode == 200 && mounted) {
        try {
          final data = jsonDecode(res.body);
          if (data is List) {
            setState(() {
              _cours = data
                  .whereType<Map<String, dynamic>>()
                  .toList();
            });
            debugPrint('✅ ${_cours.length} cours chargés');
          }
        } catch (e) {
          debugPrint('Erreur parsing cours: $e');
        }
      } else if (res.statusCode == 403) {
        setState(() {
          _errorMessage = 'Accès non autorisé pour les cours.';
        });
      } else if (res.statusCode == 404) {
        setState(() {
          _errorMessage = 'Endpoint des cours non trouvé.';
        });
      }
    } catch (e) {
      debugPrint('Exception dans _chargerCours: $e');
    }
  }

  // ─── ACTIONS SUR LES ENSEIGNANTS ─────────────────────────────────────
  Future<void> _retirerEnseignant(int coursId, int enseignantId, String nom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text("Retirer l'assistant", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Voulez-vous retirer "$nom" de ce cours ?', style: const TextStyle()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: YekiColors.error,
              foregroundColor: YekiColors.white,
              elevation: 0,
            ),
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

  Future<void> _ajouterEnseignantSecondaire(int coursId) async {
    final headers = await _authHeaders();
    List<Map<String, dynamic>> enseignantsDisponibles = [];
    
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/enseignants/liste/?role=enseignant'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          enseignantsDisponibles = data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (_) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur de chargement des enseignants');
      }
      return;
    }

    if (!mounted) return;

    final cours = _cours.firstWhere(
      (c) => c['id'] == coursId,
      orElse: () => {},
    );
    
    final existants = (cours['enseignants'] as List? ?? [])
        .map((e) => e is Map ? e['id'] : e)
        .toSet();
    
    final candidats = enseignantsDisponibles
        .where((e) => !existants.contains(e['id']))
        .toList();

    List<int> selectedIds = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.72,
            decoration: const BoxDecoration(
              color: YekiColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                _sheetHandle(),
                const SizedBox(height: 20),
                Text(
                  'Assigner des assistants',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.textDark),
                ),
                Text(
                  '${candidats.length} enseignant(s) disponible(s)',
                  style: const TextStyle(fontSize: 12, color: YekiColors.textLight),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: candidats.isEmpty
                      ? const Center(
                          child: Text(
                            'Tous les enseignants sont déjà assignés.',
                            style: TextStyle(color: YekiColors.textMedium),
                          ),
                        )
                      : ListView.builder(
                          itemCount: candidats.length,
                          itemBuilder: (_, i) {
                            final ens = candidats[i];
                            final isSelected = selectedIds.contains(ens['id']);
                            final username = ens['nom'] ?? ens['username'] ?? '';
                            final email = ens['email'] ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? YekiColors.primaryDark.withAlpha(13) 
                                    : YekiColors.backgroundLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected 
                                      ? YekiColors.primaryDark.withAlpha(76) 
                                      : YekiColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              child: CheckboxListTile(
                                activeColor: YekiColors.primaryDark,
                                checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                title: Text(
                                  username,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: YekiColors.textDark),
                                ),
                                subtitle: email.isNotEmpty 
                                    ? Text(email, style: const TextStyle(fontSize: 12, color: YekiColors.textMedium)) 
                                    : null,
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
                    bool success = true;

                    for (final id in selectedIds) {
                      try {
                        final res = await http.post(
                          Uri.parse('${ApiConstants.baseUrl}/cours/$coursId/add-enseignant/'),
                          headers: await _authHeaders(),
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
                              final added = candidats.firstWhere((e) => e['id'] == id, orElse: () => {});
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: YekiColors.borderLight,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  // ─── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      body: _isLoading
          ? const Center(child: YekiLoader())
          : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : NestedScrollView(
                  headerSliverBuilder: (_, _) => [
                    _buildTabBar(),
                  ],
                  body: TabBarView(
                    controller: _tabCtrl,
                    children: [_tabCours(), _tabSuivi(), _tabStats()],
                  ),
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: YekiColors.error.withAlpha(179),
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: YekiColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: YekiColors.textMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _chargerDonnees,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: YekiColors.primaryDark,
                foregroundColor: YekiColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
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
              color: YekiColors.purple.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: YekiColors.purple.withAlpha(51), width: 1),
            ),
            child: Icon(Icons.book_outlined, size: 48, color: YekiColors.purple),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun cours assigné',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Les cours vous seront attribués par votre cadre',
            style: TextStyle(fontSize: 13, color: YekiColors.textMedium),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _chargerDonnees,
      color: YekiColors.purple,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _cours.map(_buildCoursCard).toList(),
      ),
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
    final int coursId = c['id'] as int? ?? 0;

    return GestureDetector(
      onTap: () {
        if (coursId > 0) {
          context.pushNamed(
            AppRoute.coursDetailEnseignant,
            pathParameters: {'coursId': coursId.toString()},
            queryParameters: {
              'titre': (c['titre'] ?? '') as String,
              'estEnseignantPrincipal': 'true',
              'courseColor': cardColor.value.toString(),
            },
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YekiColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardColor.withAlpha(13),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardColor.withAlpha(51), width: 0.8),
                    ),
                    child: Icon(Icons.book, color: cardColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['titre'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: YekiColors.textDark),
                        ),
                        Text(
                          c['niveau'] ?? '',
                          style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: YekiColors.textLight,
                    size: 20,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _badge2(Icons.article, '$lecons Leçons', YekiColors.info),
                  const SizedBox(width: 8),
                  _badge2(Icons.assignment, '$devoirs Devoirs', YekiColors.warning),
                  const SizedBox(width: 8),
                  _badge2(Icons.people, '$apprenants Élèves', YekiColors.success),
                ],
              ),
            ),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  'Équipe (${assistants.length} assistant${assistants.length > 1 ? 's' : ''})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: YekiColors.textDark),
                ),
                leading: Icon(Icons.people_outline, color: cardColor, size: 20),
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (assistants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Aucun assistant assigné.',
                        style: const TextStyle(fontSize: 13, color: YekiColors.textMedium),
                      ),
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
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: YekiColors.purple.withAlpha(26),
                            child: Text(
                              username.isNotEmpty ? username[0].toUpperCase() : 'A',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: YekiColors.textDark),
                                ),
                                if (email.isNotEmpty)
                                  Text(email, style: const TextStyle(fontSize: 11, color: YekiColors.textMedium)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: YekiColors.error, size: 20),
                            tooltip: 'Retirer',
                            onPressed: () => _retirerEnseignant(c['id'] as int, e['id'] as int, username),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () => _ajouterEnseignantSecondaire(c['id'] as int),
                    icon: const Icon(Icons.add, size: 16, color: YekiColors.primaryDark),
                    label: const Text('Ajouter un assistant', style: TextStyle(color: YekiColors.primaryDark)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: YekiColors.primaryDark,
                      side: BorderSide(color: YekiColors.primaryDark.withAlpha(102)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

    return Row(
      children: [
        _kpiCard('Rendu', '${stats.tauxRenduGlobal.toStringAsFixed(0)}%', 
            Icons.assignment_turned_in, YekiColors.success),
        const SizedBox(width: 12),
        _kpiCard('Moyenne', stats.moyenneGlobale.toStringAsFixed(1), 
            Icons.analytics, YekiColors.primaryDark),
        const SizedBox(width: 12),
        _kpiCard('Retards', stats.nbRetards.toString(), 
            Icons.timer_outlined, YekiColors.warning),
      ],
    );
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
        child: const Center(
          child: Text(
            'Aucune donnée de tendance disponible',
            style: TextStyle(color: YekiColors.textMedium),
          ),
        ),
      );
    }

    final List<TendanceRendu> sorted = List<TendanceRendu>.from(_tendanceRendus)
      ..sort((a, b) => a.date.compareTo(b.date));
    final int maxValue = sorted.fold<int>(0, (max, t) => t.nbRendus.toInt() > max ? t.nbRendus.toInt() : max);
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
              Text(
                'Derniers 7 jours',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: YekiColors.textDark),
              ),
              Text(
                'Total: ${sorted.fold<int>(0, (sum, t) => sum + t.nbRendus.toInt())} rendus',
                style: const TextStyle(fontSize: 12, color: YekiColors.textLight),
              ),
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
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: YekiColors.textDark),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: isToday ? YekiColors.purple : YekiColors.purple.withAlpha(128),
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
        child: const Center(
          child: Text('Aucun devoir créé', style: TextStyle(color: YekiColors.textMedium)),
        ),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: YekiColors.textDark),
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
                      ? YekiColors.success.withAlpha(26)
                      : dpc.tauxRendu >= 40
                          ? YekiColors.warning.withAlpha(26)
                          : YekiColors.error.withAlpha(26),
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
                child: Text(
                  'Aucun devoir pour ce cours',
                  style: TextStyle(color: YekiColors.textMedium),
                ),
              )
            else
              ...dpc.detailsDevoirs.map((dd) => _buildDetailDevoirCard(dd)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailDevoirCard(DetailDevoir dd) {
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: YekiColors.textDark),
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
                  color: color.withAlpha(26),
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
              _miniBadge('${dd.nbRendus} rendus', Icons.check_circle, YekiColors.info),
              const SizedBox(width: 8),
              _miniBadge('${dd.nbRetards} retards', Icons.warning, YekiColors.warning),
              const SizedBox(width: 8),
              _miniBadge('Moy: ${dd.noteMoyenne.toStringAsFixed(1)}/20', Icons.grade, YekiColors.accent),
            ],
          ),
        ],
      ),
    );
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
        child: const Center(
          child: Text('Aucun élève à risque', style: TextStyle(color: YekiColors.textMedium)),
        ),
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

  Widget _buildApprenantRisqueTile(Map<String, dynamic> ar) {
    final taux = (ar['taux_rendu'] as num? ?? 0).toDouble();
    final Color color = taux < 50 ? YekiColors.error : YekiColors.warning;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: YekiColors.borderLight)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withAlpha(26),
            child: Text(
              (ar['prenom'] as String? ?? '?')[0].toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ar['prenom'] ?? ''} ${ar['nom'] ?? ''}'.trim(),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: YekiColors.textDark),
                ),
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(
                      ar['raison'] ?? 'Taux de rendu faible',
                      style: TextStyle(fontSize: 11, color: color),
                    ),
                  ],
                ),
                Text(
                  'Rendu: ${taux.toStringAsFixed(0)}% · Moy: ${(ar['moyenne'] as num? ?? 0).toStringAsFixed(1)}/20',
                  style: const TextStyle(fontSize: 11, color: YekiColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 3 : STATISTIQUES ─────────────────────────────────────────────
  Widget _tabStats() {
    final stats = _stats;
    if (stats == null) {
      return const Center(
        child: Text(
          'Aucune statistique disponible',
          style: TextStyle(color: YekiColors.textMedium),
        ),
      );
    }

    final items = [
      _StatInfo('Cours', '${stats.nbCours}', Icons.book, YekiColors.purple),
      _StatInfo('Apprenants', '${stats.nbApprenants}', Icons.people, YekiColors.success),
      _StatInfo('Leçons', '${stats.nbLecons}', Icons.article, YekiColors.info),
      _StatInfo('Devoirs', '${stats.nbDevoirs}', Icons.assignment_outlined, YekiColors.warning),
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
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
            color: item.color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.color.withAlpha(51), width: 0.8),
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: item.color),
            ),
            Text(
              item.label,
              style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildPerformanceCard(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [YekiColors.purple, YekiColors.purple.withAlpha(217)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: YekiColors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Résumé de vos cours',
                style: TextStyle(color: YekiColors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _perfItem('${stats.nbCours}', 'Cours actifs')),
              Expanded(child: _perfItem('${stats.nbLecons}', 'Leçons publiées')),
              Expanded(child: _perfItem('${stats.nbDevoirs}', 'Devoirs créés')),
            ],
          ),
        ],
      ),
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

  Widget _badge2(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha(26),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: YekiColors.textDark),
  );

  Widget _kpiCard(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: YekiColors.borderLight, width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.textDark),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: YekiColors.textLight),
              ),
            ],
          ),
        ),
      );

  Widget _perfItem(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(color: YekiColors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      Text(
        label,
        style: const TextStyle(color: YekiColors.white, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _miniBadge(String text, IconData icon, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(fontSize: 11, color: color),
      ),
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