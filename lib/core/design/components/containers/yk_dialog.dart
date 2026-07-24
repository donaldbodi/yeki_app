import 'package:flutter/material.dart';

import '../../tokens/tokens.dart';
import '../actions/yk_button.dart';

/// Variante de [YkDialog] — CDC_DESIGN §5.3.3.
enum YkDialogVariant { standard, destructive }

/// Boîtes de dialogue — CDC_DESIGN §5.3.3 : confirmation, alerte,
/// formulaire court.
class YkDialog {
  YkDialog._();

  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    YkDialogVariant variant = YkDialogVariant.standard,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: YkColors.surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.lg)),
        title: Text(title, style: YkTypography.h4(ctx).copyWith(color: YkColors.textPrimary(ctx))),
        content: Text(
          message,
          style: YkTypography.bodyMd(ctx).copyWith(color: YkColors.textSecondary(ctx)),
        ),
        actions: [
          YkButton(
            label: cancelLabel,
            variant: YkButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          YkButton(
            label: confirmLabel,
            variant: variant == YkDialogVariant.destructive
                ? YkButtonVariant.destructive
                : YkButtonVariant.primary,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  static Future<void> alert({
    required BuildContext context,
    required String title,
    required String message,
    String dismissLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: YkColors.surface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(YkRadius.lg)),
        title: Text(title, style: YkTypography.h4(ctx).copyWith(color: YkColors.textPrimary(ctx))),
        content: Text(
          message,
          style: YkTypography.bodyMd(ctx).copyWith(color: YkColors.textSecondary(ctx)),
        ),
        actions: [
          YkButton(label: dismissLabel, onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }
}
