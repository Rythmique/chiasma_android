import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';

/// Service pour gérer les annonces
class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'announcements';

  /// Créer une annonce
  Future<String> createAnnouncement(AnnouncementModel announcement) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(announcement.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'annonce: $e');
    }
  }

  /// Mettre à jour une annonce
  Future<void> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(announcementId)
          .update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'annonce: $e');
    }
  }

  /// Supprimer une annonce
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection(_collection).doc(announcementId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'annonce: $e');
    }
  }

  /// Récupérer une annonce par ID
  Future<AnnouncementModel?> getAnnouncement(String announcementId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(announcementId).get();
      if (!doc.exists) return null;
      return AnnouncementModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'annonce: $e');
    }
  }

  /// Stream de toutes les annonces (pour admin)
  Stream<List<AnnouncementModel>> streamAllAnnouncements() {
    return _firestore
        .collection(_collection)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList());
  }

  /// Stream des annonces actives pour un type de compte
  Stream<List<AnnouncementModel>> streamActiveAnnouncementsForAccount(
    String accountType,
  ) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) {
            // Filtrer par type de compte et expiration
            final isForAccount = announcement.targetAccounts.contains('all') ||
                announcement.targetAccounts.contains(accountType);
            final isNotExpired = announcement.expiresAt == null ||
                announcement.expiresAt!.isAfter(now);
            return isForAccount && isNotExpired;
          })
          .toList();
    });
  }

  /// Récupérer les annonces actives pour un type de compte (Future)
  Future<List<AnnouncementModel>> getActiveAnnouncementsForAccount(
    String accountType,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) {
            final isForAccount = announcement.targetAccounts.contains('all') ||
                announcement.targetAccounts.contains(accountType);
            final isNotExpired = announcement.expiresAt == null ||
                announcement.expiresAt!.isAfter(now);
            return isForAccount && isNotExpired;
          })
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des annonces: $e');
    }
  }

  /// Activer/Désactiver une annonce
  Future<void> toggleAnnouncementStatus(
    String announcementId,
    bool isActive,
  ) async {
    try {
      await updateAnnouncement(announcementId, {'isActive': isActive});
    } catch (e) {
      throw Exception('Erreur lors du changement de statut: $e');
    }
  }

  /// Compter les annonces actives
  Future<int> countActiveAnnouncements() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.size;
    } catch (e) {
      throw Exception('Erreur lors du comptage des annonces: $e');
    }
  }

  /// Nettoyer les annonces expirées
  Future<int> cleanExpiredAnnouncements() async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      final snapshot = await _firestore
          .collection(_collection)
          .where('expiresAt', isLessThan: now)
          .where('isActive', isEqualTo: true)
          .get();

      int count = 0;
      for (var doc in snapshot.docs) {
        await doc.reference.update({'isActive': false});
        count++;
      }
      return count;
    } catch (e) {
      throw Exception('Erreur lors du nettoyage des annonces: $e');
    }
  }
}
