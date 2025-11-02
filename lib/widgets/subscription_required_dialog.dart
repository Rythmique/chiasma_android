import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionRequiredDialog extends StatelessWidget {
  final String accountType;

  const SubscriptionRequiredDialog({
    super.key,
    required this.accountType,
  });

  // Liens de paiement pour chaque prix (à configurer)
  static final Map<String, Map<String, String>> _paymentLinks = {
    'teacher_transfer': {
      '1_month': 'https://pay.wave.com/m/M_ci_zRdAK78v8F1I/c/ci/?amount=500', // 500 F - Configuré ✅
      '3_months': 'https://pay.wave.com/m/M_ci_zRdAK78v8F1I/c/ci/?amount=1500', // 1 500 F - Configuré ✅
      '12_months': 'https://pay.wave.com/m/M_ci_zRdAK78v8F1I/c/ci/?amount=2500', // 2 500 F - Configuré ✅
    },
    'teacher_candidate': {
      '1_week': 'https://pay.wave.com/m/M_ci_zRdAK78v8F1I/c/ci/?amount=500', // 500 F - Configuré ✅
      '1_month': 'https://pay.wave.com/m/M_ci_zRdAK78v8F1I/c/ci/?amount=1500', // 1 500 F - Configuré ✅
      '12_months': 'https://pay.wave.com/m/M_ci_zRdAK78v8F1I/c/ci/?amount=20000', // 20 000 F - Configuré ✅
    },
    'school': {
      '1_week': 'https://pay.wave.com/m/M_ci_zRdAK78v8F1I/c/ci/?amount=2000', // 2 000 F - Configuré ✅
      '1_month': 'https://pay.wave.com/m/M_ci_zRdAK78v8F1I/c/ci/?amount=5000', // 5 000 F - Configuré ✅
      '12_months': 'https://pay.wave.com/m/M_ci_zRdAK78v8F1I/c/ci/?amount=90000', // 90 000 F - Configuré ✅
    },
  };

  String _getPaymentLink(String duration) {
    return _paymentLinks[accountType]?[duration] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final prices = SubscriptionService.getSubscriptionPrices(accountType);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône et titre
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF77F00).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_membership,
                  size: 48,
                  color: Color(0xFFF77F00),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Abonnement requis',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                _getDescription(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Boutons de prix
              ...prices.entries.map((entry) {
                return _buildPriceButton(
                  context,
                  duration: entry.key,
                  durationLabel: SubscriptionService.getDurationLabel(entry.key),
                  price: entry.value,
                  paymentLink: _getPaymentLink(entry.key),
                );
              }),

              const SizedBox(height: 20),

              // Divider
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),

              // Informations de contact
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF009E60).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF009E60).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF009E60),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Besoin d\'aide ?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_android,
                          color: Color(0xFF009E60),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '+225 0758747888',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF009E60),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                              const ClipboardData(text: '+225 0758747888'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Numéro copié !'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Color(0xFF009E60),
                              ),
                            );
                          },
                          tooltip: 'Copier',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final whatsappUrl = Uri.parse(
                            'https://wa.me/2250758747888',
                          );
                          if (await canLaunchUrl(whatsappUrl)) {
                            await launchUrl(
                              whatsappUrl,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('Contacter via WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF009E60)),
                          foregroundColor: const Color(0xFF009E60),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bouton Fermer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDescription() {
    switch (accountType) {
      case 'teacher_transfer':
        return 'Votre quota de consultations gratuites est épuisé. Choisissez un abonnement pour continuer.';
      case 'teacher_candidate':
        return 'Votre quota de candidatures gratuites est épuisé. Choisissez un abonnement pour continuer à postuler.';
      case 'school':
        return 'Votre quota d\'offres gratuites est épuisé. Choisissez un abonnement pour continuer à publier.';
      default:
        return 'Choisissez un abonnement pour continuer.';
    }
  }

  Widget _buildPriceButton(
    BuildContext context, {
    required String duration,
    required String durationLabel,
    required String price,
    required String paymentLink,
  }) {
    final bool hasPaymentLink = paymentLink.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bouton de prix
          ElevatedButton(
            onPressed: hasPaymentLink
                ? () async {
                    final uri = Uri.parse(paymentLink);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossible d\'ouvrir le lien de paiement'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF77F00),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              elevation: hasPaymentLink ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: hasPaymentLink ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      durationLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hasPaymentLink
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    price,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: hasPaymentLink ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lien de paiement (si disponible)
          if (hasPaymentLink)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Cliquez pour payer via le lien sécurisé',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Contactez-nous via WhatsApp pour ce tarif',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Variable statique pour s'assurer qu'on n'affiche le dialogue qu'une seule fois
  static bool _isShowing = false;

  static Future<void> show(BuildContext context, String accountType) async {
    // Éviter d'afficher plusieurs dialogues en même temps
    if (_isShowing) return;

    _isShowing = true;
    await showDialog(
      context: context,
      barrierDismissible: true, // Peut maintenant être fermé en cliquant à l'extérieur
      builder: (context) => SubscriptionRequiredDialog(
        accountType: accountType,
      ),
    );
    _isShowing = false;
  }

  // Méthode pour réinitialiser (utile pour les tests)
  static void reset() {
    _isShowing = false;
  }
}
