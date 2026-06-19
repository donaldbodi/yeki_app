// lib/views/pages/enseignants/cadre_dashboard_page.dart
// Version avec MULTI-DÉPARTEMENTS - Refactorisée avec design global

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/gestion_demandes_page.dart';
import 'package:yeki/widgets/creer_cours_sheet.dart';
import 'package:yeki/widgets/modifier_cours_sheet.dart';
import 'package:yeki/widgets/creer_olympiade_sheet.dart';
import 'package:yeki/views/pages/enseignants/detail_departement_page.dart';
import 'package:yeki/core/design/yeki_design.dart';
import 'package:yeki/core/constants/api_constants.dart';

// Couleurs supplémentaires (non définies dans yeki_design.dart)
const Color _kGreen = Color(0xFF10B981);
const Color _kTealLight = Color(0xFF39A0C2);
const Color _kTealDark = Color(0xFF1F5F75);

class CadreDashboardPage extends StatefulWidget {
  const CadreDashboardPage({super.key});

  @override
  State<CadreDashboardPage> createState() => _CadreDashboardPageState();
}

class _CadreDashboardPageState extends State<CadreDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  
  // ========== MODIFICATIONS MULTI-DÉPARTEMENTS ==========
  List<Map<String, dynamic>> _departements = [];
  
  Map<String, dynamic> _stats = {};
  List _cours = [];
  List<Map<String, dynamic>> _olympiades = [];
  List _enseignantsPrincipaux = [];
  String _nomEnseignant = '';
  late TabController _tabCtrl;
  
  int? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _charger();
  }

  Future<void> _chargerOlympiades() async {
    final token = await _getToken();
    if (token == null) return;
    
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/olympiades/mes-olympiades/'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _olympiades = data.map((o) => Map<String, dynamic>.from(o)).toList();
        });
      }
    } catch (_) {}
  }

  void _ouvrirGestionDemandes(Map<String, dynamic> dept) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GestionDemandesPage(
          departementId: dept['id'] as int,
          departementNom: dept['nom'] as String? ?? '',
        ),
      ),
    ).then((_) => _charger());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final token = await _getToken();
    if (token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/enseignant/cadre/dashboard/'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _stats = Map<String, dynamic>.from(data['stats'] ?? {});
          _departements = List<Map<String, dynamic>>.from(data['departements'] ?? []);
          _cours = data['cours'] ?? [];
          _enseignantsPrincipaux = data['enseignants_principaux'] ?? [];
          _nomEnseignant = data['nom'] ?? '';
          _loading = false;
          
          if (_selectedDeptId == null && _departements.isNotEmpty) {
            _selectedDeptId = _departements[0]['id'];
          }
        });
      } else if (mounted) {
        setState(() => _loading = false);
        _showError('Erreur chargement (${res.statusCode})');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Erreur réseau');
      }
    }
    await _chargerOlympiades(); 
  }

  Map<String, dynamic>? get _currentDepartement {
    if (_selectedDeptId == null || _departements.isEmpty) return null;
    try {
      return _departements.firstWhere((d) => d['id'] == _selectedDeptId);
    } catch (_) {
      return _departements.isNotEmpty ? _departements[0] : null;
    }
  }

  void _ouvrirDetailDepartement(Map<String, dynamic> dept) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailDepartementPage(
          departementId: dept['id'],
          departementNom: dept['nom'],
          departement: dept,
        ),
      ),
    ).then((_) => _charger());
  }

  void _changerEnseignantPrincipal(Map cours) async {
    final token = await _getToken();
    List enseignants = [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/enseignants/liste/?role=principal'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200) {
        enseignants = jsonDecode(res.body);
      } else {
        _showError('Impossible de charger les enseignants');
        return;
      }
    } catch (_) {
      _showError('Erreur réseau');
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
            color: kECard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusLg)),
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kEDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cours : ${cours['titre'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: kEMuted),
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
                          style: TextStyle(color: kEMuted),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: enseignants
                            .map<Widget>(
                              (e) => RadioListTile<int>(
                                value: e['id'] as int,
                                groupValue: selected,
                                activeColor: kPrimary,
                                title: Text(
                                  e['nom'] ?? e['username'] ?? '',
                                  style: const TextStyle(color: kEDark),
                                ),
                                subtitle: Text(
                                  e['email'] ?? '',
                                  style: const TextStyle(color: kEMuted),
                                ),
                                onChanged: (v) => setS(() => selected = v),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: selected == null
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _applyChangerEnseignant(
                            cours['id'] as int,
                            selected!,
                          );
                        },
                  child: const Text(
                    'Confirmer',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyChangerEnseignant(int coursId, int enseignantId) async {
    final token = await _getToken();
    try {
      final res = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/cours/$coursId/changer-enseignant-principal/'),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({'enseignant_principal_id': enseignantId}),
      );
      if (res.statusCode == 200) {
        _showSuccess('Enseignant principal modifié avec succès !');
        _charger();
      } else {
        final err = jsonDecode(res.body);
        _showError(err['detail'] ?? 'Erreur lors du changement');
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  void ouvrirFormulaireCreerCours({
    required BuildContext context,
    required int departementId,
    required String departementNom,
    required VoidCallback onSuccess,
  }) {
    final currentDept = _currentDepartement;
    if (currentDept == null) {
      _showError('Aucun département assigné. Contactez votre administrateur.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreerCoursSheet(
        departementId: departementId,
        departementNom: departementNom,
        onSuccess: onSuccess,
      ),
    );
  }

  void _ouvrirModifierCours(Map cours) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ModifierCoursSheet(
        cours: cours,
        onSuccess: () {
          _charger();
        },
      ),
    );
  }

  void _ouvrirCreerOlympiade() {
    final currentDept = _currentDepartement;
    if (currentDept == null) {
      _showError('Aucun département assigné. Contactez votre administrateur.');
      return;
    }

    final parcoursType = currentDept['parcours_type']?.toString() ?? 'cursus';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreerOlympiadeSheet(
        departementId: currentDept['id'] as int,
        departementNom: currentDept['nom'] as String? ?? '',
        parcoursType: parcoursType,
        onSuccess: () {
          _showSuccess('Olympiade créée ! Ajoutez les questions depuis la section Olympiades.');
          _charger();
        },
      ),
    );
  }

  void _afficherMenuActions() {
    if (_departements.isEmpty) {
      _showError('Aucun département assigné');
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: kECard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusLg)),
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
                  color: kEDark,
                ),
              ),
              const SizedBox(height: 20),
              
              if (_departements.length > 1) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: kEBg,
                    borderRadius: BorderRadius.circular(kRadiusMd),
                    border: Border.all(color: kEBorder),
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
                color: kPrimary,
                onTap: () {
                  final currentDept = _departements.firstWhere(
                    (d) => d['id'] == _selectedDeptId,
                    orElse: () => _departements[0],
                  );
                  Navigator.pop(ctx);
                  ouvrirFormulaireCreerCours(
                    context: context,
                    departementId: currentDept['id'],
                    departementNom: currentDept['nom'],
                    onSuccess: _charger,
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildActionTile(
                icon: Icons.emoji_events,
                label: 'Créer une olympiade',
                subtitle: 'Organiser une compétition académique',
                color: kGold,
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
        borderRadius: BorderRadius.circular(kRadiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacityValue(0.07),
            borderRadius: BorderRadius.circular(kRadiusMd),
            border: Border.all(color: color.withOpacityValue(0.25), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacityValue(0.15),
                  borderRadius: BorderRadius.circular(kRadiusMd),
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
                        color: kEDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: kEMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 14),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hasDepartements = _departements.isNotEmpty;
    
    return Scaffold(
      backgroundColor: kEBg,
      floatingActionButton: hasDepartements
          ? FloatingActionButton(
              backgroundColor: kPrimary,
              elevation: 4,
              onPressed: _afficherMenuActions,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : NestedScrollView(
              headerSliverBuilder: (_, _) => [_buildAppBar(), _buildTabBar()],
              body: TabBarView(
                controller: _tabCtrl,
                children: [_tabCours(), _tabEnseignants(), _tabStats()],
              ),
            ),
    );
  }

  SliverAppBar _buildAppBar() {
    final currentDept = _currentDepartement;
    final nomDept = currentDept?['nom'] as String?;
    final nomParcours = currentDept?['parcours'] as String?;
    final nbDepts = _departements.length;

    return SliverAppBar(
      expandedHeight: nomDept != null ? 250 : 200,
      pinned: true,
      backgroundColor: kPrimary,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, kPrimary.withOpacityValue(0.85)],
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
                      color: Colors.white.withOpacityValue(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "CADRE",
                      style: TextStyle(
                        color: kGold,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nomEnseignant.isEmpty
                        ? 'Enseignant Cadre'
                        : _nomEnseignant,
                    style: const TextStyle(
                      color: Colors.white,
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
                      color: Colors.white.withOpacityValue(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Enseignant Cadre',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (nomDept == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kAccent.withOpacityValue(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: kAccent, size: 12),
                          SizedBox(width: 6),
                          Text(
                            'Aucun département assigné',
                            style: TextStyle(color: kAccent, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacityValue(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.domain_rounded, color: kGold, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                nbDepts > 1 ? '$nbDepts départements' : '1 département',
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacityValue(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium, color: kGold, size: 12),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Cadre : $nomDept',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (nomParcours != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.route, color: Colors.white, size: 11),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Parcours : $nomParcours',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (_departements.isNotEmpty)
          IconButton(
            icon: Icon(Icons.emoji_events, color: kGold, size: 22),
            tooltip: 'Créer une olympiade',
            onPressed: _ouvrirCreerOlympiade,
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _charger,
        ),
      ],
    );
  }

  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: TabBarDelegate(
        TabBar(
          controller: _tabCtrl,
          labelColor: kPrimary,
          unselectedLabelColor: kEMuted,
          indicatorColor: kPrimary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Mes cours'),
            Tab(text: 'Enseignants'),
            Tab(text: 'Statistiques'),
          ],
        ),
        backgroundColor: kECard,
      ),
    );
  }

  // ─── TAB 1 : Cours (Afficher tous les départements) ───
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
                  color: kAccent.withOpacityValue(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: kAccent.withOpacityValue(0.2), width: 1),
                ),
                child: Icon(Icons.domain_disabled, size: 50, color: kAccent),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun département assigné',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kEDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous n\'êtes encore affecté à aucun département.\n'
                'Contactez votre administrateur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kEMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      color: kPrimary,
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
    
    // Récupérer le nombre de demandes en attente
    int demandesAttente = 0;
    if (dept['demandes_acces'] != null) {
      demandesAttente = (dept['demandes_acces'] as List).length;
    }
    
    Color cardColor;
    try {
      cardColor = Color(int.parse('FF${couleur.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      cardColor = kPrimary;
    }

    return GestureDetector(
      onTap: () => _ouvrirDetailDepartement(dept),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: kECard,
          borderRadius: BorderRadius.circular(kRadiusLg),
          border: Border.all(color: kEBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacityValue(0.04),
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
                color: cardColor.withOpacityValue(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusLg)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacityValue(0.15),
                      borderRadius: BorderRadius.circular(kRadiusMd),
                      border: Border.all(color: cardColor.withOpacityValue(0.2), width: 0.8),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kEDark),
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
                      color: cardColor.withOpacityValue(0.1),
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
                        style: const TextStyle(fontSize: 13, color: kEMuted, height: 1.4),
                      ),
                    ),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.people_rounded, '$nbApprenants apprenants', kPurple),
                      if (dept['ville'] != null && dept['ville'].toString().isNotEmpty)
                        _infoChip(Icons.location_on_rounded, dept['ville'], kAccent),
                      if (dept['prix'] != null && dept['prix'] > 0)
                        _infoChip(Icons.attach_money_rounded, '${dept['prix']} FCFA', kGold),
                      if (dept['prix'] == 0)
                        _infoChip(Icons.lock_open_rounded, 'Gratuit', _kGreen),
                      if (accesRestreint)
                        _infoChip(Icons.lock_rounded, 'Sur demande', kAccent),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Gestion des demandes d'accès (si accès restreint)
                  if (accesRestreint) ...[
                    GestureDetector(
                      onTap: () => _ouvrirGestionDemandes(dept),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacityValue(0.08),
                          borderRadius: BorderRadius.circular(kRadiusMd),
                          border: Border.all(color: kPrimary.withOpacityValue(0.2), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_alt_1_rounded, 
                                 color: kPrimary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Demandes d\'accès',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary),
                            ),
                            if (demandesAttente > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$demandesAttente',
                                  style: const TextStyle(
                                    color: kECard,
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
                            backgroundColor: kEBorder,
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
        color: color.withOpacityValue(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacityValue(0.15), width: 0.5),
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

  // ─── CARTE COURS ───
  Widget _buildCoursCard(Map cours) {
    final taux = (cours['taux_completion'] as num? ?? 0).toDouble();
    final nbApp = cours['nb_apprenants'] ?? 0;
    final ep = cours['enseignant_principal'];

    final colorHex =
        (cours['color_code'] as String? ?? '#2884A0').replaceAll('#', '');
    Color coursColor;
    try {
      coursColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      coursColor = kPrimary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kECard,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(color: kEBorder, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusLg),
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
                      color: coursColor.withOpacityValue(0.1),
                      borderRadius: BorderRadius.circular(kRadiusMd),
                      border: Border.all(color: coursColor.withOpacityValue(0.2), width: 0.8),
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
                            color: kEDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$nbApp apprenants',
                          style: const TextStyle(
                            fontSize: 12,
                            color: kEMuted,
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
                      backgroundColor: kPrimary.withOpacityValue(0.1),
                      child: Icon(Icons.person, size: 14, color: kPrimary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'EP : ${ep['nom'] ?? ep['username'] ?? 'Non assigné'}',
                        style: const TextStyle(fontSize: 12, color: kEMuted),
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
                    color: kAccent.withOpacityValue(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kAccent.withOpacityValue(0.2), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_outlined, size: 12, color: kAccent),
                      SizedBox(width: 5),
                      Text(
                        'Aucun enseignant principal',
                        style: TextStyle(fontSize: 11, color: kAccent),
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
                        backgroundColor: kEBorder,
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

  Widget _buildCoursActions(Map cours, Color coursColor) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: kEMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'modifier',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: coursColor, size: 18),
              const SizedBox(width: 10),
              const Text('Modifier le cours', style: TextStyle(color: kEDark)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'changer_ep',
          child: Row(
            children: [
              Icon(Icons.swap_horiz, color: kPrimary, size: 18),
              const SizedBox(width: 10),
              const Text('Changer l\'enseignant', style: TextStyle(color: kEDark)),
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

  // ─── TAB 2 : Enseignants Principaux ───
  Widget _tabEnseignants() {
    if (_enseignantsPrincipaux.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kPrimary.withOpacityValue(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withOpacityValue(0.2), width: 1),
              ),
              child: Icon(Icons.person_outline_rounded, size: 48, color: kPrimary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun enseignant principal assigné',
              style: TextStyle(color: kEMuted, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _enseignantsPrincipaux.length,
        itemBuilder: (_, i) =>
            _buildEnseignantCard(_enseignantsPrincipaux[i] as Map),
      ),
    );
  }

  Widget _buildEnseignantCard(Map ep) {
    final score = (ep['score_moyen'] as num? ?? 0).toDouble();
    final nbCours = ep['nb_cours'] ?? 0;
    final nbApp = ep['nb_apprenants'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kECard,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kEBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: kPrimary.withOpacityValue(0.1),
              backgroundImage: ep['photo'] != null
                  ? NetworkImage(ep['photo'] as String)
                  : null,
              child: ep['photo'] == null
                  ? Text(
                      (ep['nom'] as String? ?? 'E')[0].toUpperCase(),
                      style: const TextStyle(
                        color: kPrimary,
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
                      color: kEDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip('$nbCours cours', Icons.book_outlined, _kTealLight),
                      _chip('$nbApp apprenants', Icons.people_outline, _kTealDark),
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
                    color: kPrimary,
                  ),
                ),
                const Text(
                  '/20',
                  style: TextStyle(fontSize: 11, color: kEMuted),
                ),
                const Text(
                  'moy.',
                  style: TextStyle(fontSize: 10, color: kEMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3 : Statistiques ───
  Widget _tabStats() {
    final nbDepts = _stats['nb_departements'] ?? _departements.length;
    final nbCours = _stats['nb_cours'] ?? 0;
    final nbApprenants = _stats['nb_apprenants'] ?? 0;
    final nbEnseignants = _stats['nb_enseignants'] ?? 0;
    final tauxMoyen = (_stats['taux_moyen'] as num? ?? 0).toDouble();

    final items = [
      _StatInfo('Départements', '$nbDepts', Icons.domain_rounded, kPrimary),
      _StatInfo('Cours', '$nbCours', Icons.book_rounded, _kTealLight),
      _StatInfo('Apprenants', '$nbApprenants', Icons.people_rounded, _kTealDark),
      _StatInfo('Enseignants', '$nbEnseignants', Icons.person_outline_rounded, kGold),
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
          colors: [kPrimary, kPrimary.withOpacityValue(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(kRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Taux de complétion moyen', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    backgroundColor: Colors.white.withOpacityValue(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(kGold),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${tauxMoyen.toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassementDepartements() {
    if (_departements.isEmpty) return const SizedBox();
    
    final sortedDepts = List<Map<String, dynamic>>.from(_departements);
    sortedDepts.sort((a, b) {
      final tauxA = (a['taux_moyen'] as num?)?.toDouble() ?? 0;
      final tauxB = (b['taux_moyen'] as num?)?.toDouble() ?? 0;
      return tauxB.compareTo(tauxA);
    });
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kECard,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(color: kEBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: kGold, size: 20),
              SizedBox(width: 8),
              Text('Classement des départements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kEDark)),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedDepts.asMap().entries.map((entry) {
            final index = entry.key;
            final dept = entry.value;
            final taux = (dept['taux_moyen'] as num?)?.toDouble() ?? 0;
            final color = index == 0 ? kGold : (index == 1 ? Colors.grey.shade400 : kAccent);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? kEBg : kECard,
                borderRadius: BorderRadius.circular(kRadiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withOpacityValue(0.1),
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kEDark),
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
        color: kECard,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(color: kEBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kEDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatActionBtn(
                  icon: Icons.add_circle_outline,
                  label: 'Nouveau cours',
                  color: kPrimary,
                  onTap: () {
                    final currentDept = _currentDepartement;
                    if (currentDept != null) {
                      ouvrirFormulaireCreerCours(
                        context: context,
                        departementId: currentDept['id'],
                        departementNom: currentDept['nom'],
                        onSuccess: _charger,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatActionBtn(
                  icon: Icons.emoji_events,
                  label: 'Olympiade',
                  color: kGold,
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
        borderRadius: BorderRadius.circular(kRadiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacityValue(0.08),
            borderRadius: BorderRadius.circular(kRadiusMd),
            border: Border.all(color: color.withOpacityValue(0.2), width: 1),
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
        color: kECard,
        borderRadius: BorderRadius.circular(kRadiusLg),
        border: Border.all(color: kEBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withOpacityValue(0.1),
              borderRadius: BorderRadius.circular(kRadiusMd),
              border: Border.all(color: item.color.withOpacityValue(0.2), width: 0.8),
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
                style: const TextStyle(fontSize: 12, color: kEMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _ouvrirCours(Map cours) {}

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: kEBorder,
        borderRadius: BorderRadius.circular(kRadiusSm),
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

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: kAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
      ),
    );
  }
}

class _StatInfo {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatInfo(this.label, this.value, this.icon, this.color);
}

class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  const TabBarDelegate(this.tabBar, {this.backgroundColor = Colors.white});

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
  bool shouldRebuild(covariant TabBarDelegate old) => old.tabBar != tabBar;
}