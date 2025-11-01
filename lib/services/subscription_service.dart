import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/user_model.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Messages de notification selon le type de compte
  static String getSubscriptionMessage(String accountType) {
    switch (accountType) {
      case 'teacher_transfer':
        return '''
Pour continuer à utiliser nos services, veuillez prendre un abonnement :
• 500 F = 1 mois
• 1 500 F = 3 mois
• 2 500 F = 12 mois

Faites un dépôt WAVE ou MTN Money au +225 0758747888,
puis envoyez la capture de votre preuve de paiement au même numéro via WhatsApp.
''';
      case 'teacher_candidate':
        return '''
Pour continuer à postuler, veuillez prendre un abonnement :
• 500 F = 1 semaine
• 1 500 F = 1 mois (au lieu de 2 000 F)
• 20 000 F = 12 mois (au lieu de 24 000 F)

Faites un dépôt WAVE ou MTN Money au +225 0758747888,
puis envoyez la capture de votre preuve de paiement au même numéro via WhatsApp.
''';
      case 'school':
        return '''
Pour continuer à publier des offres, veuillez prendre un abonnement :
• 2 000 F = 1 semaine
• 5 000 F = 1 mois (au lieu de 8 000 F)
• 90 000 F = 12 mois (au lieu de 96 000 F)

Faites un dépôt WAVE ou MTN Money au +225 0758747888,
puis envoyez la capture de votre preuve de paiement au même numéro via WhatsApp.
''';
      default:
        return 'Veuillez contacter l\'administrateur pour plus d\'informations.';
    }
  }

  // Message de bienvenue avec quota gratuit
  static String getWelcomeMessage(String accountType, int freeQuota) {
    switch (accountType) {
      case 'teacher_transfer':
        return 'Bienvenue ! Vous disposez de $freeQuota consultations gratuites.';
      case 'teacher_candidate':
        return 'Bienvenue ! Vous pouvez postuler gratuitement à $freeQuota offres d\'emploi.';
      case 'school':
        return 'Bienvenue ! Vous pouvez créer $freeQuota offre d\'emploi gratuite.';
      default:
        return 'Bienvenue !';
    }
  }

  // Incrémenter l'utilisation du quota gratuit
  Future<bool> incrementQuotaUsage(String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        if (!snapshot.exists) {
          throw Exception('Utilisateur introuvable');
        }

        final userData = snapshot.data()!;
        final currentUsed = userData['freeQuotaUsed'] ?? 0;
        final limit = userData['freeQuotaLimit'] ?? 0;

        if (currentUsed >= limit) {
          // Quota épuisé, désactiver la vérification
          transaction.update(userDoc, {
            'isVerified': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return false;
        }

        // Incrémenter le quota utilisé
        transaction.update(userDoc, {
          'freeQuotaUsed': currentUsed + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      print('Erreur lors de l\'incrémentation du quota: $e');
      return false;
    }
  }

  // Vérifier si l'utilisateur peut effectuer une action
  Future<bool> canPerformAction(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final user = UserModel.fromFirestore(userDoc);

      // Vérifier l'expiration
      if (user.isVerificationExpired) {
        // Désactiver la vérification si expiré
        await _firestore.collection('users').doc(userId).update({
          'isVerified': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return false;
      }

      // Vérifier le quota
      if (user.isFreeQuotaExhausted && !user.isVerified) {
        return false;
      }

      return user.hasAccess;
    } catch (e) {
      print('Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  // Activer un abonnement avec durée spécifique
  Future<void> activateSubscription(
    String userId,
    String duration, // '1_week', '1_month', '3_months', '6_months', '12_months'
  ) async {
    try {
      final expiresAt = _calculateExpirationDate(duration);

      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verificationExpiresAt': Timestamp.fromDate(expiresAt),
        'subscriptionDuration': duration,
        'freeQuotaUsed': 0, // Reset du quota
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de l\'activation de l\'abonnement: $e');
      rethrow;
    }
  }

  // Calculer la date d'expiration selon la durée
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
        return DateTime(now.year, now.month + 1, now.day); // Par défaut 1 mois
    }
  }

  // Vérifier et expirer automatiquement les comptes
  Future<void> checkAndExpireAccounts() async {
    try {
      final now = DateTime.now();
      final expiredUsersQuery = await _firestore
          .collection('users')
          .where('isVerified', isEqualTo: true)
          .where('verificationExpiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      // Batch update pour performance
      final batch = _firestore.batch();
      for (var doc in expiredUsersQuery.docs) {
        batch.update(doc.reference, {
          'isVerified': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('${expiredUsersQuery.docs.length} comptes expirés désactivés');
    } catch (e) {
      print('Erreur lors de la vérification des expirations: $e');
    }
  }

  // Réinitialiser le quota d'un utilisateur
  Future<void> resetQuota(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'freeQuotaUsed': 0,
        'lastQuotaResetDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la réinitialisation du quota: $e');
      rethrow;
    }
  }

  // Obtenir les tarifs selon le type de compte
  static Map<String, String> getSubscriptionPrices(String accountType) {
    switch (accountType) {
      case 'teacher_transfer':
        return {
          '1_month': '500 F',
          '3_months': '1 500 F',
          '12_months': '2 500 F',
        };
      case 'teacher_candidate':
        return {
          '1_week': '500 F',
          '1_month': '1 500 F',
          '12_months': '20 000 F',
        };
      case 'school':
        return {
          '1_week': '2 000 F',
          '1_month': '5 000 F',
          '12_months': '90 000 F',
        };
      default:
        return {};
    }
  }

  // Obtenir le libellé de la durée
  static String getDurationLabel(String duration) {
    switch (duration) {
      case '1_week':
        return '1 semaine';
      case '1_month':
        return '1 mois';
      case '3_months':
        return '3 mois';
      case '6_months':
        return '6 mois';
      case '12_months':
        return '12 mois';
      default:
        return duration;
    }
  }
}
