// lib/core/utils/error_handler.dart
// ═══════════════════════════════════════════════════════════════════════════
//
// P13.1 : migré hors de `yeki_design_system.dart` (ancien) vers les tokens
// `Yk*` — comportement/API publique INCHANGÉS pour ses 4 appelants
// (`yeki_ia_chat_page.dart`/`details_question_forum.dart`/
// `forum_page.dart`/`forum_audio_player.dart`), seule la source des
// constantes change. Rediriger ces appelants vers `YkSnack` (déjà
// équivalent, voir son commentaire de tête) reste un ticket de bascule à
// part — non fait ici, `ErrorHandler` continue d'exister.

import 'package:flutter/material.dart';
import 'package:yeki/core/design/tokens/tokens.dart';

class ErrorHandler {
  static void _showToast(BuildContext context, String message, Color bgColor) {
    if (!context.mounted) return;

    final bool isWide = YkBreakpoints.of(context) != YkBreakpoint.compact;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: YkColors.textOnPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: isWide
            ? EdgeInsets.only(bottom: 24, right: 24, left: MediaQuery.sizeOf(context).width - 400) // Coin inférieur droit sur Bureau
            : const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.md)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) => _showToast(context, message, YkColors.error);
  static void showSuccess(BuildContext context, String message) => _showToast(context, message, YkColors.success);
  static void showWarning(BuildContext context, String message) => _showToast(context, message, YkColors.warning);
}
