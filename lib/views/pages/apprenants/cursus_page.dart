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
// CURSUS PAGE — Design harmonisé avec RegisterPage
// Palette : fond blanc, cartes dégradé brandBackground (#135F74)
// ─────────────────────────────────────────────────────────────────

const String _base = 'https://yeki.pythonanywhere.com/api';

// Palette harmonisée
const Color brandBackground = Color(0xFF135F74);
const Color actionOrange = Color(0xFFFF6B00);
const Color glassFill = Color(0x1AFFFFFF);

// Couleurs pour le mode light
const Color _white = Color(0xFFFFFFFF);
const Color _white80 = Color(0xCCFFFFFF);
const Color _white60 = Color(0x99FFFFFF);
const Color _white20 = Color(0x33FFFFFF);
const Color _textDark = Color(0xFF1A1C1E);
const Color _textMedium = Color(0xFF5A5C5E);
const Color _textLight = Color(0xFF8A8C8E);
const Color _borderLight = Color(0xFFE8ECEF);
const Color _bgLight = Color(0xFFF8FAFC);

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

  // ── Abonnement ───────────────────────────────────────────────────
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _white,
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.bold, color: _textDark)),
        content: const Text(
          'Souhaitez-vous vraiment quitter l\'application ?',
          style: TextStyle(color: _textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: _textMedium)),
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
    if (hex == null) return brandBackground;
    try {
      return Color(int.parse(hex.replaceAll('#', 'FF'), radix: 16));
    } catch (_) {
      return brandBackground;
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

  // ════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
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
                  color: brandBackground,
                  backgroundColor: _white,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: _coursFiltres.length + 2,
                      itemBuilder: (ctx, i) {
                        if (i == 0) return _buildTopSection();
                        if (i == _coursFiltres.length + 1)
                          return const SizedBox(height: 80);
                        return _buildCoursCard(_coursFiltres[i - 1], i - 1);
                      },
                    ),
                  ),
                ),
    );
  }

  // ── Section supérieure ───────────────────────────────────────────
  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildHeader(),
        const SizedBox(height: 24),
        _buildSearchBar(),
        const SizedBox(height: 32),
        _buildContinuerLecture(),
        const SizedBox(height: 32),
        _buildListeTitle(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _loadingProfil
                    ? 'Bonjour 👋'
                    : 'Bonjour $_nomApprenant',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prêt à apprendre quelque chose aujourd\'hui ?',
                style: TextStyle(
                  color: _textMedium,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /*Widget _avatarFallback() {
    final initial = _nomApprenant.isNotEmpty
        ? _nomApprenant[0].toUpperCase()
        : 'A';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: brandBackground,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }*/

  // ── Barre de recherche ───────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _filtrer,
        style: const TextStyle(color: _textDark, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Rechercher un cours, un professeur...',
          hintStyle: TextStyle(color: _textLight, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: _textMedium),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  color: _textLight,
                  onPressed: () {
                    _searchCtrl.clear();
                    _filtrer('');
                  },
                )
              : Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: brandBackground.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded,
                      color: brandBackground, size: 18),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 16),
        _loadingRecent
            ? _buildRecentSkeleton()
            : _recent.isEmpty
                ? _buildMotivation()
                : SizedBox(
                    height: 170,
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
    final coursId = item['cours_id'];

    return GestureDetector(
      onTap: () {
        if (coursId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CoursDetailTabs(
                coursId: coursId.toString(),
                titre: item['cours_titre']?.toString() ?? '',
                coursColor: color.value,
                isPremium: true,
              ),
            ),
          );
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brandBackground, brandBackground.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: brandBackground.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bande supérieure avec icône
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _white20,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: _white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['cours_titre']?.toString() ?? '',
                      style: const TextStyle(
                        color: _white80,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Titre leçon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                item['lecon_titre']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
            const Spacer(),
            // Barre de progression
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: _white20,
                            valueColor: const AlwaysStoppedAnimation<Color>(_white),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          color: _white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12, color: _white60),
                      const SizedBox(width: 4),
                      Text(
                        module.isNotEmpty ? '$module · $mins min' : '$mins min restantes',
                        style: TextStyle(
                          color: _white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── État motivationnel ───────────────────────────────────────────
  Widget _buildMotivation() {
    return GestureDetector(
      onTap: () {
        // Scroll vers la liste des cours
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brandBackground, brandBackground.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: brandBackground.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _white20,
                shape: BoxShape.circle,
              ),
              child: const Text('🚀', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Le savoir n\'attend pas !',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tu n\'as rien lu récemment. Lance-toi !',
                    style: TextStyle(
                      fontSize: 13,
                      color: _white80,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Choisir un cours',
                        style: TextStyle(
                          color: actionOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: actionOrange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
            color: _textDark,
          ),
        ),
        const Spacer(),
        if (_cours.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: brandBackground.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_cours.length} cours',
              style: TextStyle(
                color: brandBackground,
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CoursDetailTabs(
                coursId: cours['id'].toString(),
                titre: titre,
                coursColor: color.value, // Transmettre la couleur
                isPremium: true,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
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
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 12, color: _textLight),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ep,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textMedium,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildBadge(progression, color),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textMedium,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    _metaChip(
                      icon: Icons.play_lesson_outlined,
                      label: '$nbLecons leçon${nbLecons > 1 ? 's' : ''}',
                      color: color,
                    ),
                    const SizedBox(width: 12),
                    if (nbDevoirs > 0)
                      _metaChip(
                        icon: Icons.assignment_outlined,
                        label: '$nbDevoirs devoir${nbDevoirs > 1 ? 's' : ''}',
                        color: actionOrange,
                      ),
                    const Spacer(),
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
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progression / 100,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
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
      label = 'TERMINÉ';
      bg = Colors.green.withOpacity(0.1);
      fg = Colors.green;
    } else {
      label = 'EN COURS';
      bg = actionOrange.withOpacity(0.1);
      fg = actionOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textMedium,
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
                size: 64, color: _textLight),
            const SizedBox(height: 20),
            Text(
              _errorCours,
              style: TextStyle(color: _textMedium, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBackground,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _chargerTout,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeletons ────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const SizedBox(height: 60),
        _skeletonBox(h: 48, radius: 16),
        const SizedBox(height: 24),
        _skeletonBox(h: 18, w: 160),
        const SizedBox(height: 16),
        SizedBox(
          height: 170,
          child: Row(
            children: [
              _skeletonBox(h: 170, w: 280, radius: 20),
              const SizedBox(width: 16),
              _skeletonBox(h: 170, w: 280, radius: 20),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _skeletonBox(h: 20, w: 150),
        const SizedBox(height: 16),
        ...List.generate(3, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _skeletonBox(h: 140, radius: 20),
        )),
      ],
    );
  }

  Widget _buildRecentSkeleton() => SizedBox(
        height: 170,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _skeletonBox(h: 170, w: 280, radius: 20),
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
          color: _borderLight,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  // ── Utilitaire couleur ───────────────────────────────────────────
  /*Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }*/
}