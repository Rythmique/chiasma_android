import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:myapp/services/firestore_service.dart';

/// Service pour gérer les notifications push Firebase Cloud Messaging
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal de notification pour Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications importantes',
    description:
        'Ce canal est utilisé pour les notifications importantes de Chiasma',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Initialiser FCM et demander les permissions
  Future<void> initialize(String userId) async {
    try {
      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Créer le canal de notification pour Android 8+
      await _createNotificationChannel();

      // Demander la permission pour les notifications (iOS et Android 13+)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Permission de notification: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Utilisateur a accepté les notifications');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('Utilisateur a accepté les notifications provisoires');
      } else {
        debugPrint('Utilisateur a refusé les notifications');
        return;
      }

      // Demander la permission POST_NOTIFICATIONS pour Android 13+
      await _requestAndroidNotificationPermission();

      // Obtenir le token FCM
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // Sauvegarder le token dans Firestore
        await _saveFCMToken(userId, token);
      }

      // Écouter les changements de token
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('Nouveau FCM Token: $newToken');
        _saveFCMToken(userId, newToken);
      });

      // Configurer les handlers de notifications
      _setupMessageHandlers();
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de FCM: $e');
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification cliquée: ${response.payload}');
        // Gérer la navigation ici si nécessaire
      },
    );

    debugPrint('✅ Notifications locales initialisées');
  }

  /// Créer le canal de notification pour Android 8+
  Future<void> _createNotificationChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.createNotificationChannel(_channel);
    debugPrint('✅ Canal de notification créé: ${_channel.id}');
  }

  /// Demander la permission POST_NOTIFICATIONS pour Android 13+
  Future<void> _requestAndroidNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final bool? granted = await androidImplementation
        ?.requestNotificationsPermission();

    if (granted == true) {
      debugPrint('✅ Permission POST_NOTIFICATIONS accordée (Android 13+)');
    } else if (granted == false) {
      debugPrint('❌ Permission POST_NOTIFICATIONS refusée (Android 13+)');
    } else {
      debugPrint(
        '⚠️ Permission POST_NOTIFICATIONS non applicable (Android < 13)',
      );
    }
  }

  /// Afficher une notification locale avec son et vibration
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails
      androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Notifications importantes',
        channelDescription:
            'Ce canal est utilisé pour les notifications importantes de Chiasma',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFF77F00), // Couleur orange Chiasma
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/
            1000, // ID unique basé sur le timestamp
        title,
        body,
        platformDetails,
        payload: payload,
      );

      debugPrint('🔔 Notification locale affichée: $title');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'affichage de la notification locale: $e');
    }
  }

  /// Sauvegarder le token FCM dans Firestore
  Future<void> _saveFCMToken(String userId, String token) async {
    try {
      await _firestoreService.updateUser(userId, {'fcmToken': token});
      debugPrint('Token FCM sauvegardé pour l\'utilisateur $userId');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du token FCM: $e');
    }
  }

  /// Configurer les handlers de notifications
  void _setupMessageHandlers() {
    // Handler pour les notifications quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '📬 Message reçu au premier plan: ${message.notification?.title}',
      );

      if (message.notification != null) {
        debugPrint('Titre: ${message.notification!.title}');
        debugPrint('Corps: ${message.notification!.body}');

        // Afficher une notification locale VISIBLE avec SON et VIBRATION ✅
        _showLocalNotification(
          title: message.notification!.title ?? 'Chiasma',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // Handler pour les notifications quand l'app est en arrière-plan et qu'on clique dessus
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        'Notification cliquée (app en arrière-plan): ${message.notification?.title}',
      );
      _handleNotificationTap(message);
    });

    // Vérifier si l'app a été ouverte depuis une notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          'App ouverte depuis une notification: ${message.notification?.title}',
        );
        _handleNotificationTap(message);
      }
    });
  }

  /// Gérer le tap sur une notification
  void _handleNotificationTap(RemoteMessage message) {
    // Extraire les données de navigation
    final data = message.data;

    if (data.isEmpty) {
      debugPrint('Aucune donnée de navigation dans la notification');
      return;
    }

    // Vous pouvez ajouter la navigation ici en fonction du type de notification
    final type = data['type'] as String?;
    debugPrint('Type de notification: $type');
    debugPrint('Données: $data');

    // Exemple de navigation basée sur le type
    // switch (type) {
    //   case 'message':
    //     // Naviguer vers la conversation
    //     final conversationId = data['conversationId'];
    //     // NavigationService.navigateToChat(conversationId);
    //     break;
    //   case 'application':
    //     // Naviguer vers les candidatures
    //     final offerId = data['offerId'];
    //     // NavigationService.navigateToApplication(offerId);
    //     break;
    //   default:
    //     // Naviguer vers la page des notifications
    //     // NavigationService.navigateToNotifications();
    // }
  }

  /// Se désabonner des notifications (utile lors de la déconnexion)
  Future<void> unsubscribe(String userId) async {
    try {
      // Supprimer le token FCM du profil utilisateur
      await _firestoreService.updateUser(userId, {'fcmToken': null});

      // Supprimer le token local
      await _messaging.deleteToken();

      debugPrint('Désabonné des notifications push');
    } catch (e) {
      debugPrint('Erreur lors du désabonnement: $e');
    }
  }

  /// S'abonner à un topic (utile pour les notifications de groupe)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Abonné au topic: $topic');
    } catch (e) {
      debugPrint('Erreur lors de l\'abonnement au topic: $e');
    }
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Désabonné du topic: $topic');
    } catch (e) {
      debugPrint('Erreur lors du désabonnement du topic: $e');
    }
  }
}

/// Handler pour les messages en arrière-plan (doit être une fonction top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Message reçu en arrière-plan: ${message.notification?.title}');

  // Vous pouvez traiter le message ici si nécessaire
  // mais ne faites PAS d'opérations UI ici
}
