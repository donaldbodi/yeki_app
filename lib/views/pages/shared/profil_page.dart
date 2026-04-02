// lib/views/pages/shared/profil_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/edit_profil_page.dart';
import 'package:yeki/views/pages/apprenants/settings_page.dart';

const String _base = 'https://yeki.pythonanywhere.com/api';

// ── Palette ────────────────────────────────────────────────────
const Color _blue   = Color(0xFF2884A0);
const Color _teal   = Color(0xFF2A657D);
const Color _dark   = Color(0xFF0D1B2A);
const Color _mid    = Color(0xFF1E293B);
const Color _grey   = Color(0xFF64748B);
const Color _bg     = Color(0xFFF8FAFC);
const Color _gold   = Color(0xFFE2A84B);
const Color _green  = Color(0xFF10B981);
const Color _purple = Color(0xFF8B5CF6);

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic> _profil = {};
  Map<String, dynamic> _stats  = {};
  String _userType = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _charger();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<Map<String, String>> _headers() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('token');
    return {'Content-Type': 'application/json', if (t != null) 'Authorization': 'Token $t'};
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final h = await _headers();
      final [resP, resS] = await Future.wait([
        http.get(Uri.parse('$_base/profil/me/'), headers: h),
        http.get(Uri.parse('$_base/profil/stats/'), headers: h),
      ]);
      if (!mounted) return;
      if (resP.statusCode == 200) {
        final p = jsonDecode(resP.body) as Map<String, dynamic>;
        setState(() {
          _profil = p;
          _userType = p['user_type']?.toString() ?? '';
        });
      }
      if (resS.statusCode == 200) {
        setState(() => _stats = jsonDecode(resS.body) as Map<String, dynamic>);
      }
      _animCtrl.forward();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  bool get _isEnseignant => _userType.contains('enseignant') || _userType == 'admin';

  String get _nomComplet {
    final fn = _profil['first_name']?.toString() ?? '';
    final ln = _profil['last_name']?.toString() ?? '';
    if (fn.isNotEmpty || ln.isNotEmpty) return '$fn $ln'.trim();
    return _profil['username']?.toString() ?? 'Utilisateur';
  }

  String get _roleLabel {
    switch (_userType) {
      case 'apprenant':             return 'Apprenant';
      case 'enseignant':            return 'Enseignant';
      case 'enseignant_principal':  return 'Enseignant Principal';
      case 'enseignant_cadre':      return 'Enseignant Cadre';
      case 'enseignant_admin':      return 'Coordonnateur';
      case 'admin':                 return 'Administrateur';
      default:                      return 'Utilisateur';
    }
  }

  Color get _roleColor {
    switch (_userType) {
      case 'apprenant':            return _blue;
      case 'enseignant':           return _teal;
      case 'enseignant_principal': return _purple;
      case 'enseignant_cadre':     return _gold;
      case 'enseignant_admin':     return _green;
      case 'admin':                return Colors.deepOrange;
      default:                     return _grey;
    }
  }

  String get _initials {
    final parts = _nomComplet.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
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

  // ── SliverAppBar avec bannière ────────────────────────────────
  Widget _buildSliverAppBar() {
    final avatarUrl = _profil['avatar']?.toString();

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: _isEnseignant ? _teal : _blue,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _charger,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ── Fond dégradé ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isEnseignant
                      ? [const Color(0xFF1A3A4A), _teal]
                      : [const Color(0xFF1565A0), _blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // ── Cercles décoratifs ─────────────────────────────
            Positioned(top: -40, right: -40,
              child: Container(width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ))),
            Positioned(bottom: 60, left: -30,
              child: Container(width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ))),
            // ── Contenu ───────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12, offset: const Offset(0, 4),
                        )],
                      ),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? Image.network(avatarUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarFallback())
                            : _avatarFallback(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_nomComplet, style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _profil['email']?.toString().isNotEmpty == true
                          ? Text(_profil['email'].toString(),
                              style: const TextStyle(color: Colors.white70, fontSize: 12))
                          : const SizedBox(),
                    ]),
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
    color: _roleColor.withOpacity(0.2),
    child: Center(child: Text(_initials, style: TextStyle(
      fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white,
    ))),
  );

  Widget _roleBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: Colors.white30),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_isEnseignant ? Icons.verified_rounded : Icons.school_rounded,
          color: Colors.white, size: 13),
      const SizedBox(width: 5),
      Text(_roleLabel, style: const TextStyle(
        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );

  // ── Corps ─────────────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 40),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // ── Stats ────────────────────────────────────────────
          _buildStats(),
          const SizedBox(height: 24),
          // ── Infos perso ──────────────────────────────────────
          _buildInfosPerso(),
          const SizedBox(height: 16),
          // ── Section spécifique au rôle ───────────────────────
          if (_isEnseignant) _buildSectionEnseignant() else _buildSectionApprenant(),
          const SizedBox(height: 16),
          // ── Bio ──────────────────────────────────────────────
          if ((_profil['bio']?.toString() ?? '').isNotEmpty) _buildBio(),
          const SizedBox(height: 24),
          // ── Boutons d'action ─────────────────────────────────
          _buildActions(),
        ],
      ),
    );
  }

  // ── Statistiques adaptées au rôle ────────────────────────────
  Widget _buildStats() {
    List<_StatItem> items;
    if (_isEnseignant) {
      items = [
        _StatItem('Cours', '${_stats['nb_cours'] ?? 0}', Icons.book_rounded, _blue),
        _StatItem('Leçons', '${_stats['nb_lecons'] ?? 0}', Icons.article_rounded, _teal),
        if (_userType == 'enseignant_cadre')
          _StatItem('Dépts', '${_stats['nb_departements'] ?? 0}', Icons.domain_rounded, _gold),
        _StatItem('Devoirs', '${_stats['nb_devoirs'] ?? 0}', Icons.assignment_rounded, _purple),
      ];
    } else {
      items = [
        _StatItem('Cours', '${_stats['nb_cours'] ?? 0}', Icons.school_rounded, _blue),
        _StatItem('Devoirs', '${_stats['nb_devoirs'] ?? 0}', Icons.assignment_rounded, _purple),
        _StatItem('Moyenne', '${(_stats['moyenne'] as num? ?? 0).toStringAsFixed(1)}/20',
            Icons.stars_rounded, _gold),
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _blue.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((s) => _buildStatCell(s)).toList(),
        ),
      ),
    );
  }

  Widget _buildStatCell(_StatItem s) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: s.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(s.icon, color: s.color, size: 20),
      ),
      const SizedBox(height: 8),
      Text(s.value, style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w900, color: s.color)),
      const SizedBox(height: 2),
      Text(s.label, style: const TextStyle(fontSize: 11, color: _grey)),
    ],
  );

  // ── Informations personnelles ──────────────────────────────────
  Widget _buildInfosPerso() {
    final rows = <_InfoRow>[];

    if ((_profil['phone']?.toString() ?? '').isNotEmpty)
      rows.add(_InfoRow(Icons.phone_rounded, 'Téléphone', _profil['phone'].toString()));
    if ((_profil['email']?.toString() ?? '').isNotEmpty)
      rows.add(_InfoRow(Icons.email_rounded, 'Email', _profil['email'].toString()));

    if (!_isEnseignant) {
      if ((_profil['cursus']?.toString() ?? '').isNotEmpty)
        rows.add(_InfoRow(Icons.route_rounded, 'Cursus', _profil['cursus'].toString()));
      if ((_profil['niveau']?.toString() ?? '').isNotEmpty)
        rows.add(_InfoRow(Icons.grade_rounded, 'Niveau', _profil['niveau'].toString()));
      if ((_profil['filiere']?.toString() ?? '').isNotEmpty)
        rows.add(_InfoRow(Icons.bookmark_rounded, 'Filière', _profil['filiere'].toString()));
    }
    if ((_profil['username']?.toString() ?? '').isNotEmpty)
      rows.add(_InfoRow(Icons.alternate_email_rounded, 'Nom d\'utilisateur', _profil['username'].toString()));

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
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Column(
              children: rows.asMap().entries.map((e) {
                final isLast = e.key == rows.length - 1;
                return _buildInfoTile(e.value, showBorder: !isLast);
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
            ? Border(bottom: BorderSide(color: const Color(0xFFF1F5F9), width: 1))
            : null,
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(row.icon, size: 15, color: _blue),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.label, style: const TextStyle(fontSize: 11, color: _grey, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(row.value, style: const TextStyle(fontSize: 14, color: _dark, fontWeight: FontWeight.w600)),
          ],
        )),
      ]),
    );
  }

  // ── Section spécifique enseignant ──────────────────────────────
  Widget _buildSectionEnseignant() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Activité', Icons.analytics_rounded),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _buildMiniCard(
              'Enseignant\n${_roleLabel}',
              Icons.verified_rounded, _teal,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniCard(
              '${_stats['nb_cours'] ?? 0} cours\nactifs',
              Icons.book_rounded, _blue,
            )),
          ]),
        ],
      ),
    );
  }

  // ── Section spécifique apprenant ──────────────────────────────
  Widget _buildSectionApprenant() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Parcours', Icons.school_rounded),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _buildMiniCard(
              _profil['cursus']?.toString() ?? 'Non défini',
              Icons.route_rounded, _blue,
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniCard(
              _profil['niveau']?.toString() ?? 'Non défini',
              Icons.grade_rounded, _purple,
            )),
          ]),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: color, height: 1.4))),
      ]),
    );
  }

  // ── Bio ───────────────────────────────────────────────────────
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Text(
              _profil['bio'].toString(),
              style: const TextStyle(fontSize: 14, color: _mid, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Boutons d'action ──────────────────────────────────────────
  Widget _buildActions() {
    final color = _isEnseignant ? _teal : _blue;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Modifier profil
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, _darken(color, 0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => EditProfilePage(profil: _profil))).then((_) => _charger()),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Modifier mon profil', style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Paramètres
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsPage())),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.25)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.settings_rounded, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text('Paramètres', style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: _blue),
    ),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(
      fontSize: 15, fontWeight: FontWeight.w800, color: _dark)),
  ]);

  Color _darken(Color c, double amt) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amt).clamp(0.0, 1.0)).toColor();
  }

  // ── Skeleton ──────────────────────────────────────────────────
  Widget _buildSkeleton() => Scaffold(
    backgroundColor: _bg,
    body: Column(children: [
      Container(height: 240, color: _blue.withOpacity(0.3)),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          _skBox(h: 90, r: 16),
          const SizedBox(height: 16),
          _skBox(h: 140, r: 18),
          const SizedBox(height: 16),
          _skBox(h: 100, r: 18),
        ]),
      ),
    ]),
  );

  Widget _skBox({double h = 20, double? w, double r = 8}) => Container(
    height: h, width: w,
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

// ── Data classes ─────────────────────────────────────────────────
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
