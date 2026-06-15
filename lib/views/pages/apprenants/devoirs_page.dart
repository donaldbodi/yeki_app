// lib/views/pages/apprenants/devoirs_page.dart
// ═══════════════════════════════════════════════════════════════════════════
//  YEKI DEVOIRS — Design Unifié Premium (CORRIGÉ)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/widgets/yeki_app_bar.dart';
import 'package:yeki/services/offline_service.dart';
import 'package:yeki/services/sync_service.dart';
import 'package:yeki/views/pages/apprenants/composer_devoir_page.dart';
import 'package:yeki/views/pages/apprenants/resultat_devoir_page.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

class DevoirItem {
  final int id;
  final String titre;
  final String description;
  final String typeDevoir;
  final String matiere;
  final String niveau;
  final DateTime dateDebut;
  final DateTime dateLimite;
  final int dureeMinutes;
  final double noteSur;
  final double coefficient;
  final String? statutApprenant;
  final double? noteApprenant;
  final int tempsRestantJours;
  final bool estOuvert;
  final bool estExpire;
  final bool estPublie;
  final int nbQuestions;

  DevoirItem({
    required this.id,
    required this.titre,
    required this.description,
    required this.typeDevoir,
    required this.matiere,
    required this.niveau,
    required this.dateDebut,
    required this.dateLimite,
    required this.dureeMinutes,
    required this.noteSur,
    required this.coefficient,
    this.statutApprenant,
    this.noteApprenant,
    required this.tempsRestantJours,
    required this.estOuvert,
    required this.estExpire,
    required this.estPublie,
    required this.nbQuestions,
  });

  factory DevoirItem.fromJson(Map<String, dynamic> json) {
    return DevoirItem(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      typeDevoir: json['type_devoir'] ?? 'cursus',
      matiere: json['matiere'] ?? '',
      niveau: json['niveau'] ?? '',
      dateDebut: DateTime.tryParse(json['date_debut'] ?? '') ?? DateTime.now(),
      dateLimite: DateTime.tryParse(json['date_limite'] ?? '') ?? DateTime.now(),
      dureeMinutes: json['duree_minutes'] ?? 60,
      noteSur: (json['note_sur'] as num?)?.toDouble() ?? 20.0,
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      statutApprenant: json['statut_apprenant'],
      noteApprenant: (json['note_apprenant'] as num?)?.toDouble(),
      tempsRestantJours: json['temps_restant_jours'] ?? 0,
      estOuvert: json['est_ouvert'] ?? false,
      estExpire: json['est_expire'] ?? false,
      estPublie: json['est_publie'] ?? false,
      nbQuestions: json['nb_questions'] ?? 0,
    );
  }

  bool get aSoumis => statutApprenant != null && statutApprenant != 'non_commence';
  bool get estCorrige => statutApprenant == 'corrige';
  bool get estEnCours => statutApprenant == 'en_cours';

  String get statutLabel {
    switch (statutApprenant) {
      case 'non_commence':
        return 'À faire';
      case 'en_cours':
        return 'En cours';
      case 'soumis':
        return 'Soumis';
      case 'corrige':
        return 'Corrigé';
      case 'en_retard':
        return 'En retard';
      default:
        return 'À faire';
    }
  }

  Color get statutColor {
    switch (statutApprenant) {
      case 'non_commence':
        return YekiColors.primaryDark;
      case 'en_cours':
        return YekiColors.purple;
      case 'soumis':
        return YekiColors.warning;
      case 'corrige':
        return YekiColors.success;
      case 'en_retard':
        return YekiColors.error;
      default:
        return YekiColors.primaryDark;
    }
  }

  Color get typeColor {
    switch (typeDevoir) {
      case 'cursus':
        return Colors.blue;
      case 'concours':
        return YekiColors.accent;
      case 'formation_classique':
        return Colors.teal;
      case 'formation_metier':
        return YekiColors.warning;
      case 'olympiade':
        return YekiColors.purple;
      default:
        return YekiColors.primaryDark;
    }
  }

  String get typeLabel {
    switch (typeDevoir) {
      case 'cursus':
        return 'Cursus';
      case 'concours':
        return 'Concours';
      case 'formation_classique':
        return 'Formation';
      case 'formation_metier':
        return 'Métier';
      case 'olympiade':
        return 'Olympiade';
      default:
        return typeDevoir;
    }
  }
}

class DevoirsPage extends StatefulWidget {
  final bool estEnseignantPrincipal;

  const DevoirsPage({super.key, required this.estEnseignantPrincipal});

  @override
  State<DevoirsPage> createState() => _DevoirsPageState();
}

class _DevoirsPageState extends State<DevoirsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;
  final String _error = '';

  List<DevoirItem> _tous = [];
  List<DevoirItem> _affiches = [];

  String _typeSelectionne = 'Tous';
  String? _matiereSelectionnee;
  String? _niveauSelectionne;
  String _statutSelectionne = 'Tous';
  String _recherche = '';

  final TextEditingController _searchCtrl = TextEditingController();

  final int _unreadNotifications = 0;
  final bool _isSubscribed = true;
  String _username = 'Apprenant';

  final List<_TypeDevoirTab> _types = [
    const _TypeDevoirTab('Tous', Icons.grid_view_rounded, YekiColors.primaryDark),
    const _TypeDevoirTab('cursus', Icons.school_rounded, Colors.blue),
    const _TypeDevoirTab('concours', Icons.emoji_events_rounded, YekiColors.accent),
    const _TypeDevoirTab('formation_classique', Icons.account_balance_rounded, Colors.teal),
    const _TypeDevoirTab('formation_metier', Icons.work_rounded, YekiColors.warning),
    const _TypeDevoirTab('olympiade', Icons.military_tech_rounded, YekiColors.purple),
  ];

  final List<String> _matieres = [
    'Mathématiques', 'Physique', 'Chimie', 'SVT', 'Informatique',
    'Français', 'Anglais', 'Histoire-Géo', 'Philosophie', 'Économie',
    'Autre',
  ];

  final List<String> _niveaux = [
    'Terminale', '1ère', '2nde', '3ème',
    'Licence 1', 'Licence 2', 'Licence 3', 'Master 1', 'Master 2',
    'Autre',
  ];

  final List<String> _statuts = [
    'Tous', 'non_commence', 'en_cours', 'soumis', 'corrige', 'en_retard',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _types.length, vsync: this)
      ..addListener(_onTabChanged);

    _initOffline();
    _charger();
    _loadUserData();

    _searchCtrl.addListener(() {
      setState(() => _recherche = _searchCtrl.text);
      _appliquerFiltres();
    });
  }

  Future<void> _initOffline() async {
    await OfflineService.init();
    SyncService().startAutoSync();
  }

  void _onTabChanged() {
    if (!_tabCtrl.indexIsChanging) {
      setState(() {
        _typeSelectionne = _types[_tabCtrl.index].code;
        _appliquerFiltres();
      });
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    SyncService().stopAutoSync();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.profilMe),
        headers: ApiHeaders.auth(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _username = data['username'] ?? 'Apprenant');
      }
    } catch (_) {}
  }

  Future<String?> _getToken() async {
    return (await SharedPreferences.getInstance()).getString('token');
  }

  Future<void> _charger({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);

    final token = await _getToken();
    if (token == null) {
      _loadFromCache();
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.devoirs),
        headers: ApiHeaders.auth(token),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final devoirs = data
            .map((d) => DevoirItem.fromJson(d as Map<String, dynamic>))
            .toList();

        setState(() {
          _tous = devoirs;
          _appliquerFiltres();
        });

        await OfflineService.cacheDevoirs('all_devoirs', data);
        OfflineService.isOnline = true;
      } else {
        _loadFromCache();
      }
    } catch (e) {
      OfflineService.isOnline = false;
      _loadFromCache();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadFromCache() {
    final cached = OfflineService.getCachedDevoirs('all_devoirs');
    if (cached != null) {
      setState(() {
        _tous = cached
            .map((d) => DevoirItem.fromJson(d as Map<String, dynamic>))
            .toList();
        _appliquerFiltres();
      });
    }
  }

  void _appliquerFiltres() {
    List<DevoirItem> temp = List.from(_tous);

    if (_typeSelectionne != 'Tous') {
      temp = temp.where((d) => d.typeDevoir == _typeSelectionne).toList();
    }

    if (_matiereSelectionnee != null) {
      temp = temp.where((d) => d.matiere == _matiereSelectionnee).toList();
    }

    if (_niveauSelectionne != null) {
      temp = temp.where((d) => d.niveau == _niveauSelectionne).toList();
    }

    if (_statutSelectionne != 'Tous') {
      temp = temp.where((d) => d.statutApprenant == _statutSelectionne).toList();
    }

    if (_recherche.isNotEmpty) {
      temp = temp.where((d) => d.titre.toLowerCase().contains(_recherche.toLowerCase())).toList();
    }

    setState(() => _affiches = temp);
  }

  int get _aFaire => _tous.where((d) => d.statutApprenant == 'non_commence').length;
  int get _enRetard => _tous.where((d) => d.statutApprenant == 'en_retard').length;

  Future<void> _refresh() async {
    await _charger(silent: true);
  }

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Souhaitez-vous vraiment quitter l\'application ?',
            style: TextStyle(color: YekiColors.textMedium)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: YekiColors.error,
                foregroundColor: YekiColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  void _ouvrirDevoir(DevoirItem d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposerDevoirPage(
          devoirId: d.id,
          titre: d.titre,
          dureeMin: d.dureeMinutes,
          noteSur: d.noteSur.toInt(),
        ),
      ),
    ).then((_) => _charger());
  }

  void _voirResultat(DevoirItem d) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultatDevoirPage(
          devoirId: d.id,
          titre: d.titre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padX = screenWidth > 800 ? (screenWidth - 760) / 2 : 18.0;

    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: YekiHeader(
        unreadNotifications: _unreadNotifications,
        isSubscribed: _isSubscribed,
        userRole: 'Apprenant',
        username: _username,
        avatarUrl: null,
        onLogout: _deconnecter,
        onSettings: () {},
        onNotifications: () {},
      ),
      body: _loading
          ? _buildResponsiveSkeleton(padX)
          : _error.isNotEmpty
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: YekiColors.primaryDark,
                  backgroundColor: YekiColors.white,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(padX, 20, padX, 8),
                          child: _buildPageTitle(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: padX),
                          child: _buildStatsSection(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(padX, 12, padX, 4),
                          child: _buildSearchBar(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: padX),
                          child: _buildTabsSection(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(padX, 4, padX, 8),
                          child: _buildFiltersSection(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(padX, 8, padX, 12),
                          child: _buildSectionTitle(),
                        ),
                      ),
                      _affiches.isEmpty
                          ? const SliverFillRemaining(hasScrollBody: false, child: _EmptyView())
                          : SliverPadding(
                              padding: EdgeInsets.fromLTRB(padX, 0, padX, 110),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, idx) => _buildUnifiedCard(_affiches[idx]),
                                  childCount: _affiches.length,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPageTitle() {
    return Row(
      children: [
        const Text(
          "Mes Devoirs",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: YekiColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "ÉVALUATIONS",
            style: TextStyle(
              color: YekiColors.accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _buildStatCard('Total', _tous.length.toString(),
              Icons.assignment_rounded, YekiColors.primaryDark),
          const SizedBox(width: 10),
          _buildStatCard('À faire', _aFaire.toString(),
              Icons.pending_rounded, Colors.blue),
          const SizedBox(width: 10),
          _buildStatCard('En retard', _enRetard.toString(),
              Icons.warning_rounded, YekiColors.error),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YekiColors.borderLight, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: YekiColors.borderLight, width: 1.2),
        boxShadow: YekiShadows.subtle,
      ),
      child: TextField(
        controller: _searchCtrl,
        style: YekiTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Rechercher un devoir...',
          hintStyle: YekiTextStyles.bodySmall,
          prefixIcon: Icon(Icons.search_rounded, color: YekiColors.primaryLight, size: 22),
          suffixIcon: _recherche.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _recherche = '');
                    _appliquerFiltres();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTabsSection() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = _typeSelectionne == type.code;
          return GestureDetector(
            onTap: () {
              setState(() {
                _typeSelectionne = type.code;
                _tabCtrl.animateTo(index);
                _appliquerFiltres();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? type.color.withValues(alpha: 0.12) : YekiColors.backgroundAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? type.color.withValues(alpha: 0.35) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type.icon, size: 15, color: isSelected ? type.color : YekiColors.textLight),
                  const SizedBox(width: 6),
                  Text(_typeLabel(type.code),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? type.color : YekiColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterDropdown(
            value: _matiereSelectionnee,
            hint: 'Matière',
            items: _matieres,
            onChanged: (v) => setState(() {
              _matiereSelectionnee = v;
              _appliquerFiltres();
            }),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            value: _niveauSelectionne,
            hint: 'Niveau',
            items: _niveaux,
            onChanged: (v) => setState(() {
              _niveauSelectionne = v;
              _appliquerFiltres();
            }),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            value: _statutSelectionne == 'Tous' ? null : _statutSelectionne,
            hint: 'Statut',
            items: _statuts.where((s) => s != 'Tous').toList(),
            onChanged: (v) => setState(() {
              _statutSelectionne = v ?? 'Tous';
              _appliquerFiltres();
            }),
            labelBuilder: _statutLabel,
          ),
          if (_matiereSelectionnee != null || _niveauSelectionne != null || _statutSelectionne != 'Tous')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  _matiereSelectionnee = null;
                  _niveauSelectionne = null;
                  _statutSelectionne = 'Tous';
                  _appliquerFiltres();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: YekiColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: YekiColors.error.withValues(alpha: 0.2), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_rounded, size: 14, color: YekiColors.error),
                      SizedBox(width: 4),
                      Text('Effacer', style: TextStyle(fontSize: 12, color: YekiColors.error, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String Function(String)? labelBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: YekiColors.borderLight, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          isDense: true,
          items: items.map((s) => DropdownMenuItem(
            value: s,
            child: Text(
              labelBuilder != null ? labelBuilder(s) : s,
              style: const TextStyle(fontSize: 12),
            ),
          )).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down, size: 18),
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        const Text(
          "Vos Devoirs",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: YekiColors.primaryDark.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${_affiches.length} Devoirs",
            style: const TextStyle(
              color: YekiColors.primaryDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedCard(DevoirItem d) {
    final joursRestants = d.dateLimite.difference(DateTime.now()).inDays;
    final estExpire = joursRestants < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: YekiColors.borderLight, width: 1.0),
        boxShadow: YekiShadows.subtle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (d.estCorrige && d.noteApprenant != null) {
                _voirResultat(d);
              } else if (!estExpire || d.aSoumis) {
                _ouvrirDevoir(d);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: d.typeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_getIconForType(d.typeDevoir), color: d.typeColor, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.titre,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                _infoChip(d.typeLabel, d.typeColor),
                                const SizedBox(width: 6),
                                _infoChip(d.statutLabel, d.statutColor),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (d.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      d.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: YekiColors.textDark.withValues(alpha: 0.6), height: 1.4, fontSize: 12.5),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: YekiColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoIcon(Icons.layers_outlined, '${d.matiere} • ${d.niveau}'),
                        _infoIcon(Icons.quiz_rounded, '${d.nbQuestions} questions'),
                        _infoIcon(Icons.timer_rounded, '${d.dureeMinutes} min'),
                      ],
                    ),
                  ),
                  if (d.estCorrige && d.noteApprenant != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: YekiColors.success.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: YekiColors.success.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.grade_rounded, color: YekiColors.success, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Note : ${d.noteApprenant!.toStringAsFixed(1)} / ${d.noteSur.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: YekiColors.success, borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              '${((d.noteApprenant! / d.noteSur) * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: YekiColors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTimerInfo(joursRestants, estExpire)),
                      const SizedBox(width: 12),
                      _buildActionButton(d, estExpire),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String typeDevoir) {
    switch (typeDevoir) {
      case 'cursus':
        return Icons.school_rounded;
      case 'concours':
        return Icons.emoji_events_rounded;
      case 'formation_classique':
        return Icons.account_balance_rounded;
      case 'formation_metier':
        return Icons.work_rounded;
      case 'olympiade':
        return Icons.military_tech_rounded;
      default:
        return Icons.assignment_rounded;
    }
  }

  Widget _infoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _infoIcon(IconData icon, String text) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: YekiColors.textLight),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerInfo(int joursRestants, bool estExpire) {
    if (estExpire) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: YekiColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_clock_rounded, size: 14, color: YekiColors.error),
            const SizedBox(width: 6),
            Text('Clôturé', style: TextStyle(color: YekiColors.error, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    final color = joursRestants < 3 ? YekiColors.error : (joursRestants < 7 ? YekiColors.warning : YekiColors.success);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$joursRestants jour${joursRestants > 1 ? 's' : ''}',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildActionButton(DevoirItem d, bool estExpire) {
    if (d.estCorrige && d.noteApprenant != null) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: YekiColors.success,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _voirResultat(d),
            child: const Center(
              child: Text('Voir résultat', style: TextStyle(color: YekiColors.white, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      );
    }

    if (estExpire && !d.aSoumis) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: d.typeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _ouvrirDevoir(d),
          child: Center(
            child: Text(
              d.estEnCours ? 'Continuer' : 'Commencer',
              style: const TextStyle(color: YekiColors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  String _typeLabel(String code) {
    switch (code) {
      case 'Tous': return 'Tous';
      case 'cursus': return 'Cursus';
      case 'concours': return 'Concours';
      case 'formation_classique': return 'Formation';
      case 'formation_metier': return 'Métier';
      case 'olympiade': return 'Olympiade';
      default: return code;
    }
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'non_commence': return 'À faire';
      case 'en_cours': return 'En cours';
      case 'soumis': return 'Soumis';
      case 'corrige': return 'Corrigé';
      case 'en_retard': return 'En retard';
      default: return s;
    }
  }

  Widget _buildResponsiveSkeleton(double padding) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      children: [
        const SizedBox(height: 20),
        _skeletonWidget(h: 28, w: 200),
        const SizedBox(height: 16),
        Row(
          children: List.generate(3, (_) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _skeletonWidget(h: 70, r: 16),
            ),
          )),
        ),
        const SizedBox(height: 16),
        _skeletonWidget(h: 48, r: 24),
        const SizedBox(height: 14),
        _skeletonWidget(h: 44, r: 22),
        const SizedBox(height: 24),
        _skeletonWidget(h: 220, r: 22),
        const SizedBox(height: 16),
        _skeletonWidget(h: 220, r: 22),
      ],
    );
  }

  Widget _skeletonWidget({double h = 20, double? w, double r = 12}) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(color: YekiColors.borderLight, borderRadius: BorderRadius.circular(r)),
      );

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 44, color: YekiColors.error),
            const SizedBox(height: 12),
            Text(_error, style: YekiTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            YekiButton(
              label: 'Réessayer',
              icon: Icons.refresh_rounded,
              onPressed: _charger,
              width: 160,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeDevoirTab {
  final String code;
  final IconData icon;
  final Color color;
  const _TypeDevoirTab(this.code, this.icon, this.color);
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: YekiColors.borderLight),
            const SizedBox(height: 16),
            const Text('Aucun devoir trouvé',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('Ajustez vos filtres pour voir plus de résultats.',
                style: TextStyle(fontSize: 12.5, height: 1.35), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}