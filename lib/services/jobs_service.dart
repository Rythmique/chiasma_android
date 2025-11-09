import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/job_application_model.dart';
import '../models/job_offer_model.dart';
import '../models/offer_application_model.dart';
import '../services/notification_service.dart';

/// Service pour gérer les candidatures et offres d'emploi
class JobsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Collections Firestore
  static const String _jobApplicationsCollection = 'job_applications';
  static const String _jobOffersCollection = 'job_offers';
  static const String _offerApplicationsCollection = 'offer_applications';

  // ========== CANDIDATURES ==========

  /// Créer une candidature d'enseignant
  Future<String> createJobApplication(JobApplicationModel application) async {
    try {
      final docRef = await _firestore
          .collection(_jobApplicationsCollection)
          .add(application.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la candidature: $e');
    }
  }

  /// Récupérer la candidature d'un utilisateur
  Future<JobApplicationModel?> getJobApplicationByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_jobApplicationsCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return JobApplicationModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la candidature: $e');
    }
  }

  /// Mettre à jour une candidature
  Future<void> updateJobApplication(
    String applicationId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(_jobApplicationsCollection)
          .doc(applicationId)
          .update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la candidature: $e');
    }
  }

  /// Supprimer une candidature
  Future<void> deleteJobApplication(String applicationId) async {
    try {
      await _firestore
          .collection(_jobApplicationsCollection)
          .doc(applicationId)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la candidature: $e');
    }
  }

  /// Rechercher des candidatures (pour les recruteurs)
  Future<List<JobApplicationModel>> searchJobApplications({
    List<String>? matieres,
    List<String>? niveaux,
    List<String>? zones,
    String? experience,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_jobApplicationsCollection)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true);

      if (matieres != null && matieres.isNotEmpty) {
        query = query.where('matieres', arrayContainsAny: matieres);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => JobApplicationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche de candidatures: $e');
    }
  }

  /// Incrémenter le compteur de vues d'une candidature
  Future<void> incrementApplicationViews(String applicationId) async {
    try {
      await _firestore
          .collection(_jobApplicationsCollection)
          .doc(applicationId)
          .update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'incrémentation des vues: $e');
    }
  }

  /// Incrémenter le compteur de contacts d'une candidature
  Future<void> incrementApplicationContacts(String applicationId) async {
    try {
      await _firestore
          .collection(_jobApplicationsCollection)
          .doc(applicationId)
          .update({
        'contactsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'incrémentation des contacts: $e');
    }
  }

  // ========== OFFRES D'EMPLOI ==========

  /// Créer une offre d'emploi
  Future<String> createJobOffer(JobOfferModel offer) async {
    try {
      final docRef =
          await _firestore.collection(_jobOffersCollection).add(offer.toMap());
      final offerId = docRef.id;

      // Envoyer des notifications aux candidats matchants (en arrière-plan)
      _notifyMatchingCandidates(offer, offerId);

      return offerId;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'offre: $e');
    }
  }

  /// Notifier les candidats qui correspondent aux critères de l'offre
  Future<void> _notifyMatchingCandidates(JobOfferModel offer, String offerId) async {
    try {
      // Rechercher les candidats enseignants (teacher_candidate) qui correspondent
      // Note: On ne peut pas faire de filtres complexes avec Firestore (limitations des where multiples)
      // On récupère tous les candidats autorisés et on filtre en mémoire
      final snapshot = await _firestore.collection('users')
          .where('accountType', isEqualTo: 'teacher_candidate')
          .where('isAuthorized', isEqualTo: true)
          .limit(100) // Limiter pour éviter surcharge
          .get();

      int notificationCount = 0;

      // Envoyer une notification à chaque candidat matchant
      for (var doc in snapshot.docs) {
        try {
          final candidateId = doc.id;
          final candidateData = doc.data() as Map<String, dynamic>?;

          if (candidateData == null) continue;

          // Filtrage côté client pour matcher les critères
          bool isMatch = true;

          // Vérifier si la matière du candidat correspond à l'une des matières de l'offre
          if (offer.matieres.isNotEmpty && candidateData['discipline'] != null) {
            final candidateDiscipline = candidateData['discipline'] as String;
            // Si le candidat a une discipline et l'offre aussi, vérifier la correspondance
            if (!offer.matieres.contains(candidateDiscipline) &&
                !offer.matieres.contains('Toutes matières')) {
              isMatch = false;
            }
          }

          // Vérifier si la zone du candidat correspond à la ville de l'offre
          if (isMatch && candidateData['zone'] != null && offer.ville.isNotEmpty) {
            final candidateZone = candidateData['zone'] as String;
            // Matching simple: si la zone du candidat contient la ville de l'offre ou vice versa
            if (!candidateZone.toLowerCase().contains(offer.ville.toLowerCase()) &&
                !offer.ville.toLowerCase().contains(candidateZone.toLowerCase())) {
              // Pas de match strict, mais on envoie quand même (mieux notifier trop que pas assez)
            }
          }

          // Envoyer la notification si le profil correspond
          if (isMatch) {
            final matieresText = offer.matieres.isEmpty ? '' : ' (${offer.matieres.join(', ')})';

            await _notificationService.sendNotification(
              userId: candidateId,
              type: 'offer',
              title: 'Nouvelle offre d\'emploi',
              message: '${offer.nomEtablissement} recrute pour un poste de ${offer.poste}$matieresText',
              data: {
                'offerId': offerId,
                'schoolId': offer.schoolId,
                'schoolName': offer.nomEtablissement,
                'jobTitle': offer.poste,
                'matieres': offer.matieres.join(', '),
                'ville': offer.ville,
              },
            );
            notificationCount++;
          }
        } catch (e) {
          debugPrint('Erreur lors de l\'envoi de notification au candidat ${doc.id}: $e');
        }
      }

      debugPrint('Notifications envoyées à $notificationCount candidats matchants sur ${snapshot.docs.length}');
    } catch (e) {
      debugPrint('Erreur lors de la notification des candidats matchants: $e');
    }
  }

  /// Récupérer les offres d'un établissement
  Future<List<JobOfferModel>> getJobOffersBySchoolId(String schoolId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_jobOffersCollection)
          .where('schoolId', isEqualTo: schoolId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => JobOfferModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des offres: $e');
    }
  }

  /// Stream des offres d'un établissement (mises à jour en temps réel)
  Stream<List<JobOfferModel>> streamJobOffersBySchoolId(String schoolId) {
    return _firestore
        .collection(_jobOffersCollection)
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => JobOfferModel.fromFirestore(doc)).toList());
  }

  /// Récupérer une offre par ID
  Future<JobOfferModel?> getJobOfferById(String offerId) async {
    try {
      final doc =
          await _firestore.collection(_jobOffersCollection).doc(offerId).get();

      if (!doc.exists) {
        return null;
      }

      return JobOfferModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'offre: $e');
    }
  }

  /// Mettre à jour une offre
  Future<void> updateJobOffer(
    String offerId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection(_jobOffersCollection).doc(offerId).update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'offre: $e');
    }
  }

  /// Supprimer une offre
  Future<void> deleteJobOffer(String offerId) async {
    try {
      await _firestore.collection(_jobOffersCollection).doc(offerId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'offre: $e');
    }
  }

  /// Rechercher des offres d'emploi (pour les candidats)
  Future<List<JobOfferModel>> searchJobOffers({
    List<String>? matieres,
    List<String>? niveaux,
    String? ville,
    String? typeContrat,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_jobOffersCollection)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true);

      if (matieres != null && matieres.isNotEmpty) {
        query = query.where('matieres', arrayContainsAny: matieres);
      }

      if (ville != null && ville.isNotEmpty) {
        query = query.where('ville', isEqualTo: ville);
      }

      if (typeContrat != null && typeContrat.isNotEmpty) {
        query = query.where('typeContrat', isEqualTo: typeContrat);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => JobOfferModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'offres: $e');
    }
  }

  /// Récupérer toutes les offres actives
  Future<List<JobOfferModel>> getActiveJobOffers({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_jobOffersCollection)
          .where('status', isEqualTo: 'active')
          .where('dateExpiration', isGreaterThan: Timestamp.now())
          .orderBy('dateExpiration')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => JobOfferModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des offres: $e');
    }
  }

  /// Incrémenter le compteur de vues d'une offre
  Future<void> incrementOfferViews(String offerId) async {
    try {
      await _firestore.collection(_jobOffersCollection).doc(offerId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'incrémentation des vues: $e');
    }
  }

  /// Incrémenter le compteur de candidatures d'une offre
  Future<void> incrementOfferApplications(String offerId) async {
    try {
      await _firestore.collection(_jobOffersCollection).doc(offerId).update({
        'applicantsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception(
          'Erreur lors de l\'incrémentation des candidatures: $e');
    }
  }

  // ========== STREAM POUR TEMPS RÉEL ==========

  /// Stream des candidatures actives
  Stream<List<JobApplicationModel>> streamActiveApplications({int limit = 20}) {
    return _firestore
        .collection(_jobApplicationsCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JobApplicationModel.fromFirestore(doc))
            .toList());
  }

  /// Stream des offres actives
  Stream<List<JobOfferModel>> streamActiveOffers({int limit = 20}) {
    // Requête simplifiée sans vérification d'expiration pour éviter l'erreur d'index
    // L'index composite sera créé dans Firebase Console
    return _firestore
        .collection(_jobOffersCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => JobOfferModel.fromFirestore(doc)).toList());
  }

  /// Stream des offres ouvertes (pour les candidats)
  /// Accepte 'open' et 'active' pour compatibilité avec anciennes offres
  Stream<List<JobOfferModel>> streamOpenJobOffers({int limit = 50}) {
    return _firestore
        .collection(_jobOffersCollection)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => JobOfferModel.fromFirestore(doc)).toList());
  }

  /// Stream de la candidature d'un utilisateur
  Stream<JobApplicationModel?> streamUserApplication(String userId) {
    return _firestore
        .collection(_jobApplicationsCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return JobApplicationModel.fromFirestore(snapshot.docs.first);
    });
  }

  // ========== CANDIDATURES À DES OFFRES SPÉCIFIQUES ==========

  /// Créer une candidature à une offre
  Future<String> applyToOffer(OfferApplicationModel application) async {
    try {
      final docRef = await _firestore
          .collection(_offerApplicationsCollection)
          .add(application.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la candidature: $e');
    }
  }

  /// Vérifier si un utilisateur a déjà postulé à une offre
  Future<bool> hasUserAppliedToOffer(String userId, String offerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_offerApplicationsCollection)
          .where('userId', isEqualTo: userId)
          .where('offerId', isEqualTo: offerId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification: $e');
    }
  }

  /// Récupérer les candidatures d'un utilisateur
  Future<List<OfferApplicationModel>> getUserApplications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_offerApplicationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OfferApplicationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des candidatures: $e');
    }
  }

  /// Créer une candidature à une offre
  Future<String> createOfferApplication(OfferApplicationModel application) async {
    try {
      final docRef = await _firestore
          .collection(_offerApplicationsCollection)
          .add(application.toMap());

      // Incrémenter le compteur de candidatures de l'offre
      await incrementOfferApplicantsCount(application.offerId);

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la candidature: $e');
    }
  }

  /// Vérifier si un utilisateur a déjà postulé à une offre
  Future<OfferApplicationModel?> getOfferApplicationByUserAndOffer(
    String userId,
    String offerId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_offerApplicationsCollection)
          .where('userId', isEqualTo: userId)
          .where('offerId', isEqualTo: offerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return OfferApplicationModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Erreur lors de la vérification de la candidature: $e');
    }
  }

  /// Récupérer les candidatures pour une offre (pour les recruteurs)
  Future<List<OfferApplicationModel>> getOfferApplications(String offerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_offerApplicationsCollection)
          .where('offerId', isEqualTo: offerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OfferApplicationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des candidatures: $e');
    }
  }

  /// Incrémenter le compteur de vues d'une offre
  Future<void> incrementOfferViewCount(String offerId) async {
    try {
      await _firestore
          .collection(_jobOffersCollection)
          .doc(offerId)
          .update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Erreur silencieuse pour ne pas bloquer l'affichage
    }
  }

  /// Incrémenter le compteur de candidatures d'une offre
  Future<void> incrementOfferApplicantsCount(String offerId) async {
    try {
      await _firestore
          .collection(_jobOffersCollection)
          .doc(offerId)
          .update({
        'applicantsCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Erreur silencieuse
    }
  }

  /// Décrémenter le compteur de candidatures d'une offre
  Future<void> decrementOfferApplicantsCount(String offerId) async {
    try {
      await _firestore
          .collection(_jobOffersCollection)
          .doc(offerId)
          .update({
        'applicantsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      // Erreur silencieuse
    }
  }

  /// Mettre à jour le statut d'une candidature
  Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    try {
      await _firestore
          .collection(_offerApplicationsCollection)
          .doc(applicationId)
          .update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  /// Retirer une candidature (change le statut à 'withdrawn')
  Future<void> withdrawApplication(String applicationId) async {
    try {
      await updateApplicationStatus(applicationId, 'withdrawn');
    } catch (e) {
      throw Exception('Erreur lors du retrait de la candidature: $e');
    }
  }

  /// Supprimer complètement une candidature (suppression de Firestore)
  Future<void> deleteOfferApplication(String applicationId) async {
    try {
      // Récupérer la candidature avant de la supprimer pour avoir l'offerId
      final doc = await _firestore
          .collection(_offerApplicationsCollection)
          .doc(applicationId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final offerId = data?['offerId'] as String?;

        // Supprimer la candidature
        await _firestore
            .collection(_offerApplicationsCollection)
            .doc(applicationId)
            .delete();

        // Décrémenter le compteur de candidatures de l'offre
        if (offerId != null) {
          await decrementOfferApplicantsCount(offerId);
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la candidature: $e');
    }
  }

  /// Stream des candidatures d'un utilisateur
  Stream<List<OfferApplicationModel>> streamUserOfferApplications(String userId) {
    return _firestore
        .collection(_offerApplicationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OfferApplicationModel.fromFirestore(doc))
            .toList());
  }

  /// Stream des candidatures pour une offre
  Stream<List<OfferApplicationModel>> streamOfferApplications(String offerId) {
    return _firestore
        .collection(_offerApplicationsCollection)
        .where('offerId', isEqualTo: offerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OfferApplicationModel.fromFirestore(doc))
            .toList());
  }

  /// Incrémenter le compteur de vues d'une candidature
  Future<void> incrementApplicationViewCount(String applicationId) async {
    try {
      await _firestore
          .collection(_offerApplicationsCollection)
          .doc(applicationId)
          .update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Erreur silencieuse pour ne pas bloquer l'affichage
    }
  }
}
