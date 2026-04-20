// lib/services/notification_service.dart
//
// SERVICE COMPLET DE NOTIFICATIONS YEKI avec awesome_notifications
// ─────────────────────────────────────────────────────────────────


import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

//const String _baseN = 'https://yeki.pythonanywhere.com/api';

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
      await _initAwesomeNotifications();
      _initialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  // ── Awesome Notifications ─────────────────────────────────────
  Future<void> _initAwesomeNotifications() async {
    // Initialiser Awesome Notifications
    await AwesomeNotifications().initialize(
      null, // Utilise les ressources par défaut
      [
        NotificationChannel(
          channelKey: 'devoirs_channel',
          channelName: 'Devoirs et exercices',
          channelDescription: 'Notifications pour les devoirs et exercices',
          defaultColor: const Color(0xFF135F74),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'cours_channel',
          channelName: 'Cours et leçons',
          channelDescription: 'Notifications pour les cours et leçons',
          defaultColor: const Color(0xFF135F74),
          ledColor: Colors.white,
          importance: NotificationImportance.Default,
          channelShowBadge: true,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: 'forum_channel',
          channelName: 'Forum',
          channelDescription: 'Notifications du forum',
          defaultColor: const Color(0xFF8B5CF6),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
        ),
        NotificationChannel(
          channelKey: 'general_channel',
          channelName: 'Informations générales',
          channelDescription: 'Notifications générales de la plateforme',
          defaultColor: const Color(0xFF135F74),
          ledColor: Colors.white,
          importance: NotificationImportance.Default,
          channelShowBadge: true,
          playSound: true,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'yeki_group',
          channelGroupName: 'Yéki Notifications',
        ),
      ],
    );

    // Écouter les événements de notification
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onDismissActionReceived,
    );

    // Demander les permissions nécessaires
    await _requestPermissions();

    debugPrint('AwesomeNotifications initialized');
  }

  // Demander les permissions
  Future<void> _requestPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // ── Callbacks Awesome Notifications ───────────────────────────
  Future<void> _onActionReceived(ReceivedAction action) async {
    debugPrint('Notification action received: ${action.toMap()}');
    
    // Naviguer selon les données
    final payload = action.payload;
    if (payload != null && payload.isNotEmpty) {
      _naviguerDepuisData(payload);
    }
  }

  Future<void> _onNotificationCreated(ReceivedNotification notification) async {
    debugPrint('Notification created: ${notification.id}');
  }

  Future<void> _onNotificationDisplayed(ReceivedNotification notification) async {
    debugPrint('Notification displayed: ${notification.id}');
  }

  Future<void> _onDismissActionReceived(ReceivedAction action) async {
    debugPrint('Notification dismissed: ${action.toMap()}');
  }

  // ── Afficher une notification ─────────────────────────────────
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelKey,
    Map<String, String>? payload,
    String? largeIcon,
    String? summary,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey ?? 'general_channel',
          title: title,
          body: body,
          payload: payload,
          largeIcon: largeIcon,
          notificationLayout: NotificationLayout.Default,
          displayOnBackground: true,
          displayOnForeground: true,
          color: const Color(0xFF135F74),
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'OPEN',
            label: 'Ouvrir',
            autoDismissible: true,
          ),
          NotificationActionButton(
            key: 'DISMISS',
            label: 'Ignorer',
            autoDismissible: true,
            isDangerousOption: true,
          ),
        ],
      );
      debugPrint('Notification sent: $id - $title');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // ── Notification avec progression (téléchargement) ────────────
  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    int maxProgress = 100,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'general_channel',
          title: title,
          body: body,
          notificationLayout: NotificationLayout.ProgressBar,
          progress: progress,
          progressMax: maxProgress,
          color: const Color(0xFF135F74),
          displayOnBackground: true,
          displayOnForeground: true,
        ),
      );
    } catch (e) {
      debugPrint('Error showing progress notification: $e');
    }
  }

  // ── Notification avec image ───────────────────────────────────
  Future<void> showImageNotification({
    required int id,
    required String title,
    required String body,
    required String imageUrl,
    String? channelKey,
    Map<String, String>? payload,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey ?? 'general_channel',
          title: title,
          body: body,
          bigPicture: imageUrl,
          notificationLayout: NotificationLayout.BigPicture,
          payload: payload,
          color: const Color(0xFF135F74),
          displayOnBackground: true,
          displayOnForeground: true,
        ),
      );
    } catch (e) {
      debugPrint('Error showing image notification: $e');
    }
  }

  // ── Notification pour rappel de devoir ────────────────────────
  Future<void> showDevoirNotification({
    required int devoirId,
    required String titre,
    required DateTime dateLimite,
  }) async {
    final daysLeft = dateLimite.difference(DateTime.now()).inDays;
    
    String body;
    if (daysLeft == 0) {
      body = '⚠️ Votre devoir "$titre" expire aujourd\'hui !';
    } else if (daysLeft == 1) {
      body = '📝 Votre devoir "$titre" expire demain.';
    } else if (daysLeft <= 3) {
      body = '⏰ Plus que $daysLeft jours pour rendre "$titre".';
    } else {
      body = '📚 N\'oubliez pas votre devoir "$titre" dans $daysLeft jours.';
    }
    
    await showNotification(
      id: devoirId,
      title: 'Rappel de devoir',
      body: body,
      channelKey: 'devoirs_channel',
      payload: {'type': 'devoir', 'id': devoirId.toString()},
    );
  }

  // ── Notification pour nouvelle leçon ──────────────────────────
  Future<void> showNouvelleLeconNotification({
    required int leconId,
    required String titre,
    required String coursTitre,
  }) async {
    await showNotification(
      id: leconId,
      title: '📖 Nouvelle leçon disponible',
      body: '$titre - $coursTitre',
      channelKey: 'cours_channel',
      payload: {'type': 'lecon', 'id': leconId.toString()},
    );
  }

  // ── Notification pour résultat d'exercice ─────────────────────
  Future<void> showResultatNotification({
    required int exerciceId,
    required String titre,
    required double note,
    required double noteSur,
  }) async {
    final pourcentage = (note / noteSur * 100).round();
    String emoji = pourcentage >= 75 ? '🎉' : (pourcentage >= 50 ? '👍' : '📚');
    
    await showNotification(
      id: exerciceId,
      title: '$emoji Résultat de l\'exercice',
      body: 'Vous avez obtenu ${note.toStringAsFixed(1)}/$noteSur ($pourcentage%) à "$titre"',
      channelKey: 'cours_channel',
      payload: {'type': 'exercice', 'id': exerciceId.toString()},
    );
  }

  // ── Notification pour nouvelle réponse dans le forum ──────────
  Future<void> showNouvelleReponseNotification({
    required int questionId,
    required String questionTitre,
    required String auteurNom,
  }) async {
    await showNotification(
      id: questionId,
      title: '💬 Nouvelle réponse dans le forum',
      body: '$auteurNom a répondu à "$questionTitre"',
      channelKey: 'forum_channel',
      payload: {'type': 'forum', 'id': questionId.toString()},
    );
  }

  // ── Notification pour correction de devoir ────────────────────
  Future<void> showCorrectionNotification({
    required int devoirId,
    required String titre,
    required double note,
    required double noteSur,
  }) async {
    await showNotification(
      id: devoirId,
      title: '✅ Devoir corrigé',
      body: 'Votre devoir "$titre" a été corrigé. Note: ${note.toStringAsFixed(1)}/$noteSur',
      channelKey: 'devoirs_channel',
      payload: {'type': 'devoir_corrige', 'id': devoirId.toString()},
    );
  }

  // ── Notification programmée (rappel) ──────────────────────────
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? channelKey,
    Map<String, String>? payload,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey ?? 'general_channel',
          title: title,
          body: body,
          payload: payload,
          color: const Color(0xFF135F74),
          displayOnBackground: true,
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledTime,
          allowWhileIdle: true,
        ),
      );
      debugPrint('Scheduled notification: $id at $scheduledTime');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // ── Annuler une notification ──────────────────────────────────
  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  // ── Annuler toutes les notifications ──────────────────────────
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  // ── Obtenir les notifications actives ─────────────────────────
  Future<List<ReceivedNotification>> getActiveNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }

  // ── Navigation depuis les données de notification ─────────────
  void _naviguerDepuisData(Map<String, String> payload) {
    final type = payload['type'] ?? '';
    final id = int.tryParse(payload['id'] ?? '');

    final nav = navigatorKey?.currentState;
    if (nav == null) return;

    switch (type) {
      case 'devoir':
        nav.pushNamed('/devoir', arguments: {'id': id});
        break;
      case 'devoir_corrige':
        nav.pushNamed('/resultat-devoir', arguments: {'id': id});
        break;
      case 'lecon':
        nav.pushNamed('/lecon', arguments: {'id': id});
        break;
      case 'exercice':
        nav.pushNamed('/exercice', arguments: {'id': id});
        break;
      case 'forum':
        nav.pushNamed('/forum-question', arguments: {'id': id});
        break;
      default:
        nav.pushNamed('/notifications');
        break;
    }
  }

  // ── Navigation depuis les données JSON ────────────────────────
  void _naviguerDepuisDataJson(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final objetId = int.tryParse(data['objet_id']?.toString() ?? '');

    final nav = navigatorKey?.currentState;
    if (nav == null) return;

    switch (type) {
      case 'devoir':
        nav.pushNamed('/devoir', arguments: {'id': objetId});
        break;
      case 'devoir_corrige':
        nav.pushNamed('/resultat-devoir', arguments: {'id': objetId});
        break;
      case 'lecon':
        nav.pushNamed('/lecon', arguments: {'id': objetId});
        break;
      case 'forum':
        nav.pushNamed('/forum-question', arguments: {'id': objetId});
        break;
      default:
        nav.pushNamed('/notifications');
        break;
    }
  }

  // ── Vérifier si les notifications sont autorisées ─────────────
  Future<bool> areNotificationsAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  // ── Demander explicitement la permission ──────────────────────
  Future<void> requestPermission() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}