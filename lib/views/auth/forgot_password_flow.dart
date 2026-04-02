import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────
// MOT DE PASSE OUBLIÉ — 3 ÉCRANS (design RegisterPage)
//  1. ForgotPasswordPage   → saisie email
//  2. VerifyOTPPage        → saisie code OTP (6 chiffres)
//  3. ResetPasswordPage    → nouveau mot de passe
// ─────────────────────────────────────────────────────────────────

const String _fpBaseUrl = 'https://yeki.pythonanywhere.com/api';

// ── PALETTE (identique à RegisterPage) ──────────────────────────
const Color _mainBlue   = Color(0xFF2884A0);
const Color _darkBlue   = Color(0xFF164A5A);
const Color _accentWarm = Color(0xFFF39C12);


// ═══════════════════════════════════════════════════════════════════
//  ÉCRAN 1 — Saisie de l'email
// ═══════════════════════════════════════════════════════════════════
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
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── LOGIQUE INCHANGÉE ────────────────────────────────────────────
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
        Uri.parse('$_fpBaseUrl/auth/forgot-password/'),
        headers: {'Content-Type': 'application/json'},
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
      body: _GlassScaffold(
        animCtrl: _animCtrl,
        fadeAnim: _fadeAnim,
        children: [
          _FpHeader(
            icon: Icons.mark_email_unread_outlined,
            title: 'MOT DE PASSE',
            subtitle: 'OUBLIÉ',
          ),
          const SizedBox(height: 40),

          _buildSectionLabel('IDENTIFICATION'),
          _GlassTextField(
            controller: _emailCtrl,
            label: 'Email académique',
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _error = ''),
            onSubmitted: (_) => _envoyerCode(),
          ),

          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            _GlassError(message: _error),
          ],

          const SizedBox(height: 40),
          _FpStepIndicator(step: 0),
          const SizedBox(height: 30),

          _loading
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : _GlassSubmitButton(
                  label: 'ENVOYER LE CODE',
                  icon: Icons.send_outlined,
                  onTap: _envoyerCode,
                ),

          const SizedBox(height: 25),
          _BackToLoginLink(onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
//  ÉCRAN 2 — Saisie du code OTP
// ═══════════════════════════════════════════════════════════════════
class VerifyOTPPage extends StatefulWidget {
  final String email;
  final String? debugCode;

  const VerifyOTPPage({super.key, required this.email, this.debugCode});

  @override
  State<VerifyOTPPage> createState() => _VerifyOTPPageState();
}

class _VerifyOTPPageState extends State<VerifyOTPPage>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

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
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    _startCountdown();

    if (widget.debugCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final code = widget.debugCode!;
        for (int i = 0; i < 6 && i < code.length; i++) {
          _otpCtrl[i].text = code[i];
        }
        setState(() {
          _successMsg =
              '(Mode DEBUG) Code pré-rempli : ${widget.debugCode}';
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

  // ── LOGIQUE INCHANGÉE ────────────────────────────────────────────
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
        Uri.parse('$_fpBaseUrl/auth/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'code': code}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        final resetToken = data['reset_token'] as String;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          _slideRoute(
              ResetPasswordPage(email: widget.email, resetToken: resetToken)),
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
        Uri.parse('$_fpBaseUrl/auth/forgot-password/'),
        headers: {'Content-Type': 'application/json'},
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
      body: _GlassScaffold(
        animCtrl: _animCtrl,
        fadeAnim: _fadeAnim,
        children: [
          _FpHeader(
            icon: Icons.shield_outlined,
            title: 'VÉRIFICATION',
            subtitle: 'CODE OTP',
          ),
          const SizedBox(height: 40),

          _buildSectionLabel('CODE ENVOYÉ À'),
          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 20),
            child: Text(
              widget.email,
              style: const TextStyle(
                color: _accentWarm,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),

          _buildSectionLabel('SAISIE DU CODE'),
          _buildOTPFields(),

          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            _GlassError(message: _error),
          ],
          if (_successMsg.isNotEmpty) ...[
            const SizedBox(height: 12),
            _GlassSuccess(message: _successMsg),
          ],

          const SizedBox(height: 30),
          _FpStepIndicator(step: 1),
          const SizedBox(height: 30),

          _loading
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : _GlassSubmitButton(
                  label: 'VÉRIFIER LE CODE',
                  icon: Icons.verified_outlined,
                  onTap: _verifier,
                ),

          const SizedBox(height: 20),
          _buildResendRow(),
          const SizedBox(height: 10),
          _BackToLoginLink(onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildOTPFields() {
    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: SizedBox(
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
                    color: Colors.white,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _error.isNotEmpty
                        ? Colors.red.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _error.isNotEmpty
                            ? Colors.redAccent.withOpacity(0.5)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _otpCtrl[i].text.isNotEmpty
                            ? _accentWarm.withOpacity(0.6)
                            : Colors.white.withOpacity(0.1),
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
                  onTap: () => _otpCtrl[i].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _otpCtrl[i].text.length,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResendRow() {
    final canResend = _resendCountdown == 0;
    return SizedBox(
      width: 300,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pas reçu ? ',
            style: TextStyle(
                fontSize: 11, color: Colors.white.withOpacity(0.35)),
          ),
          _resending
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accentWarm),
                )
              : GestureDetector(
                  onTap: canResend ? _renvoyerCode : null,
                  child: Text(
                    canResend
                        ? 'RENVOYER'
                        : 'RENVOYER (${_resendCountdown}s)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: canResend
                          ? _accentWarm
                          : Colors.white.withOpacity(0.2),
                      decoration: canResend
                          ? TextDecoration.underline
                          : null,
                      decorationColor: _accentWarm,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
//  ÉCRAN 3 — Nouveau mot de passe
// ═══════════════════════════════════════════════════════════════════
class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordPage(
      {super.key, required this.email, required this.resetToken});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _newPwdCtrl     = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _loading        = false;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _success        = false;
  String _error        = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // ── Règles de complexité (INCHANGÉES) ──────────────────────────
  bool get _hasLength => _newPwdCtrl.text.length >= 8;
  bool get _hasLetter => RegExp(r'[a-zA-Z]').hasMatch(_newPwdCtrl.text);
  bool get _hasDigit  => RegExp(r'[0-9]').hasMatch(_newPwdCtrl.text);
  bool get _matches   =>
      _newPwdCtrl.text == _confirmPwdCtrl.text &&
      _confirmPwdCtrl.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  // ── LOGIQUE INCHANGÉE ────────────────────────────────────────────
  Future<void> _reinitialiser() async {
    if (!_hasLength || !_hasLetter || !_hasDigit) {
      setState(
          () => _error = 'Le mot de passe ne respecte pas les critères.');
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
        Uri.parse('$_fpBaseUrl/auth/reset-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email':            widget.email,
          'reset_token':      widget.resetToken,
          'new_password':     _newPwdCtrl.text,
          'confirm_password': _confirmPwdCtrl.text,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() => _success = true);
        _animCtrl.reset();
        _animCtrl.forward();
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
      body: _success ? _buildSuccessView(context) : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    return _GlassScaffold(
      animCtrl: _animCtrl,
      fadeAnim: _fadeAnim,
      children: [
        _FpHeader(
          icon: Icons.lock_reset_outlined,
          title: 'NOUVEAU',
          subtitle: 'MOT DE PASSE',
        ),
        const SizedBox(height: 40),

        _buildSectionLabel('SÉCURITÉ'),
        _GlassTextField(
          controller: _newPwdCtrl,
          label: 'Nouveau mot de passe',
          icon: Icons.lock_outline,
          isPassword: true,
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
          onChanged: (_) => setState(() => _error = ''),
        ),
        const SizedBox(height: 12),
        _buildPasswordRules(),
        const SizedBox(height: 15),
        _GlassTextField(
          controller: _confirmPwdCtrl,
          label: 'Confirmation',
          icon: Icons.shield_outlined,
          isPassword: true,
          obscure: _obscureConfirm,
          onToggle: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          onChanged: (_) => setState(() => _error = ''),
        ),

        if (_confirmPwdCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: 300,
            child: Row(
              children: [
                Icon(
                  _matches ? Icons.check_circle : Icons.cancel,
                  size: 13,
                  color: _matches ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  _matches
                      ? 'Les mots de passe correspondent'
                      : 'Les mots de passe ne correspondent pas',
                  style: TextStyle(
                    fontSize: 11,
                    color: _matches
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          _GlassError(message: _error),
        ],

        const SizedBox(height: 30),
        _FpStepIndicator(step: 2),
        const SizedBox(height: 30),

        _loading
            ? const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)
            : _GlassSubmitButton(
                label: 'RÉINITIALISER',
                icon: Icons.check_circle_outline,
                onTap: _reinitialiser,
              ),
      ],
    );
  }

  Widget _buildPasswordRules() {
    return SizedBox(
      width: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CRITÈRES REQUIS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
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
        ),
      ),
    );
  }

  Widget _buildRule(String label, bool valid) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                valid
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                key: ValueKey(valid),
                size: 13,
                color: valid
                    ? Colors.greenAccent
                    : Colors.white.withOpacity(0.25),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: valid
                    ? Colors.greenAccent
                    : Colors.white.withOpacity(0.4),
                fontWeight:
                    valid ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );

  Widget _buildSuccessView(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_mainBlue, _darkBlue],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -30,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: _accentWarm.withOpacity(0.04),
            ),
          ),
          SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icône succès glassmorphism
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: 12, sigmaY: 12),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.greenAccent
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.greenAccent,
                                size: 52,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'MOT DE PASSE\nRÉINITIALISÉ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            fontSize: 18,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 2,
                          decoration: BoxDecoration(
                            color: _accentWarm,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Votre mot de passe a été mis à jour avec succès.\nConnectez-vous avec votre nouveau mot de passe.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 45),
                        GestureDetector(
                          onTap: () => Navigator.of(context)
                              .popUntil((route) => route.isFirst),
                          child: Container(
                            width: 300,
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: _accentWarm,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _accentWarm.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 10),
                                Text(
                                  'SE CONNECTER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
//  WIDGETS PARTAGÉS — DESIGN REGISTER
// ═══════════════════════════════════════════════════════════════════

/// Scaffold avec fond dégradé + éléments décoratifs + FadeTransition
class _GlassScaffold extends StatelessWidget {
  final AnimationController animCtrl;
  final Animation<double> fadeAnim;
  final List<Widget> children;

  const _GlassScaffold({
    required this.animCtrl,
    required this.fadeAnim,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_mainBlue, _darkBlue],
        ),
      ),
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -40,
            right: -40,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -30,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: _accentWarm.withOpacity(0.02),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Bouton retour
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white54, size: 18),
                        onPressed: () =>
                            Navigator.of(context).maybePop(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...children,
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
}

/// En-tête avec icône glassmorphism + titre uppercase + trait accentué
class _FpHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FpHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icône dans un cercle glassmorphism
        ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.12), width: 1),
              ),
              child: Icon(icon, color: Colors.white70, size: 34),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            fontSize: 15,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: _accentWarm,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

/// Label de section (identique à _buildSectionLabel de RegisterPage)
Widget _buildSectionLabel(String label) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 15, bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    ),
  );
}

/// Champ texte glassmorphism (clone de _buildGlassField)
class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final bool? obscure;
  final VoidCallback? onToggle;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.obscure,
    this.onToggle,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: SizedBox(
          width: 300,
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && (obscure ?? true),
            keyboardType: keyboardType,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 11),
              floatingLabelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              prefixIcon: Icon(icon,
                  color: Colors.white.withOpacity(0.5), size: 16),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscure!
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Colors.white24,
                        size: 16,
                      ),
                      onPressed: onToggle,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 15),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide:
                    const BorderSide(color: Colors.white, width: 0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton principal (clone de _buildSubmitButton)
class _GlassSubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassSubmitButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _accentWarm,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _accentWarm.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 15),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicateur d'étapes (adapté du style Register)
class _FpStepIndicator extends StatelessWidget {
  final int step;
  const _FpStepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive   = i == step;
        final isComplete = i < step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isComplete
                ? Colors.greenAccent.withOpacity(0.8)
                : isActive
                    ? _accentWarm
                    : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(5),
          ),
          child: isComplete
              ? const Icon(Icons.check, size: 8, color: Colors.white)
              : null,
        );
      }),
    );
  }
}

/// Bandeau d'erreur glassmorphism
class _GlassError extends StatelessWidget {
  final String message;
  const _GlassError({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.redAccent.withOpacity(0.3), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau de succès glassmorphism
class _GlassSuccess extends StatelessWidget {
  final String message;
  const _GlassSuccess({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.3),
                  width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.greenAccent, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lien retour connexion (clone de _buildFooterLink)
class _BackToLoginLink extends StatelessWidget {
  final VoidCallback onTap;
  const _BackToLoginLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: RichText(
        text: TextSpan(
          style:
              TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
          children: const [
            TextSpan(text: 'Déjà membre ? '),
            TextSpan(
              text: 'CONNEXION',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
//  UTILITAIRE
// ═══════════════════════════════════════════════════════════════════
PageRouteBuilder _slideRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 350),
    );