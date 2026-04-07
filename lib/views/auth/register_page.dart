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
  // --- PALETTE HARMONISÉE ---
  static const Color brandBackground = Color(0xFF135F74); 
  static const Color actionOrange = Color(0xFFFF6B00); 
  static const Color glassFill = Color(0x1AFFFFFF);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

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

  // ✅ États pour les erreurs de validation en temps réel
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmError;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
    _fetchCursus();
    
    // ✅ Ajout des listeners pour validation en temps réel
    _emailController.addListener(_validateEmail);
    _usernameController.addListener(_validateUsername);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
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

  // ✅ Validation email en temps réel
  void _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = "Email invalide");
    } else {
      setState(() => _emailError = null);
    }
  }

  void _validateUsername() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }
    if (username.length < 3) {
      setState(() => _usernameError = "Au moins 3 caractères");
    } else {
      setState(() => _usernameError = null);
    }
  }

  void _validatePassword() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = null);
      return;
    }
    if (password.length < 6) {
      setState(() => _passwordError = "Au moins 6 caractères");
    } else {
      setState(() => _passwordError = null);
    }
    _validateConfirmPassword();
  }

  void _validateConfirmPassword() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (confirm.isEmpty) {
      setState(() => _confirmError = null);
      return;
    }
    if (password != confirm) {
      setState(() => _confirmError = "Les mots de passe ne correspondent pas");
    } else {
      setState(() => _confirmError = null);
    }
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

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty &&
           _usernameController.text.trim().isNotEmpty &&
           _usernameError == null &&
           _emailController.text.trim().isNotEmpty &&
           _emailError == null &&
           _passwordController.text.isNotEmpty &&
           _passwordError == null &&
           _confirmError == null &&
           selectedUserType != null;
  }

  void _submitRegistration() async {
    // ✅ Validation finale avant envoi
    if (!_isFormValid()) {
      _showSnackBar("Veuillez remplir correctement tous les champs", errorRed);
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
        "cursus": selectedUserType == "Apprenant" ? selectedCursus : null,
        "niveau": selectedUserType == "Apprenant" ? selectedNiveau : null,
      };

      final response = await Dio().post(
        'https://yeki.pythonanywhere.com/api/auth/register/',
        data: body,
        options: Options(validateStatus: (s) => s! < 500),
      );

      if (response.statusCode == 201) {
        _showSnackBar("Compte créé avec succès !", successGreen);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      } else {
        final data = response.data;
        final errorMessage = data?['detail'] ?? "Erreur lors de l'inscription";
        
        // ✅ Gestion spécifique de l'erreur email existant
        if (data?['error_type'] == 'email_exists' || 
            errorMessage.contains("email") || 
            errorMessage.contains("déjà utilisée")) {
          _showSnackBar("❌ Cette adresse email est déjà utilisée. Veuillez en utiliser une autre.", errorRed);
          setState(() => _emailError = "Email déjà utilisé");
        } else {
          _showSnackBar(errorMessage, errorRed);
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        final errorMessage = data?['detail'] ?? "Email déjà utilisé ou données invalides";
        
        if (errorMessage.contains("email") || errorMessage.contains("déjà")) {
          _showSnackBar("❌ Cette adresse email est déjà utilisée.", errorRed);
          setState(() => _emailError = "Email déjà utilisé");
        } else {
          _showSnackBar(errorMessage, errorRed);
        }
      } else {
        _showSnackBar("Problème de connexion. Vérifiez votre réseau.", errorRed);
      }
    } catch (e) {
      _showSnackBar("Une erreur est survenue. Veuillez réessayer.", errorRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBackground,
      body: Stack(
        children: [
          // ÉLÉMENTS DÉCORATIFS
          Positioned(top: -40, left: -40, child: _buildCircle(180, Colors.white.withOpacity(0.03))),
          Positioned(bottom: 20, right: -30, child: _buildCircle(120, Colors.white.withOpacity(0.02))),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 40),
                      
                      // FORMULAIRE
                      _buildSectionLabel("IDENTITÉ"),
                      _buildModernField(
                        controller: _nameController, 
                        label: "Nom complet", 
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 15),
                      
                      // ✅ Email avec validation visuelle
                      _buildModernField(
                        controller: _emailController, 
                        label: "Email académique", 
                        icon: Icons.alternate_email_rounded,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 15),
                      
                      _buildModernField(
                        controller: _usernameController, 
                        label: "Nom d'utilisateur", 
                        icon: Icons.badge_outlined,
                        errorText: _usernameError,
                      ),
                      
                      const SizedBox(height: 30),
                      _buildSectionLabel("VOTRE STATUT"),
                      _buildModernDropdown<String>(
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
                          ? const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: LinearProgressIndicator(color: Colors.white24, backgroundColor: Colors.transparent))
                          : _buildModernDropdown<String>(
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
                          : _buildModernDropdown<int>(
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
                          : _buildModernDropdown<String>(
                              label: "Niveau d'étude",
                              value: selectedNiveau,
                              items: niveauOptions.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                              onChanged: (v) => setState(() => selectedNiveau = v),
                            ),
                        ],
                      ],

                      const SizedBox(height: 30),
                      _buildSectionLabel("SÉCURITÉ"),
                      _buildModernField(
                        controller: _passwordController, 
                        label: "Mot de passe", 
                        icon: Icons.lock_outline_rounded, 
                        isPassword: true, 
                        obscure: _obscurePassword, 
                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                        errorText: _passwordError,
                      ),
                      const SizedBox(height: 15),
                      _buildModernField(
                        controller: _confirmPasswordController, 
                        label: "Confirmation", 
                        icon: Icons.shield_outlined, 
                        isPassword: true, 
                        obscure: _obscureConfirm, 
                        onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        errorText: _confirmError,
                      ),

                      const SizedBox(height: 45),
                      
                      _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        : _buildSubmitButton(),
                      
                      const SizedBox(height: 30),
                      _buildFooterLink(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text('REJOINDRE YEKI', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 8, fontSize: 18)),
        const SizedBox(height: 10),
        Container(width: 40, height: 3, decoration: BoxDecoration(color: actionOrange, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 12),
        child: Text(label, 
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isPassword = false, 
    bool? obscure, 
    VoidCallback? onToggle,
    String? errorText,
  }) {
    return SizedBox(
      width: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            obscureText: isPassword && (obscure ?? true),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              floatingLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(obscure! ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white24, size: 18), 
                onPressed: onToggle
              ) : null,
              filled: true,
              fillColor: glassFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15), 
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05))
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15), 
                borderSide: const BorderSide(color: Colors.white, width: 1.5)
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: errorRed.withOpacity(0.5), width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: errorRed, width: 1.5),
              ),
              errorText: errorText,
              errorStyle: const TextStyle(color: errorRed, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required String label, 
    required T? value, 
    required List<DropdownMenuItem<T>> items, 
    required ValueChanged<T?> onChanged
  }) {
    return SizedBox(
      width: 320,
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: brandBackground,
        icon: const Icon(Icons.expand_more_rounded, color: Colors.white38),
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
          floatingLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          prefixIcon: const Icon(Icons.account_tree_outlined, color: Colors.white38, size: 18),
          filled: true,
          fillColor: glassFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15), 
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05))
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15), 
            borderSide: const BorderSide(color: Colors.white, width: 1.5)
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isValid = _isFormValid();
    return GestureDetector(
      onTap: isValid ? _submitRegistration : null,
      child: Container(
        width: 320,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isValid ? actionOrange : Colors.grey.shade600,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isValid ? [
            BoxShadow(color: actionOrange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ] : [],
        ),
        child: const Text('CRÉER MON COMPTE', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildFooterLink() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          children: const [
            TextSpan(text: "Déjà membre ? "),
            TextSpan(text: "CONNEXION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
          ],
        ),
      ),
    );
  }
}