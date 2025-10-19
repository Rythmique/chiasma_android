import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String accountType;             // 'teacher_transfer', 'teacher_candidate', 'school'
  final String matricule;
  final String nom;
  final List<String> telephones;
  final String fonction;
  final String zoneActuelle;
  final String? dren;
  final String infosZoneActuelle;
  final List<String> zonesSouhaitees;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOnline;
  final bool isVerified;
  final bool isAdmin;
  final int profileViewsCount;           // Nombre de consultations de profils effectuées
  final int freeViewsRemaining;          // Consultations gratuites restantes
  final bool hasActiveSubscription;      // Possède un abonnement actif
  final DateTime? subscriptionEndDate;   // Date de fin de l'abonnement actuel

  UserModel({
    required this.uid,
    required this.email,
    this.accountType = 'teacher_transfer', // Par défaut pour compatibilité avec comptes existants
    required this.matricule,
    required this.nom,
    required this.telephones,
    required this.fonction,
    required this.zoneActuelle,
    this.dren,
    required this.infosZoneActuelle,
    required this.zonesSouhaitees,
    required this.createdAt,
    required this.updatedAt,
    this.isOnline = false,
    this.isVerified = false,
    this.isAdmin = false,
    this.profileViewsCount = 0,
    this.freeViewsRemaining = 5,        // 5 consultations gratuites par défaut
    this.hasActiveSubscription = false,
    this.subscriptionEndDate,
  });

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'accountType': accountType,
      'matricule': matricule,
      'nom': nom,
      'telephones': telephones,
      'fonction': fonction,
      'zoneActuelle': zoneActuelle,
      'dren': dren,
      'infosZoneActuelle': infosZoneActuelle,
      'zonesSouhaitees': zonesSouhaitees,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isOnline': isOnline,
      'isVerified': isVerified,
      'isAdmin': isAdmin,
      'profileViewsCount': profileViewsCount,
      'freeViewsRemaining': freeViewsRemaining,
      'hasActiveSubscription': hasActiveSubscription,
      'subscriptionEndDate': subscriptionEndDate != null
          ? Timestamp.fromDate(subscriptionEndDate!)
          : null,
    };
  }

  // Créer à partir d'un document Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      accountType: data['accountType'] ?? 'teacher_transfer', // Par défaut pour compatibilité
      matricule: data['matricule'] ?? '',
      nom: data['nom'] ?? '',
      telephones: List<String>.from(data['telephones'] ?? []),
      fonction: data['fonction'] ?? '',
      zoneActuelle: data['zoneActuelle'] ?? '',
      dren: data['dren'],
      infosZoneActuelle: data['infosZoneActuelle'] ?? '',
      zonesSouhaitees: List<String>.from(data['zonesSouhaitees'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isOnline: data['isOnline'] ?? false,
      isVerified: data['isVerified'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      profileViewsCount: data['profileViewsCount'] ?? 0,
      freeViewsRemaining: data['freeViewsRemaining'] ?? 5,
      hasActiveSubscription: data['hasActiveSubscription'] ?? false,
      subscriptionEndDate: data['subscriptionEndDate'] != null
          ? (data['subscriptionEndDate'] as Timestamp).toDate()
          : null,
    );
  }

  // Copier avec modifications
  UserModel copyWith({
    String? uid,
    String? email,
    String? accountType,
    String? matricule,
    String? nom,
    List<String>? telephones,
    String? fonction,
    String? zoneActuelle,
    String? dren,
    String? infosZoneActuelle,
    List<String>? zonesSouhaitees,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    bool? isVerified,
    bool? isAdmin,
    int? profileViewsCount,
    int? freeViewsRemaining,
    bool? hasActiveSubscription,
    DateTime? subscriptionEndDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      accountType: accountType ?? this.accountType,
      matricule: matricule ?? this.matricule,
      nom: nom ?? this.nom,
      telephones: telephones ?? this.telephones,
      fonction: fonction ?? this.fonction,
      zoneActuelle: zoneActuelle ?? this.zoneActuelle,
      dren: dren ?? this.dren,
      infosZoneActuelle: infosZoneActuelle ?? this.infosZoneActuelle,
      zonesSouhaitees: zonesSouhaitees ?? this.zonesSouhaitees,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      profileViewsCount: profileViewsCount ?? this.profileViewsCount,
      freeViewsRemaining: freeViewsRemaining ?? this.freeViewsRemaining,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }

  // Vérifier si l'utilisateur peut consulter des profils
  bool canViewProfiles(bool subscriptionSystemEnabled) {
    // Si le système d'abonnement est désactivé, tout le monde a accès illimité
    if (!subscriptionSystemEnabled) return true;

    // Si l'utilisateur a un abonnement actif, il a accès illimité
    if (hasActiveSubscription && subscriptionEndDate != null) {
      if (DateTime.now().isBefore(subscriptionEndDate!)) {
        return true;
      }
    }

    // Sinon, vérifier s'il reste des consultations gratuites
    return freeViewsRemaining > 0;
  }

  // Obtenir le statut de l'utilisateur
  String getSubscriptionStatus(bool subscriptionSystemEnabled) {
    if (!subscriptionSystemEnabled) return 'unlimited_free';
    if (hasActiveSubscription && subscriptionEndDate != null &&
        DateTime.now().isBefore(subscriptionEndDate!)) {
      return 'premium';
    }
    if (freeViewsRemaining > 0) return 'free_limited';
    return 'expired';
  }
}
