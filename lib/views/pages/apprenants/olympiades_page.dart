// lib/views/pages/apprenants/olympiades_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// PAGE OLYMPIADES — GLASSMORPHISM EDITION
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/classement_olympiade.dart';
import 'package:yeki/views/pages/apprenants/composer_devoir_page.dart';
import 'package:yeki/views/pages/apprenants/sheet_inscription.dart';
import 'package:yeki/views/pages/apprenants/formations_models.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/constants/api_constants.dart';

class OlympiadesPage extends StatefulWidget {
  const OlympiadesPage({super.key});
  @override
  State<OlympiadesPage> createState() => _OlympiadesPageState();
}

class _OlympiadesPageState extends State<OlympiadesPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String _error = '';
  List<OlympiadeItem> _tous = [];
  List<OlympiadeItem> _affich = [];
  String _niveau = '';
  String _phaseFiltre = 'tous';

  final List<(String, String, Color, IconData)> _phases = [
    ('tous', 'Toutes', YekiColors.primary, Icons.apps_rounded),
    ('inscription', 'Inscriptions', YekiColors.success, Icons.how_to_reg_rounded),
    ('competition', 'En cours', YekiColors.purple, Icons.play_circle_rounded),
    ('terminee', 'Terminées', YekiColors.accent, Icons.emoji_events_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _charger();
    _loadNiveau();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadNiveau() async {
    final niveau = await NiveauService.getNiveau();
    if (niveau != null) {
      setState(() => _niveau = niveau);
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
      final rP = await http.get(Uri.parse(ApiConstants.profilMe),
          headers: ApiHeaders.auth(token));
      if (rP.statusCode == 200) {
        _niveau = (jsonDecode(rP.body) as Map)['niveau']?.toString() ?? '';
      }
    } catch (_) {}

    try {
      final res = await http.get(
        Uri.parse(ApiConstants.olympiadesPourMoi),
        headers: ApiHeaders.auth(token),
      );

      if (res.statusCode == 200 && mounted) {
        final data = (jsonDecode(res.body) as List)
            .map((j) => OlympiadeItem.fromJson(j as Map<String, dynamic>))
            .toList();
        setState(() {
          _tous = data;
        });
        _appliquerFiltre();
      } else if (mounted) {
        setState(() => _error = 'Erreur ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur réseau: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _appliquerFiltre() {
    setState(() {
      _affich = _phaseFiltre == 'tous'
          ? _tous
          : _tous.where((o) => o.phase == _phaseFiltre).toList();
    });
  }

  IconData _getIconForMatiere(String matiere) {
    final m = matiere.toLowerCase();
    if (m.contains('math')) return Icons.calculate_rounded;
    if (m.contains('physique')) return Icons.science_rounded;
    if (m.contains('chimie')) return Icons.biotech_rounded;
    if (m.contains('svt') || m.contains('bio')) return Icons.eco_rounded;
    if (m.contains('info')) return Icons.terminal_rounded;
    if (m.contains('français') || m.contains('lettre')) {
      return Icons.menu_book_rounded;
    }
    if (m.contains('anglais') || m.contains('langue')) {
      return Icons.language_rounded;
    }
    if (m.contains('histoire') || m.contains('géo')) return Icons.public_rounded;
    if (m.contains('philo')) return Icons.psychology_rounded;
    if (m.contains('éco')) return Icons.trending_up_rounded;
    return Icons.military_tech_rounded;
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
                  color: YekiColors.purple.withValues(alpha: 0.08),
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
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(padX, 16, padX, 0),
            child: _buildHeroSection(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padX),
            child: _buildFilters(),
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
    if (_affich.isEmpty) {
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
            return _buildUnifiedCard(_affich[index]);
          },
          childCount: _affich.length,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
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
                'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=600&auto=format&fit=crop',
              ),
              fit: BoxFit.cover,
            ),
            boxShadow: [
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
                    "EXCELLENCE ACADÉMIQUE",
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
                  "Olympiades",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: YekiColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _niveau.isNotEmpty
                      ? "Compétitions disponibles pour le niveau : $_niveau"
                      : "Défiez les meilleurs apprenants",
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

  Widget _buildFilters() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _phases.length,
        itemBuilder: (context, i) {
          final phase = _phases[i];
          final sel = _phaseFiltre == phase.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _phaseFiltre = phase.$1);
              _appliquerFiltre();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? phase.$3.withValues(alpha: 0.12)
                    : YekiColors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? phase.$3.withValues(alpha: 0.3) : YekiColors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    phase.$4,
                    size: 15,
                    color: sel ? phase.$3 : YekiColors.textMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    phase.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      color: sel ? phase.$3 : YekiColors.textMedium,
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

  Widget _buildSectionTitle() {
    return Row(
      children: [
        const Text(
          "Vos Olympiades",
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
            "${_affich.length} Épreuves",
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

  Widget _buildUnifiedCard(OlympiadeItem o) {
    final (phaseLabel, phaseColor) = _phaseInfo(o.phase);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final Color cardColor = phaseColor;

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
              boxShadow: [
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
                onTap: () => _handleCardTap(o),
                borderRadius: BorderRadius.circular(24),
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
                              color: cardColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _getIconForMatiere(o.matiere),
                              color: cardColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.titre,
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
                                    Text(
                                      o.matiere,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: YekiColors.textDark,
                                      ),
                                    ),
                                    if (o.niveau.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: YekiColors.white.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: YekiColors.white.withValues(alpha: 0.6),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          o.niveau,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ...o.niveauxAccessibles.map((niveau) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cardColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              phaseLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: cardColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (o.reglement.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          o.reglement,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: YekiColors.textDark.withValues(alpha: 0.6),
                            height: 1.4,
                            fontSize: 12.5,
                          ),
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
                        child: Column(
                          children: [
                            _buildDateRow(
                              Icons.how_to_reg_rounded,
                              'Fin des inscriptions',
                              dateFmt.format(o.datFinInscription),
                              YekiColors.success,
                            ),
                            const SizedBox(height: 8),
                            _buildDateRow(
                              Icons.play_circle_rounded,
                              'Début de l\'épreuve',
                              dateFmt.format(o.datDebutCompetition),
                              YekiColors.primary,
                            ),
                            const SizedBox(height: 8),
                            _buildDateRow(
                              Icons.stop_circle_rounded,
                              'Clôture générale',
                              dateFmt.format(o.datFinCompetition),
                              YekiColors.error,
                            ),
                          ],
                        ),
                      ),

                      if (o.note != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: YekiColors.accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: YekiColors.accent.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events_rounded, color: YekiColors.accent, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Résultat : ${o.note!.toStringAsFixed(1)} / ${o.noteMax?.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              if (o.rang != null) ...[
                                const Spacer(),
                                Text(
                                  'Rang : #${o.rang}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: YekiColors.accent,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      _buildActions(o),
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

  void _handleCardTap(OlympiadeItem o) {
    if (o.phase == 'terminee' && o.afficherClassement) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassementOlympiadePage(
            olympiadeId: o.id, titre: o.titre),
        ),
      );
    } else if (o.phase == 'competition' && o.estInscrit) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComposerDevoirPage(
            devoirId: o.devoirId,
            titre: o.titre,
            dureeMin: o.dureeMinutes,
            noteSur: (o.noteMax ?? 20).toInt(),
          ),
        ),
      );
    } else if (o.phase == 'inscription' && !o.estInscrit) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => InscriptionSheet(
          olympiadeId: o.id,
          titre: o.titre,
          onSuccess: _charger,
        ),
      );
    }
  }

  Widget _buildActions(OlympiadeItem o) {
    if (o.phase == 'terminee' && o.afficherClassement) {
      return SizedBox(
        width: double.infinity,
        child: YekiButton(
          label: 'Visualiser le classement',
          icon: Icons.leaderboard_rounded,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassementOlympiadePage(
                olympiadeId: o.id, titre: o.titre),
            ),
          ),
          width: double.infinity,
        ),
      );
    }
    if (o.phase == 'competition' && o.estInscrit) {
      return SizedBox(
        width: double.infinity,
        child: YekiButton(
          label: 'Lancer la compétition',
          icon: Icons.play_arrow_rounded,
          color: YekiColors.purple,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComposerDevoirPage(
                devoirId: o.devoirId,
                titre: o.titre,
                dureeMin: o.dureeMinutes,
                noteSur: (o.noteMax ?? 20).toInt(),
              ),
            ),
          ),
          width: double.infinity,
        ),
      );
    }
    if (o.phase == 'inscription' && !o.estInscrit) {
      return SizedBox(
        width: double.infinity,
        child: YekiButton(
          label: "S'inscrire maintenant",
          icon: Icons.assignment_turned_in_rounded,
          color: YekiColors.primaryDark,
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => InscriptionSheet(
              olympiadeId: o.id,
              titre: o.titre,
              onSuccess: _charger,
            ),
          ),
          width: double.infinity,
        ),
      );
    }
    if (o.phase == 'inscription' && o.estInscrit) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: YekiColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: YekiColors.success.withValues(alpha: 0.15)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: YekiColors.success, size: 16),
            SizedBox(width: 8),
            Text(
              'Enregistré — En attente du lancement',
              style: TextStyle(
                color: YekiColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDateRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: YekiColors.textMedium.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text('$label : ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: YekiColors.textMedium,
            )),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  (String, Color) _phaseInfo(String phase) => switch (phase) {
        'inscription' => ('Inscriptions', YekiColors.success),
        'competition' => ('En cours', YekiColors.purple),
        'terminee' => ('Terminée', YekiColors.accent),
        _ => ('En attente', YekiColors.textLight),
      };

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 44, color: YekiColors.textLight),
            const SizedBox(height: 12),
            Text(_error, style: YekiTextStyles.body(context), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            YekiButton(
              label: 'Actualiser',
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
            color: YekiColors.textLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 16),
        _skeletonWidget(h: 44, r: 22),
        const SizedBox(height: 24),
        _skeletonWidget(h: 250, r: 22),
        const SizedBox(height: 16),
        _skeletonWidget(h: 250, r: 22),
      ],
    );
  }

  Widget _skeletonWidget({double h = 20, double r = 12}) => Container(
        height: h,
        decoration: BoxDecoration(
          color: YekiColors.textLight.withValues(alpha: 0.15),
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
            Icon(Icons.military_tech_outlined, size: 64, color: YekiColors.textLight.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'Aucune olympiade trouvée',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Ajustez vos filtres ou revenez plus tard.',
              style: TextStyle(
                fontSize: 12.5, height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}