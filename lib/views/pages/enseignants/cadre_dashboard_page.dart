import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/creer_cours_sheet.dart';
import 'package:yeki/widgets/modifier_cours_sheet.dart';
import 'package:yeki/widgets/creer_olympiade_sheet.dart';

// ─────────────────────────────────────────────────────────────────
// DASHBOARD ENSEIGNANT CADRE
// - Affiche clairement le département auquel il est affecté
// - Stats complètes du département
// - Liste des cours du département
// - Performances des enseignants principaux
// - Changer un enseignant principal dans un cours
// - Créer un cours
// - Modifier un cours          ← NOUVEAU
// - Créer une olympiade        ← NOUVEAU
// ─────────────────────────────────────────────────────────────────

const String _baseUrl = 'https://yeki.pythonanywhere.com/api';
const Color _primary = Color(0xFF6A1B9A);
const Color _dark = Color(0xFF0D1B2A);
const Color _bg = Color(0xFFF8F4FC);

class CadreDashboardPage extends StatefulWidget {
  const CadreDashboardPage({super.key});

  @override
  State<CadreDashboardPage> createState() => _CadreDashboardPageState();
}

class _CadreDashboardPageState extends State<CadreDashboardPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _departement = {};
  List _cours = [];
  List _enseignantsPrincipaux = [];
  String _nomEnseignant = '';
  late TabController _tabCtrl;

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

  // ─── Chargement dashboard ────────────────────────────────────────
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
          _departement = Map<String, dynamic>.from(data['departement'] ?? {});
          _cours = data['cours'] ?? [];
          _enseignantsPrincipaux = data['enseignants_principaux'] ?? [];
          _nomEnseignant = data['nom'] ?? '';
          _loading = false;
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

  // ─── Changer enseignant principal d'un cours ─────────────────────
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              const SizedBox(height: 16),
              Text(
                'Changer l\'enseignant principal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cours : ${cours['titre'] ?? ''}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                ),
                child: enseignants.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun enseignant principal disponible',
                          style: TextStyle(color: Colors.grey),
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
                                title: Text(e['nom'] ?? e['username'] ?? ''),
                                subtitle: Text(e['email'] ?? ''),
                                onChanged: (v) => setS(() => selected = v),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    style: TextStyle(color: Colors.white, fontSize: 16),
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

  // ─── Créer un cours ──────────────────────────────────────────────
  void ouvrirFormulaireCreerCours({
    required BuildContext context,
    required int departementId,
    required String departementNom,
    required VoidCallback onSuccess,
  }) {
    if (_departement.isEmpty) {
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

  // ─── Modifier un cours ────────────────────────────────────────────
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

  // ─── Créer une olympiade ──────────────────────────────────────────
  void _ouvrirCreerOlympiade() {
    if (_departement.isEmpty) {
      _showError('Aucun département assigné. Contactez votre administrateur.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CreerOlympiadeSheet(
        departementId: _departement['id'] as int,
        departementNom: _departement['nom'] as String? ?? '',
        onSuccess: () {
          _showSuccess('Olympiade créée ! Ajoutez les questions depuis la section Olympiades.');
          // Rafraîchir si besoin (les olympiades ne sont pas dans ce dashboard)
        },
      ),
    );
  }

  // ─── Menu d'actions rapides (SpeedDial custom) ────────────────────
  void _afficherMenuActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: _dark,
              ),
            ),
            const SizedBox(height: 20),
            // ── Créer un cours ──────────────────────────────────
            _buildActionTile(
              icon: Icons.book_outlined,
              label: 'Créer un cours',
              subtitle: 'Ajouter un nouveau cours au département',
              color: _primary,
              onTap: () {
                Navigator.pop(ctx);
                ouvrirFormulaireCreerCours(
                  context: context,
                  departementId: _departement['id'],
                  departementNom: _departement['nom'],
                  onSuccess: _charger,
                );
              },
            ),
            const SizedBox(height: 10),
            // ── Créer une olympiade ──────────────────────────────
            _buildActionTile(
              icon: Icons.emoji_events,
              label: 'Créer une olympiade',
              subtitle: 'Organiser une compétition académique',
              color: const Color(0xFFFFA000),
              onTap: () {
                Navigator.pop(ctx);
                _ouvrirCreerOlympiade();
              },
            ),
          ],
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
            border: Border.all(color: color.withOpacity(0.25)),
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
                        color: _dark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 14),
            ],
          ),
        ),
      );

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // ── FAB avec menu actions ─────────────────────────────────────
      floatingActionButton: _departement.isEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: _primary,
              onPressed: _afficherMenuActions,
              child: const Icon(Icons.add, color: Colors.white),
            ),
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

  // ─── AppBar ──────────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    final nomDept = _departement['nom'] as String?;
    final nomParcours = _departement['parcours'] as String?;

    return SliverAppBar(
      expandedHeight: nomDept != null ? 215 : 170,
      pinned: true,
      backgroundColor: _primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A148C), _primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Tableau de bord',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _nomEnseignant.isEmpty
                        ? 'Enseignant Cadre'
                        : _nomEnseignant,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _badge('Enseignant Cadre', Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 8),
                  if (nomDept == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Aucun département assigné',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              color: Colors.amber,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Cadre du département $nomDept',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (nomParcours != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.route,
                                color: Colors.white54,
                                size: 12,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Parcours : $nomParcours',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
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
        title: const Text(
          'Dashboard Cadre',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        collapseMode: CollapseMode.parallax,
      ),
      actions: [
        // ── Bouton Olympiade dans l'AppBar ──────────────────────
        if (_departement.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber),
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
          labelColor: _primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _primary,
          tabs: const [
            Tab(text: 'Mes cours'),
            Tab(text: 'Enseignants'),
            Tab(text: 'Statistiques'),
          ],
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  // ─── TAB 1 : Cours ───────────────────────────────────────────────
  Widget _tabCours() {
    if (_departement.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.domain_disabled,
                  size: 50,
                  color: Colors.orange.shade300,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun département assigné',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous n\'êtes encore affecté à aucun département.\n'
                'Contactez votre administrateur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _charger,
      color: _primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDeptBannerCard(),
          const SizedBox(height: 16),
          if (_cours.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 60,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucun cours créé',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Créer un cours',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        ouvrirFormulaireCreerCours(
                          context: context,
                          departementId: _departement['id'],
                          departementNom: _departement['nom'],
                          onSuccess: _charger,
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          else
            ..._cours.map((c) => _buildCoursCard(c as Map)),
        ],
      ),
    );
  }

  // ── Bannière département ─────────────────────────────────────────
  Widget _buildDeptBannerCard() {
    final nomDept = _departement['nom'] as String? ?? '';
    final nomParcours = _departement['parcours'] as String? ?? '';
    final desc = _departement['description'] as String? ?? '';
    final nbCours = _cours.length;
    final nbApp = (_stats['nb_apprenants'] as num? ?? 0).toInt();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
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
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.domain, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon département',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      'Enseignant Cadre',
                      style: TextStyle(
                        color: Colors.white,
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
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$nbApp apprenants',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Text(
            nomDept,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          if (nomParcours.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.route, color: Colors.white54, size: 13),
                const SizedBox(width: 5),
                Text(
                  'Parcours : $nomParcours',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Carte cours (avec bouton Modifier) ────────────────────────────
  Widget _buildCoursCard(Map cours) {
    final taux = (cours['taux_completion'] as num? ?? 0).toDouble();
    final nbApp = cours['nb_apprenants'] ?? 0;
    final ep = cours['enseignant_principal'];

    // Couleur du cours
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
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
                  // ── Icône colorée ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: coursColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
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
                            color: _dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$nbApp apprenants',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Menu d'actions (3 boutons) ────────────────
                  _buildCoursActions(cours, coursColor),
                ],
              ),
              if (ep != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFFE8F4F8),
                      child: Icon(Icons.person, size: 14, color: _primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EP : ${ep['nom'] ?? ep['username'] ?? 'Non assigné'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        size: 12,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Aucun enseignant principal',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
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
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: taux / 100,
                        backgroundColor: Colors.grey.shade100,
                        color: coursColor,
                        minHeight: 7,
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

  // ── Boutons d'actions sur une carte cours ─────────────────────────
  Widget _buildCoursActions(Map cours, Color coursColor) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'modifier',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: coursColor, size: 18),
              const SizedBox(width: 10),
              const Text('Modifier le cours'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'changer_ep',
          child: Row(
            children: [
              Icon(Icons.swap_horiz, color: _primary, size: 18),
              const SizedBox(width: 10),
              const Text('Changer l\'enseignant'),
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

  // ─── TAB 2 : Enseignants Principaux ──────────────────────────────
  Widget _tabEnseignants() {
    if (_enseignantsPrincipaux.isEmpty) {
      return Center(
        child: Text(
          'Aucun enseignant principal assigné',
          style: TextStyle(color: Colors.grey.shade400),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
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
                      color: _dark,
                    ),
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
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Text(
                  'moy.',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 3 : Statistiques ────────────────────────────────────────
  Widget _tabStats() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _statsGrid(),
          const SizedBox(height: 20),
          _buildDeptCardStats(),
          const SizedBox(height: 20),
          // ── Raccourcis actions ───────────────────────────────
          _buildRaccourcisActions(),
        ],
      ),
    );
  }

  Widget _buildRaccourcisActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _dark,
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
                  onTap: () => ouvrirFormulaireCreerCours(
                    context: context,
                    departementId: _departement['id'],
                    departementNom: _departement['nom'],
                    onSuccess: _charger,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatActionBtn(
                  icon: Icons.emoji_events,
                  label: 'Olympiade',
                  color: const Color(0xFFFFA000),
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
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
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
        const Color(0xFF6A1B9A),
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
        const Color(0xFF008088),
      ),
      _StatInfo(
        'Taux moyen',
        '${(_stats['taux_moyen'] as num? ?? 0).toStringAsFixed(0)}%',
        Icons.bar_chart,
        const Color(0xFFE65100),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeptCardStats() {
    if (_departement.isEmpty) return const SizedBox();
    final desc = _departement['description'] as String? ?? '';
    final nomParcours = _departement['parcours'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary.withOpacity(0.85), _primary],
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
              Icon(Icons.domain, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Mon Département',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _departement['nom'] ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          if (nomParcours.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.route, color: Colors.white54, size: 13),
                const SizedBox(width: 5),
                Text(
                  'Parcours : $nomParcours',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  void _ouvrirCours(Map cours) {}

  Widget _sheetHandle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  Widget _badge(String text, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 12),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }
}

// ─────────────────────────────────────────────────────────────────
// Types helpers
// ─────────────────────────────────────────────────────────────────
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
