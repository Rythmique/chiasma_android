import 'package:flutter/material.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/models/user_model.dart';

class WelcomeQuotaDialog extends StatelessWidget {
  static const _greenColor = Color(0xFF009E60);
  static const _orangeColor = Color(0xFFF77F00);
  static const _borderRadius = 12.0;

  final UserModel user;

  const WelcomeQuotaDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final welcomeMessage = SubscriptionService.getWelcomeMessage(
      user.accountType,
      user.freeQuotaLimit,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            const SizedBox(height: 16),
            _buildTitle(),
            const SizedBox(height: 16),
            _buildWelcomeMessage(welcomeMessage),
            const SizedBox(height: 16),
            _buildQuotaInfo(),
            const SizedBox(height: 24),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _greenColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.celebration, size: 48, color: _greenColor),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Bienvenue ${user.nom} !',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildWelcomeMessage(String message) {
    return Text(
      message,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _orangeColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildQuotaInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _orangeColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${user.freeQuotaLimit}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _getQuotaDescription(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Après utilisation de votre quota gratuit, vous pourrez souscrire à un abonnement pour continuer.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _greenColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          'Commencer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getQuotaDescription() {
    switch (user.accountType) {
      case 'teacher_transfer':
        return 'consultations gratuites pour trouver un partenaire de permutation';
      case 'teacher_candidate':
        return 'candidatures gratuites pour postuler aux offres d\'emploi';
      case 'school':
        return 'offre d\'emploi gratuite à publier';
      default:
        return 'actions gratuites';
    }
  }

  // Variable statique pour s'assurer qu'on n'affiche le dialogue qu'une seule fois
  static final Set<String> _shownForUsers = {};

  static Future<void> showIfFirstTime(
    BuildContext context,
    UserModel user,
  ) async {
    // Vérifier si c'est la première connexion (quota jamais utilisé)
    // ET qu'on n'a pas déjà affiché le dialogue pour cet utilisateur
    if (user.freeQuotaUsed == 0 &&
        user.lastQuotaResetDate == null &&
        !_shownForUsers.contains(user.uid)) {
      // Marquer comme affiché pour cet utilisateur
      _shownForUsers.add(user.uid);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WelcomeQuotaDialog(user: user),
      );
    }
  }

  // Méthode pour réinitialiser (utile pour les tests)
  static void reset() {
    _shownForUsers.clear();
  }
}
