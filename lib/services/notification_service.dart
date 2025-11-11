import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/notification_model.dart';
import 'package:myapp/services/notification_settings_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';
  final NotificationSettingsService _settingsService = NotificationSettingsService();

  // NOTE: Les notifications push sont envoyées automatiquement par Cloud Functions
  // Voir functions/index.js pour la configuration complète

  // Créer une notification
  Future<String> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _firestore.collection(_collection).add(notification.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la notification: $e');
    }
  }

  // Créer une notification simple avec vérification des paramètres utilisateur
  Future<String> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Récupérer les paramètres de notification de l'utilisateur
      final settings = await _settingsService.getUserSettings(userId);

      // Vérifier si l'utilisateur a activé ce type de notification
      bool shouldSend = true;

      switch (type) {
        case 'message':
          shouldSend = settings.messages;
          break;
        case 'application':
          shouldSend = settings.newApplications;
          break;
        case 'application_status':
          shouldSend = settings.applicationStatus;
          break;
        case 'offer':
          shouldSend = settings.newJobOffers;
          break;
        case 'match':
        case 'favorite':
          shouldSend = settings.jobRecommendations;
          break;
        case 'system':
          // Les notifications système sont toujours envoyées
          shouldSend = true;
          break;
        default:
          // Par défaut, envoyer la notification
          shouldSend = true;
      }

      // Ne pas envoyer si l'utilisateur a désactivé ce type
      if (!shouldSend) {
        return ''; // Retourner un ID vide si la notification n'est pas envoyée
      }

      // Créer et envoyer la notification dans Firestore
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        isRead: false,
        data: data,
      );
      final notificationId = await createNotification(notification);

      // NOTE: Les notifications push sont maintenant envoyées automatiquement
      // par Cloud Functions quand une notification est créée dans Firestore.
      // Voir functions/index.js pour la configuration du son et de la vibration.

      // Si vous n'utilisez pas Cloud Functions, décommentez les lignes ci-dessous:
      // await _sendPushNotification(
      //   userId: userId,
      //   title: title,
      //   body: message,
      //   data: data ?? {},
      // );

      return notificationId;
    } catch (e) {
      // En cas d'erreur lors de la vérification des paramètres, envoyer quand même la notification
      // pour ne pas perdre d'informations importantes
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        isRead: false,
        data: data,
      );
      final notificationId = await createNotification(notification);

      // NOTE: Les notifications push sont envoyées automatiquement par Cloud Functions
      // Si vous n'utilisez pas Cloud Functions, décommentez:
      // try {
      //   await _sendPushNotification(
      //     userId: userId,
      //     title: title,
      //     body: message,
      //     data: data ?? {},
      //   );
      // } catch (pushError) {
      //   debugPrint('Erreur lors de l\'envoi de la notification push: $pushError');
      // }

      return notificationId;
    }
  }

  // La méthode _sendPushNotification a été supprimée car les notifications push
  // sont maintenant gérées automatiquement par Cloud Functions (voir functions/index.js)
  //
  // Avantages de cette approche:
  // ✅ Plus sécurisé (pas de clé serveur dans le code client)
  // ✅ Automatique (trigger Firestore)
  // ✅ Son et vibration configurés côté serveur
  // ✅ Gestion centralisée des erreurs

  // Récupérer toutes les notifications d'un utilisateur (stream)
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Récupérer les notifications non lues
  Stream<List<NotificationModel>> streamUnreadNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Compter les notifications non lues
  Stream<int> streamUnreadCount(String userId) {
    return streamUnreadNotifications(userId).map((notifications) => notifications.length);
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la notification: $e');
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des notifications: $e');
    }
  }

  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la notification: $e');
    }
  }

  // Supprimer toutes les notifications d'un utilisateur
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erreur lors de la suppression des notifications: $e');
    }
  }

  // Supprimer les notifications anciennes (plus de 30 jours)
  Future<int> cleanOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldNotifications = await _firestore
          .collection(_collection)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return oldNotifications.docs.length;
    } catch (e) {
      throw Exception('Erreur lors du nettoyage des notifications: $e');
    }
  }

}
