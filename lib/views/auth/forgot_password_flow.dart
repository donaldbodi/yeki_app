// lib/views/auth/forgot_password_flow.dart
// ═══════════════════════════════════════════════════════════════════════════
// MOT DE PASSE OUBLIÉ — 3 ÉCRANS (CORRIGÉ)
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:yeki/core/theme/app_theme.dart';
import 'package:yeki/core/constants/api_constants.dart';
//import 'package:yeki/utils/error_handler.dart';

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

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
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
    return Scaffold(
      backgroundColor: YekiColors.primaryDark,
      body: Stack(
        children: [
          _buildDecorations(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildBackButton(),
                    const SizedBox(height: 10),
                    _buildHeader(
                      icon: Icons.mark_email_unread_outlined,
                      title: 'MOT DE PASSE OUBLIÉ',
                    ),
                    const SizedBox(height: 40),
                    _buildSectionLabel("IDENTIFICATION"),
                    _buildModernField(
                      controller: _emailCtrl,
                      label: "Email académique",
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() => _error = ''),
                      onSubmitted: (_) => _envoyerCode(),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildErrorWidget(_error),
                    ],
                    const SizedBox(height: 40),
                    _buildStepIndicator(step: 0),
                    const SizedBox(height: 30),
                    _loading
                        ? const YekiLoader(color: YekiColors.white)
                        : _buildSubmitButton(
                            label: 'ENVOYER LE CODE',
                            icon: Icons.send_outlined,
                            onTap: _envoyerCode,
                          ),
                    const SizedBox(height: 30),
                    _buildFooterLink(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: YekiColors.white, size: 18),
        onPressed: () => Navigator.of(context).maybePop(),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -40,
          left: -40,
          child: _buildCircle(180, YekiColors.white.withValues(alpha: 0.03)),
        ),
        Positioned(
          bottom: 20,
          right: -30,
          child: _buildCircle(120, YekiColors.white.withValues(alpha: 0.02)),
        ),
      ],
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ÉCRAN 2 — Saisie du code OTP (CORRIGÉ)
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

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
    _startCountdown();

    if (widget.debugCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final code = widget.debugCode!;
        for (int i = 0; i < 6 && i < code.length; i++) {
          _otpCtrl[i].text = code[i];
        }
        setState(() {
          _successMsg = '(Mode DEBUG) Code pré-rempli : ${widget.debugCode}';
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
            _successMsg = '(DEBUG) Nouveau code : ${data['debug_code']}';
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
    return Scaffold(
      backgroundColor: YekiColors.primaryDark,
      body: Stack(
        children: [
          _buildDecorations(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildBackButton(),
                    const SizedBox(height: 10),
                    _buildHeader(
                      icon: Icons.shield_outlined,
                      title: 'VÉRIFICATION',
                    ),
                    const SizedBox(height: 40),
                    _buildSectionLabel("CODE ENVOYÉ À"),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, bottom: 20),
                      child: Text(
                        widget.email,
                        style: TextStyle(
                          color: YekiColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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
                    const SizedBox(height: 30),
                    _buildStepIndicator(step: 1),
                    const SizedBox(height: 30),
                    _loading
                        ? const YekiLoader(color: YekiColors.white)
                        : _buildSubmitButton(
                            label: 'VÉRIFIER LE CODE',
                            icon: Icons.verified_outlined,
                            onTap: _verifier,
                          ),
                    const SizedBox(height: 20),
                    _buildResendRow(),
                    const SizedBox(height: 20),
                    _buildFooterLink(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: YekiColors.white, size: 18),
        onPressed: () => Navigator.of(context).maybePop(),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -40,
          left: -40,
          child: _buildCircle(180, YekiColors.white.withValues(alpha: 0.03)),
        ),
        Positioned(
          bottom: 20,
          right: -30,
          child: _buildCircle(120, YekiColors.white.withValues(alpha: 0.02)),
        ),
      ],
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildOTPFields() {
    return SizedBox(
      width: 320,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) {
          return SizedBox(
            width: 42,
            height: 52,
            child: TextField(
              controller: _otpCtrl[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: YekiColors.white,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: YekiColors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: YekiRadius.borderRadiusMd,
                  borderSide: BorderSide(
                    color: _error.isNotEmpty
                        ? YekiColors.error.withValues(alpha: 0.5)
                        : YekiColors.white.withValues(alpha: 0.05),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: YekiRadius.borderRadiusMd,
                  borderSide: const BorderSide(color: YekiColors.white, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: YekiRadius.borderRadiusMd,
                  borderSide: BorderSide(
                    color: _otpCtrl[i].text.isNotEmpty
                        ? YekiColors.accent.withValues(alpha: 0.6)
                        : YekiColors.white.withValues(alpha: 0.05),
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
    return SizedBox(
      width: 320,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pas reçu ? ',
            style: TextStyle(fontSize: 12, color: YekiColors.white.withValues(alpha: 0.5)),
          ),
          _resending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: YekiLoader(color: YekiColors.accent, size: 14),
                )
              : GestureDetector(
                  onTap: canResend ? _renvoyerCode : null,
                  child: Text(
                    canResend ? 'RENVOYER' : 'RENVOYER (${_resendCountdown}s)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: canResend ? YekiColors.accent : YekiColors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
        ],
      ),
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

  bool get _hasLength => _newPwdCtrl.text.length >= 8;
  bool get _hasLetter => RegExp(r'[a-zA-Z]').hasMatch(_newPwdCtrl.text);
  bool get _hasDigit => RegExp(r'[0-9]').hasMatch(_newPwdCtrl.text);
  bool get _matches => _newPwdCtrl.text == _confirmPwdCtrl.text && _confirmPwdCtrl.text.isNotEmpty;

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
    return Scaffold(
      backgroundColor: YekiColors.primaryDark,
      body: _success ? _buildSuccessView() : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    return Stack(
      children: [
        _buildDecorations(),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildBackButton(),
                  const SizedBox(height: 10),
                  _buildHeader(
                    icon: Icons.lock_reset_outlined,
                    title: 'NOUVEAU MOT DE PASSE',
                  ),
                  const SizedBox(height: 40),
                  _buildSectionLabel("SÉCURITÉ"),
                  _buildModernField(
                    controller: _newPwdCtrl,
                    label: "Nouveau mot de passe",
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    onChanged: (_) => setState(() => _error = ''),
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordRules(),
                  const SizedBox(height: 15),
                  _buildModernField(
                    controller: _confirmPwdCtrl,
                    label: "Confirmation",
                    icon: Icons.shield_outlined,
                    isPassword: true,
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    onChanged: (_) => setState(() => _error = ''),
                  ),
                  if (_confirmPwdCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 320,
                      child: Row(
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
                              fontSize: 11,
                              color: _matches ? YekiColors.success : YekiColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildErrorWidget(_error),
                  ],
                  const SizedBox(height: 30),
                  _buildStepIndicator(step: 2),
                  const SizedBox(height: 30),
                  _loading
                      ? const YekiLoader(color: YekiColors.white)
                      : _buildSubmitButton(
                          label: 'RÉINITIALISER',
                          icon: Icons.check_circle_outline,
                          onTap: _reinitialiser,
                        ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ],
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
                        color: YekiColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: YekiColors.success.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: YekiColors.success,
                        size: 52,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'MOT DE PASSE\nRÉINITIALISÉ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: YekiColors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        fontSize: 18,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: YekiColors.accent,
                        borderRadius: YekiRadius.borderRadiusSm,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Votre mot de passe a été mis à jour avec succès.\nConnectez-vous avec votre nouveau mot de passe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: YekiColors.white.withValues(alpha: 0.5),
                        fontSize: 12,
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
        icon: const Icon(Icons.arrow_back_ios_new, color: YekiColors.white, size: 18),
        onPressed: () => Navigator.of(context).maybePop(),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDecorations() {
    return Stack(
      children: [
        Positioned(
          top: -40,
          left: -40,
          child: _buildCircle(180, YekiColors.white.withValues(alpha: 0.03)),
        ),
        Positioned(
          bottom: 20,
          right: -30,
          child: _buildCircle(120, YekiColors.white.withValues(alpha: 0.02)),
        ),
      ],
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildPasswordRules() {
    return SizedBox(
      width: 320,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: YekiColors.white.withValues(alpha: 0.1),
          borderRadius: YekiRadius.borderRadiusMd,
          border: Border.all(color: YekiColors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CRITÈRES REQUIS',
              style: TextStyle(
                color: YekiColors.white.withValues(alpha: 0.3),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            _buildRule('Au moins 8 caractères', _hasLength),
            _buildRule('Au moins une lettre', _hasLetter),
            _buildRule('Au moins un chiffre', _hasDigit),
          ],
        ),
      ),
    );
  }

  Widget _buildRule(String label, bool valid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 13,
            color: valid ? YekiColors.success : YekiColors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: valid ? YekiColors.success : YekiColors.white.withValues(alpha: 0.4),
              fontWeight: valid ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  WIDGETS PARTAGÉS (CORRIGÉS)
// ═══════════════════════════════════════════════════════════════════════════

Widget _buildHeader({required IconData icon, required String title}) {
  return Column(
    children: [
      Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: YekiColors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: YekiColors.white.withValues(alpha: 0.12), width: 1),
        ),
        child: Icon(icon, color: YekiColors.white, size: 34),
      ),
      const SizedBox(height: 20),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: YekiColors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 10),
      Container(
        width: 40,
        height: 3,
        decoration: BoxDecoration(
          color: YekiColors.accent,
          borderRadius: YekiRadius.borderRadiusSm,
        ),
      ),
    ],
  );
}

Widget _buildSectionLabel(String label) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          color: YekiColors.white.withValues(alpha: 0.3),
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
  required IconData icon,
  bool isPassword = false,
  bool? obscure,
  VoidCallback? onToggle,
  TextInputType? keyboardType,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
}) {
  return SizedBox(
    width: 320,
    child: TextFormField(
      controller: controller,
      obscureText: isPassword && (obscure ?? true),
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: YekiColors.white, fontSize: 14, fontWeight: FontWeight.w500),
      cursorColor: YekiColors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: YekiColors.white.withValues(alpha: 0.4), fontSize: 13),
        floatingLabelStyle: const TextStyle(color: YekiColors.white, fontWeight: FontWeight.bold, fontSize: 12),
        prefixIcon: Icon(icon, color: YekiColors.white.withValues(alpha: 0.7), size: 18),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure! ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: YekiColors.white,
                  size: 18,
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: YekiColors.white.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: YekiRadius.borderRadiusMd,
          borderSide: BorderSide(color: YekiColors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: YekiRadius.borderRadiusMd,
          borderSide: const BorderSide(color: YekiColors.white, width: 1.5),
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
      width: 320,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: YekiColors.accent,
        borderRadius: YekiRadius.borderRadiusMd,
        boxShadow: YekiShadows.accent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: YekiColors.white, size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: YekiColors.white,
              fontWeight: FontWeight.w900,
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
        height: 10,
        decoration: BoxDecoration(
          color: isComplete
              ? YekiColors.success.withValues(alpha: 0.8)
              : (isActive ? YekiColors.accent : YekiColors.white.withValues(alpha: 0.15)),
          borderRadius: YekiRadius.borderRadiusSm,
        ),
        child: isComplete ? const Icon(Icons.check, size: 8, color: YekiColors.white) : null,
      );
    }),
  );
}

Widget _buildErrorWidget(String message) {
  return SizedBox(
    width: 320,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: YekiColors.error.withValues(alpha: 0.12),
        borderRadius: YekiRadius.borderRadiusMd,
        border: Border.all(color: YekiColors.error.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: YekiColors.error, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: YekiColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSuccessWidget(String message) {
  return SizedBox(
    width: 320,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: YekiColors.success.withValues(alpha: 0.08),
        borderRadius: YekiRadius.borderRadiusMd,
        border: Border.all(color: YekiColors.success.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: YekiColors.success, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: YekiColors.success, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildFooterLink(BuildContext context) {
  return TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: RichText(
      text: TextSpan(
        style: TextStyle(color: YekiColors.white.withValues(alpha: 0.6), fontSize: 13),
        children: const [
          TextSpan(text: "Retour à "),
          TextSpan(
            text: "LA CONNEXION",
            style: TextStyle(
              color: YekiColors.white,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    ),
  );
}

PageRouteBuilder _slideRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    );