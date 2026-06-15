// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeki/services/cache_manager.dart';
import 'package:yeki/services/offline_service.dart';
import 'package:yeki/services/sync_service.dart';
import 'package:yeki/services/recharge_wallet_page.dart';
import 'package:yeki/views/pages/apprenants/dasboard.dart';
import 'package:yeki/views/pages/enseignants/interface_enseignant_page.dart';
import 'package:yeki/views/pages/onboarding.dart';
import 'package:yeki/views/auth/login_page.dart';
import 'package:yeki/services/update_service.dart';
import 'package:yeki/views/pages/shared/profil_page.dart';
import 'package:yeki/widgets/wallet_page.dart';

// ─────────────────────────────────────────────────────────────────
// SHARED PREFERENCES — clés
//   'token'           → token d'auth  (effacé à la déconnexion)
//   'role'            → rôle          (effacé à la déconnexion)
//   'onboarding_done' → bool          (JAMAIS effacé → onboarding vu 1x)
//
// LOGIQUE DE DÉMARRAGE :
//   onboarding_done == false  →  OnboardingPage  (toute première fois)
//   token == null             →  LoginPage
//   rôle enseignant/*         →  EnseignantHomePage  (reprise directe)
//   rôle apprenant            →  Dashboard           (reprise directe)
// ─────────────────────────────────────────────────────────────────

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final ThemeData appTheme = ThemeData(
  primaryColor: const Color(0xFF135F74),
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.teal,
    accentColor: const Color(0xFFC5A059),
    backgroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      padding: const EdgeInsets.symmetric(vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF4F4F4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
  ),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialisation des services offline
  await OfflineService.init();
  await CacheManager().init();
  SyncService().startAutoSync();
  
  runApp(const YekiApp());
}

class YekiApp extends StatelessWidget {
  const YekiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yéki',
      theme: appTheme,
      navigatorKey: navigatorKey,
      routes: {
        '/login':      (_) => const LoginPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/wallet':     (_) => const WalletPage(),
        '/recharge':   (_) => const RechargeWalletPage(),
        '/profile':    (_) => const ProfilPage(),
      },
      home: FutureBuilder<Widget>(
        future: YekiAuth.resolveStartPage(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          return snapshot.data ?? const LoginPage();
        },
      ),
    );
  }
}

// ── Splash ────────────────────────────────────────────────────────
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    await Future.delayed(const Duration(seconds: 2));
    final updateInfo = await UpdateService.checkForUpdate();
    if (updateInfo != null && mounted) {
      await UpdateService.showUpdateDialog(context, updateInfo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Yéki', style: TextStyle(
            fontSize: 52, fontWeight: FontWeight.w900,
            color: Color(0xFF2884A0), fontFamily: 'FredokaOne', letterSpacing: 2)),
          SizedBox(height: 44),
          SizedBox(width: 26, height: 26,
            child: CircularProgressIndicator(
              color: Color(0xFF2884A0), strokeWidth: 2.5)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  YEKI AUTH — helper centralisé
//
//  Toutes les pages utilisent ce helper pour naviguer.
//  Import : import 'package:yeki/main.dart';
//
//  Déconnexion  : await YekiAuth.logout(context);
//  Connexion    : await YekiAuth.login(context, token, role);
//  Onboarding   : YekiAuth.finishOnboarding(context);
// ═══════════════════════════════════════════════════════════════
class YekiAuth {
  YekiAuth._();

  static const _kToken       = 'token';
  static const _kRole        = 'role';
  static const _kFcmToken    = 'fcm_token';
  static const _kOnboarding  = 'onboarding_done';
  static const _kApiBase     = 'https://yeki.pythonanywhere.com/api';

  // ── Page de démarrage ─────────────────────────────────────────
  static Future<Widget> resolveStartPage() async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingDone = prefs.getBool(_kOnboarding) ?? false;
    final String? token       = prefs.getString(_kToken);
    final String  role        = prefs.getString(_kRole) ?? '';

    if (!onboardingDone)              return const OnboardingPage();
    if (token == null || token.isEmpty) return const LoginPage();
    return _widgetFromRole(role);
  }

  // ── Connexion ─────────────────────────────────────────────────
  static Future<void> login(
    BuildContext context, {
    required String token,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken,      token);
    await prefs.setString(_kRole,       role);
    await prefs.setBool(_kOnboarding,   true);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      _fade(_widgetFromRole(role)), (_) => false);
  }

  // ── Déconnexion ───────────────────────────────────────────────
  /// Efface token + rôle mais PAS onboarding_done.
  /// → L'utilisateur retourne sur LoginPage, jamais sur OnboardingPage.
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);

    // Appel API best-effort
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$_kApiBase/auth/logout/'),
          headers: {'Authorization': 'Token $token'},
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    // Supprimer session uniquement
    await prefs.remove(_kToken);
    await prefs.remove(_kRole);
    await prefs.remove(_kFcmToken);
    // ⚠️ 'onboarding_done' intentionnellement conservé

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      _fade(const LoginPage()), (_) => false);
  }

  // ── Fin onboarding ────────────────────────────────────────────
  /// Appelé depuis OnboardingPage → marque vu et va sur Login.
  static Future<void> finishOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarding, true);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      _fade(const LoginPage()), (_) => false);
  }

  // ── Helpers privés ────────────────────────────────────────────
  static Widget _widgetFromRole(String role) {
    if (role == 'apprenant') {
      return const Dashboard();
    }
    if (_isEnseignant(role)) {
      return const EnseignantHomePage();
    }
    return const LoginPage();
  }

  static bool _isEnseignant(String role) => {
    'enseignant', 'enseignant_principal',
    'enseignant_cadre', 'enseignant_admin', 'admin',
  }.contains(role);

  static PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 350),
  );
}