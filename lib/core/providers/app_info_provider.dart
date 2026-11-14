// lib/core/providers/app_info_provider.dart
//
// Numéro de version affiché par l'écran Splash (P5.1) — lu une seule
// fois via `package_info_plus` (déjà utilisé par `UpdateService`),
// jamais une chaîne figée dans l'écran.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
});
