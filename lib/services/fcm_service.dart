import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/services/firestore_service.dart';

/// Service pour gérer les notifications push Firebase Cloud Messaging
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Initialiser FCM et demander les permissions
  Future<void> initialize(String userId) async {
    try {
      // Demander la permission pour les notifications (iOS)
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
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('Utilisateur a accepté les notifications provisoires');
      } else {
        debugPrint('Utilisateur a refusé les notifications');
        return;
      }

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
      debugPrint('Message reçu au premier plan: ${message.notification?.title}');

      if (message.notification != null) {
        debugPrint('Titre: ${message.notification!.title}');
        debugPrint('Corps: ${message.notification!.body}');
      }

      // Vous pouvez afficher une notification locale ici si nécessaire
      // ou un snackbar/toast
    });

    // Handler pour les notifications quand l'app est en arrière-plan et qu'on clique dessus
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification cliquée (app en arrière-plan): ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Vérifier si l'app a été ouverte depuis une notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App ouverte depuis une notification: ${message.notification?.title}');
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
