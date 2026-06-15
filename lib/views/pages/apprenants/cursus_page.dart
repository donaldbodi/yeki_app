// lib/views/pages/apprenants/cursus_page.dart
// ═══════════════════════════════════════════════════════════════════════════
//  YEKI CURSUS PAGE — CORRIGÉE
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/auth/login_page.dart';
import 'package:yeki/views/pages/apprenants/cours_detail_page.dart';
import 'package:yeki/views/pages/shared/notifications_page.dart';
import 'package:yeki/views/pages/shared/profil_page.dart';
import 'package:yeki/widgets/yeki_app_bar.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

class CursusPage extends StatefulWidget {
  const CursusPage({super.key});

  @override
  State<CursusPage> createState() => _CursusPageState();
}

class _CursusPageState extends State<CursusPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic> _profil = {};
  List<Map<String, dynamic>> _cours = [];
  List<Map<String, dynamic>> _recent = [];

  bool _loadingCours = true;
  bool _loadingRecent = true;
  bool _loadingProfil = true;
  String _errorCours = '';

  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _coursFiltres = [];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final bool _isSubscribed = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _chargerTout();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('token');
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Token $t',
    };
  }

  Future<void> _chargerTout() async {
    await Future.wait([_chargerProfil(), _chargerCours(), _chargerRecent()]);
  }

  Future<void> _chargerProfil() async {
    try {
      final headers = await _headers();
      final res = await http.get(Uri.parse(ApiConstants.profilMe), headers: headers);
      if (res.statusCode == 200 && mounted) {
        setState(() => _profil = Map<String, dynamic>.from(jsonDecode(res.body)));
      }
    } catch (_) {
      // Ignorer l'erreur
    } finally {
      if (mounted) setState(() => _loadingProfil = false);
    }
  }

  Future<void> _chargerCours() async {
    if (mounted) {
      setState(() {
        _loadingCours = true;
        _errorCours = '';
      });
    }
    try {
      final headers = await _headers();
      final res = await http.get(Uri.parse(ApiConstants.cursus), headers: headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final mapped = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (mounted) {
          setState(() {
            _cours = mapped;
            _coursFiltres = mapped;
          });
          _animCtrl.forward(from: 0);
        }
      } else {
        if (mounted) setState(() => _errorCours = 'Incapable de récupérer vos programmes (${res.statusCode})');
      }
    } catch (_) {
      if (mounted) setState(() => _errorCours = 'Vérifiez votre connexion internet');
    } finally {
      if (mounted) setState(() => _loadingCours = false);
    }
  }

  Future<void> _chargerRecent() async {
    if (mounted) setState(() => _loadingRecent = true);
    try {
      final headers = await _headers();
      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/apprenant/lectures-recentes/?limit=5'),
        headers: headers,
      );
      if (res.statusCode == 200 && mounted) {
        final List data = jsonDecode(res.body);
        setState(() {
          _recent = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {
      // Ignorer l'erreur
    } finally {
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  void _filtrer(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _coursFiltres = _cours;
      } else {
        final query = q.toLowerCase();
        _coursFiltres = _cours.where((c) {
          return (c['title']?.toString().toLowerCase().contains(query) ?? false) ||
                 (c['enseignant_principal']?.toString().toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: YekiColors.white,
        title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Quitter votre espace de formation Yéki pour le moment ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: YekiColors.textMedium)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: YekiColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final headers = await _headers();
        await http.post(Uri.parse(ApiConstants.logout), headers: headers);
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  String get _nomApprenant => _profil['first_name']?.toString() ?? _profil['username']?.toString() ?? 'Étudiant';
  String? get _avatarUrl => _profil['avatar']?.toString();

  Color _parseColor(String? hex) {
    if (hex == null) return YekiColors.primaryLight;
    try {
      return Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16));
    } catch (_) {
      return YekiColors.primaryLight;
    }
  }

  IconData _getIconForSubject(String title) {
    final t = title.toLowerCase();
    if (t.contains('physique') || t.contains('onde') || t.contains('biomasse') || t.contains('chimie')) {
      return Icons.science_rounded;
    }
    if (t.contains('crypto') || t.contains('code') || t.contains('flutter') || t.contains('dev')) {
      return Icons.terminal_rounded;
    }
    if (t.contains('mine') || t.contains('geolo') || t.contains('leapfrog') || t.contains('or')) {
      return Icons.landscape_rounded;
    }
    if (t.contains('math') || t.contains('algebre') || t.contains('calcul')) {
      return Icons.functions_rounded;
    }
    if (t.contains('loi') || t.contains('droit') || t.contains('juridique')) {
      return Icons.gavel_rounded;
    }
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double paddingHorizontal = screenWidth > 800 ? (screenWidth - 760) / 2 : 18.0;

    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      appBar: YekiHeader(
        unreadNotifications: 2,
        isSubscribed: _isSubscribed,
        userRole: 'Apprenant',
        username: _loadingProfil ? 'Chargement...' : _nomApprenant,
        avatarUrl: _avatarUrl,
        onNotifications: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
        onSettings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilPage())),
        onLogout: _deconnecter,
      ),
      body: _loadingCours
          ? _buildResponsiveSkeleton(paddingHorizontal)
          : _errorCours.isNotEmpty
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _chargerTout,
                  color: YekiColors.primaryDark,
                  backgroundColor: YekiColors.white,
                  edgeOffset: 10,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(paddingHorizontal, 8, paddingHorizontal, 110),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _coursFiltres.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == 0) return _buildHeaderComplex();
                        return _buildModernProgramCard(_coursFiltres[i - 1]);
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderComplex() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: YekiColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: YekiColors.borderLight, width: 1.0),
            boxShadow: YekiShadows.subtle,
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filtrer,
            style: YekiTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Rechercher un cours, un enseignant...',
              hintStyle: YekiTextStyles.bodySmall,
              prefixIcon: Icon(Icons.search_rounded, color: YekiColors.primaryLight, size: 22),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildResumeSection(),
        const SizedBox(height: 32),
        Row(
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: [
            const Text(
              'Vos Programmes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3),
            ),
            const Spacer(),
            if (_cours.isNotEmpty)
              Text(
                '${_coursFiltres.length} cours disponibles',
                style: TextStyle(color: YekiColors.primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildResumeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Continuer la lecture',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.1),
        ),
        const SizedBox(height: 12),
        _loadingRecent
            ? _skeletonWidget(h: 90, r: 24)
            : _recent.isEmpty
                ? _buildEmptyMotivationBox()
                : SizedBox(
                    height: 105,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _recent.length,
                      itemBuilder: (_, idx) {
                        final item = _recent[idx];
                        final accentColor = _parseColor(item['cours_color'] as String?);
                        final pct = (item['pourcentage'] as num? ?? 0).toInt();

                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 12, bottom: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.015),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: YekiColors.borderLight, width: 1.0),
                            boxShadow: YekiShadows.subtle,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                if (item['cours_id'] != null) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => CoursDetailTabs(
                                    coursId: item['cours_id'].toString(),
                                    titre: item['cours_titre']?.toString() ?? '',
                                    coursColor: accentColor.value,
                                    isPremium: true,
                                  )));
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: accentColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item['cours_titre']?.toString().toUpperCase() ?? '',
                                            style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item['lecon_titre']?.toString() ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: LinearProgressIndicator(
                                                    value: pct / 100,
                                                    backgroundColor: YekiColors.white,
                                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                                    minHeight: 3.5,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text('$pct%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            ],
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildEmptyMotivationBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: YekiColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: YekiColors.borderLight, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: YekiColors.backgroundAlt, shape: BoxShape.circle),
            child: const Text('🎓', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prêt à entamer un chapitre ?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text('Choisissez une filière d\'enseignement ci-dessous.', style: const TextStyle(fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildModernProgramCard(Map<String, dynamic> cours) {
    final themeColor = _parseColor(cours['color'] as String?);
    final titre = cours['title']?.toString() ?? '';
    final desc = cours['description']?.toString() ?? '';
    final mentor = cours['enseignant_principal']?.toString() ?? 'Yéki Expert';
    final totalLessons = (cours['lessons'] as num? ?? 0).toInt();
    final progress = (cours['progression'] as num? ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _lerpColor(YekiColors.white, themeColor, 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lerpColor(YekiColors.borderLight, themeColor, 0.08), width: 1.1),
        boxShadow: YekiShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CoursDetailTabs(
            coursId: cours['id'].toString(),
            titre: titre,
            coursColor: themeColor.value,
            isPremium: true,
          ))),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalLessons modules académiques',
                              style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            titre,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.25, letterSpacing: -0.2),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: themeColor.withValues(alpha: 0.12), width: 1),
                      ),
                      child: Icon(
                        _getIconForSubject(titre),
                        color: themeColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                ],
                const SizedBox(height: 16),
                Container(height: 1, color: _lerpColor(YekiColors.white, themeColor, 0.1)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: themeColor.withValues(alpha: 0.12),
                            child: Icon(Icons.person_rounded, size: 12, color: themeColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mentor,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildDynamicBadge(progress),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Text(
                          '${progress.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            value: progress / 100,
                            strokeWidth: 2.2,
                            backgroundColor: YekiColors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(progress > 0 ? YekiColors.primaryDark : YekiColors.textLight),
                          ),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _lerpColor(Color a, Color b, double t) {
    return Color.lerp(a, b, t)!;
  }

  Widget _buildDynamicBadge(double progress) {
    String txt = 'NOUVEAU';
    Color c = YekiColors.primaryDark;
    if (progress >= 100) {
      txt = 'TERMINÉ';
      c = YekiColors.success;
    } else if (progress > 0) {
      txt = 'EN COURS';
      c = YekiColors.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Text(
        txt,
        style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.3),
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
            Text(_errorCours, style: YekiTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            YekiButton(
              label: 'Actualiser la page',
              icon: Icons.refresh_rounded,
              onPressed: _chargerTout,
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveSkeleton(double padding) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      children: [
        _skeletonWidget(h: 50, r: 28),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _skeletonWidget(h: 36, r: 18)),
            const SizedBox(width: 10),
            Expanded(child: _skeletonWidget(h: 36, r: 18)),
            const SizedBox(width: 10),
            Expanded(child: _skeletonWidget(h: 36, r: 18)),
          ],
        ),
        const SizedBox(height: 32),
        _skeletonWidget(h: 18, w: 140),
        const SizedBox(height: 12),
        _skeletonWidget(h: 90, r: 24),
        const SizedBox(height: 32),
        _skeletonWidget(h: 22, w: 180),
        const SizedBox(height: 14),
        _skeletonWidget(h: 160, r: 24),
        const SizedBox(height: 14),
        _skeletonWidget(h: 160, r: 24),
      ],
    );
  }

  Widget _skeletonWidget({double h = 20, double? w, double r = 12}) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: YekiColors.borderLight,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}