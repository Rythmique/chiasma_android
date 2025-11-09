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
  final bool showContactInfo;            // Afficher les coordonnées (pour les écoles)
  final int profileViewsCount;           // Nombre de vues du profil (pour les candidats)

  // Système de quotas et abonnements
  final int freeQuotaUsed;               // Quota gratuit utilisé
  final int freeQuotaLimit;              // Limite de quota gratuit selon le type de compte
  final DateTime? verificationExpiresAt; // Date d'expiration de la vérification
  final String? subscriptionDuration;    // Durée choisie: '1_week', '1_month', '3_months', '6_months', '12_months'
  final DateTime? lastQuotaResetDate;    // Date du dernier reset de quota

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
    this.showContactInfo = true,        // Par défaut, les écoles affichent leurs coordonnées
    this.profileViewsCount = 0,         // Par défaut 0 vue
    this.freeQuotaUsed = 0,            // Par défaut 0 quota utilisé
    int? freeQuotaLimit,               // Calculé selon le type de compte si non fourni
    this.verificationExpiresAt,
    this.subscriptionDuration,
    this.lastQuotaResetDate,
  }) : freeQuotaLimit = freeQuotaLimit ?? _getDefaultQuotaLimit(accountType);

  // Calcul du quota gratuit par défaut selon le type de compte
  static int _getDefaultQuotaLimit(String accountType) {
    switch (accountType) {
      case 'teacher_transfer':
        return 5;  // 5 consultations gratuites
      case 'teacher_candidate':
        return 2;  // 2 candidatures gratuites
      case 'school':
        return 1;  // 1 offre d'emploi gratuite
      default:
        return 0;
    }
  }

  // Vérifier si le quota gratuit est épuisé
  bool get isFreeQuotaExhausted => freeQuotaUsed >= freeQuotaLimit;

  // Vérifier si la vérification a expiré
  bool get isVerificationExpired {
    if (verificationExpiresAt == null) return false;
    return DateTime.now().isAfter(verificationExpiresAt!);
  }

  // Vérifier si l'utilisateur peut accéder à l'application
  // L'utilisateur a accès si :
  // - Il a un abonnement actif ET non expiré OU
  // - Il a encore du quota gratuit disponible
  bool get hasAccess =>
    (isVerified && !isVerificationExpired) || !isFreeQuotaExhausted;

  // Calculer le nombre de jours restants avant expiration
  int? get daysUntilExpiration {
    if (verificationExpiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(verificationExpiresAt!)) return 0;
    return verificationExpiresAt!.difference(now).inDays;
  }

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
      'showContactInfo': showContactInfo,
      'profileViewsCount': profileViewsCount,
      'freeQuotaUsed': freeQuotaUsed,
      'freeQuotaLimit': freeQuotaLimit,
      'verificationExpiresAt': verificationExpiresAt != null
          ? Timestamp.fromDate(verificationExpiresAt!)
          : null,
      'subscriptionDuration': subscriptionDuration,
      'lastQuotaResetDate': lastQuotaResetDate != null
          ? Timestamp.fromDate(lastQuotaResetDate!)
          : null,
    };
  }

  // Créer à partir d'un document Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Gestion robuste des timestamps (peuvent être null)
    DateTime now = DateTime.now();
    DateTime createdAt = now;
    DateTime updatedAt = now;

    try {
      if (data['createdAt'] != null) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      }
    } catch (e) {
      // Si erreur de conversion, utiliser la date actuelle
      createdAt = now;
    }

    try {
      if (data['updatedAt'] != null) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      }
    } catch (e) {
      // Si erreur de conversion, utiliser la date actuelle
      updatedAt = now;
    }

    DateTime? verificationExpiresAt;
    try {
      if (data['verificationExpiresAt'] != null) {
        verificationExpiresAt = (data['verificationExpiresAt'] as Timestamp).toDate();
      }
    } catch (e) {
      verificationExpiresAt = null;
    }

    DateTime? lastQuotaResetDate;
    try {
      if (data['lastQuotaResetDate'] != null) {
        lastQuotaResetDate = (data['lastQuotaResetDate'] as Timestamp).toDate();
      }
    } catch (e) {
      lastQuotaResetDate = null;
    }

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
      createdAt: createdAt,
      updatedAt: updatedAt,
      isOnline: data['isOnline'] ?? false,
      isVerified: data['isVerified'] ?? false,
      isAdmin: data['isAdmin'] ?? false,
      showContactInfo: data['showContactInfo'] ?? true, // Par défaut true pour compatibilité
      profileViewsCount: data['profileViewsCount'] ?? 0, // Par défaut 0 pour compatibilité
      freeQuotaUsed: data['freeQuotaUsed'] ?? 0,
      freeQuotaLimit: data['freeQuotaLimit'],
      verificationExpiresAt: verificationExpiresAt,
      subscriptionDuration: data['subscriptionDuration'],
      lastQuotaResetDate: lastQuotaResetDate,
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
    bool? showContactInfo,
    int? profileViewsCount,
    int? freeQuotaUsed,
    int? freeQuotaLimit,
    DateTime? verificationExpiresAt,
    String? subscriptionDuration,
    DateTime? lastQuotaResetDate,
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
      showContactInfo: showContactInfo ?? this.showContactInfo,
      profileViewsCount: profileViewsCount ?? this.profileViewsCount,
      freeQuotaUsed: freeQuotaUsed ?? this.freeQuotaUsed,
      freeQuotaLimit: freeQuotaLimit ?? this.freeQuotaLimit,
      verificationExpiresAt: verificationExpiresAt ?? this.verificationExpiresAt,
      subscriptionDuration: subscriptionDuration ?? this.subscriptionDuration,
      lastQuotaResetDate: lastQuotaResetDate ?? this.lastQuotaResetDate,
    );
  }
}
