import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/privacy_settings_model.dart';

/// Service pour gérer les paramètres de confidentialité
class PrivacySettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'privacy_settings';

  /// Obtenir les paramètres de confidentialité d'un utilisateur
  Future<PrivacySettingsModel> getUserSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(userId)
          .get();

      if (doc.exists) {
        return PrivacySettingsModel.fromFirestore(doc);
      } else {
        // Créer des paramètres par défaut si aucun n'existe
        final defaultSettings = PrivacySettingsModel.defaultSettings(userId);
        await createUserSettings(defaultSettings);
        return defaultSettings;
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des paramètres: $e');
      // Retourner les paramètres par défaut en cas d'erreur
      return PrivacySettingsModel.defaultSettings(userId);
    }
  }

  /// Créer les paramètres de confidentialité pour un utilisateur
  Future<void> createUserSettings(PrivacySettingsModel settings) async {
    try {
      await _firestore.collection(_collectionName).doc(settings.userId).set({
        'userId': settings.userId,
        'hideProfile': settings.hideProfile,
        'profileVisibility': settings.profileVisibility,
        'hidePhoneNumber': settings.hidePhoneNumber,
        'showOnlineStatus': settings.showOnlineStatus,
        'allowMessages': settings.allowMessages,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Erreur lors de la création des paramètres: $e');
      throw Exception('Erreur lors de la création des paramètres: $e');
    }
  }

  /// Mettre à jour les paramètres de confidentialité
  Future<void> updateUserSettings(PrivacySettingsModel settings) async {
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

  /// Mettre à jour un paramètre spécifique (bool)
  Future<void> updateBoolSetting(
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

  /// Mettre à jour un paramètre spécifique (String)
  Future<void> updateStringSetting(
    String userId,
    String settingKey,
    String value,
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
      final defaultSettings = PrivacySettingsModel.defaultSettings(userId);
      await updateUserSettings(defaultSettings);
    } catch (e) {
      debugPrint('Erreur lors de la réinitialisation: $e');
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  /// Stream des paramètres de confidentialité
  Stream<PrivacySettingsModel> streamUserSettings(String userId) {
    return _firestore.collection(_collectionName).doc(userId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return PrivacySettingsModel.fromFirestore(doc);
      } else {
        return PrivacySettingsModel.defaultSettings(userId);
      }
    });
  }
}
