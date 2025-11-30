import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/job_application_model.dart';
import '../models/job_offer_model.dart';
import '../models/offer_application_model.dart';
import '../services/notification_service.dart';

class JobsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  static const String _jobApplicationsCollection = 'job_applications';
  static const String _jobOffersCollection = 'job_offers';
  static const String _offerApplicationsCollection = 'offer_applications';

  // ========== CANDIDATURES ==========

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

  Future<JobApplicationModel?> getJobApplicationByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_jobApplicationsCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return JobApplicationModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la candidature: $e');
    }
  }

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

  Future<void> _incrementField(
    String collection,
    String docId,
    String field,
  ) async {
    try {
      await _firestore.collection(collection).doc(docId).update({
        field: FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'incrémentation: $e');
    }
  }

  Future<void> incrementApplicationViews(String applicationId) =>
      _incrementField(_jobApplicationsCollection, applicationId, 'viewsCount');

  Future<void> incrementApplicationContacts(String applicationId) =>
      _incrementField(
        _jobApplicationsCollection,
        applicationId,
        'contactsCount',
      );

  // ========== OFFRES D'EMPLOI ==========

  Future<String> createJobOffer(JobOfferModel offer) async {
    try {
      final docRef = await _firestore
          .collection(_jobOffersCollection)
          .add(offer.toMap());
      final offerId = docRef.id;
      _notifyMatchingCandidates(offer, offerId);
      return offerId;
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'offre: $e');
    }
  }

  Future<void> _notifyMatchingCandidates(
    JobOfferModel offer,
    String offerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('accountType', isEqualTo: 'teacher_candidate')
          .where('isAuthorized', isEqualTo: true)
          .limit(100)
          .get();

      int notificationCount = 0;

      for (var doc in snapshot.docs) {
        try {
          final candidateData = doc.data();
          if (!_isMatchingCandidate(offer, candidateData)) continue;

          await _sendOfferNotification(doc.id, offer, offerId);
          notificationCount++;
        } catch (e) {
          debugPrint('Erreur notification candidat ${doc.id}: $e');
        }
      }

      debugPrint(
        'Notifications envoyées à $notificationCount candidats sur ${snapshot.docs.length}',
      );
    } catch (e) {
      debugPrint('Erreur notification candidats: $e');
    }
  }

  bool _isMatchingCandidate(
    JobOfferModel offer,
    Map<String, dynamic> candidateData,
  ) {
    if (offer.matieres.isEmpty) return true;

    final candidateDiscipline = candidateData['discipline'] as String?;
    if (candidateDiscipline == null) return true;

    return offer.matieres.contains(candidateDiscipline) ||
        offer.matieres.contains('Toutes matières');
  }

  Future<void> _sendOfferNotification(
    String candidateId,
    JobOfferModel offer,
    String offerId,
  ) async {
    final matieresText = offer.matieres.isEmpty
        ? ''
        : ' (${offer.matieres.join(', ')})';

    await _notificationService.sendNotification(
      userId: candidateId,
      type: 'offer',
      title: 'Nouvelle offre d\'emploi',
      message:
          '${offer.nomEtablissement} recrute pour un poste de ${offer.poste}$matieresText',
      data: {
        'offerId': offerId,
        'schoolId': offer.schoolId,
        'schoolName': offer.nomEtablissement,
        'jobTitle': offer.poste,
        'matieres': offer.matieres.join(', '),
        'ville': offer.ville,
      },
    );
  }

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

  Stream<List<JobOfferModel>> streamJobOffersBySchoolId(String schoolId) {
    return _firestore
        .collection(_jobOffersCollection)
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JobOfferModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<JobOfferModel?> getJobOfferById(String offerId) async {
    try {
      final doc = await _firestore
          .collection(_jobOffersCollection)
          .doc(offerId)
          .get();
      if (!doc.exists) return null;
      return JobOfferModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'offre: $e');
    }
  }

  Future<void> updateJobOffer(
    String offerId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(_jobOffersCollection)
          .doc(offerId)
          .update(updates);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'offre: $e');
    }
  }

  Future<void> deleteJobOffer(String offerId) async {
    try {
      await _firestore.collection(_jobOffersCollection).doc(offerId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'offre: $e');
    }
  }

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

  Future<void> incrementOfferViews(String offerId) =>
      _incrementField(_jobOffersCollection, offerId, 'viewsCount');

  Future<void> incrementOfferApplications(String offerId) =>
      _incrementField(_jobOffersCollection, offerId, 'applicantsCount');

  // ========== STREAM POUR TEMPS RÉEL ==========

  Stream<List<JobApplicationModel>> streamActiveApplications({int limit = 20}) {
    return _firestore
        .collection(_jobApplicationsCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JobApplicationModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<JobOfferModel>> streamActiveOffers({int limit = 20}) {
    return _firestore
        .collection(_jobOffersCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JobOfferModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<JobOfferModel>> streamOpenJobOffers({int limit = 50}) {
    return _firestore
        .collection(_jobOffersCollection)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JobOfferModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<JobApplicationModel?> streamUserApplication(String userId) {
    return _firestore
        .collection(_jobApplicationsCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return JobApplicationModel.fromFirestore(snapshot.docs.first);
        });
  }

  // ========== CANDIDATURES À DES OFFRES SPÉCIFIQUES ==========

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

  Future<String> createOfferApplication(
    OfferApplicationModel application,
  ) async {
    try {
      final docRef = await _firestore
          .collection(_offerApplicationsCollection)
          .add(application.toMap());

      await incrementOfferApplicantsCount(application.offerId);
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la candidature: $e');
    }
  }

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

      if (querySnapshot.docs.isEmpty) return null;
      return OfferApplicationModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Erreur lors de la vérification de la candidature: $e');
    }
  }

  Future<List<OfferApplicationModel>> getOfferApplications(
    String offerId,
  ) async {
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

  Future<void> incrementOfferViewCount(String offerId) async {
    try {
      await _firestore.collection(_jobOffersCollection).doc(offerId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Erreur silencieuse
    }
  }

  Future<void> incrementOfferApplicantsCount(String offerId) async {
    try {
      await _firestore.collection(_jobOffersCollection).doc(offerId).update({
        'applicantsCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Erreur silencieuse
    }
  }

  Future<void> decrementOfferApplicantsCount(String offerId) async {
    try {
      await _firestore.collection(_jobOffersCollection).doc(offerId).update({
        'applicantsCount': FieldValue.increment(-1),
      });
    } catch (e) {
      // Erreur silencieuse
    }
  }

  Future<void> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    try {
      await _firestore
          .collection(_offerApplicationsCollection)
          .doc(applicationId)
          .update({'status': status, 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  Future<void> withdrawApplication(String applicationId) async {
    try {
      await updateApplicationStatus(applicationId, 'withdrawn');
    } catch (e) {
      throw Exception('Erreur lors du retrait de la candidature: $e');
    }
  }

  Future<void> deleteOfferApplication(String applicationId) async {
    try {
      final doc = await _firestore
          .collection(_offerApplicationsCollection)
          .doc(applicationId)
          .get();

      if (doc.exists) {
        final offerId = doc.data()?['offerId'] as String?;

        await _firestore
            .collection(_offerApplicationsCollection)
            .doc(applicationId)
            .delete();

        if (offerId != null) {
          await decrementOfferApplicantsCount(offerId);
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la candidature: $e');
    }
  }

  Stream<List<OfferApplicationModel>> streamUserOfferApplications(
    String userId,
  ) {
    return _firestore
        .collection(_offerApplicationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OfferApplicationModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<OfferApplicationModel>> streamOfferApplications(String offerId) {
    return _firestore
        .collection(_offerApplicationsCollection)
        .where('offerId', isEqualTo: offerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OfferApplicationModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> incrementApplicationViewCount(String applicationId) async {
    try {
      await _firestore
          .collection(_offerApplicationsCollection)
          .doc(applicationId)
          .update({'viewsCount': FieldValue.increment(1)});
    } catch (e) {
      // Erreur silencieuse
    }
  }
}
