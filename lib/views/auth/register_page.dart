import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  // --- PALETTE PREMIUM & BOUSSOLE VISUELLE ---
  static const Color mainBlue = Color(0xFF2884A0); 
  static const Color darkBlue = Color(0xFF164A5A);
  static const Color accentWarm = Color(0xFFF39C12);

  // --- CONTROLLERS ---
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- STATES ---
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

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
    _fetchCursus();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- LOGIQUE API ---
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
    HapticFeedback.lightImpact();

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
        options: Options(validateStatus: (s) => s! < 500),
      );

      if (response.statusCode == 201) {
        _showSnackBar("Compte créé avec succès !", mainBlue);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      } else {
        _showSnackBar("Erreur lors de l'inscription", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("Problème de connexion", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [mainBlue, darkBlue],
          ),
        ),
        child: Stack(
          children: [
            // ÉLÉMENTS DÉCORATIFS
            Positioned(top: -40, right: -40, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05))),
            Positioned(bottom: 50, left: -30, child: CircleAvatar(radius: 60, backgroundColor: accentWarm.withOpacity(0.02))),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      
                      // FORMULAIRE
                      _buildSectionLabel("IDENTITÉ"),
                      _buildGlassField(controller: _nameController, label: "Nom complet", icon: Icons.person_outline),
                      const SizedBox(height: 15),
                      _buildGlassField(controller: _emailController, label: "Email académique", icon: Icons.alternate_email),
                      const SizedBox(height: 15),
                      _buildGlassField(controller: _usernameController, label: "Nom d'utilisateur", icon: Icons.badge_outlined),
                      
                      const SizedBox(height: 30),
                      _buildSectionLabel("VOTRE STATUT"),
                      _buildGlassDropdown<String>(
                        label: "Vous êtes ?",
                        value: selectedUserType,
                        items: ["Apprenant", "Enseignant"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() {
                          selectedUserType = v;
                          selectedCursus = null;
                          selectedDepartementId = null;
                        }),
                      ),

                      if (selectedUserType == "Apprenant") ...[
                        const SizedBox(height: 15),
                        loadingCursus 
                          ? const LinearProgressIndicator(color: Colors.white24, backgroundColor: Colors.transparent)
                          : _buildGlassDropdown<String>(
                              label: "Parcours",
                              value: selectedCursus,
                              items: cursusOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              onChanged: (v) {
                                final id = _parcoursRaw.firstWhere((p) => p['nom'] == v)['id'];
                                setState(() => selectedCursus = v);
                                _fetchDepartements(id);
                              },
                            ),
                        if (selectedCursus != null) ...[
                          const SizedBox(height: 15),
                          loadingDepartements
                          ? const LinearProgressIndicator(color: Colors.white24, backgroundColor: Colors.transparent)
                          : _buildGlassDropdown<int>(
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
                          const SizedBox(height: 15),
                          loadingNiveaux
                          ? const LinearProgressIndicator(color: Colors.white24, backgroundColor: Colors.transparent)
                          : _buildGlassDropdown<String>(
                              label: "Niveau d'étude",
                              value: selectedNiveau,
                              items: niveauOptions.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                              onChanged: (v) => setState(() => selectedNiveau = v),
                            ),
                        ],
                      ],

                      const SizedBox(height: 30),
                      _buildSectionLabel("SÉCURITÉ"),
                      _buildGlassField(
                        controller: _passwordController, 
                        label: "Mot de passe", 
                        icon: Icons.lock_outline, 
                        isPassword: true, 
                        obscure: _obscurePassword, 
                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword)
                      ),
                      const SizedBox(height: 15),
                      _buildGlassField(
                        controller: _confirmPasswordController, 
                        label: "Confirmation", 
                        icon: Icons.shield_outlined, 
                        isPassword: true, 
                        obscure: _obscureConfirm, 
                        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)
                      ),

                      const SizedBox(height: 45),
                      
                      _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : _buildSubmitButton(),
                      
                      const SizedBox(height: 25),
                      _buildFooterLink(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text('REJOINDRE YEKI', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 8, fontSize: 16)),
        const SizedBox(height: 6),
        Container(width: 40, height: 2, decoration: BoxDecoration(color: accentWarm, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, bottom: 10),
        child: Text(label, 
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isPassword = false, 
    bool? obscure, 
    VoidCallback? onToggle
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 300,
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && (obscure ?? true),
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
              floatingLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 16),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(obscure! ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white24, size: 16), 
                onPressed: onToggle
              ) : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20), 
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20), 
                borderSide: const BorderSide(color: Colors.white, width: 0.8)
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown<T>({
    required String label, 
    required T? value, 
    required List<DropdownMenuItem<T>> items, 
    required ValueChanged<T?> onChanged
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 300,
          padding: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: darkBlue,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              icon: const Icon(Icons.expand_more_rounded, color: Colors.white24, size: 20),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                floatingLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                prefixIcon: const Icon(Icons.account_tree_outlined, color: Colors.white24, size: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submitRegistration,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: accentWarm,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: accentWarm.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: const Center(
          child: Text('CRÉER MON COMPTE', 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          children: const [
            TextSpan(text: "Déjà membre ? "),
            TextSpan(text: "CONNEXION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}