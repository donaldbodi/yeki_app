// lib/core/utils/error_handler.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:yeki/core/theme/yeki_design_system.dart';

class ErrorHandler {
  static void _showToast(BuildContext context, String message, Color bgColor) {
    if (!context.mounted) return;

    final bool isWide = !YekiResponsive.isMobile(context);

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: const TextStyle(color: YekiColors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: isWide 
            ? EdgeInsets.only(bottom: 24, right: 24, left: MediaQuery.sizeOf(context).width - 400) // Coin inférieur droit sur Bureau
            : const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: YekiRadius.radiusMd),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) => _showToast(context, message, YekiColors.error);
  static void showSuccess(BuildContext context, String message) => _showToast(context, message, YekiColors.success);
  static void showWarning(BuildContext context, String message) => _showToast(context, message, YekiColors.warning);
}
