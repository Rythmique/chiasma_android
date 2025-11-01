import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_settings_model.dart';

/// Service pour gérer les paramètres de notifications
class NotificationSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'notification_settings';

  /// Obtenir les paramètres de notifications d'un utilisateur
  Future<NotificationSettingsModel> getUserSettings(String userId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(userId).get();

      if (doc.exists) {
        return NotificationSettingsModel.fromFirestore(doc);
      } else {
        // Créer des paramètres par défaut si aucun n'existe
        final defaultSettings = NotificationSettingsModel.defaultSettings(userId);
        await createUserSettings(defaultSettings);
        return defaultSettings;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des paramètres: $e');
      // Retourner les paramètres par défaut en cas d'erreur
      return NotificationSettingsModel.defaultSettings(userId);
    }
  }

  /// Créer les paramètres de notifications pour un utilisateur
  Future<void> createUserSettings(NotificationSettingsModel settings) async {
    try {
      await _firestore.collection(_collectionName).doc(settings.userId).set({
        'userId': settings.userId,
        'messages': settings.messages,
        'newJobOffers': settings.newJobOffers,
        'applicationStatus': settings.applicationStatus,
        'jobRecommendations': settings.jobRecommendations,
        'newApplications': settings.newApplications,
        'offerExpiration': settings.offerExpiration,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Erreur lors de la création des paramètres: $e');
      throw Exception('Erreur lors de la création des paramètres: $e');
    }
  }

  /// Mettre à jour les paramètres de notifications
  Future<void> updateUserSettings(NotificationSettingsModel settings) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(settings.userId)
          .update(settings.toFirestore());
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des paramètres: $e');
      throw Exception('Erreur lors de la mise à jour des paramètres: $e');
    }
  }

  /// Mettre à jour un paramètre spécifique
  Future<void> updateSetting(
    String userId,
    String settingKey,
    bool value,
  ) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        settingKey: value,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du paramètre: $e');
      throw Exception('Erreur lors de la mise à jour du paramètre: $e');
    }
  }

  /// Réinitialiser tous les paramètres aux valeurs par défaut
  Future<void> resetToDefaults(String userId) async {
    try {
      final defaultSettings = NotificationSettingsModel.defaultSettings(userId);
      await updateUserSettings(defaultSettings);
    } catch (e) {
      debugPrint('Erreur lors de la réinitialisation: $e');
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  /// Stream des paramètres de notifications
  Stream<NotificationSettingsModel> streamUserSettings(String userId) {
    return _firestore
        .collection(_collectionName)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return NotificationSettingsModel.fromFirestore(doc);
      } else {
        return NotificationSettingsModel.defaultSettings(userId);
      }
    });
  }
}
