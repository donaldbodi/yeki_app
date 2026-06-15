// lib/views/pages/apprenants/formations_pages.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';
import 'package:yeki/views/pages/apprenants/formation_detail_page.dart';
import 'package:yeki/widgets/yeki_app_bar.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

class FormationsPage extends StatefulWidget {
  const FormationsPage({super.key});

  @override
  State<FormationsPage> createState() => _FormationsPageState();
}

class _FormationsPageState extends State<FormationsPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _error = '';
  List<DepartementItem> _tous = [];
  List<DepartementItem> _affiches = [];
  late TabController _tabCtrl;
  String _niveauApprenant = '';

  String _searchQ = '';
  String _filtreProg = 'Toutes';
  final _searchCtrl = TextEditingController();

  static const _types = ['Tout', 'Métier', 'Classique'];

  int _unreadNotifications = 0;
  bool _isSubscribed = true;
  String _username = 'Apprenant';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _types.length, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    _loadNiveau();
    _charger();
    _loadUserData();
  }

  void _onTabChanged() {
    if (!_tabCtrl.indexIsChanging) {
      setState(() {});
      _appliquerFiltres();
    }
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;
    try {
      final response = await http.get(
          Uri.parse(ApiConstants.profilMe), headers: ApiHeaders.auth(token));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _username = data['username'] ?? 'Apprenant');
      }
    } catch (_) {}
  }

  Future<void> _loadNiveau() async {
    final niveau = await NiveauService.getNiveau();
    if (niveau != null) {
      setState(() => _niveauApprenant = niveau);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final token = await _getToken();
    try {
      final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/apprenant/formations/'),
          headers: ApiHeaders.auth(token));
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _tous = data
              .map((d) =>
                  DepartementItem.fromJson(d as Map<String, dynamic>))
              .toList();
          _appliquerFiltres();
        });
      } else if (mounted) {
        setState(() =>
            _error = 'Impossible de charger les formations (${res.statusCode})');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Vérifiez votre connexion internet');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _appliquerFiltres() {
    final q = _searchQ.toLowerCase();
    final tab = _tabCtrl.index;

    setState(() {
      _affiches = _tous.where((d) {
        final matchType = switch (tab) {
          1 => d.estFormationMetier,
          2 => d.estFormationClassique,
          _ => true,
        };

        bool matchNiveau = true;
        if (_niveauApprenant.isNotEmpty && d.niveauxAccessibles.isNotEmpty) {
          matchNiveau = NiveauService.estAccessibleParListe(
              _niveauApprenant, d.niveauxAccessibles);
        }

        final matchProg = switch (_filtreProg) {
          'En cours' => d.progression > 0 && d.progression < 100,
          'Nouvelles' => d.progression == 0,
          'Terminées' => d.progression >= 100,
          _ => true,
        };

        final matchSearch = q.isEmpty ||
            d.nom.toLowerCase().contains(q) ||
            d.domaine.toLowerCase().contains(q) ||
            d.ville.toLowerCase().contains(q) ||
            d.dureeFormation.toLowerCase().contains(q);

        return matchType && matchProg && matchSearch && matchNiveau;
      }).toList();
    });
  }

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Souhaitez-vous vraiment quitter votre espace Yéki ?',
            style: TextStyle(color: YekiColors.textMedium)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler',
                  style: TextStyle(color: YekiColors.textMedium))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: YekiColors.error,
              foregroundColor: YekiColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
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
        Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false);
      }
    }
  }

  IconData _getIconForFormation(DepartementItem dept) {
    final domaine = dept.domaine.toLowerCase();
    final nom = dept.nom.toLowerCase();

    if (domaine.contains('tech') ||
        domaine.contains('informatique') ||
        nom.contains('développement') ||
        nom.contains('programmation')) {
      return Icons.terminal_rounded;
    }
    if (domaine.contains('business') ||
        domaine.contains('gestion') ||
        domaine.contains('finance')) {
      return Icons.trending_up_rounded;
    }
    if (domaine.contains('design') ||
        domaine.contains('graphique') ||
        domaine.contains('créativ')) {
      return Icons.palette_rounded;
    }
    if (domaine.contains('santé') ||
        domaine.contains('médecine') ||
        domaine.contains('médical')) {
      return Icons.health_and_safety_rounded;
    }
    if (domaine.contains('artisanat') ||
        domaine.contains('métier') ||
        dept.estFormationMetier) {
      return Icons.handyman_rounded;
    }
    if (dept.modeFormation == 'distance') {
      return Icons.laptop_rounded;
    }

    return dept.estFormationMetier
        ? Icons.work_rounded
        : Icons.account_balance_rounded;
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
                  onRefresh: _charger,
                  color: YekiColors.primaryDark,
                  backgroundColor: YekiColors.white,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(padX, 16, padX, 0),
                          child: _buildHeroImageCover(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: padX),
                          child: _buildSearchBarAndPopup(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: padX),
                          child: _buildPremiumTabBar(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(padX, 8, padX, 12),
                          child: _buildSectionTitle(),
                        ),
                      ),
                      _affiches.isEmpty
                          ? const SliverFillRemaining(
                              hasScrollBody: false, child: _EmptyView())
                          : SliverPadding(
                              padding: EdgeInsets.fromLTRB(padX, 0, padX, 110),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, idx) =>
                                      _buildUnifiedCard(_affiches[idx]),
                                  childCount: _affiches.length,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroImageCover() {
    return Container(
      width: double.infinity,
      height: 175,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: YekiShadows.medium,
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?q=80&w=600&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              YekiColors.primaryLight.withValues(alpha: 0.15),
              YekiColors.primaryLight.withValues(alpha: 0.85),
            ],
          ),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: YekiColors.accent.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "DÉVELOPPEMENT PROFESSIONNEL",
                style: TextStyle(
                  color: YekiColors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Formations",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: YekiColors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              "Développez vos compétences avec nos experts.",
              style: TextStyle(
                fontSize: 13,
                color: YekiColors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBarAndPopup() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: YekiColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: YekiColors.borderLight, width: 1.2),
                boxShadow: YekiShadows.subtle,
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  _searchQ = v;
                  _appliquerFiltres();
                },
                style: YekiTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: "Rechercher une formation...",
                  hintStyle: YekiTextStyles.bodySmall,
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: YekiColors.primaryLight, size: 22),
                  suffixIcon: _searchQ.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQ = '');
                            _appliquerFiltres();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 15, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _FilterPopup(
            selected: _filtreProg,
            onChanged: (v) {
              setState(() => _filtreProg = v);
              _appliquerFiltres();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTabBar() {
    final counts = [
      _tous.length,
      _tous.where((d) => d.estFormationMetier).length,
      _tous.where((d) => d.estFormationClassique).length,
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: YekiColors.backgroundAlt,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TabBar(
        controller: _tabCtrl,
        labelColor: YekiColors.primaryLight,
        unselectedLabelColor: YekiColors.textLight,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YekiColors.primaryLight.withValues(alpha: 0.15), width: 1),
          boxShadow: YekiShadows.subtle,
        ),
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w900, fontSize: 12.5),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 12.5),
        tabs: List.generate(_types.length, (i) {
          bool isSelected = _tabCtrl.index == i;
          return Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_types[i]),
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? YekiColors.primaryLight.withValues(alpha: 0.12)
                        : YekiColors.backgroundAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${counts[i]}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? YekiColors.primaryLight
                          : YekiColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        const Text(
          "Vos Formations",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: YekiColors.primaryLight.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${_affiches.length} Disponibles",
            style: const TextStyle(
              color: YekiColors.primaryLight,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedCard(DepartementItem dept) {
    Color itemColor;
    try {
      final hex = dept.couleur.replaceAll('#', '');
      itemColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      itemColor = dept.estFormationMetier ? YekiColors.accent : YekiColors.primaryLight;
    }

    final typeLabel = dept.estFormationMetier
        ? 'Formation Métier'
        : 'Formation Classique';
    final bool aProgression = dept.progression > 0;
    final double progFraction = dept.progressionMoyenne / 100;
    
    final bool niveauMatch = _niveauApprenant.isEmpty || 
        dept.niveauxAccessibles.isEmpty ||
        dept.niveauxAccessibles.any((n) => n.toLowerCase() == _niveauApprenant.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: niveauMatch ? YekiColors.borderLight : YekiColors.borderLight.withValues(alpha: 0.5),
          width: niveauMatch ? 1.0 : 0.5,
        ),
        boxShadow: YekiShadows.subtle,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FormationDetailPage(
                    formationId: dept.id, deptPrecharge: dept),
              ),
            ).then((_) => _charger()),
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
                          color: itemColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getIconForFormation(dept),
                          color: itemColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dept.nom,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: itemColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    typeLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: itemColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                ...dept.niveauxAccessibles.map((niveau) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: YekiColors.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    niveau,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: YekiColors.warning,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (dept.estCertifiante)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: YekiColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 11, color: YekiColors.white),
                              SizedBox(width: 4),
                              Text(
                                'Certifiante',
                                style: TextStyle(
                                  color: YekiColors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  if (dept.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      dept.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: YekiColors.textDark.withValues(alpha: 0.6),
                          height: 1.4,
                          fontSize: 12.5),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (dept.dureeFormation.isNotEmpty)
                        _infoChip(Icons.schedule_rounded,
                            dept.dureeFormation, YekiColors.primaryLight),
                      if (dept.modeFormation.isNotEmpty)
                        _infoChip(
                          dept.modeFormation == 'presentiel'
                              ? Icons.location_city_rounded
                              : dept.modeFormation == 'distance'
                                  ? Icons.wifi_rounded
                                  : Icons.devices_rounded,
                          dept.modeFormationLabel,
                          YekiColors.purple,
                        ),
                      if (dept.ville.isNotEmpty)
                        _infoChip(Icons.location_on_rounded,
                            dept.ville, itemColor),
                      if (dept.domaine.isNotEmpty)
                        _infoChip(Icons.category_rounded, dept.domaine,
                            YekiColors.accent),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: YekiColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        _infoIcon(Icons.layers_rounded,
                            "${dept.nbCours} modules"),
                        if (dept.dureeFormation.isNotEmpty)
                          _infoIcon(Icons.timer_rounded,
                              dept.dureeFormation),
                        _infoIcon(Icons.menu_book_rounded,
                            '${dept.nbCours} cours'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  aProgression
                                      ? "Formation en cours"
                                      : (dept.prix == 0
                                          ? "Accès Libre"
                                          : "${dept.prix} FCFA"),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: aProgression
                                        ? YekiColors.primaryLight
                                        : (dept.prix == 0
                                            ? YekiColors.success
                                            : YekiColors.textLight),
                                  ),
                                ),
                                if (aProgression)
                                  Text(
                                    "${dept.progressionMoyenne.toStringAsFixed(0)}%",
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      color: YekiColors.primaryDark,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value:
                                    aProgression ? progFraction : 0.0,
                                backgroundColor: YekiColors.borderLight,
                                valueColor: AlwaysStoppedAnimation<
                                    Color>(
                                  aProgression
                                      ? YekiColors.primaryDark
                                      : YekiColors.textLight.withValues(alpha: 0.3),
                                ),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14),
                        decoration: BoxDecoration(
                          color: aProgression
                              ? YekiColors.accent
                              : itemColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          aProgression ? "CONTINUER" : "DÉCOUVRIR",
                          style: const TextStyle(
                            color: YekiColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
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

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: YekiColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: YekiColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 44, color: YekiColors.textLight),
            const SizedBox(height: 12),
            Text(_error,
                style: YekiTextStyles.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
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

  Widget _buildResponsiveSkeleton(double padding) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      children: [
        Container(
            height: 175,
            decoration: BoxDecoration(
                color: YekiColors.borderLight,
                borderRadius: BorderRadius.circular(24))),
        const SizedBox(height: 16),
        _skeletonWidget(h: 48, r: 24),
        const SizedBox(height: 14),
        _skeletonWidget(h: 44, r: 24),
        const SizedBox(height: 24),
        _skeletonWidget(h: 220, r: 22),
        const SizedBox(height: 16),
        _skeletonWidget(h: 220, r: 22),
      ],
    );
  }

  Widget _skeletonWidget({double h = 20, double r = 12}) => Container(
        height: h,
        decoration: BoxDecoration(
            color: YekiColors.borderLight, borderRadius: BorderRadius.circular(r)),
      );
}

class _FilterPopup extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _FilterPopup({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: YekiColors.white,
      elevation: 6,
      itemBuilder: (_) => ['Toutes', 'En cours', 'Nouvelles', 'Terminées']
          .map((s) => PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    if (s == selected)
                      const Icon(Icons.check_rounded,
                          size: 15, color: YekiColors.primaryLight),
                    if (s == selected) const SizedBox(width: 8),
                    Text(s,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: YekiColors.borderLight, width: 1.2),
        ),
        child: const Icon(Icons.tune_rounded, color: YekiColors.primaryLight, size: 22),
      ),
    );
  }
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
            Icon(Icons.workspace_premium_outlined,
                size: 64, color: YekiColors.borderLight),
            const SizedBox(height: 16),
            const Text(
              'Aucune formation disponible',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajustez vos filtres ou explorez d\'autres catégories.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}