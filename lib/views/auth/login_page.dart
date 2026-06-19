// lib/views/auth/login_page.dart
// ═══════════════════════════════════════════════════════════════════════════
//  YEKI LOGIN PAGE — GLASSMORPHISM LIGHT EDITION
//  DESIGN ÉLÉGANT & MODERNE AVEC FORMULAIRES RAFFINÉS
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yeki/main.dart';
import 'package:yeki/core/constants/api_constants.dart';
import 'package:yeki/views/auth/forgot_password_flow.dart';
import 'package:yeki/views/auth/register_page.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _identCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePwd = true;
  String _error = '';
  bool _rememberMe = false;

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
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _identCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_identCtrl.text.trim().isEmpty || _pwdCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.login),
        headers: ApiHeaders.auth(null),
        body: jsonEncode({
          'identifier': _identCtrl.text.trim(),
          'password': _pwdCtrl.text.trim(),
        }),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        if (!mounted) return;
        await YekiAuth.login(
          context,
          token: data['token'] as String,
          role: data['role'] as String,
        );
      } else {
        setState(() => _error = (data['detail'] as String?) ?? 'Identifiants incorrects.');
      }
    } catch (_) {
      setState(() => _error = 'Problème de connexion au serveur.');
    } finally {
      if (mounted) setState(() => _loading = false);
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
            // ── Sphères décoratives élégantes ──────────────────────
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      YekiColors.primary.withValues(alpha: 0.12),
                      YekiColors.primaryLight.withValues(alpha: 0.05),
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
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      YekiColors.accent.withValues(alpha: 0.08),
                      YekiColors.gold.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 300,
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.gold.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: YekiColors.primary.withValues(alpha: 0.06),
                ),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            children: [
                              _buildLogo(),
                              const SizedBox(height: 20),
                              _buildTitle(),
                              const SizedBox(height: 40),
                              _buildGlassCard(),
                              const SizedBox(height: 20),
                              _buildFooterLink(),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ],
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

  // ─── Logo élégant ───────────────────────────────────────────────────
  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(18),
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
        boxShadow: [
          BoxShadow(
            color: YekiColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.school_rounded,
        color: YekiColors.primary,
        size: 40,
      ),
    );
  }

  // ─── Titre élégant ──────────────────────────────────────────────────
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'YEKI',
          style: TextStyle(
            color: YekiColors.primaryDark,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            fontSize: 34,
            shadows: [
              Shadow(
                color: YekiColors.primary.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'L\'EXCELLENCE A PORTEE DE MAIN',
          style: TextStyle(
            color: YekiColors.textMedium,
            fontSize: 11,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w600,
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
      ],
    );
  }

  // ─── Carte de connexion en verre ──────────────────────────────────
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
              // ── En-tête de la carte ──────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: YekiColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Connectez-vous pour continuer',
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
                      Icons.login_rounded,
                      color: YekiColors.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Champ Identifiant ─────────────────────────────────
              _buildModernTextField(
                controller: _identCtrl,
                label: "Email ou Identifiant",
                hint: "exemple@email.com",
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 18),

              // ── Champ Mot de passe ──────────────────────────────
              _buildModernTextField(
                controller: _pwdCtrl,
                label: "Mot de passe",
                hint: "••••••••",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              
              const SizedBox(height: 8),

              // ── Ligne Remember Me + Oublié ──────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildRememberMe(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordPage(),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 40),
                    ),
                    child: Text(
                      "Mot de passe oublié ?",
                      style: TextStyle(
                        color: YekiColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              // ── Message d'erreur ──────────────────────────────────
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: YekiColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: YekiColors.error.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: YekiColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error,
                            style: TextStyle(
                              color: YekiColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // ── Bouton de connexion ──────────────────────────────
              _loading
                  ? Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: YekiColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _buildGradientButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Champ de texte moderne ────────────────────────────────────────
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    final bool hasFocus = controller.text.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFocus 
              ? YekiColors.primary.withValues(alpha: 0.3)
              : YekiColors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePwd,
        style: TextStyle(
          color: YekiColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: YekiColors.primary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: YekiColors.textMedium,
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
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: hasFocus ? YekiColors.primary : YekiColors.textMedium,
              size: 20,
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePwd 
                        ? Icons.visibility_off_outlined 
                        : Icons.visibility_outlined,
                    color: YekiColors.textMedium,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ─── Checkbox Remember Me ──────────────────────────────────────────
  Widget _buildRememberMe() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _rememberMe ? YekiColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _rememberMe ? YekiColors.primary : YekiColors.textLight,
                width: 2,
              ),
            ),
            child: _rememberMe
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "Se souvenir de moi",
          style: TextStyle(
            color: YekiColors.textMedium,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Bouton dégradé moderne ────────────────────────────────────────
  Widget _buildGradientButton() {
    return GestureDetector(
      onTap: _login,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              YekiColors.primary,
              YekiColors.primaryLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: YekiColors.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SE CONNECTER',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Footer d'inscription élégant ──────────────────────────────────
  Widget _buildFooterLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: YekiColors.white.withValues(alpha: 0.9),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterPage()),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: YekiColors.textMedium,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              const TextSpan(text: "Vous n'avez pas de compte ? "),
              TextSpan(
                text: "S'inscrire",
                style: TextStyle(
                  color: YekiColors.primary,
                  fontWeight: FontWeight.w800,
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