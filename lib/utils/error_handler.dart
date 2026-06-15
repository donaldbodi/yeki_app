// lib/core/utils/error_handler.dart
// ═══════════════════════════════════════════════════════════════════════════
//  GESTIONNAIRE D'ERREURS CENTRALISÉ
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:yeki/core/theme/app_theme.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: YekiColors.white)),
        backgroundColor: YekiColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: YekiRadius.borderRadiusMd,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: YekiColors.white)),
        backgroundColor: YekiColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: YekiRadius.borderRadiusMd,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: YekiColors.white)),
        backgroundColor: YekiColors.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: YekiRadius.borderRadiusMd,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  static String formatErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Map) {
      if (error.containsKey('detail')) return error['detail'].toString();
      if (error.containsKey('message')) return error['message'].toString();
      if (error.containsKey('error')) return error['error'].toString();
      
      // Premier champ d'erreur
      final firstKey = error.keys.first;
      final firstValue = error[firstKey];
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
      return firstValue.toString();
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}