// lib/views/pages/apprenants/concours_pages.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';
import 'package:yeki/views/pages/apprenants/concours_detail_page.dart';
import 'package:yeki/widgets/yeki_app_bar.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

class ConcoursPage extends StatefulWidget {
  const ConcoursPage({super.key});

  @override
  State<ConcoursPage> createState() => _ConcoursPageState();
}

class _ConcoursPageState extends State<ConcoursPage> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _error = '';
  List<DepartementItem> _tous = [];
  List<DepartementItem> _affiches = [];
  String _filtre = 'Tous';
  String _searchQ = '';
  String _niveauApprenant = '';
  final _searchCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _filtres = ['Tous', 'Gratuit', 'Payant', 'En cours'];

  final int _unreadNotifications = 2;
  final bool _isSubscribed = true;
  String _username = 'Apprenant';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _loadNiveau();
    _charger();
    _loadUserData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
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

  Future<void> _loadNiveau() async {
    final niveau = await NiveauService.getNiveau();
    if (niveau != null) {
      setState(() => _niveauApprenant = niveau);
    }
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
        _animCtrl.forward(from: 0);
      } else if (mounted) {
        setState(() => _error = 'Impossible de charger les programmes (${res.statusCode})');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Vérifiez votre connexion internet');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _appliquerFiltre() {
    final q = _searchQ.toLowerCase();
    setState(() {
      _affiches = _tous.where((d) {
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

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Souhaitez-vous vraiment quitter votre espace Yéki Prépa ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: YekiColors.error),
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
                  child: FadeTransition(
                    opacity: _fadeAnim,
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
                        _affiches.isEmpty
                            ? const SliverFillRemaining(hasScrollBody: false, child: _EmptyView())
                            : SliverPadding(
                                padding: EdgeInsets.fromLTRB(padX, 0, padX, 110),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, idx) => _buildAiryPremiumCard(_affiches[idx]),
                                    childCount: _affiches.length,
                                  ),
                                ),
                              ),
                      ],
                    ),
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
            'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=600&auto=format&fit=crop',
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
            _appliquerFiltre();
          },
          style: YekiTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: "Rechercher une école, un concours...",
            hintStyle: YekiTextStyles.bodySmall,
            prefixIcon: Icon(Icons.search_rounded, color: YekiColors.primaryLight, size: 22),
            suffixIcon: _searchQ.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQ = '');
                      _appliquerFiltre();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
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
        itemBuilder: (context, i) {
          bool isSelected = _filtre == _filtres[i];
          return GestureDetector(
            onTap: () => setState(() {
              _filtre = _filtres[i];
              _appliquerFiltre();
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? YekiColors.primaryDark.withValues(alpha: 0.12) : YekiColors.backgroundAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? YekiColors.primaryDark.withValues(alpha: 0.35) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _filtres[i],
                style: TextStyle(
                  color: isSelected ? YekiColors.primaryLight : YekiColors.textLight,
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
      children: [
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
            color: YekiColors.primaryDark.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${_affiches.length} Concours Ouverts",
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailConcoursPage(concoursId: dept.id, deptPrecharge: dept),
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
                          _getIconForConcours(affichageTitre),
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
                                children: dept.niveauxAccessibles.map((niveau) => Container(
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
                                )).toList(),
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
                      children: dept.niveauxCibles.split(',').map((niv) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: YekiColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: YekiColors.borderLight),
                        ),
                        child: Text(
                          niv.trim(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: YekiColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _infoIcon(Icons.calendar_month_rounded, dept.dateExamen?.toString().substring(0, 10) ?? "À définir"),
                        if (dept.placesDisponibles != null)
                          _infoIcon(Icons.event_seat_rounded, "${dept.placesDisponibles} pl."),
                        _infoIcon(Icons.layers_rounded, "${dept.nbCours} mod."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  aProgression ? "Préparation en cours" : (dept.prix == 0 ? "Accès Libre" : "${dept.prix} FCFA"),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: aProgression ? YekiColors.primaryLight : (dept.prix == 0 ? YekiColors.success : YekiColors.textLight),
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
                                backgroundColor: YekiColors.borderLight,
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
                          color: aProgression ? YekiColors.accent : itemColor,
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 44, color: YekiColors.textLight),
            const SizedBox(height: 12),
            Text(_error, style: YekiTextStyles.bodyMedium, textAlign: TextAlign.center),
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
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 16),
        _skeletonWidget(h: 48, r: 24),
        const SizedBox(height: 14),
        Row(
          children: List.generate(3, (_) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _skeletonWidget(h: 36, r: 18),
            ),
          )),
        ),
        const SizedBox(height: 24),
        _skeletonWidget(h: 200, r: 22),
        const SizedBox(height: 16),
        _skeletonWidget(h: 200, r: 22),
      ],
    );
  }

  Widget _skeletonWidget({double h = 20, double r = 12}) => Container(
        height: h,
        decoration: BoxDecoration(
          color: YekiColors.borderLight,
          borderRadius: BorderRadius.circular(r),
        ),
      );
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
            Icon(Icons.assignment_turned_in_rounded, size: 64, color: YekiColors.borderLight),
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