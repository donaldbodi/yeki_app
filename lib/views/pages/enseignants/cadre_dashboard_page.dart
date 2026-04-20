// lib/views/pages/enseignants/cadre_dashboard_page.dart
// Version avec MULTI-DÉPARTEMENTS (ajouté sans modifier la logique existante)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/creer_cours_sheet.dart';
import 'package:yeki/widgets/modifier_cours_sheet.dart';
import 'package:yeki/widgets/creer_olympiade_sheet.dart';
import 'package:yeki/views/pages/enseignants/detail_departement_page.dart'; // AJOUTÉ

// Palette harmonisée
const Color _primary = Color(0xFF6A1B9A);
//const Color _primaryLight = Color(0xFF8B3FC9);
const Color _textDark = Color(0xFF1A1C1E);
const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _borderLight = Color(0xFFE0E4E8);
const Color _bgLight = Color(0xFFF8FAFC);
const Color _white = Color(0xFFFFFFFF);
const Color _green = Color(0xFF10B981);
const Color _orange = Color(0xFFF97316);
const Color _red = Color(0xFFEF4444);
const Color _gold = Color(0xFFE2A84B);

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';

class CadreDashboardPage extends StatefulWidget {
  const CadreDashboardPage({super.key});

  @override
  State<CadreDashboardPage> createState() => _CadreDashboardPageState();
}

class _CadreDashboardPageState extends State<CadreDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  
  // ========== MODIFICATIONS MULTI-DÉPARTEMENTS ==========
  // AVANT: Map<String, dynamic> _departement = {};
  // APRÈS: List<Map<String, dynamic>> _departements = [];
  List<Map<String, dynamic>> _departements = [];  // MODIFIÉ: Liste de départements
  // =====================================================
  
  Map<String, dynamic> _stats = {};
  List _cours = [];
  List _enseignantsPrincipaux = [];
  String _nomEnseignant = '';
  late TabController _tabCtrl;
  
  // AJOUTÉ: Département sélectionné pour les actions
  int? _selectedDeptId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _charger();
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
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/enseignant/cadre/dashboard/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _stats = Map<String, dynamic>.from(data['stats'] ?? {});
          // MODIFIÉ: Récupérer la liste des départements
          _departements = List<Map<String, dynamic>>.from(data['departements'] ?? []);
          // Garder l'ancienne variable pour compatibilité (premier département)
          // _departement = _departements.isNotEmpty ? _departements[0] : {};
          _cours = data['cours'] ?? [];
          _enseignantsPrincipaux = data['enseignants_principaux'] ?? [];
          _nomEnseignant = data['nom'] ?? '';
          _loading = false;
          
          // AJOUTÉ: Sélectionner le premier département par défaut
          if (_selectedDeptId == null && _departements.isNotEmpty) {
            _selectedDeptId = _departements[0]['id'];
          }
        });
      } else {
        setState(() => _loading = false);
        _showError('Erreur chargement (${res.statusCode})');
      }
    } catch (_) {
      setState(() => _loading = false);
      _showError('Erreur réseau');
    }
  }

  // AJOUTÉ: Méthode pour obtenir le département actuellement sélectionné
  Map<String, dynamic>? get _currentDepartement {
    if (_selectedDeptId == null || _departements.isEmpty) return null;
    try {
      return _departements.firstWhere((d) => d['id'] == _selectedDeptId);
    } catch (_) {
      return _departements.isNotEmpty ? _departements[0] : null;
    }
  }

  // AJOUTÉ: Ouvrir le détail d'un département
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
        Uri.parse('$_baseUrl/enseignants/liste/?role=principal'),
        headers: {'Authorization': 'Token $token'},
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
            color: _white,
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cours : ${cours['titre'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: _textMedium),
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
                          style: TextStyle(color: _textLight),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: enseignants
                            .map<Widget>(
                              (e) => RadioListTile<int>(
                                value: e['id'] as int,
                                groupValue: selected,
                                activeColor: _primary,
                                title: Text(
                                  e['nom'] ?? e['username'] ?? '',
                                  style: const TextStyle(color: _textDark),
                                ),
                                subtitle: Text(
                                  e['email'] ?? '',
                                  style: const TextStyle(color: _textLight),
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
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
                    style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.bold),
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
        Uri.parse('$_baseUrl/cours/$coursId/changer-enseignant-principal/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
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

  // MODIFIÉ: Utiliser le département sélectionné
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

  // MODIFIÉ: Utiliser le département sélectionné
  void _ouvrirCreerOlympiade() {
    final currentDept = _currentDepartement;
    if (currentDept == null) {
      _showError('Aucun département assigné. Contactez votre administrateur.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreerOlympiadeSheet(
        departementId: currentDept['id'] as int,
        departementNom: currentDept['nom'] as String? ?? '',
        onSuccess: () {
          _showSuccess('Olympiade créée ! Ajoutez les questions depuis la section Olympiades.');
        },
      ),
    );
  }

  // MODIFIÉ: Menu avec sélecteur de département
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
            color: _white,
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
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 20),
              
              // AJOUTÉ: Sélecteur de département (si plusieurs)
              if (_departements.length > 1) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _bgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderLight),
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
                color: _primary,
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
                color: _gold,
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
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
                        color: _textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _textLight),
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
    // AJOUTÉ: Vérifier si des départements existent pour le FAB
    final hasDepartements = _departements.isNotEmpty;
    
    return Scaffold(
      backgroundColor: _bgLight,
      floatingActionButton: hasDepartements
          ? FloatingActionButton(
              backgroundColor: _primary,
              elevation: 4,
              onPressed: _afficherMenuActions,
              child: const Icon(Icons.add_rounded, color: _white, size: 28),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [_buildAppBar(), _buildTabBar()],
              body: TabBarView(
                controller: _tabCtrl,
                children: [_tabCours(), _tabEnseignants(), _tabStats()],
              ),
            ),
    );
  }

  SliverAppBar _buildAppBar() {
    // MODIFIÉ: Utiliser le premier département ou null
    final currentDept = _currentDepartement;
    final nomDept = currentDept?['nom'] as String?;
    final nomParcours = currentDept?['parcours'] as String?;
    final nbDepts = _departements.length;

    return SliverAppBar(
      expandedHeight: nomDept != null ? 250 : 200,
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
                  // Badge "CADRE"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "CADRE",
                      style: TextStyle(
                        color: _gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Nom de l'enseignant
                  Text(
                    _nomEnseignant.isEmpty
                        ? 'Enseignant Cadre'
                        : _nomEnseignant,
                    style: const TextStyle(
                      color: _white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Badge rôle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Enseignant Cadre',
                      style: TextStyle(
                        color: _white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Badge département(s) ou alerte
                  if (nomDept == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: _orange, size: 12),
                          SizedBox(width: 6),
                          Text(
                            'Aucun département assigné',
                            style: TextStyle(color: _orange, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AJOUTÉ: Indicateur du nombre de départements
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.domain_rounded, color: _gold, size: 12),
                              const SizedBox(width: 6),
                              Text(
                                nbDepts > 1 ? '$nbDepts départements' : '1 département',
                                style: const TextStyle(color: _white, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium, color: _gold, size: 12),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Cadre : $nomDept',
                                  style: const TextStyle(color: _white, fontSize: 11),
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
                              Icon(Icons.route, color: _white, size: 11),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Parcours : $nomParcours',
                                  style: TextStyle(
                                    color: _white,
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
            icon: Icon(Icons.emoji_events, color: _gold, size: 22),
            tooltip: 'Créer une olympiade',
            onPressed: _ouvrirCreerOlympiade,
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: _white),
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
          labelColor: _primary,
          unselectedLabelColor: _textMedium,
          indicatorColor: _primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Mes cours'),
            Tab(text: 'Enseignants'),
            Tab(text: 'Statistiques'),
          ],
        ),
        backgroundColor: _white,
      ),
    );
  }

  // ─── TAB 1 : Cours (MODIFIÉ: Afficher tous les départements) ───
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
                  color: _orange.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: _orange.withOpacity(0.2), width: 1),
                ),
                child: Icon(Icons.domain_disabled, size: 50, color: _orange),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun département assigné',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous n\'êtes encore affecté à aucun département.\n'
                'Contactez votre administrateur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textLight, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // AJOUTÉ: Affichage de tous les départements en liste
    return RefreshIndicator(
      onRefresh: _charger,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _departements.length,
        itemBuilder: (context, index) => _buildDepartementCard(_departements[index]),
      ),
    );
  }

  // AJOUTÉ: Carte pour un département (remplace l'ancienne bannière unique)
  Widget _buildDepartementCard(Map<String, dynamic> dept) {
    final taux = (dept['taux_moyen'] as num?)?.toDouble() ?? 0.0;
    final nbCours = dept['nb_cours'] ?? 0;
    final nbApprenants = dept['nb_apprenants'] ?? 0;
    final typeDept = dept['type_departement'] ?? 'cursus';
    final couleur = dept['couleur'] ?? '#6A1B9A';
    
    Color cardColor;
    try {
      cardColor = Color(int.parse('FF${couleur.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      cardColor = _primary;
    }

    return GestureDetector(
      onTap: () => _ouvrirDetailDepartement(dept),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header coloré
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardColor.withOpacity(0.2), width: 0.8),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark),
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
                      color: cardColor.withOpacity(0.1),
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
                        style: const TextStyle(fontSize: 13, color: _textMedium, height: 1.4),
                      ),
                    ),
                  
                  Row(
                    children: [
                      _infoChip(Icons.people_rounded, '$nbApprenants apprenants', _purple),
                      const SizedBox(width: 8),
                      if (dept['ville'] != null && dept['ville'].toString().isNotEmpty)
                        _infoChip(Icons.location_on_rounded, dept['ville'], _orange),
                      if (dept['prix'] != null && dept['prix'] > 0)
                        _infoChip(Icons.attach_money_rounded, '${dept['prix']} FCFA', _gold),
                      if (dept['prix'] == 0)
                        _infoChip(Icons.lock_open_rounded, 'Gratuit', _green),
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

  // AJOUTÉ: Icône par type de département
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

  // AJOUTÉ: Label par type de département
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

  // AJOUTÉ: Chip d'information
  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15), width: 0.5),
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

  // ─── GARDE L'ANCIENNE MÉTHODE POUR COMPATIBILITÉ ───
  Widget _buildDeptBannerCard() {
    // Cette méthode est gardée mais plus utilisée
    final currentDept = _currentDepartement;
    final nomDept = currentDept?['nom'] as String? ?? '';
    final nomParcours = currentDept?['parcours'] as String? ?? '';
    final desc = currentDept?['description'] as String? ?? '';
    final nbCours = _cours.length;
    final nbApp = (_stats['nb_apprenants'] as num? ?? 0).toInt();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.domain, color: _white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon département',
                      style: TextStyle(color: _white, fontSize: 12),
                    ),
                    Text(
                      'Enseignant Cadre',
                      style: TextStyle(
                        color: _white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$nbCours cours',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$nbApp apprenants',
                    style: const TextStyle(color: _white, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: _white, height: 1),
          const SizedBox(height: 14),
          Text(
            nomDept,
            style: const TextStyle(
              color: _white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(color: _white, fontSize: 13),
            ),
          ],
          if (nomParcours.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.route, color: _white, size: 13),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Parcours : $nomParcours',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── CARTE COURS (inchangée) ───
  Widget _buildCoursCard(Map cours) {
    final taux = (cours['taux_completion'] as num? ?? 0).toDouble();
    final nbApp = cours['nb_apprenants'] ?? 0;
    final ep = cours['enseignant_principal'];

    final colorHex =
        (cours['color_code'] as String? ?? '#6A1B9A').replaceAll('#', '');
    Color coursColor;
    try {
      coursColor = Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      coursColor = _primary;
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
                      color: coursColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: coursColor.withOpacity(0.2), width: 0.8),
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
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$nbApp apprenants',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textLight,
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
                      backgroundColor: _primary.withOpacity(0.1),
                      child: Icon(Icons.person, size: 14, color: _primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'EP : ${ep['nom'] ?? ep['username'] ?? 'Non assigné'}',
                        style: const TextStyle(fontSize: 12, color: _textMedium),
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
                    color: _orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _orange.withOpacity(0.2), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_outlined, size: 12, color: _orange),
                      SizedBox(width: 5),
                      Text(
                        'Aucun enseignant principal',
                        style: TextStyle(fontSize: 11, color: _orange),
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
                        backgroundColor: _borderLight,
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
      icon: Icon(Icons.more_vert, color: _textLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'modifier',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: coursColor, size: 18),
              const SizedBox(width: 10),
              const Text('Modifier le cours', style: TextStyle(color: _textDark)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'changer_ep',
          child: Row(
            children: [
              Icon(Icons.swap_horiz, color: _primary, size: 18),
              const SizedBox(width: 10),
              const Text('Changer l\'enseignant', style: TextStyle(color: _textDark)),
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

  // ─── TAB 2 : Enseignants Principaux (inchangé) ───
  Widget _tabEnseignants() {
    if (_enseignantsPrincipaux.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _primary.withOpacity(0.2), width: 1),
              ),
              child: Icon(Icons.person_outline_rounded, size: 48, color: _primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun enseignant principal assigné',
              style: TextStyle(color: _textMedium, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _charger,
      color: _primary,
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
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: _primary.withOpacity(0.1),
              backgroundImage: ep['photo'] != null
                  ? NetworkImage(ep['photo'] as String)
                  : null,
              child: ep['photo'] == null
                  ? Text(
                      (ep['nom'] as String? ?? 'E')[0].toUpperCase(),
                      style: const TextStyle(
                        color: _primary,
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
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip('$nbCours cours', Icons.book_outlined, Colors.blue),
                      const SizedBox(width: 8),
                      _chip(
                        '$nbApp apprenants',
                        Icons.people_outline,
                        Colors.teal,
                      ),
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
                    color: _primary,
                  ),
                ),
                const Text(
                  '/20',
                  style: TextStyle(fontSize: 11, color: _textLight),
                ),
                const Text(
                  'moy.',
                  style: TextStyle(fontSize: 10, color: _textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3 : Statistiques (MODIFIÉ: stats globales) ───
  Widget _tabStats() {
    final nbDepts = _stats['nb_departements'] ?? _departements.length;
    final nbCours = _stats['nb_cours'] ?? 0;
    final nbApprenants = _stats['nb_apprenants'] ?? 0;
    final nbEnseignants = _stats['nb_enseignants'] ?? 0;
    final tauxMoyen = (_stats['taux_moyen'] as num? ?? 0).toDouble();

    final items = [
      _StatInfo('Départements', '$nbDepts', Icons.domain_rounded, _primary),
      _StatInfo('Cours', '$nbCours', Icons.book_rounded, Colors.blue),
      _StatInfo('Apprenants', '$nbApprenants', Icons.people_rounded, const Color(0xFF2884A0)),
      _StatInfo('Enseignants', '$nbEnseignants', Icons.person_outline_rounded, Colors.teal),
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

  // AJOUTÉ: Carte du taux global
  Widget _buildTauxCard(double tauxMoyen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primary.withOpacity(0.85)],
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
              Icon(Icons.bar_chart_rounded, color: _white, size: 20),
              SizedBox(width: 8),
              Text('Taux de complétion moyen', style: TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.w600)),
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
                    backgroundColor: _white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${tauxMoyen.toStringAsFixed(0)}%',
                style: const TextStyle(color: _white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // AJOUTÉ: Classement des départements
  Widget _buildClassementDepartements() {
    if (_departements.isEmpty) return const SizedBox();
    
    // Trier les départements par taux de complétion
    final sortedDepts = List<Map<String, dynamic>>.from(_departements);
    sortedDepts.sort((a, b) {
      final tauxA = (a['taux_moyen'] as num?)?.toDouble() ?? 0;
      final tauxB = (b['taux_moyen'] as num?)?.toDouble() ?? 0;
      return tauxB.compareTo(tauxA);
    });
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: _gold, size: 20),
              SizedBox(width: 8),
              Text('Classement des départements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
            ],
          ),
          const SizedBox(height: 12),
          ...sortedDepts.asMap().entries.map((entry) {
            final index = entry.key;
            final dept = entry.value;
            final taux = (dept['taux_moyen'] as num?)?.toDouble() ?? 0;
            final color = index == 0 ? _gold : (index == 1 ? Colors.grey.shade400 : _orange);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? _bgLight : _white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _textDark),
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
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatActionBtn(
                  icon: Icons.add_circle_outline,
                  label: 'Nouveau cours',
                  color: _primary,
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
                  color: _gold,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
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

  Widget _statsGrid() {
    final items = [
      _StatInfo(
        'Cours créés',
        '${_stats['nb_cours'] ?? _cours.length}',
        Icons.book,
        _primary,
      ),
      _StatInfo(
        'Apprenants',
        '${_stats['nb_apprenants'] ?? 0}',
        Icons.people,
        const Color(0xFF2884A0),
      ),
      _StatInfo(
        'Enseignants',
        '${_stats['nb_enseignants'] ?? 0}',
        Icons.person_outline,
        Colors.teal,
      ),
      _StatInfo(
        'Taux moyen',
        '${(_stats['taux_moyen'] as num? ?? 0).toStringAsFixed(0)}%',
        Icons.bar_chart,
        _orange,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: items.map((i) => _buildInfoCard(i)).toList(),
    );
  }

  Widget _buildInfoCard(_StatInfo item) {
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
                style: const TextStyle(fontSize: 12, color: _textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeptCardStats() {
    // Méthode gardée pour compatibilité mais plus utilisée
    if (_departements.isEmpty) return const SizedBox();
    final currentDept = _currentDepartement;
    if (currentDept == null) return const SizedBox();
    
    final desc = currentDept['description'] as String? ?? '';
    final nomParcours = currentDept['parcours'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.domain, color: _white, size: 20),
              SizedBox(width: 8),
              Text(
                'Mon Département',
                style: TextStyle(color: _white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currentDept['nom'] ?? '',
            style: const TextStyle(
              color: _white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(color: _white, fontSize: 13),
            ),
          ],
          if (nomParcours.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.route, color: _white, size: 13),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Parcours : $nomParcours',
                    style: const TextStyle(
                      color: _white,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
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
        color: _borderLight,
        borderRadius: BorderRadius.circular(10),
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
        content: Text(msg, style: const TextStyle(color: _white)),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _white)),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// AJOUTÉ: Constante pour la couleur purple (utilisée dans _infoChip)
const Color _purple = Color(0xFF8B5CF6);

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