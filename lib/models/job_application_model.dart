import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour une candidature d'enseignant
class JobApplicationModel {
  final String id;
  final String userId; // Référence au candidat
  final String nom;
  final String email;
  final List<String> telephones;

  // Informations professionnelles
  final List<String>
  matieres; // Matières enseignées (ex: Mathématiques, Physique)
  final List<String> niveaux; // Niveaux (ex: 6ème, 5ème, Terminale)
  final List<String> diplomes; // Diplômes obtenus
  final String experience; // Années d'expérience (ex: "5 ans", "Débutant")

  // Localisation et disponibilité
  final List<String> zonesSouhaitees; // Villes/zones souhaitées
  final String disponibilite; // "Immédiate", "Dans 1 mois", etc.

  // Documents (optionnels)
  final String? cvUrl; // URL du CV uploadé
  final String? lettreMotivationUrl; // URL de la lettre
  final String? photoUrl; // Photo du candidat

  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'active', 'hired', 'inactive'

  // Statistiques
  final int viewsCount; // Nombre de vues par recruteurs
  final int contactsCount; // Nombre de contacts reçus

  JobApplicationModel({
    required this.id,
    required this.userId,
    required this.nom,
    required this.email,
    required this.telephones,
    required this.matieres,
    required this.niveaux,
    required this.diplomes,
    required this.experience,
    required this.zonesSouhaitees,
    required this.disponibilite,
    this.cvUrl,
    this.lettreMotivationUrl,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
    this.viewsCount = 0,
    this.contactsCount = 0,
  });

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nom': nom,
      'email': email,
      'telephones': telephones,
      'matieres': matieres,
      'niveaux': niveaux,
      'diplomes': diplomes,
      'experience': experience,
      'zonesSouhaitees': zonesSouhaitees,
      'disponibilite': disponibilite,
      'cvUrl': cvUrl,
      'lettreMotivationUrl': lettreMotivationUrl,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
      'viewsCount': viewsCount,
      'contactsCount': contactsCount,
    };
  }

  // Créer depuis un document Firestore
  factory JobApplicationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JobApplicationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      nom: data['nom'] ?? '',
      email: data['email'] ?? '',
      telephones: List<String>.from(data['telephones'] ?? []),
      matieres: List<String>.from(data['matieres'] ?? []),
      niveaux: List<String>.from(data['niveaux'] ?? []),
      diplomes: List<String>.from(data['diplomes'] ?? []),
      experience: data['experience'] ?? '',
      zonesSouhaitees: List<String>.from(data['zonesSouhaitees'] ?? []),
      disponibilite: data['disponibilite'] ?? '',
      cvUrl: data['cvUrl'],
      lettreMotivationUrl: data['lettreMotivationUrl'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      viewsCount: data['viewsCount'] ?? 0,
      contactsCount: data['contactsCount'] ?? 0,
    );
  }

  // Copier avec modifications
  JobApplicationModel copyWith({
    String? id,
    String? userId,
    String? nom,
    String? email,
    List<String>? telephones,
    List<String>? matieres,
    List<String>? niveaux,
    List<String>? diplomes,
    String? experience,
    List<String>? zonesSouhaitees,
    String? disponibilite,
    String? cvUrl,
    String? lettreMotivationUrl,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    int? viewsCount,
    int? contactsCount,
  }) {
    return JobApplicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      telephones: telephones ?? this.telephones,
      matieres: matieres ?? this.matieres,
      niveaux: niveaux ?? this.niveaux,
      diplomes: diplomes ?? this.diplomes,
      experience: experience ?? this.experience,
      zonesSouhaitees: zonesSouhaitees ?? this.zonesSouhaitees,
      disponibilite: disponibilite ?? this.disponibilite,
      cvUrl: cvUrl ?? this.cvUrl,
      lettreMotivationUrl: lettreMotivationUrl ?? this.lettreMotivationUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      viewsCount: viewsCount ?? this.viewsCount,
      contactsCount: contactsCount ?? this.contactsCount,
    );
  }

  // Vérifier si la candidature est active
  bool get isActive => status == 'active';

  // Obtenir un résumé des matières
  String get matieresString => matieres.join(', ');

  // Obtenir un résumé des niveaux
  String get niveauxString => niveaux.join(', ');

  // Obtenir un résumé des zones souhaitées
  String get zonesString => zonesSouhaitees.join(', ');
}
