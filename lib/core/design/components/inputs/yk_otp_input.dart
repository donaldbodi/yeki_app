import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tokens/tokens.dart';

/// Saisie de code — CDC_DESIGN §5.3.2. Généralise la logique faite main
/// de `forgot_password_flow.dart` (6 champs, avance auto, auto-
/// soumission, collage intelligent).
class YkOtpInput extends StatefulWidget {
  const YkOtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.errorText,
    this.autofocus = true,
    this.initialValue,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool autofocus;

  /// Pré-remplit les cases (P5.5 : `debug_code` renvoyé par le backend en
  /// mode `DEBUG` uniquement). Simple affichage — ne déclenche PAS
  /// `onCompleted` (l'utilisateur garde la main pour vérifier/soumettre).
  final String? initialValue;

  @override
  State<YkOtpInput> createState() => _YkOtpInputState();
}

class _YkOtpInputState extends State<YkOtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
    final initial = widget.initialValue;
    if (initial != null) {
      for (var i = 0; i < initial.length && i < widget.length; i++) {
        _controllers[i].text = initial[i];
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _handleChanged(int index, String value) {
    if (value.length > 1) {
      // Collage intelligent : répartit les chiffres collés sur les
      // cases suivantes plutôt que de rejeter la saisie.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < digits.length && index + i < widget.length; i++) {
        _controllers[index + i].text = digits[i];
      }
      final nextIndex = (index + digits.length).clamp(0, widget.length - 1);
      _nodes[nextIndex].requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }

    final code = _controllers.map((c) => c.text).join();
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(YkRadius.sm),
      borderSide: BorderSide(color: hasError ? YkColors.error : YkColors.border(context)),
    );

    return Semantics(
      label: 'Code de vérification à ${widget.length} chiffres',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                SizedBox(
                  width: 44,
                  height: 54,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _nodes[i],
                    autofocus: widget.autofocus && i == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: widget.length,
                    style: YkTypography.h3(context).copyWith(color: YkColors.textPrimary(context)),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: YkColors.surfaceVariant(context),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border.copyWith(
                        borderSide: BorderSide(color: YkColors.accent(context), width: 2),
                      ),
                    ),
                    onChanged: (v) => _handleChanged(i, v),
                  ),
                ),
                if (i < widget.length - 1) SizedBox(width: YkSpacing.xs),
              ],
            ],
          ),
          if (widget.errorText != null) ...[
            SizedBox(height: YkSpacing.xs),
            Text(widget.errorText!, style: YkTypography.bodySm(context).copyWith(color: YkColors.error)),
          ],
        ],
      ),
    );
  }
}
