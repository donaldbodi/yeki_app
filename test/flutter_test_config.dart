import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chargé automatiquement par `flutter test` pour TOUT fichier de ce
/// dossier (mécanisme officiel, voir la documentation `flutter_test`) —
/// évite d'avoir à dupliquer ce mock dans chaque fichier qui exerce
/// `authState.bootstrap()`/`login()`/`clearSession()` (P5.3).
///
/// `flutter_secure_storage` n'a pas d'équivalent
/// `SharedPreferences.setMockInitialValues` : son canal de plateforme
/// (`MethodChannelFlutterSecureStorage`, voir
/// flutter_secure_storage_platform_interface) n'a aucun répondant en
/// test widget — sans ce mock, l'appel reste indéfiniment en attente
/// (jamais de plateforme réelle enregistrée), bloquant tout test qui
/// bootstrap l'auth (déjà constaté : `test/widget_test.dart` a expiré
/// après 10 min avant l'ajout de ce fichier).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    secureStorageChannel,
    (call) async => null,
  );
  await testMain();
}
