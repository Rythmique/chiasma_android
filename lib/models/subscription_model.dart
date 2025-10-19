import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionType {
  monthly,   // 1 mois - 500 FCFA
  quarterly, // 3 mois - 1500 FCFA
  yearly,    // 12 mois - 5000 FCFA
}

enum SubscriptionStatus {
  active,
  expired,
  cancelled,
}

class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionType type;
  final SubscriptionStatus status;
  final int amountPaid; // En FCFA
  final DateTime startDate;
  final DateTime endDate;
  final String? transactionId; // ID de transaction MoneyFusion
  final String? paymentMethod; // orange_money, mtn_money, moov_money
  final DateTime createdAt;
  final DateTime? cancelledAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.amountPaid,
    required this.startDate,
    required this.endDate,
    this.transactionId,
    this.paymentMethod,
    required this.createdAt,
    this.cancelledAt,
  });

  // Vérifier si l'abonnement est actif
  bool get isActive {
    return status == SubscriptionStatus.active &&
           DateTime.now().isBefore(endDate);
  }

  // Vérifier si l'abonnement est expiré
  bool get isExpired {
    return DateTime.now().isAfter(endDate) ||
           status == SubscriptionStatus.expired;
  }

  // Obtenir le nombre de jours restants
  int get daysRemaining {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'amountPaid': amountPaid,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
    };
  }

  // Créer à partir d'un document Firestore
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SubscriptionType.monthly,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SubscriptionStatus.expired,
      ),
      amountPaid: data['amountPaid'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      transactionId: data['transactionId'],
      paymentMethod: data['paymentMethod'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Copier avec modifications
  SubscriptionModel copyWith({
    String? id,
    String? userId,
    SubscriptionType? type,
    SubscriptionStatus? status,
    int? amountPaid,
    DateTime? startDate,
    DateTime? endDate,
    String? transactionId,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? cancelledAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      amountPaid: amountPaid ?? this.amountPaid,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  // Obtenir le prix selon le type
  static int getPrice(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return 500;  // 1 mois - 500 FCFA
      case SubscriptionType.quarterly:
        return 1500; // 3 mois - 1500 FCFA
      case SubscriptionType.yearly:
        return 5000; // 12 mois - 5000 FCFA
    }
  }

  // Obtenir la durée en mois selon le type
  static int getDurationMonths(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return 1;
      case SubscriptionType.quarterly:
        return 3;
      case SubscriptionType.yearly:
        return 12;
    }
  }

  // Obtenir le label du type
  static String getTypeLabel(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return '1 mois';
      case SubscriptionType.quarterly:
        return '3 mois';
      case SubscriptionType.yearly:
        return '12 mois';
    }
  }
}

// Modèle pour la configuration globale de l'application
class AppConfigModel {
  final bool subscriptionSystemEnabled; // Toggle pour activer/désactiver le système
  final int freeConsultationsLimit;     // Nombre de consultations gratuites (5)
  final DateTime updatedAt;
  final String? updatedBy;              // UID de l'admin qui a fait la modification

  AppConfigModel({
    required this.subscriptionSystemEnabled,
    this.freeConsultationsLimit = 5,
    required this.updatedAt,
    this.updatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'subscriptionSystemEnabled': subscriptionSystemEnabled,
      'freeConsultationsLimit': freeConsultationsLimit,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  factory AppConfigModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppConfigModel(
      subscriptionSystemEnabled: data['subscriptionSystemEnabled'] ?? false,
      freeConsultationsLimit: data['freeConsultationsLimit'] ?? 5,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'],
    );
  }

  AppConfigModel copyWith({
    bool? subscriptionSystemEnabled,
    int? freeConsultationsLimit,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AppConfigModel(
      subscriptionSystemEnabled: subscriptionSystemEnabled ?? this.subscriptionSystemEnabled,
      freeConsultationsLimit: freeConsultationsLimit ?? this.freeConsultationsLimit,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
