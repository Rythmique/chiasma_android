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

  @override
  Widget build(BuildContext context) {
    final message = SubscriptionService.getSubscriptionMessage(accountType);
    final prices = SubscriptionService.getSubscriptionPrices(accountType);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF77F00).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 48,
                color: Color(0xFFF77F00),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            const Text(
              'Abonnement requis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Tarifs
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tarifs disponibles :',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...prices.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Color(0xFF009E60),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${SubscriptionService.getDurationLabel(entry.key)} : ',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF77F00),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Informations de paiement
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF009E60).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF009E60).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.phone_android,
                    color: Color(0xFF009E60),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '+225 0758747888',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009E60),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(
                        const ClipboardData(text: '+225 0758747888'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Numéro copié !'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copier le numéro',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
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
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF009E60)),
                      foregroundColor: const Color(0xFF009E60),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF77F00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      barrierDismissible: false, // Ne peut être fermé qu'avec le bouton
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
