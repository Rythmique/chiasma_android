import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les paramètres de notifications d'un utilisateur
class NotificationSettingsModel {
  final String userId;

  // Notifications communes
  final bool messages; // Messages directs

  // Notifications pour les candidats
  final bool newJobOffers; // Nouvelles offres d'emploi
  final bool applicationStatus; // Réponses aux candidatures (accepté/refusé)
  final bool jobRecommendations; // Recommandations personnalisées

  // Notifications pour les écoles
  final bool newApplications; // Nouvelles candidatures
  final bool offerExpiration; // Expiration des offres

  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationSettingsModel({
    required this.userId,
    this.messages = true,
    this.newJobOffers = true,
    this.applicationStatus = true,
    this.jobRecommendations = true,
    this.newApplications = true,
    this.offerExpiration = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis Firestore
  factory NotificationSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationSettingsModel(
      userId: doc.id,
      messages: data['messages'] ?? true,
      newJobOffers: data['newJobOffers'] ?? true,
      applicationStatus: data['applicationStatus'] ?? true,
      jobRecommendations: data['jobRecommendations'] ?? true,
      newApplications: data['newApplications'] ?? true,
      offerExpiration: data['offerExpiration'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'messages': messages,
      'newJobOffers': newJobOffers,
      'applicationStatus': applicationStatus,
      'jobRecommendations': jobRecommendations,
      'newApplications': newApplications,
      'offerExpiration': offerExpiration,
      'updatedAt': Timestamp.now(),
    };
  }

  /// Créer des paramètres par défaut
  factory NotificationSettingsModel.defaultSettings(String userId) {
    return NotificationSettingsModel(
      userId: userId,
      messages: true,
      newJobOffers: true,
      applicationStatus: true,
      jobRecommendations: true,
      newApplications: true,
      offerExpiration: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Copier avec modifications
  NotificationSettingsModel copyWith({
    String? userId,
    bool? messages,
    bool? newJobOffers,
    bool? applicationStatus,
    bool? jobRecommendations,
    bool? newApplications,
    bool? offerExpiration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsModel(
      userId: userId ?? this.userId,
      messages: messages ?? this.messages,
      newJobOffers: newJobOffers ?? this.newJobOffers,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      jobRecommendations: jobRecommendations ?? this.jobRecommendations,
      newApplications: newApplications ?? this.newApplications,
      offerExpiration: offerExpiration ?? this.offerExpiration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
