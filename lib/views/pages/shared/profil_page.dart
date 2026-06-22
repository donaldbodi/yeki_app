// lib/views/pages/shared/profil_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// PAGE PROFIL — AVEC VILLE ET WHATSAPP POUR ENSEIGNANT
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/edit_profil_page.dart';
import 'package:yeki/views/pages/apprenants/settings_page.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _profil = {};
  Map<String, dynamic> _stats = {};
  String _userType = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _charger();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final headers = await _headers();
      final [resProfil, resStats] = await Future.wait([
        http.get(Uri.parse(ApiConstants.profilMe), headers: headers),
        http.get(Uri.parse(ApiConstants.profilStats), headers: headers),
      ]);

      if (!mounted) return;

      if (resProfil.statusCode == 200) {
        final data = jsonDecode(resProfil.body) as Map<String, dynamic>;
        setState(() {
          _profil = data;
          _userType = data['user_type']?.toString() ?? '';
        });
      }

      if (resStats.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(resStats.body) as Map<String, dynamic>;
        });
      }

      _animCtrl.forward();
    } catch (_) {
      // Gestion silencieuse des erreurs
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isEnseignant =>
      _userType.contains('enseignant') || _userType == 'admin';

  String get _nomComplet {
    final fn = _profil['first_name']?.toString() ?? '';
    final ln = _profil['last_name']?.toString() ?? '';
    if (fn.isNotEmpty || ln.isNotEmpty) return '$fn $ln'.trim();
    return _profil['username']?.toString() ?? 'Utilisateur';
  }

  String get _roleLabel {
    switch (_userType) {
      case 'apprenant':
        return 'Apprenant';
      case 'enseignant':
        return 'Enseignant';
      case 'enseignant_principal':
        return 'Enseignant Principal';
      case 'enseignant_cadre':
        return 'Enseignant Cadre';
      case 'enseignant_admin':
        return 'Coordonnateur';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Utilisateur';
    }
  }

  Color get _roleColor {
    switch (_userType) {
      case 'apprenant':
        return YekiColors.primaryDark;
      case 'enseignant':
        return YekiColors.primaryLight;
      case 'enseignant_principal':
        return YekiColors.purple;
      case 'enseignant_cadre':
        return YekiColors.accent;
      case 'enseignant_admin':
        return YekiColors.success;
      case 'admin':
        return YekiColors.error;
      default:
        return YekiColors.textLight;
    }
  }

  String get _initials {
    final parts = _nomComplet.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YekiColors.backgroundLight,
      body: _loading
          ? _buildSkeleton()
          : FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(child: _buildBody()),
                ],
              ),
            ),
    );
  }

  // ─── APP BAR ────────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    final avatarUrl = _profil['avatar']?.toString();

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: _isEnseignant ? YekiColors.primaryLight : YekiColors.primaryDark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: YekiColors.white),
          onPressed: _charger,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isEnseignant
                      ? [const Color(0xFF1A3A4A), YekiColors.primaryLight]
                      : [const Color(0xFF1565A0), YekiColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: YekiColors.white, width: 3),
                        boxShadow: YekiShadows.floating,
                      ),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _avatarFallback(),
                              )
                            : _avatarFallback(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nomComplet,
                      style: const TextStyle(
                        color: YekiColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if ((_profil['email']?.toString() ?? '').isNotEmpty)
                      Text(
                        _profil['email'].toString(),
                        style: const TextStyle(color: YekiColors.white, fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    _roleBadge(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: _roleColor.withValues(alpha: 0.2),
        child: Center(
          child: Text(
            _initials,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: YekiColors.white,
            ),
          ),
        ),
      );

  Widget _roleBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: YekiColors.white.withValues(alpha: 0.15),
          borderRadius: YekiRadius.borderRadiusPill,
          border: Border.all(color: YekiColors.white),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isEnseignant ? Icons.verified_rounded : Icons.school_rounded,
              color: YekiColors.white,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              _roleLabel,
              style: const TextStyle(
                color: YekiColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

  // ─── BODY ──────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 24),
          _buildInfosPerso(),
          const SizedBox(height: 16),
          if (_isEnseignant)
            _buildSectionEnseignant()
          else
            _buildSectionApprenant(),
          const SizedBox(height: 16),
          if ((_profil['bio']?.toString() ?? '').isNotEmpty) _buildBio(),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  // ─── STATISTIQUES ──────────────────────────────────────────────────────
  Widget _buildStats() {
    List<_StatItem> items;
    if (_isEnseignant) {
      items = [
        _StatItem(
          'Cours',
          '${_stats['nb_cours'] ?? 0}',
          Icons.book_rounded,
          YekiColors.primaryDark,
        ),
        _StatItem(
          'Leçons',
          '${_stats['nb_lecons'] ?? 0}',
          Icons.article_rounded,
          YekiColors.primaryLight,
        ),
        if (_userType == 'enseignant_cadre')
          _StatItem(
            'Dépts',
            '${_stats['nb_departements'] ?? 0}',
            Icons.domain_rounded,
            YekiColors.accent,
          ),
        _StatItem(
          'Devoirs',
          '${_stats['nb_devoirs'] ?? 0}',
          Icons.assignment_rounded,
          YekiColors.purple,
        ),
      ];
    } else {
      items = [
        _StatItem(
          'Cours',
          '${_stats['nb_cours'] ?? 0}',
          Icons.school_rounded,
          YekiColors.primaryDark,
        ),
        _StatItem(
          'Devoirs',
          '${_stats['nb_devoirs'] ?? 0}',
          Icons.assignment_rounded,
          YekiColors.purple,
        ),
        _StatItem(
          'Moyenne',
          '${(_stats['moyenne'] as num? ?? 0).toStringAsFixed(1)}/20',
          Icons.stars_rounded,
          YekiColors.accent,
        ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: YekiColors.white,
          borderRadius: YekiRadius.borderRadiusXl,
          boxShadow: YekiShadows.medium,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((s) => _buildStatCell(s)).toList(),
        ),
      ),
    );
  }

  Widget _buildStatCell(_StatItem item) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: YekiRadius.borderRadiusMd,
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: item.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(item.label, style: const TextStyle(fontSize: 11)),
        ],
      );

  // ─── INFORMATIONS PERSONNELLES ────────────────────────────────────────
  Widget _buildInfosPerso() {
    final rows = <_InfoRow>[];

    if ((_profil['phone']?.toString() ?? '').isNotEmpty) {
      rows.add(_InfoRow(Icons.phone_rounded, 'Téléphone', _profil['phone'].toString()));
    }
    if ((_profil['email']?.toString() ?? '').isNotEmpty) {
      rows.add(_InfoRow(Icons.email_rounded, 'Email', _profil['email'].toString()));
    }

    // Ville – pour tous les utilisateurs
    if ((_profil['ville']?.toString() ?? '').isNotEmpty) {
      rows.add(_InfoRow(Icons.location_on_rounded, 'Ville', _profil['ville'].toString()));
    }

    // WhatsApp – uniquement pour les enseignants
    if (_isEnseignant && (_profil['whatsapp']?.toString() ?? '').isNotEmpty) {
      rows.add(_InfoRow(Icons.chat_bubble_rounded, 'WhatsApp', _profil['whatsapp'].toString()));
    }

    if (!_isEnseignant) {
      if ((_profil['cursus']?.toString() ?? '').isNotEmpty) {
        rows.add(_InfoRow(Icons.route_rounded, 'Cursus', _profil['cursus'].toString()));
      }
      if ((_profil['niveau']?.toString() ?? '').isNotEmpty) {
        rows.add(_InfoRow(Icons.grade_rounded, 'Niveau', _profil['niveau'].toString()));
      }
      if ((_profil['filiere']?.toString() ?? '').isNotEmpty) {
        rows.add(_InfoRow(Icons.bookmark_rounded, 'Filière', _profil['filiere'].toString()));
      }
    }
    if ((_profil['username']?.toString() ?? '').isNotEmpty) {
      rows.add(_InfoRow(Icons.alternate_email_rounded, 'Nom d\'utilisateur', _profil['username'].toString()));
    }

    if (rows.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Informations', Icons.person_rounded),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: YekiColors.white,
              borderRadius: YekiRadius.borderRadiusLg,
              boxShadow: YekiShadows.subtle,
            ),
            child: Column(
              children: rows.asMap().entries.map((entry) {
                final isLast = entry.key == rows.length - 1;
                return _buildInfoTile(entry.value, showBorder: !isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(_InfoRow row, {bool showBorder = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: YekiColors.borderLight, width: 1))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: YekiColors.primaryDark.withValues(alpha: 0.08),
              borderRadius: YekiRadius.borderRadiusSm,
            ),
            child: Icon(row.icon, size: 15, color: YekiColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  row.value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTIONS SPÉCIFIQUES ──────────────────────────────────────────────
  Widget _buildSectionEnseignant() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Activité', Icons.analytics_rounded),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  'Enseignant\n$_roleLabel',
                  Icons.verified_rounded,
                  YekiColors.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniCard(
                  '${_stats['nb_cours'] ?? 0} cours\nactifs',
                  Icons.book_rounded,
                  YekiColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionApprenant() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Parcours', Icons.school_rounded),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMiniCard(
                  _profil['cursus']?.toString() ?? 'Non défini',
                  Icons.route_rounded,
                  YekiColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniCard(
                  _profil['niveau']?.toString() ?? 'Non défini',
                  Icons.grade_rounded,
                  YekiColors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: YekiRadius.borderRadiusLg,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: YekiRadius.borderRadiusSm,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('À propos', Icons.info_outline_rounded),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: YekiColors.white,
              borderRadius: YekiRadius.borderRadiusLg,
              boxShadow: YekiShadows.subtle,
            ),
            child: Text(
              _profil['bio'].toString(),
              style: const TextStyle(fontSize: 14, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTIONS ───────────────────────────────────────────────────────────
  Widget _buildActions() {
    final color = _isEnseignant ? YekiColors.primaryLight : YekiColors.primaryDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          YekiButton(
            label: 'Modifier mon profil',
            icon: Icons.edit_rounded,
            backgroundColor: color,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfilePage(profil: _profil),
              ),
            ).then((_) => _charger()),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: YekiColors.white,
                borderRadius: YekiRadius.borderRadiusLg,
                border: Border.all(color: color.withValues(alpha: 0.25)),
                boxShadow: YekiShadows.subtle,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings_rounded, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Paramètres',
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: YekiColors.primaryDark.withValues(alpha: 0.1),
              borderRadius: YekiRadius.borderRadiusSm,
            ),
            child: Icon(icon, size: 14, color: YekiColors.primaryDark),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _buildSkeleton() => Scaffold(
        backgroundColor: YekiColors.backgroundLight,
        body: Column(
          children: [
            Container(height: 240, color: YekiColors.primaryDark.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _skBox(h: 90, r: 16),
                  const SizedBox(height: 16),
                  _skBox(h: 140, r: 18),
                  const SizedBox(height: 16),
                  _skBox(h: 100, r: 18),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _skBox({double h = 20, double? w, double r = 8}) => Container(
        height: h,
        width: w,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: YekiColors.borderLight,
          borderRadius: BorderRadius.circular(r),
        ),
      );
}

// ─── CLASSES AUXILIAIRES ──────────────────────────────────────────────────

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _InfoRow {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);
}