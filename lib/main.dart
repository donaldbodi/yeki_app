// lib/main.dart — point d'entrée. Démarrage réel : core/router/guards.dart
// et features/splash/presentation/splash_page.dart.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yeki/core/network/interceptors/auth_interceptor.dart';
import 'package:yeki/core/providers/router_provider.dart';
import 'package:yeki/core/providers/theme_provider.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/core/design/theme/yeki_theme.dart';
import 'package:yeki/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:yeki/services/cache_manager.dart';
import 'package:yeki/services/notification_service.dart';
import 'package:yeki/services/offline_service.dart';
import 'package:yeki/services/push_notification_service.dart';
import 'package:yeki/services/sync_service.dart';
import 'package:yeki/services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Aucune init de locale n'existait auparavant (dates formatées en
  // anglais par défaut) — requis par YkDateTimePicker, voir P4.7.
  await initializeDateFormatting('fr_FR');
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Doit être enregistré tôt, une seule fois — SDK firebase_messaging.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService().initialize();
  await UpdateService.initialize();
  // 401 → refreshListenable (GoRouter ↔ authState) redirige seul vers
  // /login, sans BuildContext — guards.dart.
  AuthInterceptor.onSessionExpired = authState.clearSession;
  if (!kIsWeb) {
    await OfflineService.init();
    await CacheManager().init();
    SyncService().startAutoSync();
  }
  runApp(const ProviderScope(child: YekiApp()));
}
class YekiApp extends ConsumerWidget {
  const YekiApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Yéki',
      // Bornage textScaler ×0,85–×1,60 (CDC_DESIGN §3.4) — voir P4.1.
      builder: YekiTheme.clampedBuilder,
      theme: YekiTheme.light(),
      darkTheme: YekiTheme.dark(),
      themeMode: ref.watch(themeProvider).valueOrNull ?? ThemeMode.system,
      locale: const Locale('fr', 'CM'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // Requis par YkRichEditor (flutter_quill) — voir P4.5.
        FlutterQuillLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
