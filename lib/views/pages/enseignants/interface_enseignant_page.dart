// lib/views/pages/enseignants/interface_enseignant_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/enseignant_admin_dashboard_page.dart';
import 'package:yeki/views/pages/shared/profil_page.dart';
import 'package:yeki/views/pages/shared/notifications_page.dart';

import 'admin_general_page.dart';
import 'historique_page.dart';
import 'mes_cours_page.dart';

enum RoleEnseignant {
  administrateurGeneral,
  enseignantAdministrateur,
  enseignantCadre,
  enseignantPrincipal,
  enseignantSecondaire,
}

List<dynamic> parcours = [];
List<dynamic> departements = [];
List<dynamic> cours = [];
String nom = '';

// ── Palette enseignants ────────────────────────────────────────
const Color _eBlue   = Color(0xFF2884A0);
const Color _eTeal   = Color(0xFF2A657D);
const Color _eGold   = Color(0xFFE2A84B);
const Color _eDark   = Color(0xFF0D1B2A);
const Color _eBg     = Color(0xFFF8FAFB);

class EnseignantHomePage extends StatefulWidget {
  const EnseignantHomePage({super.key});

  @override
  State<EnseignantHomePage> createState() => _EnseignantHomePageState();
}

class _EnseignantHomePageState extends State<EnseignantHomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isLoading = true;
  RoleEnseignant? _currentRole;
  List<Widget> _pages = [];
  Map<String, dynamic> _profil = {};
  int _nbNotifs = 0;

  late AnimationController _navAnimCtrl;

  @override
  void initState() {
    super.initState();
    _navAnimCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _loadData();
  }

  @override
  void dispose() { _navAnimCtrl.dispose(); super.dispose(); }

  // ── Chargement données ────────────────────────────────────────
  Future<void> _loadData() async {
    try {
      final role = await _fetchUserRole();
      await _fetchProfil();
      setState(() {
        _currentRole = role;
        _pages = [
          _getDashboardPage(role),
          MesCoursPage(role: role),
          const HistoriquePage(),
          const ProfilPage(),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchProfil() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final res = await http.get(
        Uri.parse('https://yeki.pythonanywhere.com/api/profil/me/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200 && mounted) {
        setState(() => _profil = jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<RoleEnseignant> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token non trouvé');

    final response = await http.get(
      Uri.parse('https://yeki.pythonanywhere.com/api/enseignant/dashboard/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      nom = data['nom'] ?? '';
      parcours    = data['parcours'] ?? [];
      departements= data['departements'] ?? [];
      cours       = data['cours'] ?? [];
      final roleStr = data['role'] ?? '';
      switch (roleStr) {
        case 'admin':               return RoleEnseignant.administrateurGeneral;
        case 'enseignant_admin':    return RoleEnseignant.enseignantAdministrateur;
        case 'enseignant_cadre':    return RoleEnseignant.enseignantCadre;
        case 'enseignant_principal':return RoleEnseignant.enseignantPrincipal;
        default:                    return RoleEnseignant.enseignantSecondaire;
      }
    } else {
      throw Exception('Erreur serveur');
    }
  }

  String _getRoleLabel(RoleEnseignant role) {
    switch (role) {
      case RoleEnseignant.administrateurGeneral:   return 'Administrateur';
      case RoleEnseignant.enseignantAdministrateur:return 'Coordonnateur';
      case RoleEnseignant.enseignantCadre:         return 'Cadre';
      case RoleEnseignant.enseignantPrincipal:     return 'Principal';
      default:                                     return 'Enseignant';
    }
  }

  Color _getRoleColor(RoleEnseignant role) {
    switch (role) {
      case RoleEnseignant.administrateurGeneral:   return Colors.deepOrange;
      case RoleEnseignant.enseignantAdministrateur:return const Color(0xFF10B981);
      case RoleEnseignant.enseignantCadre:         return _eGold;
      case RoleEnseignant.enseignantPrincipal:     return const Color(0xFF8B5CF6);
      default:                                     return _eTeal;
    }
  }

  Widget _getDashboardPage(RoleEnseignant role) {
    switch (role) {
      case RoleEnseignant.administrateurGeneral:    return const AdminGeneralPage();
      case RoleEnseignant.enseignantAdministrateur: return const EnseignantAdminDashboardPage();
      case RoleEnseignant.enseignantCadre:
        return const Center(child: Text('Dashboard Cadre'));
      case RoleEnseignant.enseignantPrincipal:
        return const Center(child: Text('Dashboard Principal'));
      default:
        return const Center(child: Text('Dashboard Enseignant'));
    }
  }

  String get _nomAffiche {
    final fn = _profil['first_name']?.toString() ?? '';
    return fn.isNotEmpty ? fn : nom.split(' ').first;
  }

  String? get _avatarUrl => _profil['avatar']?.toString();

  String get _initials {
    final n = _nomAffiche;
    if (n.isEmpty) return 'E';
    return n[0].toUpperCase();
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _eDark,
        body: const Center(child: CircularProgressIndicator(color: _eBlue)),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBody: true,
        backgroundColor: _eBg,
        body: Stack(children: [
          // ── Fond dégradé haut ──────────────────────────
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D2A3A), _eBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              _buildHeader(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.02, 0), end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: _pages[_selectedIndex],
                  ),
                ),
              ),
            ]),
          ),
        ]),
        bottomNavigationBar: _buildFloatingNav(),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    final roleColor = _currentRole != null ? _getRoleColor(_currentRole!) : _eBlue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(children: [
        // ── Avatar ───────────────────────────────────────
        GestureDetector(
          onTap: () => setState(() => _selectedIndex = 3),
          child: Stack(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
              ),
              child: ClipOval(
                child: _avatarUrl != null
                    ? Image.network(_avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback())
                    : _avatarFallback(),
              ),
            ),
            Positioned(right: 0, bottom: 0, child: Container(
              width: 12, height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981), shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
              ),
            )),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bonjour, $_nomAffiche 👋', style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: roleColor.withOpacity(0.4)),
            ),
            child: Text(
              _currentRole != null ? _getRoleLabel(_currentRole!) : 'Enseignant',
              style: TextStyle(
                color: roleColor == _eGold ? _eGold : Colors.white,
                fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ])),
        // ── Notifications ─────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsPage())),
          child: Stack(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
            ),
            if (_nbNotifs > 0)
              Positioned(top: 4, right: 4, child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: Center(child: Text('$_nbNotifs', style: const TextStyle(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              )),
          ]),
        ),
      ]),
    );
  }

  Widget _avatarFallback() => Container(
    color: _eBlue.withOpacity(0.3),
    child: Center(child: Text(_initials, style: const TextStyle(
      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
  );

  // ── Navigation flottante ──────────────────────────────────────
  Widget _buildFloatingNav() {
    final items = [
      (Icons.grid_view_rounded,      Icons.grid_view_outlined,       'Accueil'),
      (Icons.menu_book_rounded,      Icons.menu_book_outlined,       'Cours'),
      (Icons.history_rounded,        Icons.history_outlined,         'Logs'),
      (Icons.person_rounded,         Icons.person_outline_rounded,   'Profil'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      height: 68,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_eDark, Color(0xFF1A3A4A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _eDark.withOpacity(0.4),
            blurRadius: 24, offset: const Offset(0, 8)),
          BoxShadow(
            color: _eBlue.withOpacity(0.15),
            blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isSelected = _selectedIndex == i;
          return GestureDetector(
            onTap: () {
              _navAnimCtrl.forward(from: 0);
              setState(() => _selectedIndex = i);
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 18 : 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _eBlue.withOpacity(0.25) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? item.$1 : item.$2,
                    key: ValueKey(isSelected),
                    color: isSelected ? _eGold : Colors.white54,
                    size: isSelected ? 22 : 20,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: isSelected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 7),
                          child: Text(item.$3, style: const TextStyle(
                            color: _eGold, fontSize: 12, fontWeight: FontWeight.w800)))
                      : const SizedBox.shrink(),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }
}
