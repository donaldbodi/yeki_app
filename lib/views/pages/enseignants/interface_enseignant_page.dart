// lib/views/pages/enseignants/interface_enseignant_page.dart
// ═══════════════════════════════════════════════════════════════════════════
// INTERFACE ENSEIGNANT — CORRIGÉE
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/enseignants/admin_general_page.dart';
import 'package:yeki/views/pages/enseignants/cadre_dashboard_page.dart';
import 'package:yeki/views/pages/enseignants/enseignant_admin_dashboard_page.dart';
import 'package:yeki/views/pages/enseignants/principal_dashboard_page.dart';
import 'package:yeki/views/pages/enseignants/secondaire_dashboard_page.dart';
import 'package:yeki/views/pages/shared/profil_page.dart';
import 'package:yeki/views/pages/shared/notifications_page.dart';
import 'package:yeki/views/pages/enseignants/historique_page.dart';
import 'package:yeki/views/pages/enseignants/mes_cours_page.dart';
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';

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
  final int _nbNotifs = 0;
  List<dynamic> _coursList = [];

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

  Future<void> _loadData() async {
    try {
      final role = await _fetchUserRole();
      await _fetchProfil();
      
      await _loadCoursByRole(role);
      
      final dashboardPage = _getDashboardPage(role);
      
      if (mounted) {
        setState(() {
          _currentRole = role;
          _pages = [
            dashboardPage,
            MesCoursPage(role: role),
            const HistoriquePage(),
            const ProfilPage(),
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCoursByRole(RoleEnseignant role) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    String endpoint;
    switch (role) {
      case RoleEnseignant.enseignantPrincipal:
        endpoint = ApiConstants.enseignantPrincipalCours;
        break;
      case RoleEnseignant.enseignantCadre:
        endpoint = ApiConstants.enseignantCadreCours;
        break;
      case RoleEnseignant.enseignantSecondaire:
        endpoint = ApiConstants.enseignantCours;
        break;
      default:
        endpoint = ApiConstants.enseignantCours;
    }

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: ApiHeaders.auth(token),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          _coursList = data;
        } else if (data is Map && data.containsKey('cours')) {
          _coursList = data['cours'] as List? ?? [];
        } else if (data is Map && data.containsKey('results')) {
          _coursList = data['results'] as List? ?? [];
        }
        debugPrint("Cours chargés: ${_coursList.length}");
      } else {
        debugPrint("Erreur chargement cours: ${response.statusCode}");
        _coursList = [];
      }
    } catch (e) {
      debugPrint("Exception chargement cours: $e");
      _coursList = [];
    }
  }

  Future<void> _fetchProfil() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;
      
      final res = await http.get(
        Uri.parse(ApiConstants.profilMe),
        headers: ApiHeaders.auth(token),
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _profil = data);
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    }
  }

  Future<RoleEnseignant> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token non trouvé');

    final response = await http.get(
      Uri.parse(ApiConstants.enseignantDashboard),
      headers: ApiHeaders.auth(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      nom = data['nom']?.toString() ?? '';
      parcours = data['parcours'] ?? [];
      departements = data['departements'] ?? [];
      cours = data['cours'] ?? [];
      
      if (cours.isNotEmpty && _coursList.isEmpty) {
        _coursList = List.from(cours);
      }
      
      final roleStr = data['role']?.toString() ?? '';
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
      case RoleEnseignant.administrateurGeneral:   return YekiColors.error;
      case RoleEnseignant.enseignantAdministrateur:return YekiColors.success;
      case RoleEnseignant.enseignantCadre:         return YekiColors.accent;
      case RoleEnseignant.enseignantPrincipal:     return YekiColors.purple;
      default:                                     return YekiColors.primaryLight;
    }
  }

  Widget _getDashboardPage(RoleEnseignant role) {
    switch (role) {
      case RoleEnseignant.administrateurGeneral:    
        return const AdminGeneralPage();
      case RoleEnseignant.enseignantAdministrateur: 
        return const EnseignantAdminDashboardPage();
      case RoleEnseignant.enseignantCadre: 
        return const CadreDashboardPage();
      case RoleEnseignant.enseignantPrincipal:
        return DashboardPrincipalPage(
          nomEnseignant: nom.isNotEmpty ? nom : 'Enseignant',
          roleEnseignant: _getRoleLabel(role),
          extraInfo: (role == RoleEnseignant.enseignantCadre) ? departements : cours,
        );
      default: 
        return const SecondaireDashboardPage();
    }
  }

  String get _nomAffiche {
    final fn = _profil['first_name']?.toString() ?? '';
    final ln = _profil['last_name']?.toString() ?? '';
    if (fn.isNotEmpty) return fn;
    if (ln.isNotEmpty) return ln;
    if (nom.isNotEmpty) return nom.split(' ').first;
    return 'Enseignant';
  }

  String? get _avatarUrl => _profil['avatar']?.toString();

  String get _initials {
    final n = _nomAffiche;
    if (n.isEmpty) return 'E';
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: YekiColors.textDark,
        body: const Center(child: YekiLoader()),
      );
    }

    if (_pages.isEmpty || _selectedIndex >= _pages.length) {
      return Scaffold(
        backgroundColor: YekiColors.backgroundLight,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              YekiLoader(),
              SizedBox(height: 16),
              Text('Chargement...'),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBody: true,
        backgroundColor: YekiColors.backgroundLight,
        body: Stack(children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D2A3A), YekiColors.primaryDark],
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
                    child: _pages.isNotEmpty ? _pages[_selectedIndex] : const SizedBox(),
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

  Widget _buildHeader() {
    final roleColor = _currentRole != null ? _getRoleColor(_currentRole!) : YekiColors.primaryDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(children: [
        GestureDetector(
          onTap: () => setState(() => _selectedIndex = 3),
          child: Stack(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: YekiColors.white.withValues(alpha: 0.4), width: 2),
              ),
              child: ClipOval(
                child: _avatarUrl != null
                    ? Image.network(_avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _avatarFallback())
                    : _avatarFallback(),
              ),
            ),
            Positioned(right: 0, bottom: 0, child: Container(
              width: 12, height: 12,
              decoration: const BoxDecoration(
                color: YekiColors.success, shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: YekiColors.white, width: 1.5)),
              ),
            )),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bonjour, $_nomAffiche 👋', style: const TextStyle(
            color: YekiColors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.25),
              borderRadius: YekiRadius.borderRadiusPill,
              border: Border.all(color: roleColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              _currentRole != null ? _getRoleLabel(_currentRole!) : 'Enseignant',
              style: TextStyle(
                color: roleColor == YekiColors.accent ? YekiColors.accent : YekiColors.white,
                fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ])),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsPage())),
          child: Stack(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: YekiColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined, color: YekiColors.white, size: 20),
            ),
            if (_nbNotifs > 0)
              Positioned(top: 4, right: 4, child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(color: YekiColors.error, shape: BoxShape.circle),
                child: Center(child: Text('$_nbNotifs', style: const TextStyle(
                  color: YekiColors.white, fontSize: 9, fontWeight: FontWeight.bold))),
              )),
          ]),
        ),
      ]),
    );
  }

  Widget _avatarFallback() => Container(
    color: YekiColors.primaryDark.withValues(alpha: 0.3),
    child: Center(child: Text(_initials, style: const TextStyle(
      color: YekiColors.white, fontSize: 18, fontWeight: FontWeight.w800))),
  );

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
          colors: [YekiColors.textDark, Color(0xFF1A3A4A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: YekiRadius.borderRadiusXxl,
        boxShadow: [
          BoxShadow(
            color: YekiColors.textDark.withValues(alpha: 0.4),
            blurRadius: 24, offset: const Offset(0, 8)),
          BoxShadow(
            color: YekiColors.primaryDark.withValues(alpha: 0.15),
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
                color: isSelected ? YekiColors.primaryDark.withValues(alpha: 0.25) : Colors.transparent,
                borderRadius: YekiRadius.borderRadiusLg,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? item.$1 : item.$2,
                    key: ValueKey(isSelected),
                    color: isSelected ? YekiColors.accent : YekiColors.white.withValues(alpha: 0.54),
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
                            color: YekiColors.accent, fontSize: 12, fontWeight: FontWeight.w800)))
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