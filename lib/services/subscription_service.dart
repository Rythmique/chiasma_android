import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/analytics_service.dart';

class QuotaResult {
  final bool success;
  final String message;
  final int quotaRemaining;
  final bool needsSubscription;
  final String? accountType;

  QuotaResult({
    required this.success,
    required this.message,
    required this.quotaRemaining,
    required this.needsSubscription,
    this.accountType,
  });
}

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();

  static final _subscriptionMessages = {
    'teacher_transfer': '''
Pour continuer à utiliser nos services, veuillez prendre un abonnement :
• 500 F = 1 mois
• 1 500 F = 3 mois
• 2 500 F = 12 mois

Faites un dépôt WAVE ou MTN Money au +225 0758747888,
puis envoyez la capture de votre preuve de paiement au même numéro via WhatsApp.
''',
    'teacher_candidate': '''
Pour continuer à postuler, veuillez prendre un abonnement :
• 500 F = 1 semaine
• 1 500 F = 1 mois (au lieu de 2 000 F)
• 20 000 F = 12 mois (au lieu de 24 000 F)

Faites un dépôt WAVE ou MTN Money au +225 0758747888,
puis envoyez la capture de votre preuve de paiement au même numéro via WhatsApp.
''',
    'school': '''
Pour continuer à publier des offres, veuillez prendre un abonnement :
• 2 000 F = 1 semaine
• 5 000 F = 1 mois (au lieu de 8 000 F)
• 90 000 F = 12 mois (au lieu de 96 000 F)

Faites un dépôt WAVE ou MTN Money au +225 0758747888,
puis envoyez la capture de votre preuve de paiement au même numéro via WhatsApp.
''',
  };

  static final _welcomeMessages = {
    'teacher_transfer': (int quota) =>
        'Bienvenue ! Vous disposez de $quota consultations gratuites.',
    'teacher_candidate': (int quota) =>
        'Bienvenue ! Vous pouvez postuler gratuitement à $quota offres d\'emploi.',
    'school': (int quota) =>
        'Bienvenue ! Vous pouvez créer $quota offre d\'emploi gratuite.',
  };

  static String getSubscriptionMessage(String accountType) =>
      _subscriptionMessages[accountType] ??
      'Veuillez contacter l\'administrateur pour plus d\'informations.';

  static String getWelcomeMessage(String accountType, int freeQuota) =>
      _welcomeMessages[accountType]?.call(freeQuota) ?? 'Bienvenue !';

  Future<bool> incrementQuotaUsage(String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        if (!snapshot.exists) throw Exception('Utilisateur introuvable');

        final userData = snapshot.data()!;
        final currentUsed = userData['freeQuotaUsed'] ?? 0;
        final limit = userData['freeQuotaLimit'] ?? 0;

        if (currentUsed >= limit) {
          transaction.update(userDoc, {
            'isVerified': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return false;
        }

        transaction.update(userDoc, {
          'freeQuotaUsed': currentUsed + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'incrémentation du quota: $e');
      return false;
    }
  }

  Future<bool> canPerformAction(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final user = UserModel.fromFirestore(userDoc);

      if (user.isVerificationExpired) {
        await _firestore.collection('users').doc(userId).update({
          'isVerified': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return false;
      }

      if (user.isFreeQuotaExhausted && !user.isVerified) return false;

      return user.hasAccess;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  Future<QuotaResult> consumeProfileViewQuota(String userId) =>
      _consumeQuota(userId, 'teacher_transfer');

  Future<QuotaResult> consumeMessageQuota(String userId) =>
      _consumeQuota(userId, 'teacher_transfer');

  Future<QuotaResult> consumeJobOfferQuota(String userId) =>
      _consumeQuota(userId, 'school');

  Future<QuotaResult> consumeCandidateViewQuota(String userId) =>
      _consumeQuota(userId, 'school');

  Future<QuotaResult> consumeApplicationQuota(String userId) =>
      _consumeQuota(userId, 'teacher_candidate');

  Future<QuotaResult> _consumeQuota(
    String userId,
    String expectedAccountType,
  ) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);

      return await _firestore.runTransaction((transaction) async {
        debugPrint(
          'Transaction quota - userId: $userId, type: $expectedAccountType',
        );
        final snapshot = await transaction.get(userDoc);

        if (!snapshot.exists) {
          return QuotaResult(
            success: false,
            message: 'Utilisateur introuvable',
            quotaRemaining: 0,
            needsSubscription: true,
          );
        }

        final user = UserModel.fromFirestore(snapshot);

        if (user.accountType != expectedAccountType) {
          return QuotaResult(
            success: false,
            message: 'Type de compte incorrect',
            quotaRemaining: 0,
            needsSubscription: false,
          );
        }

        if (user.isVerified && !user.isVerificationExpired) {
          return QuotaResult(
            success: true,
            message: 'Abonnement actif',
            quotaRemaining: -1,
            needsSubscription: false,
          );
        }

        if (user.isFreeQuotaExhausted) {
          transaction.update(userDoc, {
            'isVerified': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          return QuotaResult(
            success: false,
            message: getSubscriptionMessage(user.accountType),
            quotaRemaining: 0,
            needsSubscription: true,
            accountType: user.accountType,
          );
        }

        final newQuotaUsed = user.freeQuotaUsed + 1;
        final quotaRemaining = user.freeQuotaLimit - newQuotaUsed;

        final updateData = <String, dynamic>{
          'freeQuotaUsed': newQuotaUsed,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (quotaRemaining == 0) {
          updateData['isVerified'] = false;
        }

        transaction.update(userDoc, updateData);

        if (quotaRemaining == 0) {
          return QuotaResult(
            success: true,
            message: 'Dernière action gratuite utilisée',
            quotaRemaining: 0,
            needsSubscription: true,
            accountType: user.accountType,
          );
        }

        return QuotaResult(
          success: true,
          message: 'Quota déduit avec succès',
          quotaRemaining: quotaRemaining,
          needsSubscription: false,
        );
      });
    } catch (e) {
      debugPrint('Erreur lors de la consommation du quota: $e');
      return QuotaResult(
        success: false,
        message: 'Erreur: $e',
        quotaRemaining: 0,
        needsSubscription: false,
      );
    }
  }

  Future<void> activateSubscription(String userId, String duration) async {
    try {
      final expiresAt = _calculateExpirationDate(duration);

      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verificationExpiresAt': Timestamp.fromDate(expiresAt),
        'subscriptionDuration': duration,
        'freeQuotaUsed': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logSubscriptionStart('premium', duration);

      final prices = {
        '1_week': 1000.0,
        '1_month': 3000.0,
        '3_months': 8000.0,
        '6_months': 15000.0,
        '12_months': 25000.0,
      };

      await _analytics.logPurchase(
        subscriptionType: 'premium_$duration',
        value: prices[duration] ?? 0.0,
        currency: 'XOF',
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'activation de l\'abonnement: $e');
      rethrow;
    }
  }

  Future<void> extendSubscription(
    String userId,
    String additionalDuration,
    DateTime newExpirationDate,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verificationExpiresAt': Timestamp.fromDate(newExpirationDate),
        'subscriptionDuration': additionalDuration,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Abonnement étendu pour $userId jusqu\'au $newExpirationDate');
    } catch (e) {
      debugPrint('Erreur lors de l\'extension de l\'abonnement: $e');
      rethrow;
    }
  }

  DateTime _calculateExpirationDate(String duration) {
    final now = DateTime.now();
    switch (duration) {
      case '1_week':
        return now.add(const Duration(days: 7));
      case '1_month':
        return DateTime(now.year, now.month + 1, now.day);
      case '3_months':
        return DateTime(now.year, now.month + 3, now.day);
      case '6_months':
        return DateTime(now.year, now.month + 6, now.day);
      case '12_months':
        return DateTime(now.year + 1, now.month, now.day);
      default:
        return DateTime(now.year, now.month + 1, now.day);
    }
  }

  Future<void> checkAndExpireAccounts() async {
    try {
      final now = DateTime.now();
      final expiredUsersQuery = await _firestore
          .collection('users')
          .where('isVerified', isEqualTo: true)
          .where('verificationExpiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      for (var doc in expiredUsersQuery.docs) {
        batch.update(doc.reference, {
          'isVerified': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('${expiredUsersQuery.docs.length} comptes expirés désactivés');
    } catch (e) {
      debugPrint('Erreur lors de la vérification des expirations: $e');
    }
  }

  Future<void> resetQuota(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'freeQuotaUsed': 0,
        'lastQuotaResetDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur lors de la réinitialisation du quota: $e');
      rethrow;
    }
  }

  static Map<String, String> getSubscriptionPrices(String accountType) {
    const prices = {
      'teacher_transfer': {
        '1_month': '500 F',
        '3_months': '1 500 F',
        '12_months': '2 500 F',
      },
      'teacher_candidate': {
        '1_week': '500 F',
        '1_month': '1 500 F',
        '12_months': '20 000 F',
      },
      'school': {
        '1_week': '2 000 F',
        '1_month': '5 000 F',
        '12_months': '90 000 F',
      },
    };
    return prices[accountType] ?? {};
  }

  static String getDurationLabel(String duration) {
    const labels = {
      '1_week': '1 semaine',
      '1_month': '1 mois',
      '3_months': '3 mois',
      '6_months': '6 mois',
      '12_months': '12 mois',
    };
    return labels[duration] ?? duration;
  }
}
