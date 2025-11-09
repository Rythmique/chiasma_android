import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/access_restrictions_service.dart';

class QuotaStatusWidget extends StatelessWidget {
  final UserModel user;
  final AccessRestrictionsService _restrictionsService = AccessRestrictionsService();

  QuotaStatusWidget({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    // Écouter les restrictions en temps réel
    return StreamBuilder<Map<String, bool>>(
      stream: _restrictionsService.getRestrictionsStream(),
      builder: (context, restrictionsSnapshot) {
        // Récupérer les restrictions (valeurs par défaut si erreur)
        final restrictions = restrictionsSnapshot.data ?? {
          'teacher_transfer': true,
          'teacher_candidate': true,
          'school': true,
        };

        // Si les restrictions sont désactivées pour ce type de compte, ne rien afficher
        final restrictionsEnabled = restrictions[user.accountType] ?? true;
        if (!restrictionsEnabled) {
          return const SizedBox.shrink();
        }

        // Sinon, afficher le widget normalement
        return _buildQuotaWidget();
      },
    );
  }

  Widget _buildQuotaWidget() {
    final quotaUsed = user.freeQuotaUsed;
    final quotaLimit = user.freeQuotaLimit;
    final quotaRemaining = quotaLimit - quotaUsed;
    final percentage = quotaLimit > 0 ? quotaUsed / quotaLimit : 0.0;

    // Ne pas afficher si l'utilisateur a un abonnement actif ET n'a pas épuisé son quota
    if (user.isVerified && !user.isVerificationExpired && !user.isFreeQuotaExhausted) {
      return const SizedBox.shrink();
    }

    // Déterminer la couleur selon le quota restant
    Color color;
    if (quotaRemaining == 0) {
      color = Colors.red;
    } else if (quotaRemaining <= 1) {
      color = Colors.orange;
    } else {
      color = const Color(0xFF009E60);
    }

    String actionLabel = _getActionLabel(user.accountType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.stars,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Quota gratuit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$quotaRemaining / $quotaLimit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            quotaRemaining > 0
                ? 'Il vous reste $quotaRemaining $actionLabel'
                : 'Quota épuisé - Prenez un abonnement pour continuer',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _getActionLabel(String accountType) {
    switch (accountType) {
      case 'teacher_transfer':
        return 'consultation${user.freeQuotaLimit - user.freeQuotaUsed > 1 ? "s" : ""}';
      case 'teacher_candidate':
        return 'candidature${user.freeQuotaLimit - user.freeQuotaUsed > 1 ? "s" : ""}';
      case 'school':
        return 'offre${user.freeQuotaLimit - user.freeQuotaUsed > 1 ? "s" : ""}';
      default:
        return 'action${user.freeQuotaLimit - user.freeQuotaUsed > 1 ? "s" : ""}';
    }
  }
}
