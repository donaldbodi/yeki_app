import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/auth/login_page.dart';
import 'package:yeki/views/pages/apprenants/notifications_page.dart';
import 'package:yeki/views/pages/apprenants/profil_page.dart';
import '../../../../widgets/yeki_app_bar.dart';
import 'cours_detail_page.dart';

// ─────────────────────────────────────────────────────────────────
// CURSUS PAGE — Entièrement dynamique
//  • Profil apprenant (nom, avatar)        → GET /api/profil/me/
//  • Cours du cursus + progression         → GET /api/apprenant/cursus/
//  • Leçons récentes "Continuer la lecture"→ GET /api/apprenant/lectures-recentes/
// ─────────────────────────────────────────────────────────────────

const String _base = 'https://yeki.pythonanywhere.com/api';

// Palette
const Color _blue   = Color(0xFF2884A0);
const Color _teal   = Color(0xFF2A657D);
const Color _gold   = Color(0xFFD77B56);
const Color _bg     = Color(0xFFFBFDFF);
const Color _dark   = Color(0xFF1A1C1E);

class CursusPage extends StatefulWidget {
  const CursusPage({super.key});

  @override
  State<CursusPage> createState() => _CursusPageState();
}

class _CursusPageState extends State<CursusPage>
    with SingleTickerProviderStateMixin {

  // ── Données ──────────────────────────────────────────────────────
  Map<String, dynamic> _profil       = {};
  List<Map<String, dynamic>> _cours  = [];
  List<Map<String, dynamic>> _recent = [];

  // ── État ──────────────────────────────────────────────────────────
  bool _loadingCours   = true;
  bool _loadingRecent  = true;
  bool _loadingProfil  = true;
  String _errorCours   = '';

  // ── Recherche ────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _coursFiltres = [];

  // ── Animation ────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ── Abonnement (statique pour l'instant) ─────────────────────────
  final bool _isSubscribed = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _chargerTout();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Token ────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString('token');
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Token $t',
    };
  }

  // ── Chargement global ────────────────────────────────────────────
  Future<void> _chargerTout() async {
    await Future.wait([
      _chargerProfil(),
      _chargerCours(),
      _chargerRecent(),
    ]);
  }

  // ── Profil apprenant ─────────────────────────────────────────────
  Future<void> _chargerProfil() async {
    try {
      final headers = await _headers();
      final res = await http.get(
        Uri.parse('$_base/profil/me/'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() => _profil = Map<String, dynamic>.from(jsonDecode(res.body)));
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingProfil = false);
    }
  }

  // ── Cours du cursus ──────────────────────────────────────────────
  Future<void> _chargerCours() async {
    if (mounted) setState(() { _loadingCours = true; _errorCours = ''; });
    try {
      final headers = await _headers();
      final res = await http.get(
        Uri.parse('$_base/apprenant/cursus/'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final mapped = data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (mounted) {
          setState(() {
            _cours       = mapped;
            _coursFiltres = mapped;
          });
          _animCtrl.forward(from: 0);
        }
      } else {
        if (mounted) setState(() => _errorCours = 'Erreur ${res.statusCode}');
      }
    } catch (_) {
      if (mounted) setState(() => _errorCours = 'Erreur réseau');
    } finally {
      if (mounted) setState(() => _loadingCours = false);
    }
  }

  // ── Leçons récentes ──────────────────────────────────────────────
  Future<void> _chargerRecent() async {
    if (mounted) setState(() => _loadingRecent = true);
    try {
      final headers = await _headers();
      final res = await http.get(
        Uri.parse('$_base/apprenant/lectures-recentes/?limit=5'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _recent = data
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          });
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loadingRecent = false);
    }
  }

  // ── Filtre de recherche ──────────────────────────────────────────
  void _filtrer(String q) {
    setState(() {
      if (q.trim().isEmpty) {
        _coursFiltres = _cours;
      } else {
        final query = q.toLowerCase();
        _coursFiltres = _cours.where((c) {
          return (c['title']?.toString().toLowerCase().contains(query) ?? false) ||
              (c['enseignant_principal']?.toString().toLowerCase().contains(query) ?? false) ||
              (c['description']?.toString().toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  // ── Déconnexion ──────────────────────────────────────────────────
  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
            const Text('Souhaitez-vous vraiment quitter l\'application ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final headers = await _headers();
        await http.post(Uri.parse('$_base/auth/logout/'), headers: headers);
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

  // ── Helpers ──────────────────────────────────────────────────────
  String get _nomApprenant {
    final fn = _profil['first_name']?.toString() ?? '';
    final ln = _profil['last_name']?.toString() ?? '';
    return fn.isNotEmpty ? fn : (ln.isNotEmpty ? ln : (_profil['username']?.toString() ?? 'Apprenant'));
  }

  String? get _avatarUrl => _profil['avatar']?.toString();

  Color _parseColor(String? hex) {
    if (hex == null) return _blue;
    try {
      return Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16));
    } catch (_) {
      return _blue;
    }
  }

  IconData _parseIcon(String? name) {
    const map = {
      'school':           Icons.school,
      'book':             Icons.book,
      'science':          Icons.science,
      'calculate':        Icons.calculate,
      'history_edu':      Icons.history_edu,
      'language':         Icons.language,
      'biotech':          Icons.biotech,
      'computer':         Icons.computer,
      'architecture':     Icons.architecture,
      'psychology':       Icons.psychology,
      'palette':          Icons.palette,
      'music_note':       Icons.music_note,
      'sports_soccer':    Icons.sports_soccer,
      'medical_services': Icons.medical_services,
      'engineering':      Icons.engineering,
      'eco':              Icons.eco,
      'menu_book':        Icons.menu_book_rounded,
    };
    return map[name] ?? Icons.menu_book_rounded;
  }

  /*String _tempsDepuis(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return 'Il y a ${diff.inDays}j';
    } catch (_) {
      return '';
    }
  }*/

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: YekiHeader(
        unreadNotifications: 3,
        isSubscribed: _isSubscribed,
        userRole: 'Apprenant',
        username: _loadingProfil ? '...' : _nomApprenant,
        avatarUrl: _avatarUrl,
        onNotifications: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsPage())),
        onSettings: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ProfilPage())),
        onLogout: _deconnecter,
      ),
      body: _loadingCours
          ? _buildSkeleton()
          : _errorCours.isNotEmpty
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _chargerTout,
                  color: _blue,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: _coursFiltres.length + 2,
                      itemBuilder: (ctx, i) {
                        if (i == 0) return _buildTopSection();
                        if (i == _coursFiltres.length + 1)
                          return const SizedBox(height: 100);
                        return _buildCoursCard(_coursFiltres[i - 1], i - 1);
                      },
                    ),
                  ),
                ),
    );
  }

  // ── Section supérieure (header + recherche + récentes + titre liste) ───
  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildSearchBar(),
        const SizedBox(height: 24),
        _buildContinuerLecture(),
        const SizedBox(height: 20),
        _buildListeTitle(),
        const SizedBox(height: 10),
      ],
    );
  }

  // ── Header personnalisé ──────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _loadingProfil
                          ? 'Bonjour 👋'
                          : 'Bonjour $_nomApprenant',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    if (!_loadingProfil)
                      const Text(
                        ' 👋',
                        style: TextStyle(fontSize: 22),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Prêt à apprendre quelque chose aujourd\'hui ?',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // ── Avatar dynamique ──────────────────────────────────
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfilPage()),
      ),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _blue.withOpacity(0.3), width: 2),
          color: _blue.withOpacity(0.1),
        ),
        child: _avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  _avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarFallback(),
                ),
              )
            : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() {
    final initial = _nomApprenant.isNotEmpty
        ? _nomApprenant[0].toUpperCase()
        : 'A';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: _blue,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // ── Barre de recherche ───────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _filtrer,
        decoration: InputDecoration(
          hintText: 'Rechercher un cours, un prof...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: _blue),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: Colors.grey,
                  onPressed: () {
                    _searchCtrl.clear();
                    _filtrer('');
                  },
                )
              : Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 18),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  // ── "Continuer la lecture" ───────────────────────────────────────
  Widget _buildContinuerLecture() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Continuer la lecture',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _dark,
          ),
        ),
        const SizedBox(height: 14),
        _loadingRecent
            ? _buildRecentSkeleton()
            : _recent.isEmpty
                ? _buildMotivation()
                : SizedBox(
                    height: 162,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _recent.length,
                      itemBuilder: (_, i) => _buildRecentCard(_recent[i]),
                    ),
                  ),
      ],
    );
  }

  Widget _buildRecentCard(Map<String, dynamic> item) {
    final color  = _parseColor(item['cours_color'] as String?);
    final icon   = _parseIcon(item['cours_icon'] as String?);
    final pct    = (item['pourcentage'] as num? ?? 0).toInt();
    final mins   = item['mins_restants'] as int? ?? 5;
    final module = item['module_titre']?.toString() ?? '';
    //final leconId= item['lecon_id'];
    final coursId= item['cours_id'];

    return Container(
      width: 282,
      margin: const EdgeInsets.only(right: 16, bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, _darken(color, 0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Décor icône en filigrane ─────────────────────────
          Positioned(
            right: -12,
            bottom: -12,
            child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête ──────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item['cours_titre']?.toString() ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Titre leçon ───────────────────────────────
                Text(
                  item['lecon_titre']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                // ── Barre de progression ──────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Bas : info + bouton ──────────────────────
                Row(
                  children: [
                    Text(
                      module.isNotEmpty ? '$module · $mins min' : '$mins min restantes',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (coursId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoursDetailTabs(
                                coursId: coursId.toString(),
                                titre: item['cours_titre']?.toString() ?? '',
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Reprendre',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── État motivationnel (aucune lecture récente) ──────────────────
  Widget _buildMotivation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _teal.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _blue.withOpacity(0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Text('🚀', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Le savoir n\'attend pas !',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1e4f61),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tu n\'as rien lu récemment. Lance-toi !',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Choisir un cours',
                      style: TextStyle(
                        color: _teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: _teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Titre de la liste ────────────────────────────────────────────
  Widget _buildListeTitle() {
    return Row(
      children: [
        const Text(
          'Tes programmes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _dark,
          ),
        ),
        const Spacer(),
        if (_cours.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_cours.length} cours',
              style: const TextStyle(
                color: _blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ── Carte cours ──────────────────────────────────────────────────
  Widget _buildCoursCard(Map<String, dynamic> cours, int index) {
    final color      = _parseColor(cours['color'] as String?);
    final icon       = _parseIcon(cours['icon'] as String?);
    final titre      = cours['title']?.toString() ?? '';
    final desc       = cours['description']?.toString() ?? '';
    final ep         = cours['enseignant_principal']?.toString() ?? '—';
    final nbLecons   = (cours['lessons'] as num? ?? 0).toInt();
    final nbDevoirs  = (cours['assignments'] as num? ?? 0).toInt();
    final progression= (cours['progression'] as num? ?? 0).toDouble();

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CoursDetailTabs(
              coursId: cours['id'].toString(),
              titre: titre,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête ──────────────────────────────────────
              Row(
                children: [
                  // Icône colorée
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _dark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 12,
                                color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ep,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge état
                  _buildBadge(progression, color),
                ],
              ),

              // ── Description ──────────────────────────────────
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Méta (leçons + devoirs) ──────────────────────
              Row(
                children: [
                  _metaChip(
                    icon: Icons.play_lesson_outlined,
                    label: '$nbLecons leçon${nbLecons > 1 ? 's' : ''}',
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  if (nbDevoirs > 0)
                    _metaChip(
                      icon: Icons.assignment_outlined,
                      label: '$nbDevoirs devoir${nbDevoirs > 1 ? 's' : ''}',
                      color: _gold,
                    ),
                  const Spacer(),
                  // Pourcentage
                  Text(
                    '${progression.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Barre de progression ─────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progression / 100,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(double progression, Color color) {
    String label;
    Color bg;
    Color fg;

    if (progression == 0) {
      label = 'NOUVEAU';
      bg = color.withOpacity(0.1);
      fg = color;
    } else if (progression >= 100) {
      label = 'TERMINÉ ✓';
      bg = Colors.green.withOpacity(0.12);
      fg = Colors.green.shade700;
    } else {
      label = 'EN COURS';
      bg = _gold.withOpacity(0.15);
      fg = _gold;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );

  // ── État erreur ──────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _errorCours,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
              onPressed: _chargerTout,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Réessayer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeletons ────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        const SizedBox(height: 60),
        _skeletonBox(h: 48, radius: 20),
        const SizedBox(height: 24),
        _skeletonBox(h: 18, w: 160),
        const SizedBox(height: 14),
        SizedBox(
          height: 162,
          child: Row(
            children: [
              _skeletonBox(h: 162, w: 282, radius: 24),
              const SizedBox(width: 16),
              _skeletonBox(h: 162, w: 282, radius: 24),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: _skeletonBox(h: 160, radius: 24),
        )),
      ],
    );
  }

  Widget _buildRecentSkeleton() => SizedBox(
        height: 162,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _skeletonBox(h: 162, w: 282, radius: 24),
          ),
        ),
      );

  Widget _skeletonBox({
    double h = 20,
    double? w,
    double radius = 12,
  }) =>
      Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  // ── Utilitaire couleur ───────────────────────────────────────────
  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
