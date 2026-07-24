// lib/services/push_notification_service.dart
//
// Socle Firebase Cloud Messaging (P3.6) — permission + récupération du
// token uniquement. Volontairement PAS branché dans main.dart : quand
// demander la permission (connexion ? premier lancement ?), comment
// afficher une notification reçue au premier plan, et l'envoi du token
// au backend (aucun endpoint dédié n'existe encore côté Django) sont des
// décisions produit hors périmètre d'un ticket de configuration Firebase
// — voir docs/FIREBASE_SETUP.md. Ne pas confondre avec
// `notification_service.dart` (affichage de notifications LOCALES via
// awesome_notifications, sans rapport avec FCM).

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Clé VAPID (certificat push web), Firebase Console → Paramètres du
/// projet → Cloud Messaging → Certificats push web → Générer une paire
/// de clés. Voir docs/FIREBASE_SETUP.md pour la procédure détaillée.
// TODO(P3.6): coller ici la clé VAPID générée dans Firebase Console.
const String _vapidKey = 'TODO_VAPID_KEY_FROM_FIREBASE_CONSOLE';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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
}
