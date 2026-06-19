// lib/views/auth/forgot_password_flow.dart
// ═══════════════════════════════════════════════════════════════════════════
// MOT DE PASSE OUBLIÉ — GLASSMORPHISM LIGHT EDITION
// 3 ÉCRANS ÉLÉGANTS
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:yeki/core/theme/yeki_design_system.dart';
import 'package:yeki/core/constants/api_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ÉCRAN 1 — Saisie de l'email
// ═══════════════════════════════════════════════════════════════════════════
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';

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
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyerCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Veuillez saisir votre adresse email.');
      return;
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email)) {
      setState(() => _error = 'Adresse email invalide.');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.forgotPassword),
        headers: ApiHeaders.auth(null),
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        if (!mounted) return;
        final debugCode = data['debug_code'] as String?;
        Navigator.push(
          context,
          _slideRoute(VerifyOTPPage(email: email, debugCode: debugCode)),
        );
      } else {
        setState(() => _error = data['detail'] ?? 'Une erreur est survenue.');
      }
    } catch (_) {
      setState(() => _error = 'Erreur de connexion au serveur.');
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
                          _buildBackButton(),
                          const SizedBox(height: 10),
                          _buildHeader(
                            icon: Icons.mark_email_unread_outlined,
                            title: 'MOT DE PASSE OUBLIÉ',
                            subtitle: 'Entrez votre email pour recevoir un code',
                          ),
                          const SizedBox(height: 40),
                          _buildGlassCard(),
                          const SizedBox(height: 20),
                          _buildFooterLink(context),
                          const SizedBox(height: 30),
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
              _buildSectionLabel("IDENTIFICATION"),
              _buildModernField(
                controller: _emailCtrl,
                label: "Email académique",
                hint: "exemple@email.com",
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() => _error = ''),
                onSubmitted: (_) => _envoyerCode(),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildErrorWidget(_error),
              ],
              const SizedBox(height: 8),
              _buildStepIndicator(step: 0),
              const SizedBox(height: 24),
              _loading
                  ? Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: YekiColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _buildSubmitButton(
                      label: 'ENVOYER LE CODE',
                      icon: Icons.send_outlined,
                      onTap: _envoyerCode,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: YekiColors.primaryDark, size: 18),
        onPressed: () => Navigator.of(context).maybePop(),
        padding: EdgeInsets.zero,
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
          top: 200,
          left: -40,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: YekiColors.gold.withValues(alpha: 0.04),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ÉCRAN 2 — Saisie du code OTP
// ═══════════════════════════════════════════════════════════════════════════
class VerifyOTPPage extends StatefulWidget {
  final String email;
  final String? debugCode;

  const VerifyOTPPage({super.key, required this.email, this.debugCode});

  @override
  State<VerifyOTPPage> createState() => _VerifyOTPPageState();
}

class _VerifyOTPPageState extends State<VerifyOTPPage>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpCtrl = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  String _error = '';
  String _successMsg = '';

  int _resendCountdown = 60;
  Timer? _timer;

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
    _startCountdown();

    if (widget.debugCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final code = widget.debugCode!;
        for (int i = 0; i < 6 && i < code.length; i++) {
          _otpCtrl[i].text = code[i];
        }
        setState(() {
          _successMsg = 'Code pré-rempli : ${widget.debugCode}';
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    for (final c in _otpCtrl) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCountdown > 0) {
        if (mounted) setState(() => _resendCountdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  String get _otpValue => _otpCtrl.map((c) => c.text).join();

  Future<void> _verifier() async {
    final code = _otpValue;
    if (code.length < 6) {
      setState(() => _error = 'Veuillez saisir les 6 chiffres du code.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.verifyOtp),
        headers: ApiHeaders.auth(null),
        body: jsonEncode({'email': widget.email, 'code': code}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final resetToken = data['reset_token'] as String;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          _slideRoute(ResetPasswordPage(email: widget.email, resetToken: resetToken)),
        );
      } else {
        setState(() => _error = data['detail'] ?? 'Code incorrect.');
        _shakeOTPFields();
      }
    } catch (_) {
      setState(() => _error = 'Erreur de connexion.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _renvoyerCode() async {
    if (_resendCountdown > 0) return;
    setState(() {
      _resending = true;
      _error = '';
      _successMsg = '';
    });
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.forgotPassword),
        headers: ApiHeaders.auth(null),
        body: jsonEncode({'email': widget.email}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        for (final c in _otpCtrl) c.clear();
        _focusNodes[0].requestFocus();
        _startCountdown();
        setState(() {
          _successMsg = 'Nouveau code envoyé !';
          if (data['debug_code'] != null) {
            _successMsg = 'Nouveau code : ${data['debug_code']}';
            final code = data['debug_code'].toString();
            for (int i = 0; i < 6 && i < code.length; i++) {
              _otpCtrl[i].text = code[i];
            }
          }
        });
      } else {
        setState(() => _error = data['detail'] ?? 'Erreur.');
      }
    } catch (_) {
      setState(() => _error = 'Erreur réseau.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _shakeOTPFields() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        for (final c in _otpCtrl) c.clear();
        _focusNodes[0].requestFocus();
      }
    });
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
                          _buildBackButton(),
                          const SizedBox(height: 10),
                          _buildHeader(
                            icon: Icons.shield_outlined,
                            title: 'VÉRIFICATION',
                            subtitle: 'Saisissez le code reçu par email',
                          ),
                          const SizedBox(height: 30),
                          _buildGlassCard(),
                          const SizedBox(height: 20),
                          _buildFooterLink(context),
                          const SizedBox(height: 30),
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
              _buildSectionLabel("CODE ENVOYÉ À"),
              Padding(
                padding: const EdgeInsets.only(left: 15, bottom: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.email,
                    style: TextStyle(
                      color: YekiColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _buildSectionLabel("SAISIE DU CODE"),
              _buildOTPFields(),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildErrorWidget(_error),
              ],
              if (_successMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSuccessWidget(_successMsg),
              ],
              const SizedBox(height: 8),
              _buildStepIndicator(step: 1),
              const SizedBox(height: 24),
              _loading
                  ? Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: YekiColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _buildSubmitButton(
                      label: 'VÉRIFIER LE CODE',
                      icon: Icons.verified_outlined,
                      onTap: _verifier,
                    ),
              const SizedBox(height: 12),
              _buildResendRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: YekiColors.primaryDark, size: 18),
        onPressed: () => Navigator.of(context).maybePop(),
        padding: EdgeInsets.zero,
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
      ],
    );
  }

  Widget _buildOTPFields() {
    return SizedBox(
      width: 320,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) {
          return SizedBox(
            width: 44,
            height: 54,
            child: TextField(
              controller: _otpCtrl[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: YekiColors.primaryDark,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: YekiColors.white.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _error.isNotEmpty
                        ? YekiColors.error.withValues(alpha: 0.3)
                        : YekiColors.white.withValues(alpha: 0.8),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: YekiColors.primary,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _otpCtrl[i].text.isNotEmpty
                        ? YekiColors.primary.withValues(alpha: 0.4)
                        : YekiColors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                setState(() => _error = '');
                if (val.length == 1) {
                  if (i < 5) {
                    _focusNodes[i + 1].requestFocus();
                  } else {
                    _focusNodes[i].unfocus();
                    _verifier();
                  }
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResendRow() {
    final canResend = _resendCountdown == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas reçu ? ',
          style: TextStyle(fontSize: 13, color: YekiColors.textMedium),
        ),
        _resending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: YekiColors.primary,
                  strokeWidth: 2,
                ),
              )
            : GestureDetector(
                onTap: canResend ? _renvoyerCode : null,
                child: Text(
                  canResend ? 'RENVOYER' : 'RENVOYER (${_resendCountdown}s)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: canResend ? YekiColors.primary : YekiColors.textLight,
                  ),
                ),
              ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ÉCRAN 3 — Nouveau mot de passe
// ═══════════════════════════════════════════════════════════════════════════
class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordPage({super.key, required this.email, required this.resetToken});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _success = false;
  String _error = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool get _hasLength => _newPwdCtrl.text.length >= 8;
  bool get _hasLetter => RegExp(r'[a-zA-Z]').hasMatch(_newPwdCtrl.text);
  bool get _hasDigit => RegExp(r'[0-9]').hasMatch(_newPwdCtrl.text);
  bool get _matches => _newPwdCtrl.text == _confirmPwdCtrl.text && _confirmPwdCtrl.text.isNotEmpty;

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
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _reinitialiser() async {
    if (!_hasLength || !_hasLetter || !_hasDigit) {
      setState(() => _error = 'Le mot de passe ne respecte pas les critères.');
      return;
    }
    if (!_matches) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final res = await http.post(
        Uri.parse(ApiConstants.resetPassword),
        headers: ApiHeaders.auth(null),
        body: jsonEncode({
          'email': widget.email,
          'reset_token': widget.resetToken,
          'new_password': _newPwdCtrl.text,
          'confirm_password': _confirmPwdCtrl.text,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() => _success = true);
      } else {
        setState(() => _error = data['detail'] ?? 'Erreur.');
      }
    } catch (_) {
      setState(() => _error = 'Erreur réseau.');
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
        child: _success ? _buildSuccessView() : _buildFormView(padding),
      ),
    );
  }

  Widget _buildFormView(double padding) {
    return Stack(
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
                      _buildBackButton(),
                      const SizedBox(height: 10),
                      _buildHeader(
                        icon: Icons.lock_reset_outlined,
                        title: 'NOUVEAU MOT DE PASSE',
                        subtitle: 'Créez un mot de passe sécurisé',
                      ),
                      const SizedBox(height: 30),
                      _buildGlassCard(),
                      const SizedBox(height: 20),
                      _buildFooterLink(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
              _buildSectionLabel("SÉCURITÉ"),
              _buildModernField(
                controller: _newPwdCtrl,
                label: "Nouveau mot de passe",
                hint: "••••••••",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                onChanged: (_) => setState(() => _error = ''),
              ),
              const SizedBox(height: 8),
              _buildPasswordRules(),
              const SizedBox(height: 15),
              _buildModernField(
                controller: _confirmPwdCtrl,
                label: "Confirmation",
                hint: "••••••••",
                icon: Icons.shield_outlined,
                isPassword: true,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                onChanged: (_) => setState(() => _error = ''),
              ),
              if (_confirmPwdCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _matches ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: _matches ? YekiColors.success : YekiColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _matches
                          ? 'Les mots de passe correspondent'
                          : 'Les mots de passe ne correspondent pas',
                      style: TextStyle(
                        fontSize: 12,
                        color: _matches ? YekiColors.success : YekiColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildErrorWidget(_error),
              ],
              const SizedBox(height: 8),
              _buildStepIndicator(step: 2),
              const SizedBox(height: 24),
              _loading
                  ? Container(
                      height: 56,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: YekiColors.primary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _buildSubmitButton(
                      label: 'RÉINITIALISER',
                      icon: Icons.check_circle_outline,
                      onTap: _reinitialiser,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Stack(
      children: [
        _buildDecorations(),
        SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            YekiColors.success.withValues(alpha: 0.10),
                            YekiColors.success.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: YekiColors.success.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: YekiColors.success,
                        size: 52,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'MOT DE PASSE\nRÉINITIALISÉ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: YekiColors.textDark,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        fontSize: 20,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: YekiColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Votre mot de passe a été mis à jour avec succès.\nConnectez-vous avec votre nouveau mot de passe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: YekiColors.textMedium,
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 45),
                    YekiButton(
                      label: 'SE CONNECTER',
                      icon: Icons.login_rounded,
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: YekiColors.primaryDark, size: 18),
        onPressed: () => Navigator.of(context).maybePop(),
        padding: EdgeInsets.zero,
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
          top: 250,
          left: -40,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: YekiColors.gold.withValues(alpha: 0.04),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRules() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: YekiColors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: YekiColors.white.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CRITÈRES REQUIS',
            style: TextStyle(
              color: YekiColors.textMedium,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          _buildRule('Au moins 8 caractères', _hasLength),
          _buildRule('Au moins une lettre', _hasLetter),
          _buildRule('Au moins un chiffre', _hasDigit),
        ],
      ),
    );
  }

  Widget _buildRule(String label, bool valid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: valid ? YekiColors.success : YekiColors.textLight,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: valid ? YekiColors.success : YekiColors.textMedium,
              fontWeight: valid ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  WIDGETS PARTAGÉS — GLASSMORPHISM LIGHT
// ═══════════════════════════════════════════════════════════════════════════

Widget _buildHeader({required IconData icon, required String title, required String subtitle}) {
  return Column(
    children: [
      Container(
        width: 72,
        height: 72,
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
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: YekiColors.primary, size: 32),
      ),
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
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
        subtitle,
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
  TextInputType? keyboardType,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
}) {
  final bool hasFocus = controller.text.isNotEmpty;
  
  return Container(
    decoration: BoxDecoration(
      color: YekiColors.white.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: hasFocus 
            ? YekiColors.primary.withValues(alpha: 0.3)
            : YekiColors.white.withValues(alpha: 0.6),
        width: 1.5,
      ),
    ),
    child: TextFormField(
      controller: controller,
      obscureText: isPassword && (obscure ?? true),
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(
        color: YekiColors.textDark,
        fontSize: 14,
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
        prefixIcon: Icon(
          icon,
          color: hasFocus ? YekiColors.primary : YekiColors.textMedium,
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
      ),
    ),
  );
}

Widget _buildSubmitButton({
  required String label,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
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
          Icon(icon, color: YekiColors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
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

Widget _buildStepIndicator({required int step}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(3, (i) {
      final isActive = i == step;
      final isComplete = i < step;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 28 : 10,
        height: 8,
        decoration: BoxDecoration(
          color: isComplete
              ? YekiColors.success.withValues(alpha: 0.8)
              : (isActive ? YekiColors.primary : YekiColors.textLight.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isComplete ? Icon(Icons.check, size: 6, color: YekiColors.white) : null,
      );
    }),
  );
}

Widget _buildErrorWidget(String message) {
  return Container(
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
        Icon(Icons.error_outline_rounded, color: YekiColors.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: YekiColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSuccessWidget(String message) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: YekiColors.success.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: YekiColors.success.withValues(alpha: 0.12),
        width: 1.0,
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.check_circle_outline_rounded, color: YekiColors.success, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: YekiColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildFooterLink(BuildContext context) {
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
      onPressed: () => Navigator.of(context).pop(),
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
            TextSpan(text: "Retour à "),
            TextSpan(
              text: "LA CONNEXION",
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

PageRouteBuilder _slideRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, anim, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    );