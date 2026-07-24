// lib/features/forgot_password/presentation/forgot_password_page.dart
//
// Écran mot de passe oublié. Refondu en P5.5 (rituel P5.0) — fiche
// d'écarts : docs/ecarts/forgot_password.md. Remplace les 3 anciennes
// pages/routes (email/OTP/nouveau mot de passe, communiquant par query
// parameters d'URL — dont un `debug_code` exposé dans l'URL) par une
// seule page à wizard interne 3 étapes : seule architecture permettant
// de tenir la cible de taille du ticket (< 10 Ko contre 51 Ko avant
// refonte) et qui élimine ce risque de fuite.
//
// `StatefulWidget` simple. `lib/features/` interdit `setState` (règle
// 7) : tout l'état passe par des `ValueNotifier`.

import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/auth_repository.dart';

import 'steps/etape_email.dart';
import 'steps/etape_nouveau_mdp.dart';
import 'steps/etape_otp.dart';

const _kLabels = ['Email', 'Code', 'Nouveau mot de passe'];

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final ValueNotifier<int> _currentStep = ValueNotifier(0);
  final ValueNotifier<String?> _debugCode = ValueNotifier(null);
  final ValueNotifier<DateTime?> _codeSentAt = ValueNotifier(null);
  final ValueNotifier<String?> _resetToken = ValueNotifier(null);
  String _email = '';

  @override
  void dispose() {
    _currentStep.dispose();
    _debugCode.dispose();
    _codeSentAt.dispose();
    _resetToken.dispose();
    super.dispose();
  }

  void _onCodeEnvoye(String email, String? debugCode) {
    _email = email;
    _debugCode.value = debugCode;
    _codeSentAt.value = DateTime.now();
    _currentStep.value = 1;
  }

  Future<void> _onRenvoyer() async {
    try {
      final debugCode = await AuthRepository().forgotPassword(email: _email);
      _debugCode.value = debugCode;
      _codeSentAt.value = DateTime.now();
    } on ApiException catch (e) {
      if (!mounted) return;
      final seconds = e.retryAfterSeconds;
      YkSnack.error(
        context,
        e.isThrottled
            ? (seconds != null
                ? 'Trop de tentatives. Réessayez dans $seconds secondes.'
                : 'Trop de tentatives. Réessayez dans quelques instants.')
            : 'Une erreur est survenue. Réessayez.',
      );
    }
  }

  void _onCodeVerifie(String resetToken) {
    _resetToken.value = resetToken;
    _currentStep.value = 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YkColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(YkSpacing.md, YkSpacing.md, YkSpacing.md, 0),
              child: ValueListenableBuilder<int>(
                valueListenable: _currentStep,
                builder: (context, step, _) =>
                    YkStepIndicator(labels: _kLabels, currentIndex: step),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: _currentStep,
                builder: (context, step, _) => IndexedStack(
                  sizing: StackFit.expand,
                  index: step,
                  children: [
                    EtapeEmail(onCodeEnvoye: _onCodeEnvoye),
                    EtapeOtp(
                      email: _email,
                      debugCode: _debugCode,
                      codeSentAt: _codeSentAt,
                      onCodeVerifie: _onCodeVerifie,
                      onRenvoyer: _onRenvoyer,
                    ),
                    EtapeNouveauMdp(email: _email, resetToken: _resetToken),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
