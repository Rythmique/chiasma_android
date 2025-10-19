import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

/// Service de gestion des paiements MoneyFusion via Cloud Functions
///
/// Ce service gère l'intégration sécurisée avec MoneyFusion en utilisant
/// Firebase Cloud Functions pour protéger la clé API.
class PaymentService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Types d'abonnement disponibles
  static const String subscriptionMonthly = 'monthly';
  static const String subscriptionYearly = 'yearly';

  /// Tarifs des abonnements (en EUR)
  static const Map<String, double> subscriptionPrices = {
    subscriptionMonthly: 9.99,
    subscriptionYearly: 99.99,
  };

  /// Initialise un paiement MoneyFusion
  ///
  /// [userId] - L'ID de l'utilisateur Firebase
  /// [subscriptionType] - Le type d'abonnement ('monthly' ou 'yearly')
  ///
  /// Retourne un Map avec:
  /// - success: bool
  /// - paymentId: String (si success)
  /// - paymentUrl: String (si success)
  /// - error: String (si échec)
  static Future<Map<String, dynamic>> initializePayment({
    required String userId,
    required String subscriptionType,
  }) async {
    try {
      // Vérifier que l'utilisateur est authentifié
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        developer.log(
          'User not authenticated',
          name: 'PaymentService',
          level: 900,
        );
        return {
          'success': false,
          'error': 'Utilisateur non authentifié',
        };
      }

      // Vérifier que l'utilisateur demande un paiement pour lui-même
      if (currentUser.uid != userId) {
        developer.log(
          'User ID mismatch: ${currentUser.uid} vs $userId',
          name: 'PaymentService',
          level: 900,
        );
        return {
          'success': false,
          'error': 'Vous ne pouvez initier un paiement que pour votre propre compte',
        };
      }

      // Récupérer le montant selon le type d'abonnement
      final amount = subscriptionPrices[subscriptionType];
      if (amount == null) {
        developer.log(
          'Invalid subscription type: $subscriptionType',
          name: 'PaymentService',
          level: 900,
        );
        return {
          'success': false,
          'error': 'Type d\'abonnement invalide',
        };
      }

      developer.log(
        'Initializing payment for user $userId: $subscriptionType (€$amount)',
        name: 'PaymentService',
      );

      // Appeler la Cloud Function
      final callable = _functions.httpsCallable('initializePayment');
      final result = await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'amount': amount,
        'currency': 'EUR',
        'subscriptionType': subscriptionType,
      });

      final data = result.data;

      if (data['success'] == true) {
        developer.log(
          'Payment initialized successfully: ${data['paymentId']}',
          name: 'PaymentService',
        );
        return {
          'success': true,
          'paymentId': data['paymentId'],
          'paymentUrl': data['paymentUrl'],
        };
      } else {
        developer.log(
          'Payment initialization failed: ${data['error']}',
          name: 'PaymentService',
          level: 900,
        );
        return {
          'success': false,
          'error': data['error'] ?? 'Erreur inconnue',
        };
      }
    } on FirebaseFunctionsException catch (e) {
      developer.log(
        'Firebase Functions error: ${e.code} - ${e.message}',
        name: 'PaymentService',
        level: 1000,
        error: e,
      );
      return {
        'success': false,
        'error': 'Erreur lors de l\'initialisation du paiement: ${e.message}',
      };
    } catch (e) {
      developer.log(
        'Unexpected error initializing payment',
        name: 'PaymentService',
        level: 1000,
        error: e,
      );
      return {
        'success': false,
        'error': 'Erreur inattendue: $e',
      };
    }
  }

  /// Ouvre l'URL de paiement dans le navigateur
  ///
  /// [paymentUrl] - L'URL de paiement MoneyFusion
  ///
  /// Retourne true si l'URL a été ouverte avec succès
  static Future<bool> openPaymentUrl(String paymentUrl) async {
    try {
      final uri = Uri.parse(paymentUrl);

      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          developer.log(
            'Payment URL opened successfully',
            name: 'PaymentService',
          );
          return true;
        } else {
          developer.log(
            'Failed to launch payment URL',
            name: 'PaymentService',
            level: 900,
          );
          return false;
        }
      } else {
        developer.log(
          'Cannot launch payment URL: $paymentUrl',
          name: 'PaymentService',
          level: 900,
        );
        return false;
      }
    } catch (e) {
      developer.log(
        'Error opening payment URL',
        name: 'PaymentService',
        level: 1000,
        error: e,
      );
      return false;
    }
  }

  /// Vérifie le statut d'un paiement
  ///
  /// [paymentId] - L'ID du paiement MoneyFusion
  ///
  /// Retourne un Map avec:
  /// - success: bool
  /// - status: String ('pending', 'completed', 'failed')
  /// - amount: double
  /// - currency: String
  /// - subscriptionType: String
  static Future<Map<String, dynamic>> checkPaymentStatus({
    required String paymentId,
  }) async {
    try {
      developer.log(
        'Checking payment status for: $paymentId',
        name: 'PaymentService',
      );

      final callable = _functions.httpsCallable('checkPaymentStatus');
      final result = await callable.call<Map<String, dynamic>>({
        'paymentId': paymentId,
      });

      final data = result.data;

      if (data['success'] == true) {
        developer.log(
          'Payment status retrieved: ${data['status']}',
          name: 'PaymentService',
        );
        return {
          'success': true,
          'status': data['status'],
          'amount': data['amount'],
          'currency': data['currency'],
          'subscriptionType': data['subscriptionType'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Erreur inconnue',
        };
      }
    } on FirebaseFunctionsException catch (e) {
      developer.log(
        'Firebase Functions error: ${e.code} - ${e.message}',
        name: 'PaymentService',
        level: 1000,
        error: e,
      );
      return {
        'success': false,
        'error': 'Erreur lors de la vérification: ${e.message}',
      };
    } catch (e) {
      developer.log(
        'Unexpected error checking payment status',
        name: 'PaymentService',
        level: 1000,
        error: e,
      );
      return {
        'success': false,
        'error': 'Erreur inattendue: $e',
      };
    }
  }

  /// Initialise un paiement et ouvre directement l'URL de paiement
  ///
  /// Méthode de commodité qui combine initializePayment et openPaymentUrl
  ///
  /// [userId] - L'ID de l'utilisateur Firebase
  /// [subscriptionType] - Le type d'abonnement ('monthly' ou 'yearly')
  ///
  /// Retourne un Map avec le résultat de l'initialisation
  static Future<Map<String, dynamic>> processPayment({
    required String userId,
    required String subscriptionType,
  }) async {
    // Initialiser le paiement
    final result = await initializePayment(
      userId: userId,
      subscriptionType: subscriptionType,
    );

    if (result['success'] == true) {
      final paymentUrl = result['paymentUrl'] as String;

      // Ouvrir l'URL de paiement
      final urlOpened = await openPaymentUrl(paymentUrl);

      if (!urlOpened) {
        developer.log(
          'Payment initialized but URL could not be opened',
          name: 'PaymentService',
          level: 900,
        );
        return {
          'success': false,
          'error': 'Impossible d\'ouvrir la page de paiement',
          'paymentId': result['paymentId'],
          'paymentUrl': paymentUrl,
        };
      }

      return result;
    } else {
      return result;
    }
  }

  /// Récupère le prix d'un type d'abonnement
  ///
  /// [subscriptionType] - Le type d'abonnement
  ///
  /// Retourne le prix en EUR ou null si le type est invalide
  static double? getSubscriptionPrice(String subscriptionType) {
    return subscriptionPrices[subscriptionType];
  }

  /// Formate un prix en EUR
  ///
  /// [amount] - Le montant à formater
  ///
  /// Retourne une chaîne formatée (ex: "9,99 €")
  static String formatPrice(double amount) {
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  /// Calcule l'économie réalisée avec l'abonnement annuel
  ///
  /// Retourne un Map avec:
  /// - savings: double (montant économisé)
  /// - percentage: int (pourcentage d'économie)
  static Map<String, dynamic> calculateYearlySavings() {
    final monthlyPrice = subscriptionPrices[subscriptionMonthly]!;
    final yearlyPrice = subscriptionPrices[subscriptionYearly]!;

    final monthlyCostPerYear = monthlyPrice * 12;
    final savings = monthlyCostPerYear - yearlyPrice;
    final percentage = ((savings / monthlyCostPerYear) * 100).round();

    return {
      'savings': savings,
      'percentage': percentage,
    };
  }
}
