import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour une offre d'emploi publiée par un établissement
class JobOfferModel {
  final String id;
  final String schoolId; // Référence à l'établissement
  final String nomEtablissement;

  // Détails du poste
  final String poste; // Titre du poste
  final List<String> matieres; // Matières concernées
  final List<String> niveaux; // Niveaux (classes)
  final String typeContrat; // "Vacataire", "Fonctionnaire", "CDI", "CDD"

  // Localisation
  final String ville;
  final String commune;

  // Description
  final String description; // Description du poste
  final List<String> exigences; // Exigences (diplômes, expérience, etc.)
  final String? salaire; // Optionnel

  // Métadonnées
  final DateTime createdAt;
  final DateTime? expiresAt; // Date d'expiration de l'offre
  final String status; // 'open', 'closed', 'filled'

  // Statistiques
  final int applicantsCount; // Nombre de candidatures
  final int viewsCount; // Nombre de vues

  JobOfferModel({
    required this.id,
    required this.schoolId,
    required this.nomEtablissement,
    required this.poste,
    required this.matieres,
    required this.niveaux,
    required this.typeContrat,
    required this.ville,
    required this.commune,
    required this.description,
    required this.exigences,
    this.salaire,
    required this.createdAt,
    this.expiresAt,
    this.status = 'open',
    this.applicantsCount = 0,
    this.viewsCount = 0,
  });

  // Helper pour convertir DateTime nullable en Timestamp nullable
  static Timestamp? _dateToTimestamp(DateTime? date) =>
      date != null ? Timestamp.fromDate(date) : null;

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'nomEtablissement': nomEtablissement,
      'poste': poste,
      'matieres': matieres,
      'niveaux': niveaux,
      'typeContrat': typeContrat,
      'ville': ville,
      'commune': commune,
      'description': description,
      'exigences': exigences,
      'salaire': salaire,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': _dateToTimestamp(expiresAt),
      'status': status,
      'applicantsCount': applicantsCount,
      'viewsCount': viewsCount,
    };
  }

  // Créer depuis un document Firestore
  factory JobOfferModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JobOfferModel(
      id: doc.id,
      schoolId: data['schoolId'] ?? '',
      nomEtablissement: data['nomEtablissement'] ?? '',
      poste: data['poste'] ?? '',
      matieres: List<String>.from(data['matieres'] ?? []),
      niveaux: List<String>.from(data['niveaux'] ?? []),
      typeContrat: data['typeContrat'] ?? '',
      ville: data['ville'] ?? '',
      commune: data['commune'] ?? '',
      description: data['description'] ?? '',
      exigences: List<String>.from(data['exigences'] ?? []),
      salaire: data['salaire'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'open',
      applicantsCount: data['applicantsCount'] ?? 0,
      viewsCount: data['viewsCount'] ?? 0,
    );
  }

  // Copier avec modifications
  JobOfferModel copyWith({
    String? id,
    String? schoolId,
    String? nomEtablissement,
    String? poste,
    List<String>? matieres,
    List<String>? niveaux,
    String? typeContrat,
    String? ville,
    String? commune,
    String? description,
    List<String>? exigences,
    String? salaire,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? status,
    int? applicantsCount,
    int? viewsCount,
  }) {
    return JobOfferModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      nomEtablissement: nomEtablissement ?? this.nomEtablissement,
      poste: poste ?? this.poste,
      matieres: matieres ?? this.matieres,
      niveaux: niveaux ?? this.niveaux,
      typeContrat: typeContrat ?? this.typeContrat,
      ville: ville ?? this.ville,
      commune: commune ?? this.commune,
      description: description ?? this.description,
      exigences: exigences ?? this.exigences,
      salaire: salaire ?? this.salaire,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      viewsCount: viewsCount ?? this.viewsCount,
    );
  }

  // Vérifier si l'offre est ouverte
  bool get isOpen => status == 'open';

  // Vérifier si l'offre a expiré
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Obtenir un résumé des matières
  String get matieresString => matieres.join(', ');

  // Obtenir un résumé des niveaux
  String get niveauxString => niveaux.join(', ');

  // Obtenir la localisation complète
  String get localisationComplete => '$commune, $ville';
}
