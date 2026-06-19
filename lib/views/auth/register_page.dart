// lib/views/auth/register_page.dart
// ═══════════════════════════════════════════════════════════════════════════
//  YEKI REGISTER PAGE — GLASSMORPHISM LIGHT EDITION
//  INSCRIPTION ÉLÉGANTE AVEC FORMULAIRES MODERNES
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yeki/views/auth/login_page.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/utils/error_handler.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  // Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // States
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

  // États pour les erreurs de validation en temps réel
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmError;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    _fetchCursus();

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

  Future<void> _fetchCursus() async {
    setState(() => loadingCursus = true);
    try {
      final response = await Dio().get('${ApiConstants.baseUrl}/parcours/');
      if (response.statusCode == 200) {
        final List data = response.data;
        final filtered = data.where((e) {
          final typeParcours = e['type_parcours']?.toString().toLowerCase() ?? '';
          final nom = e['nom'].toString().toLowerCase();
          return typeParcours == 'cursus' && !nom.contains('prépas') && !nom.contains('formation');
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
      final response = await Dio().get(
        '${ApiConstants.baseUrl}/parcours/$parcoursId/departements/',
      );
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
      final response = await Dio().get(
        '${ApiConstants.baseUrl}/departements/$departementId/niveaux/',
      );
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
    if (!_isFormValid()) {
      ErrorHandler.showError(context, "Veuillez remplir correctement tous les champs");
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
        ApiConstants.register,
        data: body,
        options: Options(validateStatus: (s) => s! < 500),
      );

      if (response.statusCode == 201) {
        ErrorHandler.showSuccess(context, "Compte créé avec succès !");
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      } else {
        final data = response.data;
        final errorMessage = data?['detail'] ?? "Erreur lors de l'inscription";

        if (data?['error_type'] == 'email_exists' ||
            errorMessage.contains("email") ||
            errorMessage.contains("déjà utilisée") ||
            errorMessage.contains("already exists")) {
          ErrorHandler.showError(context, "❌ Cette adresse email est déjà utilisée. Veuillez en utiliser une autre.");
          setState(() => _emailError = "Email déjà utilisé");
        } else {
          ErrorHandler.showError(context, errorMessage);
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        final errorMessage = data?['detail'] ?? "Email déjà utilisé ou données invalides";

        if (errorMessage.contains("email") ||
            errorMessage.contains("déjà") ||
            errorMessage.contains("already")) {
          ErrorHandler.showError(context, "❌ Cette adresse email est déjà utilisée.");
          setState(() => _emailError = "Email déjà utilisé");
        } else {
          ErrorHandler.showError(context, errorMessage);
        }
      } else {
        ErrorHandler.showError(context, "Problème de connexion. Vérifiez votre réseau.");
      }
    } catch (e) {
      ErrorHandler.showError(context, "Une erreur est survenue. Veuillez réessayer.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = YekiResponsive.isMobile(context);
    final double padding = isMobile ? 20.0 : 48.0;

    return Scaffold(
      backgroundColor: YekiColors.bgLight,
      body: Container(
        decoration: const BoxDecoration(
          gradient: YekiGradients.mainBackground,
        ),
        child: Stack(
          children: [
            _buildDecorations(),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 30),
                          _buildGlassCard(),
                          const SizedBox(height: 20),
                          _buildFooterLink(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                YekiColors.white.withValues(alpha: 0.75),
                YekiColors.white.withValues(alpha: 0.45),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: YekiColors.white.withValues(alpha: 0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: YekiColors.primary.withValues(alpha: 0.06),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // En-tête de la carte
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Créer un compte',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: YekiColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Rejoignez la communauté Yéki',
                          style: TextStyle(
                            fontSize: 13,
                            color: YekiColors.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: YekiColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: YekiColors.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionLabel("IDENTITÉ"),
              _buildModernField(
                controller: _nameController,
                label: "Nom complet",
                hint: "Jean Dupont",
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _buildModernField(
                controller: _emailController,
                label: "Email académique",
                hint: "jean.dupont@email.com",
                icon: Icons.alternate_email_rounded,
                errorText: _emailError,
              ),
              const SizedBox(height: 14),
              _buildModernField(
                controller: _usernameController,
                label: "Nom d'utilisateur",
                hint: "jean.dupont",
                icon: Icons.badge_outlined,
                errorText: _usernameError,
              ),
              const SizedBox(height: 20),

              _buildSectionLabel("VOTRE STATUT"),
              _buildModernDropdown<String>(
                label: "Vous êtes ?",
                value: selectedUserType,
                items: ["Apprenant", "Enseignant"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() {
                  selectedUserType = v;
                  selectedCursus = null;
                  selectedDepartementId = null;
                  selectedNiveau = null;
                }),
              ),
              if (selectedUserType == "Apprenant") ...[
                const SizedBox(height: 14),
                loadingCursus
                    ? _buildLoadingIndicator()
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
                  const SizedBox(height: 14),
                  loadingDepartements
                      ? _buildLoadingIndicator()
                      : _buildModernDropdown<int>(
                          label: "Département",
                          value: selectedDepartementId,
                          items: departementOptions.map((d) => DropdownMenuItem(
                            value: d['id'] as int,
                            child: Text(d['nom']),
                          )).toList(),
                          onChanged: (v) {
                            setState(() => selectedDepartementId = v);
                            _fetchNiveaux(v!);
                          },
                        ),
                ],
                if (selectedDepartementId != null) ...[
                  const SizedBox(height: 14),
                  loadingNiveaux
                      ? _buildLoadingIndicator()
                      : _buildModernDropdown<String>(
                          label: "Niveau d'étude",
                          value: selectedNiveau,
                          items: niveauOptions.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                          onChanged: (v) => setState(() => selectedNiveau = v),
                        ),
                ],
              ],
              const SizedBox(height: 20),

              _buildSectionLabel("SÉCURITÉ"),
              _buildModernField(
                controller: _passwordController,
                label: "Mot de passe",
                hint: "••••••••",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                obscure: _obscurePassword,
                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                errorText: _passwordError,
              ),
              const SizedBox(height: 14),
              _buildModernField(
                controller: _confirmPasswordController,
                label: "Confirmation",
                hint: "••••••••",
                icon: Icons.shield_outlined,
                isPassword: true,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                errorText: _confirmError,
              ),
              const SizedBox(height: 24),

              _isLoading
                  ? Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: YekiColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LinearProgressIndicator(
        color: YekiColors.primary,
        backgroundColor: YekiColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        minHeight: 3,
      ),
    );
  }

  Widget _buildDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  YekiColors.primary.withValues(alpha: 0.10),
                  YekiColors.primaryLight.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  YekiColors.accent.withValues(alpha: 0.06),
                  YekiColors.gold.withValues(alpha: 0.03),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
          ),
        ),
        Positioned(
          top: 150,
          left: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: YekiColors.gold.withValues(alpha: 0.04),
            ),
          ),
        ),
        Positioned(
          bottom: 200,
          right: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: YekiColors.primary.withValues(alpha: 0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                YekiColors.primary.withValues(alpha: 0.10),
                YekiColors.primaryLight.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: YekiColors.primary.withValues(alpha: 0.15),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.school_rounded,
            color: YekiColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'REJOINDRE YEKI',
          style: TextStyle(
            color: YekiColors.textDark,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [YekiColors.primary, YekiColors.primaryLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Créez votre espace d\'apprentissage',
          style: TextStyle(
            color: YekiColors.textMedium,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 5, bottom: 10),
        child: Text(
          label,
          style: TextStyle(
            color: YekiColors.textMedium,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool? obscure,
    VoidCallback? onToggle,
    String? errorText,
  }) {
    final bool hasError = errorText != null;
    final bool hasFocus = controller.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? YekiColors.error.withValues(alpha: 0.3)
              : hasFocus
                  ? YekiColors.primary.withValues(alpha: 0.3)
                  : YekiColors.white.withValues(alpha: 0.6),
          width: hasError ? 2 : 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && (obscure ?? true),
        style: TextStyle(
          color: YekiColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: YekiColors.primary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: hasError ? YekiColors.error : YekiColors.textMedium,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          hintText: hint,
          hintStyle: TextStyle(
            color: YekiColors.textLight,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: hasError ? YekiColors.error : (hasFocus ? YekiColors.primary : YekiColors.textMedium),
            size: 18,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure! ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: YekiColors.textMedium,
                    size: 18,
                  ),
                  onPressed: onToggle,
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorText: errorText,
          errorStyle: TextStyle(
            color: YekiColors.error,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final bool hasValue = value != null;
    
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasValue
              ? YekiColors.primary.withValues(alpha: 0.3)
              : YekiColors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        dropdownColor: YekiColors.white,
        icon: Icon(
          Icons.expand_more_rounded,
          color: hasValue ? YekiColors.primary : YekiColors.textMedium,
        ),
        style: TextStyle(
          color: YekiColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: YekiColors.textMedium,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(
            Icons.account_tree_outlined,
            color: hasValue ? YekiColors.primary : YekiColors.textMedium,
            size: 18,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
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
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isValid
              ? LinearGradient(
                  colors: [
                    YekiColors.primary,
                    YekiColors.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    YekiColors.textLight,
                    YekiColors.textLight.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isValid
              ? [
                  BoxShadow(
                    color: YekiColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_rounded,
              color: YekiColors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'CRÉER MON COMPTE',
              style: TextStyle(
                color: YekiColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: YekiColors.white.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: YekiColors.textMedium,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            children: const [
              TextSpan(text: "Déjà membre ? "),
              TextSpan(
                text: "CONNEXION",
                style: TextStyle(
                  color: YekiColors.primary,
                  fontWeight: FontWeight.w900,
                  decoration: TextDecoration.underline,
                  decorationColor: YekiColors.primary,
                  decorationThickness: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}