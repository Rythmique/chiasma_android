import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour une candidature à une offre d'emploi spécifique
class OfferApplicationModel {
  final String id;
  final String offerId; // ID de l'offre d'emploi
  final String userId; // ID du candidat
  final String candidateName; // Nom du candidat
  final String candidateEmail; // Email du candidat
  final List<String> candidatePhones; // Téléphones du candidat

  // Informations de candidature
  final String? coverLetter; // Lettre de motivation (optionnelle)
  final String? cvUrl; // URL du CV (optionnel)

  // Statut
  final String status; // 'pending', 'accepted', 'rejected', 'withdrawn'

  // Métadonnées
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int viewsCount; // Nombre de fois que l'école a vu cette candidature

  // Informations de l'offre (dénormalisées pour faciliter l'affichage)
  final String jobTitle; // Titre du poste
  final String schoolName; // Nom de l'établissement
  final String schoolId; // ID de l'établissement

  OfferApplicationModel({
    required this.id,
    required this.offerId,
    required this.userId,
    required this.candidateName,
    required this.candidateEmail,
    required this.candidatePhones,
    this.coverLetter,
    this.cvUrl,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.viewsCount = 0,
    required this.jobTitle,
    required this.schoolName,
    required this.schoolId,
  });

  // Helper pour convertir DateTime nullable en Timestamp nullable
  static Timestamp? _dateToTimestamp(DateTime? date) =>
      date != null ? Timestamp.fromDate(date) : null;

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'offerId': offerId,
      'userId': userId,
      'candidateName': candidateName,
      'candidateEmail': candidateEmail,
      'candidatePhones': candidatePhones,
      'coverLetter': coverLetter,
      'cvUrl': cvUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': _dateToTimestamp(updatedAt),
      'viewsCount': viewsCount,
      'jobTitle': jobTitle,
      'schoolName': schoolName,
      'schoolId': schoolId,
    };
  }

  // Créer depuis un document Firestore
  factory OfferApplicationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OfferApplicationModel(
      id: doc.id,
      offerId: data['offerId'] ?? '',
      userId: data['userId'] ?? '',
      candidateName: data['candidateName'] ?? '',
      candidateEmail: data['candidateEmail'] ?? '',
      candidatePhones: List<String>.from(data['candidatePhones'] ?? []),
      coverLetter: data['coverLetter'],
      cvUrl: data['cvUrl'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      viewsCount: data['viewsCount'] ?? 0,
      jobTitle: data['jobTitle'] ?? '',
      schoolName: data['schoolName'] ?? '',
      schoolId: data['schoolId'] ?? '',
    );
  }

  // Copier avec modifications
  OfferApplicationModel copyWith({
    String? id,
    String? offerId,
    String? userId,
    String? candidateName,
    String? candidateEmail,
    List<String>? candidatePhones,
    String? coverLetter,
    String? cvUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? viewsCount,
    String? jobTitle,
    String? schoolName,
    String? schoolId,
  }) {
    return OfferApplicationModel(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      userId: userId ?? this.userId,
      candidateName: candidateName ?? this.candidateName,
      candidateEmail: candidateEmail ?? this.candidateEmail,
      candidatePhones: candidatePhones ?? this.candidatePhones,
      coverLetter: coverLetter ?? this.coverLetter,
      cvUrl: cvUrl ?? this.cvUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewsCount: viewsCount ?? this.viewsCount,
      jobTitle: jobTitle ?? this.jobTitle,
      schoolName: schoolName ?? this.schoolName,
      schoolId: schoolId ?? this.schoolId,
    );
  }

  // Getters
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isWithdrawn => status == 'withdrawn';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      case 'withdrawn':
        return 'Retirée';
      default:
        return 'Inconnu';
    }
  }
}
