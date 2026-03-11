import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ✅ Mise à jour de la Palette de couleurs
  final Color mainBlue = const Color(0xFF3271C8); // Couleur principale #1958AF
  final Color primaryTeal = const Color(0xFF1958AF); // Couleur secondaire Teal

  // ---------------- CONTROLLERS ----------------
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ---------------- STATES ----------------
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? selectedUserType;
  String? selectedCursus;
  List<String> cursusOptions = [];
  List<Map<String, dynamic>> _parcoursRaw = [];
  bool loadingCursus = false;

  List<Map<String, dynamic>> departementOptions = [];
  int? selectedDepartementId;
  bool loadingDepartements = false;

  List<String> niveauOptions = [];
  String? selectedNiveau;
  bool loadingNiveaux = false;

  @override
  void initState() {
    super.initState();
    _fetchCursus();
  }

  // ---------------- API CALLS ----------------
  Future<void> _fetchCursus() async {
    setState(() => loadingCursus = true);
    try {
      final response = await Dio().get('https://yeki.pythonanywhere.com/api/parcours/');
      if (response.statusCode == 200) {
        final List data = response.data;
        final filtered = data.where((e) {
          final nom = e['nom'].toString().toLowerCase();
          return !nom.contains('Prépas') && !nom.contains('Formation');
        }).toList();

        setState(() {
          _parcoursRaw = List<Map<String, dynamic>>.from(filtered);
          cursusOptions = _parcoursRaw.map((e) => e['nom'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur cursus: $e");
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
      final response = await Dio().get('https://yeki.pythonanywhere.com/api/parcours/$parcoursId/departements/');
      if (response.statusCode == 200) {
        setState(() => departementOptions = List<Map<String, dynamic>>.from(response.data));
      }
    } catch (e) {
      debugPrint("Erreur dep: $e");
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
      final response = await Dio().get('https://yeki.pythonanywhere.com/api/departements/$departementId/niveaux/');
      if (response.statusCode == 200) {
        setState(() => niveauOptions = List<String>.from(response.data));
      }
    } catch (e) {
      debugPrint("Erreur niveaux: $e");
    } finally {
      setState(() => loadingNiveaux = false);
    }
  }

  void _submitRegistration() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Les mots de passe ne correspondent pas", Colors.orange);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final body = {
        "username": _usernameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
        "name": _nameController.text.trim(),
        "user_type": selectedUserType?.toLowerCase(),
        "cursus": selectedCursus,
        "niveau": selectedNiveau,
      };

      final response = await Dio().post(
        'https://yeki.pythonanywhere.com/api/auth/register/',
        data: body,
      );

      if (response.statusCode == 201) {
        _showSnackBar("Compte créé ! Connectez-vous.", Colors.green);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      }
    } catch (e) {
      _showSnackBar("Erreur lors de l'inscription", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ Fond avec dégradé Bleu (#2884A0) et Teal (#008080)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [mainBlue, primaryTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Hero(
                    tag: 'logo',
                    child: Image.asset("assets/images/yeki_logo.png", width: 60, height: 60),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Rejoignez Yeki",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Créez votre profil en quelques étapes",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        _buildField(_nameController, "Nom complet", Icons.person_outline),
                        _buildField(_emailController, "Email", Icons.email_outlined),
                        _buildField(_usernameController, "Nom d'utilisateur", Icons.alternate_email),
                        
                        _buildDropdown<String>(
                          label: "Je suis un...",
                          value: selectedUserType,
                          items: ["Apprenant", "Enseignant"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() {
                            selectedUserType = v;
                            selectedCursus = null;
                            selectedDepartementId = null;
                          }),
                        ),

                        if (selectedUserType == "Apprenant") ...[
                          const SizedBox(height: 16),
                          loadingCursus 
                            ? LinearProgressIndicator(color: mainBlue)
                            : _buildDropdown<String>(
                                label: "Mon Parcours",
                                value: selectedCursus,
                                items: cursusOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (v) {
                                  final id = _parcoursRaw.firstWhere((p) => p['nom'] == v)['id'];
                                  setState(() => selectedCursus = v);
                                  _fetchDepartements(id);
                                },
                              ),
                          
                          if (selectedCursus != null) ...[
                            const SizedBox(height: 16),
                            loadingDepartements 
                              ? LinearProgressIndicator(color: mainBlue)
                              : _buildDropdown<int>(
                                  label: "Département",
                                  value: selectedDepartementId,
                                  items: departementOptions.map((d) => DropdownMenuItem(value: d['id'] as int, child: Text(d['nom']))).toList(),
                                  onChanged: (v) {
                                    setState(() => selectedDepartementId = v);
                                    _fetchNiveaux(v!);
                                  },
                                ),
                          ],

                          if (selectedDepartementId != null) ...[
                            const SizedBox(height: 16),
                            loadingNiveaux 
                              ? LinearProgressIndicator(color: mainBlue)
                              : _buildDropdown<String>(
                                  label: "Niveau",
                                  value: selectedNiveau,
                                  items: niveauOptions.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                                  onChanged: (v) => setState(() => selectedNiveau = v),
                                ),
                          ],
                        ],

                        const SizedBox(height: 16),
                        _buildField(_passwordController, "Mot de passe", Icons.lock_outline, isPassword: true, 
                          obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                        
                        _buildField(_confirmPasswordController, "Confirmer le mot de passe", Icons.lock_reset, isPassword: true, 
                          obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),

                        const SizedBox(height: 25),

                        _isLoading 
                          ? CircularProgressIndicator(color: mainBlue)
                          : _buildSubmitButton(),
                        
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Déjà inscrit ? Connectez-vous", style: TextStyle(color: mainBlue, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE COMPONENTS ---

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {bool isPassword = false, bool? obscure, VoidCallback? onToggle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        obscureText: obscure ?? false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: mainBlue, size: 22),
          suffixIcon: isPassword ? IconButton(icon: Icon(obscure! ? Icons.visibility_off : Icons.visibility, color: mainBlue), onPressed: onToggle) : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: mainBlue, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({required String label, required T? value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged}) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: mainBlue),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: mainBlue, width: 1.5)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(colors: [mainBlue, primaryTeal]), // ✅ Bouton en dégradé Bleu-Teal
        boxShadow: [BoxShadow(color: mainBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _submitRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text("CRÉER MON COMPTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}