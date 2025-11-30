import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/notification_model.dart';
import 'package:myapp/services/notification_settings_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();

  // NOTE: Les notifications push sont envoyées automatiquement par Cloud Functions
  // Voir functions/index.js pour la configuration complète

  Future<String> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(notification.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la notification: $e');
    }
  }

  Future<String> sendNotification({
    required String userId,
    required String createdBy,
    required String type,
    required String title,
    required String message,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final settings = await _settingsService.getUserSettings(userId);

      if (!_shouldSendNotification(type, settings)) {
        return '';
      }

      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        isRead: false,
        relatedId: relatedId,
        data: data,
      );

      return await createNotification(notification);
    } catch (e) {
      final notification = NotificationModel(
        id: '',
        userId: userId,
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        isRead: false,
        relatedId: relatedId,
        data: data,
      );
      return await createNotification(notification);
    }
  }

  bool _shouldSendNotification(String type, dynamic settings) {
    switch (type) {
      case 'message':
        return settings.messages;
      case 'application':
        return settings.newApplications;
      case 'application_status':
        return settings.applicationStatus;
      case 'offer':
        return settings.newJobOffers;
      case 'match':
      case 'favorite':
        return settings.jobRecommendations;
      case 'system':
      default:
        return true;
    }
  }

  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<NotificationModel>> streamUnreadNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<int> streamUnreadCount(String userId) {
    return streamUnreadNotifications(
      userId,
    ).map((notifications) => notifications.length);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la notification: $e');
    }
  }

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

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la notification: $e');
    }
  }

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
