import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/subscription_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/moneyfusion_service.dart';

/// Service pour gérer les abonnements et consultations
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MoneyFusionService _moneyFusionService = MoneyFusionService();

  // Collections Firestore
  static const String _subscriptionsCollection = 'subscriptions';
  static const String _usersCollection = 'users';
  static const String _appConfigCollection = 'app_config';
  static const String _appConfigDocId = 'global_config';

  /// Obtenir la configuration globale de l'application
  Future<AppConfigModel> getAppConfig() async {
    try {
      final doc = await _firestore
          .collection(_appConfigCollection)
          .doc(_appConfigDocId)
          .get();

      if (doc.exists) {
        return AppConfigModel.fromFirestore(doc);
      } else {
        // Créer une configuration par défaut
        final defaultConfig = AppConfigModel(
          subscriptionSystemEnabled: false, // Désactivé par défaut
          freeConsultationsLimit: 5,
          updatedAt: DateTime.now(),
        );
        await _firestore
            .collection(_appConfigCollection)
            .doc(_appConfigDocId)
            .set(defaultConfig.toMap());
        return defaultConfig;
      }
    } catch (e) {
      dev.log('Erreur lors de la récupération de la config',
              name: 'SubscriptionService', error: e);
      // Retourner config par défaut en cas d'erreur
      return AppConfigModel(
        subscriptionSystemEnabled: false,
        freeConsultationsLimit: 5,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Mettre à jour la configuration globale (admin seulement)
  Future<void> updateAppConfig({
    required bool subscriptionSystemEnabled,
    required String adminUid,
  }) async {
    try {
      final config = AppConfigModel(
        subscriptionSystemEnabled: subscriptionSystemEnabled,
        freeConsultationsLimit: 5,
        updatedAt: DateTime.now(),
        updatedBy: adminUid,
      );

      await _firestore
          .collection(_appConfigCollection)
          .doc(_appConfigDocId)
          .set(config.toMap());

      dev.log('Configuration mise à jour: système ${subscriptionSystemEnabled ? "activé" : "désactivé"}',
              name: 'SubscriptionService');
    } catch (e) {
      dev.log('Erreur lors de la mise à jour de la config',
              name: 'SubscriptionService', error: e);
      rethrow;
    }
  }

  /// Stream de la configuration globale
  Stream<AppConfigModel> getAppConfigStream() {
    return _firestore
        .collection(_appConfigCollection)
        .doc(_appConfigDocId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return AppConfigModel.fromFirestore(doc);
      } else {
        return AppConfigModel(
          subscriptionSystemEnabled: false,
          freeConsultationsLimit: 5,
          updatedAt: DateTime.now(),
        );
      }
    });
  }

  /// Créer un abonnement après paiement réussi
  Future<SubscriptionModel> createSubscription({
    required String userId,
    required SubscriptionType type,
    required int amountPaid,
    required String transactionId,
    required String paymentMethod,
  }) async {
    try {
      final now = DateTime.now();
      final durationMonths = SubscriptionModel.getDurationMonths(type);
      final endDate = DateTime(
        now.year,
        now.month + durationMonths,
        now.day,
      );

      final subscription = SubscriptionModel(
        id: '', // Sera généré par Firestore
        userId: userId,
        type: type,
        status: SubscriptionStatus.active,
        amountPaid: amountPaid,
        startDate: now,
        endDate: endDate,
        transactionId: transactionId,
        paymentMethod: paymentMethod,
        createdAt: now,
      );

      final docRef = await _firestore
          .collection(_subscriptionsCollection)
          .add(subscription.toMap());

      // Mettre à jour le statut d'abonnement de l'utilisateur
      await _firestore.collection(_usersCollection).doc(userId).update({
        'hasActiveSubscription': true,
        'subscriptionEndDate': Timestamp.fromDate(endDate),
        'updatedAt': Timestamp.fromDate(now),
      });

      dev.log('Abonnement créé pour l\'utilisateur $userId jusqu\'au $endDate',
              name: 'SubscriptionService');

      return subscription.copyWith(id: docRef.id);
    } catch (e) {
      dev.log('Erreur lors de la création de l\'abonnement',
              name: 'SubscriptionService', error: e);
      rethrow;
    }
  }

  /// Obtenir l'abonnement actif d'un utilisateur
  Future<SubscriptionModel?> getActiveSubscription(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('endDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final subscription = SubscriptionModel.fromFirestore(
            querySnapshot.docs.first);

        // Vérifier si vraiment actif
        if (subscription.isActive) {
          return subscription;
        }
      }
      return null;
    } catch (e) {
      dev.log('Erreur lors de la récupération de l\'abonnement',
              name: 'SubscriptionService', error: e);
      return null;
    }
  }

  /// Obtenir tous les abonnements d'un utilisateur
  Stream<List<SubscriptionModel>> getUserSubscriptionsStream(String userId) {
    return _firestore
        .collection(_subscriptionsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubscriptionModel.fromFirestore(doc))
            .toList());
  }

  /// Vérifier et mettre à jour les abonnements expirés
  Future<void> checkExpiredSubscriptions() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('status', isEqualTo: 'active')
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .get();

      for (var doc in querySnapshot.docs) {
        // Marquer l'abonnement comme expiré
        await doc.reference.update({
          'status': 'expired',
        });

        // Mettre à jour le statut de l'utilisateur
        final subscription = SubscriptionModel.fromFirestore(doc);
        await _firestore
            .collection(_usersCollection)
            .doc(subscription.userId)
            .update({
          'hasActiveSubscription': false,
          'updatedAt': Timestamp.fromDate(now),
        });

        dev.log('Abonnement expiré pour l\'utilisateur ${subscription.userId}',
                name: 'SubscriptionService');
      }
    } catch (e) {
      dev.log('Erreur lors de la vérification des abonnements expirés',
              name: 'SubscriptionService', error: e);
    }
  }

  /// Incrémenter le compteur de consultations de profils
  Future<void> incrementProfileViewCount(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'profileViewsCount': FieldValue.increment(1),
        'freeViewsRemaining': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      dev.log('Consultation de profil comptabilisée pour $userId',
              name: 'SubscriptionService');
    } catch (e) {
      dev.log('Erreur lors de l\'incrémentation du compteur',
              name: 'SubscriptionService', error: e);
      rethrow;
    }
  }

  /// Vérifier si un utilisateur peut consulter un profil
  Future<Map<String, dynamic>> canUserViewProfile(String userId) async {
    try {
      // Récupérer la configuration
      final config = await getAppConfig();

      // Récupérer l'utilisateur
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return {
          'canView': false,
          'reason': 'user_not_found',
          'message': 'Utilisateur non trouvé',
        };
      }

      final userData = UserModel.fromFirestore(userDoc);

      // Si le système est désactivé, accès illimité
      if (!config.subscriptionSystemEnabled) {
        return {
          'canView': true,
          'reason': 'unlimited_free',
          'message': 'Mode gratuit et illimité activé',
        };
      }

      // Si l'utilisateur a un abonnement actif
      if (userData.hasActiveSubscription &&
          userData.subscriptionEndDate != null &&
          DateTime.now().isBefore(userData.subscriptionEndDate!)) {
        return {
          'canView': true,
          'reason': 'premium',
          'message': 'Abonnement Premium actif',
          'daysRemaining': userData.subscriptionEndDate!
              .difference(DateTime.now())
              .inDays,
        };
      }

      // Vérifier les consultations gratuites restantes
      if (userData.freeViewsRemaining > 0) {
        return {
          'canView': true,
          'reason': 'free_limited',
          'message': '${userData.freeViewsRemaining} consultations gratuites restantes',
          'freeViewsRemaining': userData.freeViewsRemaining,
        };
      }

      // Plus de consultations disponibles
      return {
        'canView': false,
        'reason': 'expired',
        'message': 'Consultations gratuites épuisées. Veuillez souscrire à un abonnement.',
      };
    } catch (e) {
      dev.log('Erreur lors de la vérification des droits',
              name: 'SubscriptionService', error: e);
      return {
        'canView': false,
        'reason': 'error',
        'message': 'Erreur lors de la vérification',
      };
    }
  }

  /// Traiter un paiement d'abonnement
  Future<Map<String, dynamic>> processSubscriptionPayment({
    required String userId,
    required SubscriptionType type,
    required String phoneNumber,
    required String paymentMethod,
  }) async {
    try {
      final amount = SubscriptionModel.getPrice(type);
      final typeLabel = SubscriptionModel.getTypeLabel(type);

      dev.log('Traitement du paiement: $amount FCFA pour $typeLabel',
              name: 'SubscriptionService');

      // Récupérer les infos de l'utilisateur pour le nom
      final userDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      String customerName = 'Utilisateur';
      if (userDoc.exists) {
        final userData = userDoc.data();
        customerName = userData?['nom'] ?? userData?['displayName'] ?? 'Utilisateur';
      }

      // Formater le numéro de téléphone (MoneyFusion attend format: 0123456789)
      final formattedPhone = _moneyFusionService.formatPhoneNumber(phoneNumber);

      dev.log('Numéro formaté: $formattedPhone', name: 'SubscriptionService');

      // Initier le paiement via MoneyFusion (nouvelle API)
      final paymentResult = await _moneyFusionService.initiatePayment(
        amount: amount,
        phoneNumber: formattedPhone,
        customerName: customerName,
        userId: userId,
        orderId: 'sub_${DateTime.now().millisecondsSinceEpoch}',
        items: [
          {'Abonnement CHIASMA - $typeLabel': amount}
        ],
        // Optionnel: URLs de callback
        // returnUrl: 'https://your-app-url.com/payment-success',
        // webhookUrl: 'https://your-cloud-function-url/webhook',
      );

      if (paymentResult == null || paymentResult['success'] != true) {
        return {
          'success': false,
          'message': 'Erreur lors de l\'initiation du paiement',
          'error': paymentResult?['error'],
        };
      }

      return {
        'success': true,
        'transaction_id': paymentResult['transaction_id'],
        'status': paymentResult['status'],
        'payment_url': paymentResult['payment_url'],
        'message': 'Paiement initié avec succès',
      };
    } catch (e) {
      dev.log('Erreur lors du traitement du paiement',
              name: 'SubscriptionService', error: e);
      return {
        'success': false,
        'message': 'Erreur lors du traitement du paiement',
        'error': e.toString(),
      };
    }
  }

  /// Confirmer un paiement et activer l'abonnement
  /// À appeler après vérification du statut du paiement
  Future<Map<String, dynamic>> confirmPaymentAndActivateSubscription({
    required String userId,
    required String transactionId,
    required SubscriptionType type,
    required String paymentMethod,
  }) async {
    try {
      // Vérifier le statut du paiement
      final paymentStatus = await _moneyFusionService
          .checkPaymentStatus(transactionId);

      if (paymentStatus == null || paymentStatus['success'] != true) {
        return {
          'success': false,
          'message': 'Impossible de vérifier le statut du paiement',
        };
      }

      if (paymentStatus['status'] != MoneyFusionService.statusPaid) {
        return {
          'success': false,
          'message': 'Le paiement n\'est pas confirmé',
          'status': paymentStatus['status'],
        };
      }

      // Créer l'abonnement
      final subscription = await createSubscription(
        userId: userId,
        type: type,
        amountPaid: paymentStatus['amount'],
        transactionId: transactionId,
        paymentMethod: paymentMethod,
      );

      return {
        'success': true,
        'message': 'Abonnement activé avec succès',
        'subscription': subscription,
      };
    } catch (e) {
      dev.log('Erreur lors de la confirmation du paiement',
              name: 'SubscriptionService', error: e);
      return {
        'success': false,
        'message': 'Erreur lors de l\'activation de l\'abonnement',
        'error': e.toString(),
      };
    }
  }

  /// Obtenir les statistiques d'abonnement (pour les admins)
  Future<Map<String, int>> getSubscriptionStats() async {
    try {
      final subscriptionsSnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .get();

      int activeCount = 0;
      int expiredCount = 0;
      int totalRevenue = 0;

      for (var doc in subscriptionsSnapshot.docs) {
        final sub = SubscriptionModel.fromFirestore(doc);
        if (sub.isActive) {
          activeCount++;
        } else {
          expiredCount++;
        }
        totalRevenue += sub.amountPaid;
      }

      return {
        'total': subscriptionsSnapshot.size,
        'active': activeCount,
        'expired': expiredCount,
        'revenue': totalRevenue,
      };
    } catch (e) {
      dev.log('Erreur lors de la récupération des statistiques',
              name: 'SubscriptionService', error: e);
      return {
        'total': 0,
        'active': 0,
        'expired': 0,
        'revenue': 0,
      };
    }
  }
}
