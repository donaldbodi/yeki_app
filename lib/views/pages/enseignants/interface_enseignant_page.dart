import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/views/pages/apprenants/profil_page.dart';
import 'package:yeki/views/pages/enseignants/admin_enseignant_dashboard_page.dart';

// Screens
import 'admin_general_page.dart';
import 'enseignant_dashboard_page.dart';
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

class EnseignantHomePage extends StatefulWidget {
  const EnseignantHomePage({super.key});

  @override
  State<EnseignantHomePage> createState() => _EnseignantHomePageState();
}

class _EnseignantHomePageState extends State<EnseignantHomePage> {
  // ---------------- ✅ NOUVELLE CONFIGURATION DESIGN ----------------
  static const Color mainBlue = Color(0xFF2884A0);      // Couleur principale
  static const Color secondaryTeal = Color(0xFF008080); // Couleur secondaire astucieuse
  static const Color selectedColor = Color(0xFFffb800); // Accent (Jaune Yeki)
  static const Color backgroundColor = Color(0xFFF8FAFB);

  int _selectedIndex = 0;
  bool _isLoading = true;
  RoleEnseignant? _currentRole;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ---------------- LOGIQUE DATA & ROLE ----------------
  Future<void> _loadData() async {
    try {
      final role = await _fetchUserRole();
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
      debugPrint("Erreur Initialisation : $e");
      setState(() => _isLoading = false);
    }
  }

  Future<RoleEnseignant> _fetchUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception('Token non trouvé');

    final response = await http.get(
      Uri.parse('https://yeki.pythonanywhere.com/api/enseignant/dashboard/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      nom = data['nom'] ?? '';
      parcours = data['parcours'] ?? [];
      departements = data['departements'] ?? [];
      cours = data['cours'] ?? [];

      final roleStr = data['role'] ?? '';
      switch (roleStr) {
        case 'admin': return RoleEnseignant.administrateurGeneral;
        case 'enseignant_admin': return RoleEnseignant.enseignantAdministrateur;
        case 'enseignant_cadre': return RoleEnseignant.enseignantCadre;
        case 'enseignant_principal': return RoleEnseignant.enseignantPrincipal;
        default: return RoleEnseignant.enseignantSecondaire;
      }
    } else {
      throw Exception('Erreur serveur');
    }
  }

  String getSimpleRoleLabel(RoleEnseignant role) {
    switch (role) {
      case RoleEnseignant.administrateurGeneral: return 'Administrateur';
      case RoleEnseignant.enseignantAdministrateur: return 'Coordonnateur';
      case RoleEnseignant.enseignantCadre: return 'Cadre';
      case RoleEnseignant.enseignantPrincipal: return 'Principal';
      default: return 'Enseignant';
    }
  }

  Widget _getDashboardPage(RoleEnseignant role) {
    switch (role) {
      case RoleEnseignant.administrateurGeneral:
        return const AdminGeneralPage();
      case RoleEnseignant.enseignantAdministrateur:
        return AdminEnseignantDashboardPage();
      default:
        return DashboardEnseignantPage(
          role: role,
          roleEnseignant: getSimpleRoleLabel(role),
          nomEnseignant: nom,
          extraInfo: (role == RoleEnseignant.enseignantCadre) ? departements : cours,
        );
    }
  }

  // ---------------- UI COMPONENTS ----------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: mainBlue)),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Header dégradé persistant Bleu -> Teal
          Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [mainBlue, secondaryTeal], // ✅ Dégradé harmonisé
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bonjour, $nom",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  getSimpleRoleLabel(_currentRole!),
                  style: const TextStyle(color: selectedColor, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.notifications_active_outlined, color: Colors.white, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      height: 72,
      decoration: BoxDecoration(
        color: mainBlue, // ✅ Fond de la barre en bleu principal
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: mainBlue.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: selectedColor, // Le jaune ressort parfaitement sur le bleu
          unselectedItemColor: Colors.white.withOpacity(0.5),
          currentIndex: _selectedIndex,
          showUnselectedLabels: false,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            _navItem(Icons.grid_view_rounded, 'Accueil', 0),
            _navItem(Icons.menu_book_rounded, 'Cours', 1),
            _navItem(Icons.history_toggle_off_rounded, 'Logs', 2),
            _navItem(Icons.person_pin_rounded, 'Moi', 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedScale(
        scale: isActive ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}