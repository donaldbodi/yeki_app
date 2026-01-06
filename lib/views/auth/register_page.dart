import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ---------------- CONTROLLERS ----------------
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ---------------- STATES ----------------
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? selectedUserType;
  String? selectedCursus;
  String? selectedSubCursus;
  String? selectedNiveau;
  String? selectedFiliere;
  String? selectedLicence;
  bool loadingDepartements = false;
  int? selectedParcoursId;
  int? selectedDepartementId;


  // ---------------- STATIC OPTIONS ----------------
  final userTypes = ["Apprenant", "Enseignant"];
  List<Map<String, dynamic>> departementOptions = [];
  List<Map<String, dynamic>> _parcoursRaw = [];
  List<String> niveauOptions = [];
  bool loadingNiveaux = false;

  // ---------------- DYNAMIC CURSUS ----------------
  List<String> cursusOptions = [];
  bool loadingCursus = false;

  @override
  void initState() {
    super.initState();
    _fetchCursus();
  }

  // ---------------- API : FETCH CURSUS ----------------
  Future<void> _fetchCursus() async {
  setState(() => loadingCursus = true);
  try {
    final dio = Dio();
    final response =
        await dio.get('https://yekiapp.pythonanywhere.com/api/parcours/');

    if (response.statusCode == 200) {
      final List data = response.data;

      final filtered = data.where((e) {
        final nom = e['nom'].toString().toLowerCase();
        return !nom.contains('Prépas') && !nom.contains('Formation');
      }).map<Map<String, dynamic>>((e) {
        return {
          "id": e['id'],
          "nom": e['nom'],
        };
      }).toList();

      setState(() {
        cursusOptions = filtered.map((e) => e['nom'] as String).toList();
        _parcoursRaw = filtered;
      });
    }
  } catch (e) {
    debugPrint("Erreur chargement cursus : $e");
  } finally {
    setState(() => loadingCursus = false);
  }
}

Future<void> _fetchDepartements(int parcoursId) async {
  setState(() {
    loadingDepartements = true;
    departementOptions = [];
    selectedDepartementId = null;
  });

  try {
    final dio = Dio();
    final response = await dio.get(
      'https://yekiapp.pythonanywhere.com/api/parcours/$parcoursId/departements/',
    );

    if (response.statusCode == 200) {
      final List data = response.data;
      setState(() {
        departementOptions = data
            .map<Map<String, dynamic>>((e) => {
                  "id": e['id'],
                  "nom": e['nom'],
                })
            .toList();
      });
    }
  } catch (e) {
    debugPrint("Erreur chargement départements : $e");
  } finally {
    setState(() => loadingDepartements = false);
  }
}

Future<void> _fetchNiveaux(int departementId) async {
  setState(() {
    loadingNiveaux = true;
    niveauOptions = [];
    selectedNiveau = null;
  });

  try {
    final dio = Dio();
    final response = await dio.get(
      'https://yekiapp.pythonanywhere.com/api/departements/$departementId/niveaux/',
    );

    if (response.statusCode == 200) {
      setState(() {
        niveauOptions = List<String>.from(response.data);
      });
    }
  } catch (e) {
    debugPrint("Erreur chargement niveaux : $e");
  } finally {
    setState(() => loadingNiveaux = false);
  }
}


  // ---------------- SUBMIT ----------------
  void _submitRegistration() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Les mots de passe ne correspondent pas")),
      );
      return;
    }

    final body = {
      "username": _usernameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "name": _nameController.text.trim(),
      "user_type": selectedUserType?.toLowerCase(),
      "cursus": selectedCursus,
      "sub_cursus": selectedSubCursus,
      "niveau": selectedNiveau,
      "filiere": selectedFiliere,
      "licence": selectedLicence,
    };

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://yekiapp.pythonanywhere.com/api/auth/register/',
        data: body,
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Compte créé avec succès")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Erreur : $e")),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF008080), Color(0xFF00E6E6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
          child: Column(
            children: [
              const Image(
                image: AssetImage("assets/images/yeki_logo.png"),
                width: 70,
              ),
              const SizedBox(height: 20),
              const Text(
                "Création d'un nouveau compte",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // -------- FORM CARD --------
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _input("Nom complet", Icons.person, _nameController),
                    _input("Email", Icons.email, _emailController),
                    _input(
                        "Nom d'utilisateur", Icons.account_circle, _usernameController),

                    // -------- TYPE USER --------
                    DropdownButtonFormField<String>(
                      decoration: _dropdownStyle("Type d'utilisateur"),
                      value: selectedUserType,
                      items:
                          userTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() {
                        selectedUserType = v;
                        selectedCursus = null;
                      }),
                    ),

                    const SizedBox(height: 12),

                    // -------- CURSUS --------
                    if (selectedUserType == "Apprenant")
                      loadingCursus
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                            )
                          : DropdownButtonFormField<String>(
                            decoration: _dropdownStyle("Parcours"),
                            value: selectedCursus,
                            items: cursusOptions
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) {
                              final selected = _parcoursRaw.firstWhere((p) => p['nom'] == v);
                              setState(() {
                                selectedCursus = v;
                                selectedParcoursId = selected['id'];
                                selectedDepartementId = null;
                              });
                              _fetchDepartements(selectedParcoursId!);
                            },
                          ),

                    const SizedBox(height: 12),

                    if (selectedUserType == "Apprenant" && selectedParcoursId != null)
                loadingDepartements
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      )
                    : DropdownButtonFormField<int>(
                        decoration: _dropdownStyle("Département"),
                        value: selectedDepartementId,
                        items: departementOptions
                            .map(
                              (d) => DropdownMenuItem<int>(
                                value: d['id'],
                                child: Text(d['nom']),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                            setState(() {
                              selectedDepartementId = v;
                              selectedNiveau = null;
                            });
                            _fetchNiveaux(v!);
                          },
                      ),

                      const SizedBox(height: 12),

if (selectedDepartementId != null)
  loadingNiveaux
      ? const Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        )
      : DropdownButtonFormField<String>(
          decoration: _dropdownStyle("Niveau"),
          value: selectedNiveau,
          items: niveauOptions
              .map(
                (n) => DropdownMenuItem(
                  value: n,
                  child: Text(n),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => selectedNiveau = v),
        ),

                    const SizedBox(height: 12),
                    _passwordField(),
                    const SizedBox(height: 12),
                    _confirmField(),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitRegistration,
                        child: const Text("S'inscrire"),
                      ),
                    ),

                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                      child: const Text("Déjà un compte ? Connexion"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _input(String label, IconData icon, controller) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  InputDecoration _dropdownStyle(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _passwordField() => TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: "Mot de passe",
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  Widget _confirmField() => TextField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirm,
        decoration: InputDecoration(
          labelText: "Confirmation",
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
