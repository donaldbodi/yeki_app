// lib/views/pages/enseignants/cadre_dashboard_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// CADRE DASHBOARD — VERSION COMPLÈTE AVEC DESIGN SYSTÈME
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/widgets/creer_cours_sheet.dart';
import 'package:yeki/widgets/modifier_cours_sheet.dart';
import 'package:yeki/features/olympiades/presentation/widgets/creer_olympiade_sheet.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE
// ═══════════════════════════════════════════════════════════════════════════

class CadreDashboardPage extends StatefulWidget {
  const CadreDashboardPage({super.key});

  @override
  State<CadreDashboardPage> createState() => _CadreDashboardPageState();
}

class _CadreDashboardPageState extends State<CadreDashboardPage>
    with SingleTickerProviderStateMixin {
  // ── États ──────────────────────────────────────────────────────
  bool _loading = true;
  List<Map<String, dynamic>> _departements = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _olympiades = [];
  List<Map<String, dynamic>> _enseignantsPrincipaux = [];
  late TabController _tabCtrl;
  int? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────
  Future<String?> _getToken() async =>
      (await SharedPreferences.getInstance()).getString('token');

  // ── Chargement des données ──────────────────────────────────
  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorHandler.showError(context, 'Veuillez vous reconnecter.');
      }
      return;
    }

    try {
      await _chargerDashboard(token);
      await _chargerOlympiades(token);

      if (mounted) {
        setState(() => _loading = false);
        
        // Si un département est sélectionné et qu'il existe toujours
        if (_selectedDeptId != null && _departements.isNotEmpty) {
          final exists = _departements.any((d) => d['id'] == _selectedDeptId);
          if (!exists) {
            _selectedDeptId = _departements[0]['id'];
          }
        } else if (_departements.isNotEmpty) {
          _selectedDeptId = _departements[0]['id'];
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorHandler.showError(context, 'Erreur de chargement: $e');
      }
    }
  }

  Future<void> _chargerDashboard(String token) async {
    final res = await http.get(
      Uri.parse(ApiConstants.enseignantCadreDashboard),
      headers: ApiHeaders.auth(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (mounted) {
        setState(() {
          _stats = Map<String, dynamic>.from(data['stats'] ?? {});
          _departements = List<Map<String, dynamic>>.from(data['departements'] ?? []);
          _enseignantsPrincipaux = List<Map<String, dynamic>>.from(data['enseignants_principaux'] ?? []);
        });
      }
    } else if (res.statusCode == 403) {
      if (mounted) {
        ErrorHandler.showError(context, 'Accès non autorisé.');
      }
    } else {
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur chargement (${res.statusCode})');
      }
    }
  }

  Future<void> _chargerOlympiades(String token) async {
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.mesOlympiadesCadre),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _olympiades = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {
      // Ignorer l'erreur, les olympiades resteront vides
    }
  }

  // ── Getters ──────────────────────────────────────────────────
  Map<String, dynamic>? get _currentDepartement {
    if (_selectedDeptId == null || _departements.isEmpty) return null;
    try {
      return _departements.firstWhere((d) => d['id'] == _selectedDeptId);
    } catch (_) {
      return _departements.isNotEmpty ? _departements[0] : null;
    }
  }

  int get _nbOlympiadesEnAttente {
    return _olympiades.where((o) => 
      o['est_validee'] == false && o['est_refusee'] == false
    ).length;
  }

  // ── Actions ──────────────────────────────────────────────────
  void _ouvrirGestionDemandes(Map<String, dynamic> dept) {
    context.pushNamed(
      AppRoute.cadreGestionDemandes,
      pathParameters: {'departementId': (dept['id'] as int).toString()},
      queryParameters: {'departementNom': dept['nom'] as String? ?? ''},
    ).then((_) => _charger());
  }

  void _ouvrirDetailDepartement(Map<String, dynamic> dept) {
    context.pushNamed(
      AppRoute.cadreDepartementDetail,
      pathParameters: {'departementId': dept['id'].toString()},
      queryParameters: {'departementNom': dept['nom']?.toString() ?? ''},
      extra: dept,
    ).then((_) => _charger());
  }

  void _changerEnseignantPrincipal(Map<String, dynamic> cours) async {
    final token = await _getToken();
    if (token == null) return;

    List<dynamic> enseignants = [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/enseignants/liste/?role=principal'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        enseignants = jsonDecode(res.body);
      } else {
        if (mounted) {
          ErrorHandler.showError(context, 'Impossible de charger les enseignants');
        }
        return;
      }
    } catch (_) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur réseau');
      }
      return;
    }

    if (!mounted) return;

    int? selected = cours['enseignant_principal']?['id'] as int?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 20),
              Text(
                'Changer l\'enseignant principal',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                'Cours : ${cours['titre'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: YekiColors.textMedium),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                ),
                child: enseignants.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun enseignant principal disponible',
                          style: TextStyle(color: YekiColors.textMedium),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: enseignants.map<Widget>(
                          (e) => RadioListTile<int>(
                            value: e['id'] as int,
                            groupValue: selected,
                            activeColor: YekiColors.primaryDark,
                            title: Text(
                              e['nom'] ?? e['username'] ?? '',
                              style: const TextStyle(color: YekiColors.textDark),
                            ),
                            subtitle: Text(
                              e['email'] ?? '',
                              style: const TextStyle(color: YekiColors.textMedium),
                            ),
                            onChanged: (v) => setS(() => selected = v),
                          ),
                        ).toList(),
                      ),
              ),
              const SizedBox(height: 20),
              YekiButton(
                label: 'Confirmer',
                onPressed: selected == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _applyChangerEnseignant(
                          cours['id'] as int,
                          selected!,
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyChangerEnseignant(int coursId, int enseignantId) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final res = await http.patch(
        Uri.parse(ApiConstants.coursChangerPrincipal(coursId)),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({'enseignant_principal_id': enseignantId}),
      );
      if (mounted) {
        if (res.statusCode == 200) {
          ErrorHandler.showSuccess(context, 'Enseignant principal modifié !');
          _charger();
        } else {
          final err = jsonDecode(res.body);
          ErrorHandler.showError(context, err['detail'] ?? 'Erreur lors du changement');
        }
      }
    } catch (_) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur réseau');
      }
    }
  }

  void _ouvrirCreerCours() {
    final currentDept = _currentDepartement;
    if (currentDept == null) {
      ErrorHandler.showError(context, 'Aucun département assigné.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreerCoursSheet(
        departementId: currentDept['id'] as int,
        departementNom: currentDept['nom'] as String? ?? '',
        onSuccess: _charger,
      ),
    );
  }

  void _ouvrirModifierCours(Map<String, dynamic> cours) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ModifierCoursSheet(
        cours: cours,
        onSuccess: _charger,
      ),
    );
  }

  void _ouvrirCreerOlympiade() {
    final currentDept = _currentDepartement;
    if (currentDept == null) {
      ErrorHandler.showError(context, 'Aucun département assigné.');
      return;
    }

    final parcoursType = currentDept['parcours_type']?.toString() ?? 'cursus';

    ouvrirCreerOlympiade(
      context,
      departementId: currentDept['id'] as int,
      departementNom: currentDept['nom'] as String? ?? '',
      parcoursType: parcoursType,
      onSuccess: () {
        ErrorHandler.showSuccess(context, 'Olympiade créée !');
        _charger();
      },
    );
  }

  void _ouvrirDetailOlympiade(Map<String, dynamic> olympiade) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _OlympiadeDetailSheet(olympiade: olympiade),
    );
  }

  void _afficherMenuActions() {
    if (_departements.isEmpty) {
      ErrorHandler.showError(context, 'Aucun département assigné');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              const Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: YekiColors.textDark,
                ),
              ),
              const SizedBox(height: 20),

              if (_departements.length > 1) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: YekiColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: YekiColors.borderLight, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedDeptId,
                      isExpanded: true,
                      hint: const Text('Sélectionner un département'),
                      items: _departements.map((dept) {
                        return DropdownMenuItem<int>(
                          value: dept['id'],
                          child: Text(dept['nom'] ?? 'Département'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setS(() => _selectedDeptId = value);
                      },
                    ),
                  ),
                ),
              ],

              _buildActionTile(
                icon: Icons.book_outlined,
                label: 'Créer un cours',
                subtitle: 'Ajouter un nouveau cours au département',
                color: YekiColors.primaryDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _ouvrirCreerCours();
                },
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                icon: Icons.emoji_events,
                label: 'Créer une olympiade',
                subtitle: 'Organiser une compétition académique',
                color: YekiColors.gold,
                onTap: () {
                  Navigator.pop(ctx);
                  _ouvrirCreerOlympiade();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: YekiColors.textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 14),
            ],
          ),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final hasDepartements = _departements.isNotEmpty;
    final nbEnAttente = _nbOlympiadesEnAttente;

    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      floatingActionButton: hasDepartements
          ? FloatingActionButton(
              backgroundColor: YekiColors.primaryDark,
              elevation: 4,
              onPressed: _afficherMenuActions,
              child: const Icon(Icons.add_rounded, color: YekiColors.white, size: 28),
            )
          : null,
      body: _loading
          ? const Center(child: YekiLoader())
          : NestedScrollView(
              headerSliverBuilder: (_, _) => [
                _buildTabBar(nbEnAttente),
              ],
              body: TabBarView(
                controller: _tabCtrl,
                children: [
                  _tabCours(),
                  _tabEnseignants(),
                  _tabOlympiades(),
                  _tabStats(),
                ],
              ),
            ),
    );
  }

  // ── TabBar ───────────────────────────────────────────────────
  SliverPersistentHeader _buildTabBar(int nbEnAttente) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          labelColor: YekiColors.primaryDark,
          unselectedLabelColor: YekiColors.textLight,
          indicatorColor: YekiColors.primaryDark,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(text: 'Mes cours'),
            const Tab(text: 'Enseignants'),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Olympiades'),
                if (nbEnAttente > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: YekiColors.warning,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$nbEnAttente',
                      style: const TextStyle(
                        color: YekiColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ]),
            ),
            const Tab(text: 'Statistiques'),
          ],
        ),
        backgroundColor: YekiColors.white,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET : MES COURS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _tabCours() {
    if (_departements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: YekiColors.accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: YekiColors.accent.withValues(alpha: 0.2), width: 1),
                ),
                child: Icon(Icons.domain_disabled, size: 50, color: YekiColors.accent),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun département assigné',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: YekiColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous n\'êtes encore affecté à aucun département.\n'
                'Contactez votre administrateur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: YekiColors.textMedium, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primaryDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _departements.length,
        itemBuilder: (context, index) => _buildDepartementCard(_departements[index]),
      ),
    );
  }

  Widget _buildDepartementCard(Map<String, dynamic> dept) {
    final taux = (dept['taux_moyen'] as num?)?.toDouble() ?? 0.0;
    final nbCours = dept['nb_cours'] ?? 0;
    final nbApprenants = dept['nb_apprenants'] ?? 0;
    final typeDept = dept['type_departement'] ?? 'cursus';
    final couleur = dept['couleur'] ?? '#2884A0';
    final bool accesRestreint = dept['acces_restreint'] ?? false;

    int demandesAttente = 0;
    if (dept['demandes_acces'] != null) {
      demandesAttente = (dept['demandes_acces'] as List).length;
    }

    Color cardColor;
    try {
      cardColor = Color(int.parse('FF${couleur.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      cardColor = YekiColors.primaryDark;
    }

    return GestureDetector(
      onTap: () => _ouvrirDetailDepartement(dept),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: YekiColors.borderLight, width: 1),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardColor.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: _getTypeIcon(typeDept, cardColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dept['nom'] ?? 'Département',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: YekiColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTypeLabel(typeDept),
                          style: TextStyle(fontSize: 11, color: cardColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$nbCours cours',
                      style: TextStyle(fontSize: 11, color: cardColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

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
                        style: const TextStyle(fontSize: 13, color: YekiColors.textMedium, height: 1.4),
                      ),
                    ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.people_rounded, '$nbApprenants apprenants', YekiColors.purple),
                      if (dept['ville'] != null && dept['ville'].toString().isNotEmpty)
                        _infoChip(Icons.location_on_rounded, dept['ville'], YekiColors.accent),
                      if (dept['prix'] != null && dept['prix'] > 0)
                        _infoChip(Icons.attach_money_rounded, '${dept['prix']} FCFA', YekiColors.gold),
                      if (dept['prix'] == 0)
                        _infoChip(Icons.lock_open_rounded, 'Gratuit', YekiColors.success),
                      if (accesRestreint)
                        _infoChip(Icons.lock_rounded, 'Sur demande', YekiColors.accent),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (accesRestreint) ...[
                    GestureDetector(
                      onTap: () => _ouvrirGestionDemandes(dept),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: YekiColors.primaryDark.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.2), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_alt_1_rounded,
                                color: YekiColors.primaryDark, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Demandes d\'accès',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: YekiColors.primaryDark),
                            ),
                            if (demandesAttente > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: YekiColors.accent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$demandesAttente',
                                  style: const TextStyle(
                                    color: YekiColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: taux / 100,
                            backgroundColor: YekiColors.borderLight,
                            color: cardColor,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${taux.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cardColor),
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

  Widget _getTypeIcon(String type, Color color) {
    switch (type) {
      case 'prepa_concours':
        return Icon(Icons.emoji_events_rounded, color: color, size: 22);
      case 'formation_metier':
        return Icon(Icons.work_rounded, color: color, size: 22);
      case 'formation_classique':
        return Icon(Icons.account_balance_rounded, color: color, size: 22);
      default:
        return Icon(Icons.domain_rounded, color: color, size: 22);
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
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Carte d'un cours ────────────────────────────────────────
  // TODO(arbitrage) : jamais appelée dans build() — contrairement aux
  // cartes département/enseignant/olympiade, aucune section de ce
  // dashboard n'affiche de liste de cours. Trouvé lors de P4.2 (script
  // de vérification design system) ; conservé tel quel (règle 5 — ne
  // rien perdre) en attendant un ticket qui tranche si c'est une
  // fonctionnalité oubliée à câbler ou du code obsolète à retirer.
  Widget _buildCoursCard(Map<String, dynamic> cours) {
    final taux = (cours['taux_completion'] as num? ?? 0).toDouble();
    final nbApp = cours['nb_apprenants'] ?? 0;
    final ep = cours['enseignant_principal'];

    final colorHex =
        (cours['color_code'] as String? ?? '#2884A0').replaceAll('#', '');
    Color coursColor;
    try {
      coursColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      coursColor = YekiColors.primaryDark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _ouvrirCoursDetail(cours),
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
                      color: coursColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: coursColor.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Icon(Icons.book, color: coursColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cours['titre'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: YekiColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$nbApp apprenants',
                          style: const TextStyle(
                            fontSize: 12,
                            color: YekiColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCoursActions(cours, coursColor),
                ],
              ),
              if (ep != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: YekiColors.primaryDark.withValues(alpha: 0.1),
                      child: Icon(Icons.person, size: 14, color: YekiColors.primaryDark),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'EP : ${ep['nom'] ?? ep['username'] ?? 'Non assigné'}',
                        style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: YekiColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: YekiColors.accent.withValues(alpha: 0.2), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_outlined, size: 12, color: YekiColors.accent),
                      SizedBox(width: 5),
                      Text(
                        'Aucun enseignant principal',
                        style: TextStyle(fontSize: 11, color: YekiColors.accent),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: taux / 100,
                        backgroundColor: YekiColors.borderLight,
                        color: coursColor,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${taux.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: coursColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursActions(Map<String, dynamic> cours, Color coursColor) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: YekiColors.textMedium),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'modifier',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: coursColor, size: 18),
              const SizedBox(width: 10),
              const Text('Modifier le cours', style: TextStyle(color: YekiColors.textDark)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'changer_ep',
          child: Row(
            children: [
              Icon(Icons.swap_horiz, color: YekiColors.primaryDark, size: 18),
              const SizedBox(width: 10),
              const Text('Changer l\'enseignant', style: TextStyle(color: YekiColors.textDark)),
            ],
          ),
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case 'modifier':
            _ouvrirModifierCours(cours);
            break;
          case 'changer_ep':
            _changerEnseignantPrincipal(cours);
            break;
        }
      },
    );
  }

  void _ouvrirCoursDetail(Map<String, dynamic> cours) {
    final colorHex = (cours['color_code'] as String? ?? '#008080').replaceAll('#', '');
    Color coursColor;
    try {
      coursColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      coursColor = YekiColors.primaryDark;
    }

    context.pushNamed(
      AppRoute.coursDetailEnseignant,
      pathParameters: {'coursId': cours['id'].toString()},
      queryParameters: {
        'titre': (cours['titre'] ?? 'Sans titre') as String,
        'estEnseignantPrincipal': 'true',
        'courseColor': coursColor.value.toString(),
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET : ENSEIGNANTS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _tabEnseignants() {
    if (_enseignantsPrincipaux.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: YekiColors.primaryDark.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: YekiColors.primaryDark.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(Icons.person_outline_rounded, size: 48, color: YekiColors.primaryDark),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun enseignant principal assigné',
              style: TextStyle(color: YekiColors.textMedium, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primaryDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _enseignantsPrincipaux.length,
        itemBuilder: (_, i) =>
            _buildEnseignantCard(_enseignantsPrincipaux[i]),
      ),
    );
  }

  Widget _buildEnseignantCard(Map<String, dynamic> ep) {
    final score = (ep['score_moyen'] as num? ?? 0).toDouble();
    final nbCours = ep['nb_cours'] ?? 0;
    final nbApp = ep['nb_apprenants'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: YekiColors.primaryDark.withValues(alpha: 0.1),
              backgroundImage: ep['photo'] != null
                  ? NetworkImage(ep['photo'] as String)
                  : null,
              child: ep['photo'] == null
                  ? Text(
                      (ep['nom'] as String? ?? 'E')[0].toUpperCase(),
                      style: const TextStyle(
                        color: YekiColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ep['nom'] ?? ep['username'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: YekiColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip('$nbCours cours', Icons.book_outlined, YekiColors.primaryLight),
                      _chip('$nbApp apprenants', Icons.people_outline, YekiColors.primaryDark),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: YekiColors.primaryDark,
                  ),
                ),
                const Text(
                  '/20',
                  style: TextStyle(fontSize: 11, color: YekiColors.textMedium),
                ),
                const Text(
                  'moy.',
                  style: TextStyle(fontSize: 10, color: YekiColors.textMedium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET : OLYMPIADES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _tabOlympiades() {
    if (_olympiades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: YekiColors.gold.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: YekiColors.gold.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(Icons.military_tech_rounded, size: 48, color: YekiColors.gold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune olympiade créée',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: YekiColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre première olympiade depuis le menu Actions',
              style: TextStyle(fontSize: 13, color: YekiColors.textMedium),
            ),
            const SizedBox(height: 16),
            YekiButton(
              label: 'Créer une olympiade',
              icon: Icons.add,
              onPressed: _ouvrirCreerOlympiade,
              //color: YekiColors.gold,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      color: YekiColors.primaryDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _olympiades.length,
        itemBuilder: (_, i) => _buildOlympiadeCard(_olympiades[i]),
      ),
    );
  }

  Widget _buildOlympiadeCard(Map<String, dynamic> olympiade) {
    final statut = olympiade['statut'] ?? 'inscription';
    final estValidee = olympiade['est_validee'] ?? false;
    final estRefusee = olympiade['est_refusee'] ?? false;
    final nbInscrits = olympiade['nb_inscrits'] ?? 0;
    final prixGlobal = olympiade['prix_global'] ?? 0;
    final estPubliee = olympiade['est_publiee'] ?? false;

    Color statutColor;
    String statutLabel;
    if (estRefusee) {
      statutColor = YekiColors.error;
      statutLabel = 'Refusée';
    } else if (estValidee && estPubliee) {
      statutColor = YekiColors.success;
      statutLabel = 'Validée';
    } else if (prixGlobal > 0 && !estPubliee) {
      statutColor = YekiColors.warning;
      statutLabel = 'En attente de paiement';
    } else if (!estValidee && !estRefusee) {
      statutColor = YekiColors.warning;
      statutLabel = 'En attente de validation';
    } else {
      statutColor = YekiColors.textMedium;
      statutLabel = statut;
    }

    final isEditable = !estValidee && !estRefusee && !estPubliee;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statutColor.withValues(alpha: 0.3),
          width: estRefusee ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _ouvrirDetailOlympiade(olympiade),
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
                      color: YekiColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: YekiColors.gold.withValues(alpha: 0.2), width: 0.8),
                    ),
                    child: Icon(
                      Icons.military_tech_rounded,
                      color: YekiColors.gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          olympiade['titre'] ?? 'Olympiade',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: YekiColors.textDark,
                          ),
                        ),
                        if ((olympiade['edition'] ?? '').toString().isNotEmpty)
                          Text(
                            olympiade['edition'],
                            style: const TextStyle(fontSize: 12, color: YekiColors.textMedium),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statutColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statutLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statutColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _infoChip(Icons.calendar_today_rounded, 
                      'Début: ${_formatDate(olympiade['date_debut_olympiade'])}', 
                      YekiColors.primaryDark),
                  _infoChip(Icons.calendar_today_rounded, 
                      'Fin: ${_formatDate(olympiade['date_fin_olympiade'])}', 
                      YekiColors.primaryDark),
                  if (nbInscrits > 0)
                    _infoChip(Icons.people_rounded, '$nbInscrits inscrits', YekiColors.purple),
                  if (prixGlobal > 0)
                    _infoChip(Icons.attach_money_rounded, '$prixGlobal FCFA', YekiColors.gold),
                  if (estPubliee)
                    _infoChip(Icons.public_rounded, 'Publiée', YekiColors.success),
                  if (estRefusee && olympiade['motif_refus'] != null)
                    _infoChip(Icons.warning_amber_rounded, 'Motif: ${olympiade['motif_refus']}', YekiColors.error),
                ],
              ),
              if (isEditable) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!estPubliee && olympiade['devoir_id'] == null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _lierDevoirOlympiade(olympiade),
                          icon: Icon(Icons.link_rounded, size: 16, color: YekiColors.primaryDark),
                          label: const Text('Lier un devoir'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: YekiColors.primaryDark,
                            side: BorderSide(color: YekiColors.primaryDark),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isEditable ? () => _modifierOlympiade(olympiade) : null,
                        icon: Icon(Icons.edit_outlined, size: 16, color: isEditable ? YekiColors.primaryDark : YekiColors.textLight),
                        label: const Text('Modifier'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isEditable ? YekiColors.primaryDark : YekiColors.textLight,
                          side: BorderSide(color: isEditable ? YekiColors.primaryDark : YekiColors.borderLight),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return date.toString().substring(0, 10);
    }
  }

  Future<void> _lierDevoirOlympiade(Map<String, dynamic> olympiade) async {
    final token = await _getToken();
    if (token == null) return;

    // Récupérer les devoirs du cadre
    List<dynamic> devoirs = [];
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.cadreDevoirs),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        devoirs = jsonDecode(res.body);
      } else {
        if (mounted) {
          ErrorHandler.showError(context, 'Impossible de charger les devoirs');
        }
        return;
      }
    } catch (_) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur réseau');
      }
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          int? selectedDevoirId;

          return Container(
            decoration: BoxDecoration(
              color: YekiColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 20),
                const Text(
                  'Lier un devoir à l\'olympiade',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: YekiColors.textDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'Olympiade : ${olympiade['titre'] ?? ''}',
                  style: const TextStyle(fontSize: 13, color: YekiColors.textMedium),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                  ),
                  child: devoirs.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun devoir disponible à lier',
                            style: TextStyle(color: YekiColors.textMedium),
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: devoirs.where((d) => d['est_lie_olympiade'] != true).map<Widget>(
                            (d) => RadioListTile<int>(
                              value: d['id'] as int,
                              groupValue: selectedDevoirId,
                              activeColor: YekiColors.primaryDark,
                              title: Text(
                                d['titre'] ?? '',
                                style: const TextStyle(color: YekiColors.textDark),
                              ),
                              subtitle: Text(
                                '${d['matiere'] ?? ''} · ${d['niveau'] ?? ''}',
                                style: const TextStyle(color: YekiColors.textMedium),
                              ),
                              onChanged: (v) => setS(() => selectedDevoirId = v),
                            ),
                          ).toList(),
                        ),
                ),
                const SizedBox(height: 20),
                YekiButton(
                  label: 'Lier',
                  onPressed: selectedDevoirId == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _appliquerLienDevoir(
                            olympiade['id'] as int,
                            selectedDevoirId!,
                          );
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _appliquerLienDevoir(int olympiadeId, int devoirId) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.olympiadeLierDevoir(olympiadeId)),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({'devoir_id': devoirId}),
      );
      if (mounted) {
        if (res.statusCode == 200) {
          ErrorHandler.showSuccess(context, 'Devoir lié avec succès !');
          _charger();
        } else {
          final err = jsonDecode(res.body);
          ErrorHandler.showError(context, err['detail'] ?? 'Erreur lors du lien');
        }
      }
    } catch (_) {
      if (mounted) {
        ErrorHandler.showError(context, 'Erreur réseau');
      }
    }
  }

  Future<void> _modifierOlympiade(Map<String, dynamic> olympiade) async {
    // Vérifier que l'olympiade peut être modifiée
    if (olympiade['est_validee'] == true || olympiade['est_refusee'] == true) {
      ErrorHandler.showError(context, 'Cette olympiade ne peut plus être modifiée.');
      return;
    }

    ouvrirCreerOlympiade(
      context,
      departementId: _currentDepartement?['id'] as int? ?? 0,
      departementNom: _currentDepartement?['nom'] as String? ?? '',
      parcoursType: _currentDepartement?['parcours_type']?.toString() ?? 'cursus',
      olympiade: olympiade,
      onSuccess: () {
        ErrorHandler.showSuccess(context, 'Olympiade modifiée !');
        _charger();
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET : STATISTIQUES
  // ═══════════════════════════════════════════════════════════════════════

  Widget _tabStats() {
    final nbDepts = _stats['nb_departements'] ?? _departements.length;
    final nbCours = _stats['nb_cours'] ?? 0;
    final nbApprenants = _stats['nb_apprenants'] ?? 0;
    final nbEnseignants = _stats['nb_enseignants'] ?? 0;
    final tauxMoyen = (_stats['taux_moyen'] as num? ?? 0).toDouble();

    final items = [
      _StatInfo('Départements', '$nbDepts', Icons.domain_rounded, YekiColors.primaryDark),
      _StatInfo('Cours', '$nbCours', Icons.book_rounded, YekiColors.primaryLight),
      _StatInfo('Apprenants', '$nbApprenants', Icons.people_rounded, YekiColors.primaryDark),
      _StatInfo('Enseignants', '$nbEnseignants', Icons.person_outline_rounded, YekiColors.gold),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: items.map((i) => _buildInfoCard(i)).toList(),
          ),
          const SizedBox(height: 20),
          _buildTauxCard(tauxMoyen),
          const SizedBox(height: 20),
          _buildClassementDepartements(),
          const SizedBox(height: 20),
          _buildRaccourcisActions(),
        ],
      ),
    );
  }

  Widget _buildTauxCard(double tauxMoyen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [YekiColors.primaryDark, YekiColors.primaryDark.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: YekiColors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Taux de complétion moyen',
                style: TextStyle(color: YekiColors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: tauxMoyen / 100,
                    backgroundColor: YekiColors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(YekiColors.gold),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${tauxMoyen.toStringAsFixed(0)}%',
                style: const TextStyle(color: YekiColors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassementDepartements() {
    if (_departements.isEmpty) return const SizedBox.shrink();

    final sortedDepts = List<Map<String, dynamic>>.from(_departements);
    sortedDepts.sort((a, b) {
      final tauxA = (a['taux_moyen'] as num?)?.toDouble() ?? 0;
      final tauxB = (b['taux_moyen'] as num?)?.toDouble() ?? 0;
      return tauxB.compareTo(tauxA);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: YekiColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                'Classement des départements',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: YekiColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedDepts.asMap().entries.map((entry) {
            final index = entry.key;
            final dept = entry.value;
            final taux = (dept['taux_moyen'] as num?)?.toDouble() ?? 0;
            final color = index == 0 ? YekiColors.gold : (index == 1 ? Colors.grey.shade400 : YekiColors.accent);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? YekiColors.backgroundLight : YekiColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dept['nom'] ?? 'Département',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: YekiColors.textDark),
                    ),
                  ),
                  Text(
                    '${taux.toStringAsFixed(0)}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRaccourcisActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: YekiColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatActionBtn(
                  icon: Icons.add_circle_outline,
                  label: 'Nouveau cours',
                  color: YekiColors.primaryDark,
                  onTap: _ouvrirCreerCours,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatActionBtn(
                  icon: Icons.emoji_events,
                  label: 'Olympiade',
                  color: YekiColors.gold,
                  onTap: _ouvrirCreerOlympiade,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildInfoCard(_StatInfo item) {
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(24),
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: item.color.withValues(alpha: 0.2), width: 0.8),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
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
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

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

  Widget _chip(String text, IconData icon, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 11, color: color)),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// FEUILLE DE DÉTAIL OLYMPIADE
// ═══════════════════════════════════════════════════════════════════════════

class _OlympiadeDetailSheet extends StatelessWidget {
  final Map<String, dynamic> olympiade;

  const _OlympiadeDetailSheet({required this.olympiade});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: YekiColors.borderLight,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: YekiColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.military_tech_rounded, color: YekiColors.gold, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        olympiade['titre'] ?? 'Olympiade',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: YekiColors.textDark),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (olympiade['est_validee'] ?? false)
                        ? YekiColors.success.withValues(alpha: 0.1)
                        : YekiColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (olympiade['est_validee'] ?? false) ? 'Validée' : 'En attente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: (olympiade['est_validee'] ?? false) ? YekiColors.success : YekiColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: YekiColors.borderLight),
            const SizedBox(height: 16),
            _infoRow('Édition', olympiade['edition'] ?? ''),
            _infoRow('Date début', olympiade['date_debut_olympiade']?.toString().substring(0, 10) ?? ''),
            _infoRow('Date fin', olympiade['date_fin_olympiade']?.toString().substring(0, 10) ?? ''),
            _infoRow('Durée', '${olympiade['duree_minutes'] ?? 0} min'),
            _infoRow('Questions', '${olympiade['nb_questions'] ?? 0}'),
            _infoRow('Inscrits', '${olympiade['nb_inscrits'] ?? 0}'),
            if (olympiade['prix_global'] != null && olympiade['prix_global'] > 0)
              _infoRow('Prix global', '${olympiade['prix_global']} FCFA'),
            if (olympiade['description'] != null && olympiade['description'].isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: YekiColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                olympiade['description'],
                style: const TextStyle(fontSize: 14, color: YekiColors.textMedium),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: YekiColors.textMedium),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(fontSize: 13, color: YekiColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CLASSE STATISTIQUE
// ═══════════════════════════════════════════════════════════════════════════

class _StatInfo {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatInfo(this.label, this.value, this.icon, this.color);
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB BAR DELEGATE (Défini localement)
// ═══════════════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  const _TabBarDelegate(this.tabBar, {this.backgroundColor = YekiColors.white});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => old.tabBar != tabBar;
}