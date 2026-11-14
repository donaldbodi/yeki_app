// lib/services/push_notification_service.dart
//
// Notifications push Firebase Cloud Messaging (P10.3/P10.4) — permission,
// récupération et enregistrement du jeton auprès du backend, réception au
// premier plan (YkToast), en arrière-plan, application fermée (clic sur la
// notification → go_router vers `action_route`). Ne pas confondre avec
// `notification_service.dart` (notifications LOCALES via
// awesome_notifications, pour les rappels hors-ligne — sans rapport avec
// FCM, conservé tel quel).
//
// Appelé depuis :
// - `splash_page.dart`, juste après `authState.bootstrap()`, si une
//   session est restaurée (utilisateur déjà connecté).
// - `login_page.dart`, juste après `authState.login(...)` (connexion dans
//   la session app courante, pas seulement au redémarrage).
// Volontairement PAS importé par `auth_state.dart` : ce service importe
// `app_router.dart` (pour `rootNavigatorKey`), qui importe lui-même
// `auth_state.dart` — un import inverse créerait un cycle.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'package:yeki/core/design/components/feedback/yk_toast.dart';
import 'package:yeki/core/router/app_router.dart';
import 'package:yeki/core/router/auth_state.dart';
import 'package:yeki/repositories/notification_repository.dart';

/// Clé VAPID (certificat push web), Firebase Console → Paramètres du
/// projet → Cloud Messaging → Certificats push web → Générer une paire
/// de clés. Voir docs/FIREBASE_SETUP.md pour la procédure détaillée.
// TODO(P3.6): coller ici la clé VAPID générée dans Firebase Console.
const String _vapidKey = 'TODO_VAPID_KEY_FROM_FIREBASE_CONSOLE';

/// Gère la réception en arrière-plan — DOIT être une fonction TOP-LEVEL
/// (exigence du SDK `firebase_messaging`, pas une méthode de classe). Le
/// système affiche déjà la notification native à partir du bloc
/// `notification` de la charge utile ; ce handler no-op n'est nécessaire
/// que pour que le SDK considère l'app correctement initialisée en
/// arrière-plan.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  // Accesseur PARESSEUX (jamais un champ initialisé au constructeur) :
  // `PushNotificationService()` est appelé inconditionnellement dès qu'une
  // session authentifiée est restaurée (`splash_page.dart`), y compris en
  // test widget où `Firebase.initializeApp()` n'a jamais tourné —
  // `FirebaseMessaging.instance` lève alors `[core/no-app]`. En champ
  // `final` initialisé au constructeur, cette exception s'échappait AVANT
  // même que `initialiser()` (qui a son propre `try/catch`) ne soit
  // appelée — un test a confirmé ce crash. En accesseur, l'exception ne
  // se produit qu'au premier appel réel, dans le `try` d'`initialiser()`.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final NotificationRepository _repo = NotificationRepository();
  bool _ecouteursBranches = false;

  /// Demande la permission d'affichage des notifications (obligatoire iOS/
  /// web ; no-op silencieux sur Android < 13 qui n'en a pas besoin).
  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission();
  }

  /// Token FCM de l'appareil/navigateur courant, `null` si la permission
  /// n'a pas été accordée ou si `_vapidKey` n'a pas encore été renseignée
  /// (web uniquement — obligatoire pour `getToken` sur cette plateforme).
  Future<String?> getToken() {
    if (kIsWeb) {
      if (_vapidKey.startsWith('TODO_')) return Future.value(null);
      return _messaging.getToken(vapidKey: _vapidKey);
    }
    return _messaging.getToken();
  }

  String _plateformeCourante() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'desktop';
    }
  }

  /// Point d'entrée principal — demande la permission, récupère le jeton,
  /// l'enregistre côté backend, et branche les écouteurs premier plan/
  /// clic (une seule fois par session app : `_ecouteursBranches` évite les
  /// doublons si rappelé, ex. login après un bootstrap déjà authentifié).
  Future<void> initialiser() async {
    try {
      await requestPermission();
      final token = await getToken();
      if (token != null) {
        await _repo.enregistrerDeviceToken(token, _plateformeCourante());
        await authState.setFcmToken(token);
      }

      if (!_ecouteursBranches) {
        _ecouteursBranches = true;
        FirebaseMessaging.onMessage.listen(_gererMessagePremierPlan);
        FirebaseMessaging.onMessageOpenedApp.listen(_naviguerDepuisMessage);
        final messageInitial = await _messaging.getInitialMessage();
        if (messageInitial != null) _naviguerDepuisMessage(messageInitial);
      }
    } catch (_) {
      // Best-effort : l'absence de push ne doit jamais bloquer l'usage de
      // l'app — l'in-app (déjà branché indépendamment) reste la source de
      // vérité.
    }
  }

  void _gererMessagePremierPlan(RemoteMessage message) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final titre = message.notification?.title;
    final corps = message.notification?.body;
    final texte = [titre, corps]
        .where((s) => s != null && s.isNotEmpty)
        .join(' — ');
    if (texte.isNotEmpty) YkToast.show(context, texte);
  }

  void _naviguerDepuisMessage(RemoteMessage message) {
    final actionRoute = message.data['action_route'] as String?;
    if (actionRoute == null || actionRoute.isEmpty) return;
    appRouter.go(actionRoute);
  }
}
