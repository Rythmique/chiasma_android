import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour les paramètres de confidentialité d'un utilisateur
class PrivacySettingsModel {
  final String userId;

  // Visibilité du profil
  final bool hideProfile; // Masquer complètement le profil
  final String profileVisibility; // all, verified, none

  // Informations personnelles
  final bool hidePhoneNumber; // Masquer le numéro de téléphone

  // Activité
  final bool showOnlineStatus; // Afficher le statut en ligne

  // Messagerie
  final bool allowMessages; // Autoriser les messages

  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;

  PrivacySettingsModel({
    required this.userId,
    this.hideProfile = false,
    this.profileVisibility = 'all',
    this.hidePhoneNumber = true,
    this.showOnlineStatus = true,
    this.allowMessages = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Créer depuis Firestore
  factory PrivacySettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrivacySettingsModel(
      userId: doc.id,
      hideProfile: data['hideProfile'] ?? false,
      profileVisibility: data['profileVisibility'] ?? 'all',
      hidePhoneNumber: data['hidePhoneNumber'] ?? true,
      showOnlineStatus: data['showOnlineStatus'] ?? true,
      allowMessages: data['allowMessages'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'hideProfile': hideProfile,
      'profileVisibility': profileVisibility,
      'hidePhoneNumber': hidePhoneNumber,
      'showOnlineStatus': showOnlineStatus,
      'allowMessages': allowMessages,
      'updatedAt': Timestamp.now(),
    };
  }

  /// Créer des paramètres par défaut
  factory PrivacySettingsModel.defaultSettings(String userId) {
    return PrivacySettingsModel(
      userId: userId,
      hideProfile: false,
      profileVisibility: 'all',
      hidePhoneNumber: true,
      showOnlineStatus: true,
      allowMessages: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Copier avec modifications
  PrivacySettingsModel copyWith({
    String? userId,
    bool? hideProfile,
    String? profileVisibility,
    bool? hidePhoneNumber,
    bool? showOnlineStatus,
    bool? allowMessages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrivacySettingsModel(
      userId: userId ?? this.userId,
      hideProfile: hideProfile ?? this.hideProfile,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      hidePhoneNumber: hidePhoneNumber ?? this.hidePhoneNumber,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowMessages: allowMessages ?? this.allowMessages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
