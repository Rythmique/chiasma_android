import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer les restrictions d'accès globales par type de compte
///
/// Permet aux administrateurs d'activer/désactiver les restrictions
/// (quota + vérification) pour chaque type de compte de manière globale.
class AccessRestrictionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Nom du document dans app_config
  static const String _configDocId = 'access_restrictions';

  // Clés pour chaque type de compte
  static const String _teacherTransferKey =
      'teacher_transfer_restrictions_enabled';
  static const String _teacherCandidateKey =
      'teacher_candidate_restrictions_enabled';
  static const String _schoolKey = 'school_restrictions_enabled';

  /// Référence au document de configuration
  DocumentReference get _configDoc =>
      _firestore.collection('app_config').doc(_configDocId);

  /// Stream pour écouter les changements de restrictions en temps réel
  Stream<Map<String, bool>> getRestrictionsStream() {
    return _configDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) {
        // Valeurs par défaut si le document n'existe pas
        return _getDefaultRestrictions();
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        return _getDefaultRestrictions();
      }

      return {
        'teacher_transfer': data[_teacherTransferKey] ?? true,
        'teacher_candidate': data[_teacherCandidateKey] ?? true,
        'school': data[_schoolKey] ?? true,
      };
    });
  }

  /// Récupérer les restrictions actuelles (une seule fois)
  Future<Map<String, bool>> getRestrictions() async {
    try {
      final snapshot = await _configDoc.get();

      if (!snapshot.exists) {
        // Créer le document avec les valeurs par défaut
        await _initializeDefaultRestrictions();
        return _getDefaultRestrictions();
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        return _getDefaultRestrictions();
      }

      return {
        'teacher_transfer': data[_teacherTransferKey] ?? true,
        'teacher_candidate': data[_teacherCandidateKey] ?? true,
        'school': data[_schoolKey] ?? true,
      };
    } catch (e) {
      debugPrint('❌ Error getting restrictions: $e');
      return _getDefaultRestrictions();
    }
  }

  /// Vérifier si les restrictions sont activées pour un type de compte
  Future<bool> areRestrictionsEnabled(String accountType) async {
    try {
      final restrictions = await getRestrictions();
      return restrictions[accountType] ?? true; // Par défaut: activées
    } catch (e) {
      debugPrint('❌ Error checking restrictions for $accountType: $e');
      return true; // Par défaut: activées en cas d'erreur
    }
  }

  /// Mettre à jour les restrictions pour un type de compte
  Future<void> updateRestrictions(String accountType, bool enabled) async {
    try {
      String key;
      switch (accountType) {
        case 'teacher_transfer':
          key = _teacherTransferKey;
          break;
        case 'teacher_candidate':
          key = _teacherCandidateKey;
          break;
        case 'school':
          key = _schoolKey;
          break;
        default:
          throw Exception('Type de compte invalide: $accountType');
      }

      await _configDoc.set({key: enabled}, SetOptions(merge: true));

      debugPrint('✅ Restrictions updated for $accountType: $enabled');
    } catch (e) {
      debugPrint('❌ Error updating restrictions: $e');
      rethrow;
    }
  }

  /// Initialiser le document avec les valeurs par défaut
  Future<void> _initializeDefaultRestrictions() async {
    try {
      await _configDoc.set(
        _getDefaultRestrictionsMap(),
        SetOptions(merge: true),
      );
      debugPrint('✅ Default restrictions initialized');
    } catch (e) {
      debugPrint('❌ Error initializing default restrictions: $e');
    }
  }

  /// Valeurs par défaut (restrictions activées pour tous)
  Map<String, bool> _getDefaultRestrictions() {
    return {
      'teacher_transfer': true,
      'teacher_candidate': true,
      'school': true,
    };
  }

  /// Valeurs par défaut au format Firestore
  Map<String, dynamic> _getDefaultRestrictionsMap() {
    return {
      _teacherTransferKey: true,
      _teacherCandidateKey: true,
      _schoolKey: true,
    };
  }

  /// Réinitialiser toutes les restrictions aux valeurs par défaut
  Future<void> resetToDefaults() async {
    try {
      await _configDoc.set(_getDefaultRestrictionsMap());
      debugPrint('✅ All restrictions reset to defaults');
    } catch (e) {
      debugPrint('❌ Error resetting restrictions: $e');
      rethrow;
    }
  }
}
