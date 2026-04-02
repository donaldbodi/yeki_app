import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yeki/main.dart'; 
import 'package:yeki/views/auth/forgot_password_flow.dart';
import 'register_page.dart';

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

  // Palette Onboarding Validée
  static const Color mainBlue = Color(0xFF2884A0); 
  static const Color darkBlue = Color(0xFF164A5A);
  static const Color accentWarm = Color(0xFFF39C12);

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _identCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  // TA LOGIQUE DE CONNEXION CONSERVÉE
  Future<void> _login() async {
    if (_identCtrl.text.trim().isEmpty || _pwdCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs.');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    try {
      final res = await http.post(
        Uri.parse('https://yeki.pythonanywhere.com/api/auth/login/'),
        headers: {'Content-Type': 'application/json'},
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
            // ÉLÉMENTS DÉCORATIFS (Style Onboarding)
            Positioned(
              top: -50,
              left: -50,
              child: CircleAvatar(
                radius: 130,
                backgroundColor: Colors.white.withOpacity(0.05),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -30,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: accentWarm.withOpacity(0.03),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        // LOGO GLASS DÉPOLI
                        //_buildGlassLogo(),
                        const SizedBox(height: 25),
                        const Text('YEKI', 
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 10, 
                            fontSize: 24
                          )),
                        const SizedBox(height: 10),
                        Text('Connectez-vous pour continuer',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        
                        const SizedBox(height: 50),

                        // FORMULAIRE COMPACT (280px pour le look pro)
                        SizedBox(
                          width: 280, 
                          child: Column(
                            children: [
                              _buildSmallField(
                                controller: _identCtrl,
                                label: "Email ou Identifiant",
                                icon: Icons.alternate_email_rounded,
                              ),
                              const SizedBox(height: 20),
                              _buildSmallField(
                                controller: _pwdCtrl,
                                label: "Mot de passe",
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                              ),
                              
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                                  child: Text("Oublié ?", 
                                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_error.isNotEmpty) 
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(_error, 
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),

                        const SizedBox(height: 35),

                        // BOUTON ACTION (Style Onboarding)
                        _loading 
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : _buildPrimaryButton(),

                        const SizedBox(height: 50),
                        
                        // LIEN INSCRIPTION
                        _buildFooterLink(),
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

  Widget _buildGlassLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 80,
          width: 80,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Image.asset(
            'assets/images/yeki_logo.png',
            errorBuilder: (_, __, ___) => const Icon(Icons.school_rounded, color: Colors.white, size: 35),
          ),
        ),
      ),
    );
  }

  // CHAMPS PETITS, ARRONDIS & GLASS
  Widget _buildSmallField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePwd,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
            floatingLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
            suffixIcon: isPassword ? IconButton(
              icon: Icon(_obscurePwd ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                color: Colors.white24, size: 16),
              onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
            ) : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25),
              borderSide: const BorderSide(color: Colors.white, width: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTap: _login,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        decoration: BoxDecoration(
          color: accentWarm,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: accentWarm.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: const Text(
          'SE CONNECTER',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return TextButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          children: const [
            TextSpan(text: "Pas encore de compte ? "),
            TextSpan(text: "S'INSCRIRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}