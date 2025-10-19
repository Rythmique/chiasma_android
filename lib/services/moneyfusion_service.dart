import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;

/// Service pour l'intégration de l'API MoneyFusion
/// Documentation officielle: https://docs.moneyfusion.net
class MoneyFusionService {
  // ✅ API URL MoneyFusion configurée
  // Merchant: CHIASMA
  // ID: 524b6d692d00f4b1
  static const String _apiUrl = 'https://www.pay.moneyfusion.net/chiasma/524b6d692d00f4b1/pay/';

  // URL de vérification de statut (celle-ci est correcte)
  static const String _checkStatusUrl = 'https://www.pay.moneyfusion.net/paiementNotif';

  // Statuts de paiement selon la documentation MoneyFusion
  static const String statusPending = 'pending';
  static const String statusPaid = 'paid';
  static const String statusFailed = 'failure';
  static const String statusNoPaid = 'no paid';

  /// Initier un paiement via MoneyFusion
  ///
  /// [amount] : Montant total en FCFA
  /// [phoneNumber] : Numéro de téléphone du client (format: 0123456789)
  /// [customerName] : Nom du client
  /// [userId] : ID de l'utilisateur
  /// [orderId] : ID de la commande/abonnement
  /// [items] : Articles à payer (optionnel)
  /// [returnUrl] : URL de retour après paiement (optionnel)
  /// [webhookUrl] : URL webhook pour recevoir les notifications (optionnel)
  ///
  /// Retourne le token et l'URL de paiement
  Future<Map<String, dynamic>?> initiatePayment({
    required int amount,
    required String phoneNumber,
    required String customerName,
    required String userId,
    String? orderId,
    List<Map<String, dynamic>>? items,
    String? returnUrl,
    String? webhookUrl,
  }) async {
    try {
      dev.log('Initiation du paiement MoneyFusion: $amount FCFA pour $customerName',
              name: 'MoneyFusionService');

      // Préparer les données de paiement selon la documentation MoneyFusion
      final paymentData = {
        'totalPrice': amount,
        'article': items ?? [
          {'Abonnement CHIASMA': amount}
        ],
        'personal_Info': [
          {
            'userId': userId,
            if (orderId != null) 'orderId': orderId,
          }
        ],
        'numeroSend': phoneNumber,
        'nomclient': customerName,
        if (returnUrl != null) 'return_url': returnUrl,
        if (webhookUrl != null) 'webhook_url': webhookUrl,
      };

      dev.log('Données de paiement: ${jsonEncode(paymentData)}',
              name: 'MoneyFusionService');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(paymentData),
      );

      dev.log('Code de réponse: ${response.statusCode}',
              name: 'MoneyFusionService');
      dev.log('Corps de la réponse: ${response.body}',
              name: 'MoneyFusionService');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Format de réponse MoneyFusion:
        // {
        //   "statut": true,
        //   "token": "5d58823b084564",
        //   "message": "paiement en cours",
        //   "url": "https://www.pay.moneyfusion.net/pay/6596aded36bd58823b084564"
        // }

        if (data['statut'] == true) {
          dev.log('Paiement initié avec succès. Token: ${data['token']}',
                  name: 'MoneyFusionService');

          return {
            'success': true,
            'transaction_id': data['token'], // Le token sert d'ID de transaction
            'status': statusPending,
            'payment_url': data['url'],
            'message': data['message'],
          };
        } else {
          dev.log('Échec de l\'initiation: ${data['message']}',
                  name: 'MoneyFusionService');
          return {
            'success': false,
            'error': data['message'] ?? 'Erreur inconnue',
          };
        }
      } else {
        dev.log('Erreur HTTP ${response.statusCode}: ${response.body}',
                name: 'MoneyFusionService');
        return {
          'success': false,
          'error': 'Erreur HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e, stackTrace) {
      dev.log('Exception lors de l\'initiation du paiement',
              name: 'MoneyFusionService', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Vérifier le statut d'un paiement
  ///
  /// [token] : Token de paiement retourné lors de l'initiation
  ///
  /// Retourne le statut détaillé du paiement
  Future<Map<String, dynamic>?> checkPaymentStatus(String token) async {
    try {
      dev.log('Vérification du statut du paiement: $token',
              name: 'MoneyFusionService');

      final response = await http.get(
        Uri.parse('$_checkStatusUrl/$token'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Format de réponse MoneyFusion:
        // {
        //   "statut": true,
        //   "data": {
        //     "_id": "65df163b11ab882694573060",
        //     "tokenPay": "0d1d8bc9b6d2819c",
        //     "numeroSend": "01010101",
        //     "nomclient": "John Doe",
        //     "personal_Info": [{"userId": 1, "orderId": 123}],
        //     "numeroTransaction": "0708889205",
        //     "Montant": 200,
        //     "frais": 5,
        //     "statut": "paid",
        //     "moyen": "orange",
        //     "return_url": "...",
        //     "createdAt": "2024-02-28T11:17:15.285Z"
        //   },
        //   "message": "details paiement"
        // }

        if (result['statut'] == true && result['data'] != null) {
          final data = result['data'];
          dev.log('Statut du paiement: ${data['statut']}',
                  name: 'MoneyFusionService');

          return {
            'success': true,
            'transaction_id': data['tokenPay'],
            'status': data['statut'], // pending, paid, failure, no paid
            'amount': data['Montant'],
            'fees': data['frais'],
            'payment_method': data['moyen'],
            'transaction_number': data['numeroTransaction'],
            'customer_name': data['nomclient'],
            'customer_phone': data['numeroSend'],
            'personal_info': data['personal_Info'],
            'created_at': data['createdAt'],
          };
        } else {
          return {
            'success': false,
            'error': result['message'] ?? 'Impossible de récupérer le statut',
          };
        }
      } else {
        dev.log('Erreur lors de la vérification: ${response.statusCode}',
                name: 'MoneyFusionService', error: response.body);
        return {
          'success': false,
          'error': 'Erreur HTTP ${response.statusCode}',
        };
      }
    } catch (e, stackTrace) {
      dev.log('Exception lors de la vérification du statut',
              name: 'MoneyFusionService', error: e, stackTrace: stackTrace);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Formater un numéro de téléphone ivoirien
  /// Convertit +2250123456789 ou 0123456789 en 0123456789 (format MoneyFusion)
  String formatPhoneNumber(String phoneNumber) {
    // Retirer les espaces et caractères spéciaux
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Retirer le +225 si présent
    if (cleaned.startsWith('+225')) {
      cleaned = '0${cleaned.substring(4)}';
    } else if (cleaned.startsWith('225')) {
      cleaned = '0${cleaned.substring(3)}';
    }

    // S'assurer que le numéro commence par 0
    if (!cleaned.startsWith('0')) {
      cleaned = '0$cleaned';
    }

    return cleaned;
  }

  /// Obtenir le label du statut de paiement
  String getStatusLabel(String status) {
    switch (status) {
      case statusPending:
        return 'En attente';
      case statusPaid:
        return 'Payé';
      case statusFailed:
        return 'Échoué';
      case statusNoPaid:
        return 'Non payé';
      default:
        return 'Inconnu';
    }
  }

  /// Vérifier si un statut est final (terminé)
  bool isStatusFinal(String status) {
    return status == statusPaid || status == statusFailed || status == statusNoPaid;
  }

  /// Vérifier si un paiement est réussi
  bool isPaymentSuccessful(String status) {
    return status == statusPaid;
  }
}
