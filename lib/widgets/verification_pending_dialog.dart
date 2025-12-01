import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialogue affiché aux enseignants permutation non vérifiés
/// lorsque les restrictions admin sont désactivées et le quota épuisé
class VerificationPendingDialog extends StatelessWidget {
  static const _orangeColor = Color(0xFFF77F00);
  static const _greenColor = Color(0xFF009E60);
  static const _borderRadius = 12.0;
  static const _phoneNumber = '+225 0758747888';
  static const _whatsappUrl = 'https://wa.me/2250758747888';

  const VerificationPendingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildTitle(),
              const SizedBox(height: 16),
              _buildDescription(),
              const SizedBox(height: 24),
              _buildContactInfo(context),
              const SizedBox(height: 20),
              _buildCloseButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _orangeColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.hourglass_empty, size: 48, color: _orangeColor),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Vérification en cours',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return Column(
      children: [
        Text(
          'Votre compte enseignant permutation est en cours de vérification par notre équipe.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[800],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _orangeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(_borderRadius),
            border: Border.all(color: _orangeColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, color: _orangeColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Délai de vérification',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'La vérification de votre compte prend généralement environ 3 heures. Vous recevrez une notification dès que votre compte sera vérifié.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Si après ce délai votre compte n\'est toujours pas vérifié, veuillez contacter l\'administration via les moyens ci-dessous pour résoudre le problème.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.4,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _greenColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: _greenColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent, color: _greenColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Contacter l\'administration',
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
          _buildPhoneRow(context),
          const SizedBox(height: 8),
          _buildWhatsAppButton(),
        ],
      ),
    );
  }

  Widget _buildPhoneRow(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.phone_android, color: _greenColor, size: 18),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            _phoneNumber,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _greenColor,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: _phoneNumber));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Numéro copié !'),
                duration: Duration(seconds: 2),
                backgroundColor: _greenColor,
              ),
            );
          },
          tooltip: 'Copier',
        ),
      ],
    );
  }

  Widget _buildWhatsAppButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final uri = Uri.parse(_whatsappUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.chat, size: 18),
        label: const Text('Contacter via WhatsApp'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: _greenColor),
          foregroundColor: _greenColor,
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _orangeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
        ),
        child: const Text(
          'J\'ai compris',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Affiche le dialogue pour les enseignants permutation non vérifiés
  /// avec restrictions admin désactivées et quota épuisé
  static Future<void> show(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const VerificationPendingDialog(),
    );
  }
}
