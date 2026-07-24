import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';

/// Confirmation discrète — CDC_DESIGN §5.3.6.
///
/// Corrige le bug de positionnement desktop trouvé dans
/// `lib/utils/error_handler.dart` (marge gauche `width - 400`, cassante
/// sous 400px de large) en utilisant [YkBreakpoints] plutôt qu'une valeur
/// en dur. `ErrorHandler` n'est PAS modifié dans ce ticket — le brancher
/// sur ce composant changerait l'apparence des 194+ sites d'appel
/// existants d'un coup, un effet visible app-wide différé à un ticket de
/// bascule dédié.
class YkSnack {
  YkSnack._();

  static void success(
    BuildContext context,
    String message, {
    VoidCallback? onUndo,
    String undoLabel = 'Annuler',
  }) => _show(context, message, YkColors.success, onUndo: onUndo, undoLabel: undoLabel);

  static void error(
    BuildContext context,
    String message, {
    VoidCallback? onUndo,
    String undoLabel = 'Annuler',
  }) => _show(context, message, YkColors.error, onUndo: onUndo, undoLabel: undoLabel);

  static void warning(
    BuildContext context,
    String message, {
    VoidCallback? onUndo,
    String undoLabel = 'Annuler',
  }) => _show(context, message, YkColors.warning, onUndo: onUndo, undoLabel: undoLabel);

  static void info(
    BuildContext context,
    String message, {
    VoidCallback? onUndo,
    String undoLabel = 'Annuler',
  }) => _show(context, message, YkColors.info, onUndo: onUndo, undoLabel: undoLabel);

  static void _show(
    BuildContext context,
    String message,
    Color color, {
    VoidCallback? onUndo,
    required String undoLabel,
  }) {
    if (!context.mounted) return;
    final compact = YkBreakpoints.of(context) == YkBreakpoint.compact;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: YkColors.textOnPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: compact
            ? EdgeInsets.all(YkSpacing.md)
            : EdgeInsets.only(
                bottom: YkSpacing.lg,
                right: YkSpacing.lg,
                left: MediaQuery.sizeOf(context).width * 0.6,
              ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.sm)),
        duration: const Duration(seconds: 3),
        action: onUndo != null
            ? SnackBarAction(label: undoLabel, textColor: YkColors.textOnPrimary, onPressed: onUndo)
            : null,
      ),
    );
  }
}
