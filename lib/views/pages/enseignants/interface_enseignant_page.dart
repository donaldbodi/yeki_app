import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'admin_enseignant_dashboard_page.dart';
import 'admin_general_page.dart';
import 'enseignant_dashboard_page.dart';
import 'historique_page.dart';
import 'mes_cours_page.dart';
import 'profil_enseignant_page.dart';

enum RoleEnseignant {
  administrateurGeneral,
  enseignantAdministrateur,
  enseignantPrincipal,
  enseignantSecondaire,
}

String parcours = '';
String nom = '';

Future<RoleEnseignant> fetchUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token'); // Récupération du token stocké

  if (token == null) {
    throw Exception('Token non trouvé');
  }

  final response = await http.get(
    Uri.parse('https://yekiapp.pythonanywhere.com/api/enseignant/dashboard/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token', // Ajout du token ici
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    final role = data['role'] ?? '';
    final parcours = data['parcours'] as List<dynamic>;
    nom = data['nom'] ?? '';

    switch (role) {
      case 'admin':
        return RoleEnseignant.administrateurGeneral;
      case 'enseignant_admin':
        return RoleEnseignant.enseignantAdministrateur;
      case 'enseignant_principal':
        return RoleEnseignant.enseignantPrincipal;
      case 'enseignant':
      default:
        return RoleEnseignant.enseignantSecondaire;
    }
  } else if (response.statusCode == 401) {
    throw Exception('Token invalide ou expiré');
  } else {
    throw Exception(
      'Erreur de chargement du rôle : ${response.statusCode} - $data',
    );
  }
}

class EnseignantHomePage extends StatefulWidget {
  const EnseignantHomePage({super.key});

  @override
  State<EnseignantHomePage> createState() => _EnseignantHomePageState();
}

class _EnseignantHomePageState extends State<EnseignantHomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<Widget> _pages = [];

  static const Color primaryColor = Color(0xFF03224c);
  static const Color selectedColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final role = await fetchUserRole();
      setState(() {
        _pages = [
          _getDashboardPage(role),
          MesCoursPage(typeEnseignant: TypeEnseignantCours.principal),
          const HistoriquePage(),
          const ProfilEnseignantPage(),
        ];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur de rôle : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement du rôle : $e')),
      );
      setState(() {
        _pages = [
          const Center(child: Text('Erreur')),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
        ];
        _isLoading = false;
      });
    }
  }

  Widget _getDashboardPage(RoleEnseignant role) {
    switch (role) {
      case RoleEnseignant.administrateurGeneral:
        return const AdminGeneralPage();
      case RoleEnseignant.enseignantAdministrateur:
        return AdminEnseignantDashboardPage(parcours: parcours[0]);
      case RoleEnseignant.enseignantPrincipal:
        return DashboardEnseignantPage(
          isPrincipal: true,
          nomEnseignant: nom,
        );
      case RoleEnseignant.enseignantSecondaire:
        return DashboardEnseignantPage(
          isPrincipal: false,
          nomEnseignant: nom,
        );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
  ) {
    return BottomNavigationBarItem(
      icon: Icon(icon, color: isActive ? selectedColor : Colors.white),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: primaryColor,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: selectedColor,
          unselectedItemColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          items: [
            _buildNavItem(
              Icons.dashboard_rounded,
              'Dashboard',
              _selectedIndex == 0,
            ),
            _buildNavItem(
              Icons.menu_book_rounded,
              'Mes cours',
              _selectedIndex == 1,
            ),
            _buildNavItem(
              Icons.history_rounded,
              'Historiques',
              _selectedIndex == 2,
            ),
            _buildNavItem(Icons.person_rounded, 'Profil', _selectedIndex == 3),
          ],
        ),
      ),
    );
  }
}
