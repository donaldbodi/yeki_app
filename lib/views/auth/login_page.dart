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

  // Palette Mise à jour : Fond #135F74 et Bouton Vivant
  static const Color brandBackground = Color(0xFF135F74); 
  static const Color actionOrange = Color(0xFFFF6B00); // Couleur vive et pro pour le bouton
  static const Color glassFill = Color(0x1AFFFFFF); // Blanc 10% pour l'effet clair

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

  // TA LOGIQUE DE CONNEXION CONSERVÉE À 100%
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
      backgroundColor: brandBackground, // Application du fond #135F74
      body: Stack(
        children: [
          // ÉLÉMENTS DÉCORATIFS ÉPURÉS
          Positioned(
            top: -60,
            right: -60,
            child: _buildCircle(220, Colors.white.withOpacity(0.04)),
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
                      // LOGO YEKI
                      _buildLogo(),
                      const SizedBox(height: 25),
                      const Text('YEKI', 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 10, 
                          fontSize: 28
                        )),
                      const SizedBox(height: 8),
                      Text('EXCELLENCE ET INGÉNIERIE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4), 
                          fontSize: 10, 
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold
                        )),
                      
                      const SizedBox(height: 55),

                      // FORMULAIRE ÉLÉGANT
                      SizedBox(
                        width: 300, 
                        child: Column(
                          children: [
                            _buildModernField(
                              controller: _identCtrl,
                              label: "Email ou Identifiant",
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 20),
                            _buildModernField(
                              controller: _pwdCtrl,
                              label: "Mot de passe",
                              icon: Icons.lock_open_rounded,
                              isPassword: true,
                            ),
                            
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                                child: Text("Oublié ?", 
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_error.isNotEmpty) 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Text(_error, 
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),

                      const SizedBox(height: 30),

                      // BOUTON ACTION VIVANT
                      _loading 
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        : _buildPrimaryButton(),

                      const SizedBox(height: 60),
                      
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
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Icon(Icons.school_outlined, color: Colors.white, size: 40),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePwd,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        floatingLabelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePwd ? Icons.visibility_off_outlined : Icons.visibility_outlined, 
            color: Colors.white38, size: 18),
          onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
        ) : null,
        filled: true,
        fillColor: glassFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTap: _login,
      child: Container(
        width: 300,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: actionOrange, // Couleur vivante
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: actionOrange.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Text(
          'SE CONNECTER',
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w900, 
            fontSize: 14, 
            letterSpacing: 2
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return TextButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
          children: const [
            TextSpan(text: "Besoin d'un compte ? "),
            TextSpan(text: "S'INSCRIRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
          ],
        ),
      ),
    );
  }
}