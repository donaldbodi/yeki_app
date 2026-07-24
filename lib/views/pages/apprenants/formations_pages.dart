// lib/views/pages/apprenants/formations_pages.dart
// ═══════════════════════════════════════════════════════════════════════════
// FORMATIONS PAGE — GLASSMORPHISM LIGHT EDITION
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';
import 'package:yeki/core/router/route_names.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

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

  static const List<String> _types = ['Tout', 'Métier', 'Classique'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _types.length, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    _loadNiveau();
    _charger();
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
              .map((d) => DepartementItem.fromJson(d as Map<String, dynamic>))
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
      _affiches = _tous.where((DepartementItem d) {
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
      backgroundColor: YekiColors.bgLight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: YekiGradients.mainBackground,
        ),
        child: Stack(
          children: [
            // Sphères décoratives
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.primaryLight.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.accent.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 200,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.gold.withValues(alpha: 0.05),
                ),
              ),
            ),
            SafeArea(
              child: _loading
                  ? _buildResponsiveSkeleton(padX)
                  : _error.isNotEmpty
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: _charger,
                          color: YekiColors.primaryDark,
                          backgroundColor: YekiColors.white,
                          child: _buildContent(padX),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(double padX) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
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
        _buildSliverList(padX),
      ],
    );
  }

  Widget _buildSliverList(double padX) {
    if (_affiches.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyView(),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(padX, 0, padX, 110),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            return _buildUnifiedCard(_affiches[index]);
          },
          childCount: _affiches.length,
        ),
      ),
    );
  }

  Widget _buildHeroImageCover() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 175,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?q=80&w=600&auto=format&fit=crop',
              ),
              fit: BoxFit.cover,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  YekiColors.primaryLight.withValues(alpha: 0.15),
                  YekiColors.primaryLight.withValues(alpha: 0.85),
                ],
              ),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
        ),
      ),
    );
  }

  Widget _buildSearchBarAndPopup() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: YekiColors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: YekiColors.white.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (String value) {
                      _searchQ = value;
                      _appliquerFiltres();
                    },
                    style: YekiTextStyles.body(context),
                    decoration: InputDecoration(
                      hintText: "Rechercher une formation...",
                      hintStyle: YekiTextStyles.body(context).copyWith(color: YekiColors.textMedium),
                      prefixIcon: Icon(Icons.search_rounded, color: YekiColors.primaryLight, size: 22),
                      suffixIcon: _searchQ.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQ = '');
                                _appliquerFiltres();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _FilterPopup(
            selected: _filtreProg,
            onChanged: (String value) {
              setState(() => _filtreProg = value);
              _appliquerFiltres();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTabBar() {
    final counts = <int>[
      _tous.length,
      _tous.where((DepartementItem d) => d.estFormationMetier).length,
      _tous.where((DepartementItem d) => d.estFormationClassique).length,
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: YekiColors.white.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabCtrl,
        labelColor: YekiColors.primary,
        unselectedLabelColor: YekiColors.textMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: YekiColors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: YekiColors.white.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
        tabs: List.generate(_types.length, (int index) {
          bool isSelected = _tabCtrl.index == index;
          return Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(_types[index]),
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? YekiColors.primary.withValues(alpha: 0.12)
                        : YekiColors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${counts[index]}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? YekiColors.primary : YekiColors.textMedium,
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
      children: <Widget>[
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: YekiColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: YekiColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Text(
            "${_affiches.length} Disponibles",
            style: const TextStyle(
              color: YekiColors.primary,
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

    final String typeLabel = dept.estFormationMetier
        ? 'Formation Métier'
        : 'Formation Classique';
    final bool aProgression = dept.progression > 0;
    final double progFraction = dept.progressionMoyenne / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: YekiColors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: YekiColors.white.withValues(alpha: 0.9),
                width: 1.0,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleTapOnCard(dept, itemColor),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
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
                              children: <Widget>[
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
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                    if (dept.accesRestreint == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: YekiColors.warning.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Icon(Icons.lock_rounded, size: 10, color: YekiColors.warning),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Sur demande',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: YekiColors.warning,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ...dept.niveauxAccessibles.map((String niveau) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: <Color>[YekiColors.accent, YekiColors.accent.withValues(alpha: 0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.verified_rounded, size: 11, color: YekiColors.white),
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
                            fontSize: 12.5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: <Widget>[
                          if (dept.dureeFormation.isNotEmpty)
                            _infoChip(Icons.schedule_rounded, dept.dureeFormation, YekiColors.primaryLight),
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
                            _infoChip(Icons.location_on_rounded, dept.ville, itemColor),
                          if (dept.domaine.isNotEmpty)
                            _infoChip(Icons.category_rounded, dept.domaine, YekiColors.accent),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: YekiColors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: YekiColors.white.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            _infoIcon(Icons.layers_rounded, "${dept.nbCours} modules"),
                            if (dept.dureeFormation.isNotEmpty)
                              _infoIcon(Icons.timer_rounded, dept.dureeFormation),
                            _infoIcon(Icons.menu_book_rounded, '${dept.nbCours} cours'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      aProgression
                                          ? "Formation en cours"
                                          : (dept.prix == 0 ? "Accès Libre" : "${dept.prix} FCFA"),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: aProgression
                                            ? YekiColors.primary
                                            : (dept.prix == 0 ? YekiColors.success : YekiColors.textMedium),
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
                                    value: aProgression ? progFraction : 0.0,
                                    backgroundColor: YekiColors.borderLight.withValues(alpha: 0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      aProgression ? YekiColors.primaryDark : YekiColors.textLight.withValues(alpha: 0.3),
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
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  aProgression ? YekiColors.accent : itemColor,
                                  aProgression ? YekiColors.accent.withValues(alpha: 0.8) : itemColor.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
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
        ),
      ),
    );
  }

  Future<void> _handleTapOnCard(DepartementItem dept, Color itemColor) async {
    if (dept.accesRestreint == true) {
      final token = await _getToken();
      if (token == null) {
        ErrorHandler.showError(context, 'Veuillez vous reconnecter');
        return;
      }

      try {
        final res = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/apprenant/departement/${dept.id}/acces/'),
          headers: ApiHeaders.auth(token),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['acces'] == true) {
            context.pushNamed(
              AppRoute.formationDetail,
              pathParameters: {'formationId': dept.id.toString()},
              extra: dept,
            ).then((_) => _charger());
          } else if (data['statut'] == 'en_attente') {
            _showMessage('Votre demande d\'accès est en attente de traitement.', type: 'warning');
          } else if (data['statut'] == 'refusee') {
            _showMessage('Accès refusé. Veuillez contacter le service client.', type: 'error');
          } else {
            _demanderAcces(dept);
          }
        } else {
          ErrorHandler.showError(context, 'Erreur lors de la vérification');
        }
      } catch (_) {
        ErrorHandler.showError(context, 'Erreur réseau');
      }
    } else {
      context.pushNamed(
        AppRoute.formationDetail,
        pathParameters: {'formationId': dept.id.toString()},
        extra: dept,
      ).then((_) => _charger());
    }
  }

  void _demanderAcces(DepartementItem dept) {
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: YekiColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (BuildContext ctx, StateSetter setS) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                    children: <Widget>[
                      Icon(Icons.lock_outline_rounded, color: YekiColors.warning, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Demander l\'accès',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: YekiColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cette formation est à accès restreint. Veuillez expliquer brièvement votre demande.',
                    style: TextStyle(fontSize: 13, color: YekiColors.textMedium),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Expliquez pourquoi vous souhaitez accéder à cette formation...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: YekiColors.borderLight, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: YekiColors.primaryDark, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _envoyerDemandeAcces(dept.id, messageController.text.trim());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: YekiColors.primaryDark,
                            foregroundColor: YekiColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Envoyer la demande'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _envoyerDemandeAcces(int departementId, String message) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/departements/$departementId/demander-acces/'),
        headers: ApiHeaders.auth(token),
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 201) {
        ErrorHandler.showSuccess(context, '✅ Votre demande a été envoyée au cadre.');
        _charger();
      } else {
        final error = jsonDecode(response.body);
        ErrorHandler.showError(context, error['detail'] ?? 'Erreur');
      }
    } catch (_) {
      ErrorHandler.showError(context, 'Erreur réseau');
    }
  }

  void _showMessage(String message, {String type = 'info'}) {
    if (!mounted) return;
    final Map<String, Color> colors = {
      'warning': YekiColors.warning,
      'error': YekiColors.error,
      'success': YekiColors.success,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: YekiColors.white)),
        backgroundColor: colors[type] ?? YekiColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: YekiColors.white.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
        children: <Widget>[
          Icon(icon, size: 13, color: YekiColors.textMedium),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: YekiColors.textMedium),
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
          children: <Widget>[
            const Icon(Icons.wifi_off_rounded, size: 44, color: YekiColors.textLight),
            const SizedBox(height: 12),
            Text(_error, style: YekiTextStyles.body(context), textAlign: TextAlign.center),
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
      children: <Widget>[
        Container(
          height: 175,
          decoration: BoxDecoration(
            color: YekiColors.textLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
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

  Widget _skeletonWidget({double h = 20, double r = 12}) {
    return Container(
      height: h,
      decoration: BoxDecoration(
        color: YekiColors.textLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
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
      color: YekiColors.white.withValues(alpha: 0.9),
      elevation: 6,
      itemBuilder: (BuildContext context) {
        return <String>['Toutes', 'En cours', 'Nouvelles', 'Terminées']
            .map((String s) => PopupMenuItem<String>(
                  value: s,
                  child: Row(
                    children: <Widget>[
                      if (s == selected)
                        const Icon(Icons.check_rounded, size: 15, color: YekiColors.primary),
                      if (s == selected) const SizedBox(width: 8),
                      Text(
                        s,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: YekiColors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: YekiColors.white.withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        child: const Icon(Icons.tune_rounded, color: YekiColors.primary, size: 22),
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
          children: <Widget>[
            Icon(Icons.workspace_premium_outlined, size: 64, color: YekiColors.textLight.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Aucune formation disponible',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajustez vos filtres ou explorez d\'autres catégories.',
              style: TextStyle(fontSize: 12.5, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}