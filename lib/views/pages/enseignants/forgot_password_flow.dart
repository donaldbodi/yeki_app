import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────
// MOT DE PASSE OUBLIÉ — 3 ÉCRANS
//  1. ForgotPasswordPage   → saisie email
//  2. VerifyOTPPage        → saisie code OTP (6 chiffres)
//  3. ResetPasswordPage    → nouveau mot de passe
// ─────────────────────────────────────────────────────────────────

const String _fpBaseUrl = 'https://yeki.pythonanywhere.com/api';
const Color _fpBlue     = Color(0xFF2884A9);
const Color _fpTeal     = Color(0xFF2A657D);
const Color _fpBg       = Color(0xFFF1F5F9);
const Color _fpDark     = Color(0xFF1E293B);


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
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
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
        Uri.parse('$_fpBaseUrl/auth/forgot-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        if (!mounted) return;
        // En mode DEBUG, le backend renvoie le code dans la réponse
        final debugCode = data['debug_code'] as String?;

        Navigator.push(
          context,
          _slideRoute(
            VerifyOTPPage(
              email: email,
              debugCode: debugCode,
            ),
          ),
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
      backgroundColor: _fpBg,
      body: Stack(
        children: [
          _buildGradientHeader(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: Opacity(opacity: _fadeAnim.value, child: child),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildIllustration(Icons.mark_email_unread_outlined, _fpBlue),
                          const SizedBox(height: 32),
                          _buildCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mot de passe oublié ?',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _fpDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Entrez votre adresse email et nous vous enverrons un code de vérification.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                _buildEmailField(),
                                if (_error.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildError(_error),
                                ],
                                const SizedBox(height: 24),
                                _buildPrimaryBtn(
                                  label: 'Envoyer le code',
                                  icon: Icons.send_outlined,
                                  loading: _loading,
                                  onTap: _envoyerCode,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildStepIndicator(step: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adresse email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _fpDark,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _envoyerCode(),
            onChanged: (_) => setState(() => _error = ''),
            decoration: _inputDeco(
              hint: 'exemple@email.com',
              icon: Icons.alternate_email,
            ),
          ),
        ],
      );
}


// ═══════════════════════════════════════════════════════════════════
//  ÉCRAN 2 — Saisie du code OTP
// ═══════════════════════════════════════════════════════════════════
class VerifyOTPPage extends StatefulWidget {
  final String email;
  final String? debugCode;

  const VerifyOTPPage({
    super.key,
    required this.email,
    this.debugCode,
  });

  @override
  State<VerifyOTPPage> createState() => _VerifyOTPPageState();
}

class _VerifyOTPPageState extends State<VerifyOTPPage>
    with SingleTickerProviderStateMixin {
  // 6 contrôleurs, un par chiffre
  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;
  String _error = '';
  String _successMsg = '';

  // Compte à rebours renvoi (60 secondes)
  int _resendCountdown = 60;
  Timer? _timer;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    _startCountdown();

    // En mode DEBUG : pré-remplir le code
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
            ResetPasswordPage(
              email: widget.email,
              resetToken: resetToken,
            ),
          ),
        );
      } else {
        setState(() => _error = data['detail'] ?? 'Code incorrect.');
        // Secouer les champs
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
        // Vider les champs
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
    // Réinitialiser les champs en rouge pendant 1 sec
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
      backgroundColor: _fpBg,
      body: Stack(
        children: [
          _buildGradientHeader(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildIllustration(Icons.shield_outlined, const Color(0xFF2E7D32)),
                          const SizedBox(height: 32),
                          _buildCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vérification',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _fpDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      height: 1.5,
                                    ),
                                    children: [
                                      const TextSpan(
                                          text: 'Un code a été envoyé à '),
                                      TextSpan(
                                        text: widget.email,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _fpBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // ── Champs OTP ───────────────────
                                _buildOTPFields(),

                                // ── Messages ──────────────────────
                                if (_error.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildError(_error),
                                ],
                                if (_successMsg.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildSuccess(_successMsg),
                                ],
                                const SizedBox(height: 24),

                                // ── Bouton vérifier ───────────────
                                _buildPrimaryBtn(
                                  label: 'Vérifier le code',
                                  icon: Icons.verified_outlined,
                                  loading: _loading,
                                  onTap: _verifier,
                                ),
                                const SizedBox(height: 16),

                                // ── Renvoyer ──────────────────────
                                _buildResendRow(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildStepIndicator(step: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 46,
          height: 56,
          child: TextField(
            controller: _otpCtrl[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _fpDark,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: _error.isNotEmpty
                  ? Colors.red.shade50
                  : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _error.isNotEmpty
                      ? Colors.red.shade300
                      : Colors.grey.shade200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _fpBlue, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _otpCtrl[i].text.isNotEmpty
                      ? _fpBlue.withOpacity(0.5)
                      : Colors.grey.shade200,
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) {
              setState(() => _error = '');
              if (val.length == 1) {
                // Avancer au suivant
                if (i < 5) {
                  _focusNodes[i + 1].requestFocus();
                } else {
                  _focusNodes[i].unfocus();
                  // Auto-vérifier quand le 6ème est rempli
                  _verifier();
                }
              }
            },
            onTap: () => _otpCtrl[i].selection = TextSelection(
              baseOffset: 0,
              extentOffset: _otpCtrl[i].text.length,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResendRow() {
    final canResend = _resendCountdown == 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Vous n\'avez pas reçu le code ? ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        _resending
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: _fpBlue),
              )
            : GestureDetector(
                onTap: canResend ? _renvoyerCode : null,
                child: Text(
                  canResend
                      ? 'Renvoyer'
                      : 'Renvoyer (${_resendCountdown}s)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: canResend ? _fpBlue : Colors.grey.shade400,
                    decoration:
                        canResend ? TextDecoration.underline : null,
                  ),
                ),
              ),
      ],
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
//  ÉCRAN 3 — Nouveau mot de passe
// ═══════════════════════════════════════════════════════════════════
class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _newPwdCtrl     = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _loading         = false;
  bool _obscureNew      = true;
  bool _obscureConfirm  = true;
  bool _success         = false;
  String _error         = '';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // Règles de complexité
  bool get _hasLength  => _newPwdCtrl.text.length >= 8;
  bool get _hasLetter  => RegExp(r'[a-zA-Z]').hasMatch(_newPwdCtrl.text);
  bool get _hasDigit   => RegExp(r'[0-9]').hasMatch(_newPwdCtrl.text);
  bool get _matches    => _newPwdCtrl.text == _confirmPwdCtrl.text
                          && _confirmPwdCtrl.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
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
      backgroundColor: _fpBg,
      body: Stack(
        children: [
          _buildGradientHeader(),
          SafeArea(
            child: Column(
              children: [
                // Masquer le retour en arrière si succès
                if (!_success) _buildTopBar(context),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _success
                        ? _buildSuccessView(context)
                        : _buildFormView(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildIllustration(Icons.lock_reset_outlined, _fpTeal),
          const SizedBox(height: 32),
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouveau mot de passe',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _fpDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez un mot de passe sécurisé pour votre compte.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Champ nouveau mot de passe ────────────────
                _buildLabel('Nouveau mot de passe'),
                TextField(
                  controller: _newPwdCtrl,
                  obscureText: _obscureNew,
                  onChanged: (_) => setState(() => _error = ''),
                  decoration: _inputDeco(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: _fpBlue,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Indicateur de force ────────────────────────
                _buildPasswordRules(),
                const SizedBox(height: 16),

                // ── Champ confirmation ────────────────────────
                _buildLabel('Confirmer le mot de passe'),
                TextField(
                  controller: _confirmPwdCtrl,
                  obscureText: _obscureConfirm,
                  onChanged: (_) => setState(() => _error = ''),
                  decoration: _inputDeco(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: _fpBlue,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                // Indicateur correspondance
                if (_confirmPwdCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _matches ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: _matches ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _matches
                            ? 'Les mots de passe correspondent'
                            : 'Les mots de passe ne correspondent pas',
                        style: TextStyle(
                          fontSize: 11,
                          color: _matches ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],

                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildError(_error),
                ],

                const SizedBox(height: 24),
                _buildPrimaryBtn(
                  label: 'Réinitialiser',
                  icon: Icons.check_circle_outline,
                  loading: _loading,
                  onTap: _reinitialiser,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildStepIndicator(step: 2),
        ],
      ),
    );
  }

  // ── Règles du mot de passe ────────────────────────────────────────
  Widget _buildPasswordRules() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Critères requis :',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          _buildRule('Au moins 8 caractères', _hasLength),
          _buildRule('Au moins une lettre',   _hasLetter),
          _buildRule('Au moins un chiffre',   _hasDigit),
        ],
      ),
    );
  }

  Widget _buildRule(String label, bool valid) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                valid ? Icons.check_circle : Icons.radio_button_unchecked,
                key: ValueKey(valid),
                size: 14,
                color: valid ? Colors.green : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: valid ? Colors.green.shade700 : Colors.grey.shade500,
                fontWeight: valid ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );

  // ── Vue succès ────────────────────────────────────────────────────
  Widget _buildSuccessView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 56,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Mot de passe\nréinitialisé !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _fpDark,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Votre mot de passe a été mis à jour avec succès. '
                'Connectez-vous avec votre nouveau mot de passe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _fpBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Revenir à la page de connexion en vidant la pile
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text(
                    'Se connecter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════
//  WIDGETS PARTAGÉS
// ═══════════════════════════════════════════════════════════════════

Widget _buildGradientHeader() => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 220,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A5276), _fpBlue, _fpTeal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
      ),
    );

Widget _buildTopBar(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

Widget _buildIllustration(IconData icon, Color color) => Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 40),
    );

Widget _buildCard({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

InputDecoration _inputDeco({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: _fpBlue, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _fpBlue, width: 1.5),
      ),
    );

Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _fpDark,
        ),
      ),
    );

Widget _buildError(String msg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

Widget _buildSuccess(String msg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

Widget _buildPrimaryBtn({
  required String label,
  required IconData icon,
  required bool loading,
  required VoidCallback onTap,
}) =>
    SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _fpBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, color: Colors.white, size: 20),
        label: Text(
          loading ? 'Chargement…' : label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

Widget _buildStepIndicator({required int step}) => Row(
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
                ? Colors.green
                : isActive
                    ? _fpBlue
                    : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5),
          ),
          child: isComplete
              ? const Icon(Icons.check, size: 8, color: Colors.white)
              : null,
        );
      }),
    );

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
