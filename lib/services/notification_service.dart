// lib/services/notification_service.dart
//
// SERVICE COMPLET DE NOTIFICATIONS YEKI
// ─────────────────────────────────────
// Gère :
//   1. Firebase Cloud Messaging (FCM) — push Android
//   2. flutter_local_notifications — affichage local
//   3. Polling API — notifications in-app
//
// pubspec.yaml — ajouter ces dépendances :
//   firebase_core: ^2.27.0
//   firebase_messaging: ^14.7.10
//   flutter_local_notifications: ^16.3.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Imports conditionnels selon disponibilité
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String _baseN = 'https://yeki.pythonanywhere.com/api';

// ── Canaux de notification Android ────────────────────────────
const String _channelId   = 'yeki_channel';
const String _channelName = 'Notifications Yeki';
const String _channelDesc = 'Toutes les alertes de l\'application Yeki';

/// Service singleton de notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  bool _initialized = false;

  // Navigation globale (à définir dans main.dart)
  static GlobalKey<NavigatorState>? navigatorKey;

  // ── Initialisation ────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _initLocalNotifications();
      await _initFirebaseMessaging();
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  // ── Flutter Local Notifications ───────────────────────────────
  Future<void> _initLocalNotifications() async {
    // NOTE : décommenter quand flutter_local_notifications est installé
    /*
    final plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Créer le canal Android
    const channel = AndroidNotificationChannel(
      _channelId, _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );
    await plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    */
    debugPrint('LocalNotifications: initialized (stub)');
  }

  // ── Firebase Cloud Messaging ──────────────────────────────────
  Future<void> _initFirebaseMessaging() async {
    // NOTE : décommenter quand firebase_messaging est installé
    /*
    final messaging = FirebaseMessaging.instance;

    // Demander permissions (iOS + Android 13+)
    final settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Récupérer le token FCM
    final token = await messaging.getToken();
    if (token != null) await _saveFcmToken(token);

    // Écouter les refresh de token
    messaging.onTokenRefresh.listen(_saveFcmToken);

    // Message en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Message quand l'app est en background (tap)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Message quand l'app était terminée
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleMessageOpenedApp(initial);
    */
    debugPrint('FCM: initialized (stub)');
  }

  // ── Enregistrer le token FCM sur le serveur ───────────────────
  Future<void> _saveFcmToken(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      await http.post(
        Uri.parse('$_baseN/notifications/fcm-token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        }),
      );

      await prefs.setString('fcm_token', fcmToken);
      debugPrint('FCM token saved: ${fcmToken.substring(0, 20)}...');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // ── Gérer message foreground ──────────────────────────────────
  // void _handleForegroundMessage(RemoteMessage message) {
  //   final notification = message.notification;
  //   if (notification == null) return;
  //   _showLocalNotification(
  //     id:    message.hashCode,
  //     title: notification.title ?? 'Yeki',
  //     body:  notification.body ?? '',
  //     data:  message.data,
  //   );
  // }

  // ── Gérer tap sur notification ────────────────────────────────
  // void _handleMessageOpenedApp(RemoteMessage message) {
  //   _naviguerDepuisData(message.data);
  // }

  // void _onNotificationTap(NotificationResponse response) {
  //   if (response.payload != null) {
  //     try {
  //       final data = jsonDecode(response.payload!) as Map<String, dynamic>;
  //       _naviguerDepuisData(data);
  //     } catch (_) {}
  //   }
  // }

  // ── Afficher une notification locale ─────────────────────────
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? channelId,
  }) async {
    // NOTE : décommenter quand flutter_local_notifications est installé
    /*
    const androidDetails = AndroidNotificationDetails(
      _channelId, _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: Color(0xFF2884A0),
      playSound: true,
      enableLights: true,
      ledColor: Color(0xFF2884A0),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await FlutterLocalNotificationsPlugin().show(
      id, title, body, details,
      payload: data != null ? jsonEncode(data) : null,
    );
    */
    debugPrint('Local notification: $title - $body');
  }

  // ── Navigation depuis les données de notification ─────────────
  void _naviguerDepuisData(Map<String, dynamic> data) {
    final type    = data['type']?.toString() ?? '';
    final objetId = int.tryParse(data['objet_id']?.toString() ?? '');

    final nav = navigatorKey?.currentState;
    if (nav == null) return;

    switch (type) {
      case 'devoir':
        // nav.pushNamed('/devoir', arguments: {'id': objetId});
        break;
      case 'forum':
        // nav.pushNamed('/forum', arguments: {'questionId': objetId});
        break;
      case 'correction':
        // nav.pushNamed('/resultat', arguments: {'devoirId': objetId});
        break;
      default:
        // nav.pushNamed('/notifications');
        break;
    }
  }

  // ── Envoyer une notification depuis le serveur ────────────────
  /// À appeler après des événements clés :
  ///   - création d'un devoir
  ///   - correction d'une soumission
  ///   - réponse forum
  static Future<void> notifierDepuisApi({
    required List<int> destinataireIds,
    required String type,
    required String titre,
    required String contenu,
    int? objetId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      await http.post(
        Uri.parse('$_baseN/notifications/envoyer/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'destinataires': destinataireIds,
          'type':    type,
          'titre':   titre,
          'contenu': contenu,
          if (objetId != null) 'objet_id': objetId,
        }),
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // ── Demander permission notifications (Android 13+) ───────────
  static Future<bool> demanderPermission() async {
    // NOTE : décommenter quand firebase_messaging est installé
    /*
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized
        || settings.authorizationStatus == AuthorizationStatus.provisional;
    */
    return true;  // stub
  }

  // ── Obtenir le token FCM actuel ───────────────────────────────
  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
    // Ou : return await FirebaseMessaging.instance.getToken();
  }
}

// ═══════════════════════════════════════════════════════════════
//  FICHIER 2 : lib/main.dart — modifications à apporter
// ═══════════════════════════════════════════════════════════════
/*
import 'package:firebase_core/firebase_core.dart';
import 'package:yeki/services/notification_service.dart';

// Gestionnaire background FCM (top-level function obligatoire)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Gestionnaire background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialiser le service de notifications
  NotificationService.navigatorKey = navigatorKey;
  await NotificationService().initialize();
  
  runApp(const YekiApp());
}

class YekiApp extends StatelessWidget {
  const YekiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      // ... reste de votre configuration
    );
  }
}
*/

// ═══════════════════════════════════════════════════════════════
//  FICHIER 3 : android/app/build.gradle — ajouter dans dependencies
// ═══════════════════════════════════════════════════════════════
/*
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-analytics'
}
apply plugin: 'com.google.gms.google-services'
*/

// ═══════════════════════════════════════════════════════════════
//  FICHIER 4 : android/build.gradle — ajouter dans buildscript
// ═══════════════════════════════════════════════════════════════
/*
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
*/

// ═══════════════════════════════════════════════════════════════
//  FICHIER 5 : android/app/src/main/res/values/colors.xml
// ═══════════════════════════════════════════════════════════════
/*
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#2884A0</color>
</resources>
*/

// ═══════════════════════════════════════════════════════════════
//  PUBSPEC.YAML — dépendances à ajouter
// ═══════════════════════════════════════════════════════════════
/*
dependencies:
  flutter:
    sdk: flutter
  
  # Notifications
  firebase_core: ^2.27.0
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
  
  # Existants
  http: ^1.2.0
  shared_preferences: ^2.2.2
  dio: ^5.4.0
  intl: ^0.18.1
  timeago: ^3.6.0
  file_picker: ^8.0.0
*/

// ═══════════════════════════════════════════════════════════════
//  BACKEND — views.py additions pour les notifications
// ═══════════════════════════════════════════════════════════════
/*
# Ajouter dans models.py :

class DeviceToken(models.Model):
    user     = models.ForeignKey(User, on_delete=models.CASCADE, related_name='device_tokens')
    token    = models.CharField(max_length=500)
    platform = models.CharField(max_length=10, default='android')  # android | ios
    created  = models.DateTimeField(auto_now_add=True)
    active   = models.BooleanField(default=True)
    
    class Meta:
        unique_together = ('user', 'token')

# Ajouter dans models.py (modèle notification) :

class Notification(models.Model):
    TYPE_CHOICES = [
        ('devoir',      'Devoir'),
        ('correction',  'Correction'),
        ('forum',       'Forum'),
        ('cours',       'Cours'),
        ('olympiade',   'Olympiade'),
        ('systeme',     'Système'),
    ]
    user        = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    type        = models.CharField(max_length=20, choices=TYPE_CHOICES)
    titre       = models.CharField(max_length=255)
    contenu     = models.TextField()
    lu          = models.BooleanField(default=False)
    timestamp   = models.DateTimeField(auto_now_add=True)
    objet_id    = models.PositiveIntegerField(null=True, blank=True)
    
    class Meta:
        ordering = ['-timestamp']

# Ajouter dans views.py :

class SaveFcmTokenView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        token    = request.data.get('fcm_token')
        platform = request.data.get('platform', 'android')
        if token:
            DeviceToken.objects.update_or_create(
                user=request.user, token=token,
                defaults={'platform': platform, 'active': True}
            )
        return Response({'status': 'ok'})

class ListeNotificationsView(APIView):
    permission_classes = [IsAuthenticated]
    def get(self, request):
        notifs = Notification.objects.filter(user=request.user)[:50]
        data = [{'id': n.id, 'type': n.type, 'titre': n.titre,
                 'contenu': n.contenu, 'lu': n.lu,
                 'timestamp': n.timestamp.isoformat()} for n in notifs]
        return Response(data)

class MarquerNotifLueView(APIView):
    permission_classes = [IsAuthenticated]
    def patch(self, request, notif_id):
        Notification.objects.filter(id=notif_id, user=request.user).update(lu=True)
        return Response({'status': 'ok'})

class MarquerToutesLuesView(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        Notification.objects.filter(user=request.user, lu=False).update(lu=True)
        return Response({'status': 'ok'})

# Helper pour envoyer une notif FCM :
def envoyer_notification_fcm(user, titre, contenu, data=None):
    try:
        import firebase_admin
        from firebase_admin import messaging as fcm
        tokens = list(DeviceToken.objects.filter(user=user, active=True).values_list('token', flat=True))
        if not tokens:
            return
        msg = fcm.MulticastMessage(
            tokens=tokens,
            notification=fcm.Notification(title=titre, body=contenu),
            data=data or {},
            android=fcm.AndroidConfig(priority='high'),
        )
        fcm.send_multicast(msg)
        # Sauvegarder en base
        Notification.objects.create(user=user, type=data.get('type','systeme'),
                                     titre=titre, contenu=contenu)
    except Exception as e:
        pass

# urls.py — ajouter :
# path('notifications/', ListeNotificationsView.as_view(), name='notifications'),
# path('notifications/fcm-token/', SaveFcmTokenView.as_view(), name='fcm-token'),
# path('notifications/<int:notif_id>/lire/', MarquerNotifLueView.as_view(), name='notif-lire'),
# path('notifications/lire-tout/', MarquerToutesLuesView.as_view(), name='notif-lire-tout'),
*/
