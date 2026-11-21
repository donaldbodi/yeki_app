import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:yeki/core/design/components/components.dart';
import 'package:yeki/core/design/tokens/tokens.dart';
import 'package:yeki/core/network/api_exception.dart';
import 'package:yeki/repositories/auth_repository.dart';

/// Étape 2/3 — saisie du code à 6 chiffres. Pas de `YkFormController`
/// (un seul champ, pas un `YkTextField`) : état géré via `ValueNotifier`
/// (règle 7, pas de `setState` dans `lib/features/`).
///
/// `debugCode`/`codeSentAt` sont des `ValueListenable` (pas de simples
/// valeurs) : un renvoi de code ne change pas l'étape courante du
/// wizard parent, donc ne provoque pas la reconstruction de ce widget —
/// seule une écoute directe permet de refléter un renvoi.
class EtapeOtp extends StatefulWidget {
  const EtapeOtp({
    super.key,
    required this.email,
    required this.debugCode,
    required this.codeSentAt,
    required this.onCodeVerifie,
    required this.onRenvoyer,
  });

  final String email;
  final ValueListenable<String?> debugCode;
  final ValueListenable<DateTime?> codeSentAt;
  final void Function(String resetToken) onCodeVerifie;
  final VoidCallback onRenvoyer;

  @override
  State<EtapeOtp> createState() => _EtapeOtpState();
}

class _EtapeOtpState extends State<EtapeOtp> {
  final ValueNotifier<String?> _erreur = ValueNotifier(null);
  final ValueNotifier<String> _code = ValueNotifier('');
  final ValueNotifier<bool> _verification = ValueNotifier(false);
  final ValueNotifier<int> _resetTick = ValueNotifier(0);
  final ValueNotifier<bool> _peutRenvoyer = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    widget.codeSentAt.addListener(_onEnvoiChange);
  }

  @override
  void dispose() {
    widget.codeSentAt.removeListener(_onEnvoiChange);
    _erreur.dispose();
    _code.dispose();
    _verification.dispose();
    _resetTick.dispose();
    _peutRenvoyer.dispose();
    super.dispose();
  }

  /// Un (re)envoi (initial ou "Renvoyer") réinitialise le compte à
  /// rebours et vide les cases — même comportement que l'ancien
  /// `_renvoyerCode()` (`forgot_password_flow.dart`).
  void _onEnvoiChange() {
    _peutRenvoyer.value = false;
    _erreur.value = null;
    _resetTick.value++;
  }

  Future<void> _verifier(String code) async {
    if (_verification.value) return;
    _verification.value = true;
    _erreur.value = null;
    try {
      final resetToken = await AuthRepository().verifyOtp(email: widget.email, code: code);
      widget.onCodeVerifie(resetToken);
    } on ApiException catch (e) {
      _erreur.value = e.message;
      _resetTick.value++;
    } finally {
      if (mounted) _verification.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(YkSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 48, color: YkColors.accent(context)),
          SizedBox(height: YkSpacing.md),
          Text('Vérification', textAlign: TextAlign.center, style: YkTypography.h2(context)),
          SizedBox(height: YkSpacing.xs),
          Text(
            'Code envoyé à ${widget.email}',
            textAlign: TextAlign.center,
            style: YkTypography.bodyMd(context).copyWith(color: YkColors.textSecondary(context)),
          ),
          SizedBox(height: YkSpacing.lg),
          Center(
            child: ValueListenableBuilder<int>(
              valueListenable: _resetTick,
              builder: (context, tick, _) => ValueListenableBuilder<String?>(
                valueListenable: _erreur,
                builder: (context, erreur, _) => ValueListenableBuilder<String?>(
                  valueListenable: widget.debugCode,
                  builder: (context, debugCode, _) => YkOtpInput(
                    key: ValueKey(tick),
                    initialValue: debugCode,
                    errorText: erreur,
                    onChanged: (v) => _code.value = v,
                    onCompleted: _verifier,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: YkSpacing.md),
          ValueListenableBuilder<String>(
            valueListenable: _code,
            builder: (context, code, _) => ValueListenableBuilder<bool>(
              valueListenable: _verification,
              builder: (context, verifying, _) => YkButton(
                label: 'Vérifier le code',
                isLoading: verifying,
                onPressed: code.length == 6 && !verifying ? () => _verifier(code) : null,
              ),
            ),
          ),
          SizedBox(height: YkSpacing.lg),
          Center(
            child: ValueListenableBuilder<bool>(
              valueListenable: _peutRenvoyer,
              builder: (context, peutRenvoyer, _) {
                if (peutRenvoyer) {
                  return TextButton(
                    onPressed: widget.onRenvoyer,
                    child: const Text('Renvoyer le code'),
                  );
                }
                return ValueListenableBuilder<DateTime?>(
                  valueListenable: widget.codeSentAt,
                  builder: (context, sentAt, _) {
                    if (sentAt == null) return const SizedBox.shrink();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pas reçu ? ',
                          style: YkTypography.bodySm(context).copyWith(color: YkColors.textSecondary(context)),
                        ),
                        YkCountdown(
                          key: ValueKey(sentAt),
                          duration: const Duration(seconds: 60),
                          onExpired: () => _peutRenvoyer.value = true,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
