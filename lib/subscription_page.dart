import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/subscription_model.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/services/moneyfusion_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final MoneyFusionService _moneyFusionService = MoneyFusionService();

  SubscriptionType _selectedPlan = SubscriptionType.monthly;
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnement Premium'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header avec dégradé
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF77F00),
                    const Color(0xFFF77F00).withValues(alpha: 0.8),
                    const Color(0xFF009E60),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      size: 60,
                      color: Color(0xFFF77F00),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Passez au Premium',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Consultations illimitées pendant toute la durée',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avantages Premium
                  const Text(
                    'Avantages Premium',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.visibility,
                    'Consultations illimitées',
                    'Consultez autant de profils que vous voulez',
                    const Color(0xFFF77F00),
                  ),
                  _buildFeatureItem(
                    Icons.search,
                    'Recherche avancée',
                    'Filtres et options de recherche supplémentaires',
                    const Color(0xFF009E60),
                  ),
                  _buildFeatureItem(
                    Icons.notifications_active,
                    'Notifications prioritaires',
                    'Soyez alerté en premier des nouveaux matchs',
                    const Color(0xFF2196F3),
                  ),
                  _buildFeatureItem(
                    Icons.message,
                    'Messages illimités',
                    'Contactez autant d\'enseignants que nécessaire',
                    const Color(0xFF9C27B0),
                  ),
                  _buildFeatureItem(
                    Icons.verified,
                    'Badge vérifié',
                    'Gagnez en crédibilité avec un badge premium',
                    Colors.orange[700]!,
                  ),
                  _buildFeatureItem(
                    Icons.analytics,
                    'Statistiques avancées',
                    'Voir qui a consulté votre profil',
                    const Color(0xFF00BCD4),
                  ),
                  const SizedBox(height: 32),

                  // Plans tarifaires - NOUVEAUX TARIFS
                  const Text(
                    'Choisissez votre plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPlanCard(
                    SubscriptionType.monthly,
                    'Mensuel',
                    '500 FCFA',
                    '1 mois',
                    'Essayez pour commencer',
                    false,
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    SubscriptionType.quarterly,
                    'Trimestriel',
                    '1 500 FCFA',
                    '3 mois',
                    'Économisez - Seulement 500 FCFA/mois',
                    false,
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    SubscriptionType.yearly,
                    'Annuel',
                    '5 000 FCFA',
                    '12 mois au lieu de 10',
                    'Meilleure offre - 2 mois GRATUITS !',
                    true,
                  ),
                  const SizedBox(height: 32),

                  // Bouton de souscription
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () {
                        _showPaymentDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF77F00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Souscrire maintenant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Note de sécurité
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Paiement sécurisé via Mobile Money (Orange Money, MTN Money, Moov Money)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Conditions
                  Text(
                    'En souscrivant, vous acceptez nos conditions générales. L\'abonnement ne se renouvelle pas automatiquement.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    SubscriptionType value,
    String title,
    String price,
    String period,
    String badge,
    bool isPopular,
  ) {
    final isSelected = _selectedPlan == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF77F00).withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF77F00)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF77F00).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFFF77F00)
                            : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFFF77F00)
                            : Colors.grey[800],
                      ),
                    ),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.check_circle,
                          color: Color(0xFFF77F00),
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPopular
                    ? const Color(0xFF009E60).withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPopular
                      ? const Color(0xFF009E60)
                      : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF77F00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.payment,
                color: Color(0xFFF77F00),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Mode de paiement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaymentOption(
              'Orange Money',
              Icons.phone_android,
              Colors.orange,
              'orange_money',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'MTN Money',
              Icons.phone_android,
              Colors.yellow[700]!,
              'mtn_money',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'Moov Money',
              Icons.phone_android,
              Colors.blue,
              'moov_money',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String name,
    IconData icon,
    Color color,
    String method,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _showPhoneNumberDialog(context, method, name);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _showPhoneNumberDialog(
    BuildContext context,
    String method,
    String methodName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Numéro de téléphone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrez votre numéro $methodName',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '0123456789',
                prefixText: '+225 ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF77F00),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayment(method, methodName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF77F00),
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(String method, String methodName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorDialog('Vous devez être connecté pour souscrire');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showErrorDialog('Veuillez entrer votre numéro de téléphone');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final phoneNumber = _moneyFusionService.formatPhoneNumber(
        _phoneController.text.trim(),
      );

      final result = await _subscriptionService.processSubscriptionPayment(
        userId: currentUser.uid,
        type: _selectedPlan,
        phoneNumber: phoneNumber,
        paymentMethod: method,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (result['success'] == true) {
          _showPaymentProcessingDialog(
            result['transaction_id'],
            methodName,
          );
        } else {
          _showErrorDialog(
            result['message'] ?? 'Erreur lors du paiement',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog('Erreur: $e');
      }
    }
  }

  void _showPaymentProcessingDialog(String transactionId, String methodName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF2196F3)),
            SizedBox(width: 12),
            Text('Paiement en cours'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFF77F00),
            ),
            const SizedBox(height: 16),
            Text(
              'Veuillez composer #144# (pour $methodName) et valider la transaction.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Montant: ${SubscriptionModel.getPrice(_selectedPlan)} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction ID: $transactionId',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
