import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Créer une notification
  Future<String> createNotification(NotificationModel notification) async {
    try {
      final docRef = await _firestore.collection(_collection).add(notification.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la notification: $e');
    }
  }

  // Créer une notification simple
  Future<String> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
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
    return await createNotification(notification);
  }

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

  // Créer des notifications de test
  Future<void> createTestNotifications(String userId) async {
    final notifications = [
      NotificationModel(
        id: '',
        userId: userId,
        type: 'match',
        title: 'Nouveau match',
        message: 'Vous avez un nouveau match avec Jean Kouassi!',
        createdAt: DateTime.now(),
        data: {'profileId': 'mock_user_1'},
      ),
      NotificationModel(
        id: '',
        userId: userId,
        type: 'favorite',
        title: 'Nouveau favori',
        message: 'Marie Koné a ajouté votre profil en favori',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        data: {'profileId': 'mock_user_2'},
      ),
      NotificationModel(
        id: '',
        userId: userId,
        type: 'message',
        title: 'Nouveau message',
        message: 'Vous avez reçu un nouveau message',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        data: {'conversationId': 'conv_123'},
      ),
      NotificationModel(
        id: '',
        userId: userId,
        type: 'system',
        title: 'Mise à jour du système',
        message: 'De nouvelles fonctionnalités sont disponibles!',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (var notification in notifications) {
      await createNotification(notification);
    }
  }
}
