// lib/views/pages/apprenants/concours_pages.dart
// ═══════════════════════════════════════════════════════════════════════════
// CONCOURS PAGE — GLASSMORPHISM LIGHT EDITION (VERSION FINALE)
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

class ConcoursPage extends StatefulWidget {
  const ConcoursPage({super.key});

  @override
  State<ConcoursPage> createState() => _ConcoursPageState();
}

class _ConcoursPageState extends State<ConcoursPage> {
  bool _loading = true;
  String _error = '';
  List<DepartementItem> _tous = [];
  List<DepartementItem> _affiches = [];
  String _filtre = 'Tous';
  String _searchQ = '';
  String _niveauApprenant = '';
  final _searchCtrl = TextEditingController();

  static const List<String> _filtres = ['Tous', 'Gratuit', 'Payant', 'En cours'];

  @override
  void initState() {
    super.initState();
    _loadNiveau();
    _charger();
  }

  @override
  void dispose() {
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
        Uri.parse('${ApiConstants.baseUrl}/apprenant/prepa-concours/'),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _tous = data.map((d) => DepartementItem.fromJson(d as Map<String, dynamic>)).toList();
          _appliquerFiltre();
        });
      } else if (mounted) {
        setState(() => _error = 'Impossible de charger les programmes (${res.statusCode})');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Vérifiez votre connexion internet');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _appliquerFiltre() {
    final q = _searchQ.toLowerCase();
    setState(() {
      _affiches = _tous.where((DepartementItem d) {
        final matchSearch = q.isEmpty ||
            d.nom.toLowerCase().contains(q) ||
            d.nomConcours.toLowerCase().contains(q) ||
            d.niveauxCibles.toLowerCase().contains(q);

        final matchFiltre = switch (_filtre) {
          'Gratuit' => d.prix == 0,
          'Payant' => d.prix > 0,
          'En cours' => d.progressionMoyenne > 0 && d.progressionMoyenne < 100,
          _ => true,
        };

        bool matchNiveau = true;
        if (_niveauApprenant.isNotEmpty && d.niveauxAccessibles.isNotEmpty) {
          matchNiveau = NiveauService.estAccessibleParListe(_niveauApprenant, d.niveauxAccessibles);
        }

        return matchSearch && matchFiltre && matchNiveau;
      }).toList();
    });
  }

  IconData _getIconForConcours(String text) {
    final t = text.toLowerCase();
    if (t.contains('polytech') || t.contains('ingé') || t.contains('mines') || t.contains('travaux')) {
      return Icons.engineering_rounded;
    }
    if (t.contains('ens') || t.contains('normale') || t.contains('pédagogie')) {
      return Icons.school_rounded;
    }
    if (t.contains('enam') || t.contains('admin') || t.contains('gavel') || t.contains('magistrature')) {
      return Icons.gavel_rounded;
    }
    if (t.contains('santé') || t.contains('médecine') || t.contains('fmsb')) {
      return Icons.health_and_safety_rounded;
    }
    if (t.contains('numérique') || t.contains('ict') || t.contains('supptic') || t.contains('informatique')) {
      return Icons.terminal_rounded;
    }
    return Icons.workspace_premium_rounded;
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
              bottom: 100,
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
              top: 300,
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
            child: _buildSearchBar(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padX),
            child: _buildPremiumFilterBar(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padX, 8, padX, 12),
            child: _buildSectionTitle(),
          ),
        ),
        if (_affiches.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyView(),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padX, 0, padX, 110),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return _buildAiryPremiumCard(_affiches[index]);
                },
                childCount: _affiches.length,
              ),
            ),
          ),
      ],
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
                'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=600&auto=format&fit=crop',
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
                    "YÉKI PRÉPA CONCOURS",
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
                  "Atteignez l'Excellence",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: YekiColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _niveauApprenant.isNotEmpty
                      ? "Concours accessibles pour le niveau : $_niveauApprenant"
                      : "Propulsez votre avenir au sein des grandes écoles d'ingénierie.",
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
                _appliquerFiltre();
              },
              style: YekiTextStyles.body(context),
              decoration: InputDecoration(
                hintText: "Rechercher une école, un concours...",
                hintStyle: YekiTextStyles.body(context).copyWith(color: YekiColors.textMedium),
                prefixIcon: Icon(Icons.search_rounded, color: YekiColors.primaryLight, size: 22),
                suffixIcon: _searchQ.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _searchQ = '';
                          });
                          _appliquerFiltre();
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
    );
  }

  Widget _buildPremiumFilterBar() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filtres.length,
        itemBuilder: (BuildContext context, int index) {
          bool isSelected = _filtre == _filtres[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _filtre = _filtres[index];
                _appliquerFiltre();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? YekiColors.primary.withValues(alpha: 0.12)
                    : YekiColors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? YekiColors.primary.withValues(alpha: 0.3)
                      : YekiColors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _filtres[index],
                style: TextStyle(
                  color: isSelected ? YekiColors.primary : YekiColors.textMedium,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: <Widget>[
        const Text(
          "Vos Concours",
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
            "${_affiches.length} Concours Ouverts",
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

  Widget _buildAiryPremiumCard(DepartementItem dept) {
    Color itemColor;
    try {
      final hex = dept.couleur.replaceAll('#', '');
      itemColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      itemColor = YekiColors.primaryLight;
    }

    final String affichageTitre = dept.nomConcours.isNotEmpty ? dept.nomConcours : dept.nom;
    final bool aProgression = dept.progressionMoyenne > 0;
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
                onTap: () {
                  context.pushNamed(
                    AppRoute.concoursDetail,
                    pathParameters: {'concoursId': dept.id.toString()},
                    extra: dept,
                  ).then((_) => _charger());
                },
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
                              _getIconForConcours(affichageTitre),
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
                                  affichageTitre,
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                if (dept.nom != dept.nomConcours && dept.nom.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      dept.nom,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: itemColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (dept.niveauxAccessibles.isNotEmpty)
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: dept.niveauxAccessibles.map((String niveau) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: YekiColors.warning.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          niveau,
                                          style: TextStyle(
                                            color: YekiColors.warning,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }).toList(),
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
                      if (dept.niveauxCibles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: dept.niveauxCibles.split(',').map((String niv) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: YekiColors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: YekiColors.white.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                niv.trim(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: YekiColors.textDark),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
                            _infoIcon(Icons.calendar_month_rounded, dept.dateExamen?.toString().substring(0, 10) ?? "À définir"),
                            if (dept.placesDisponibles != null)
                              _infoIcon(Icons.event_seat_rounded, "${dept.placesDisponibles} pl."),
                            _infoIcon(Icons.layers_rounded, "${dept.nbCours} mod."),
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
                                      aProgression ? "Préparation en cours" : (dept.prix == 0 ? "Accès Libre" : "${dept.prix} FCFA"),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: aProgression ? YekiColors.primary : (dept.prix == 0 ? YekiColors.success : YekiColors.textMedium),
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
        Row(
          children: List.generate(3, (_) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _skeletonWidget(h: 36, r: 18),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        _skeletonWidget(h: 200, r: 22),
        const SizedBox(height: 16),
        _skeletonWidget(h: 200, r: 22),
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
            Icon(Icons.assignment_turned_in_rounded, size: 64, color: YekiColors.textLight.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Aucun concours trouvé',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajustez vos filtres ou votre recherche pour explorer d\'autres opportunités.',
              style: TextStyle(fontSize: 12.5, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}