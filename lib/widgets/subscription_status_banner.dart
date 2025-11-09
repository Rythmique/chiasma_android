import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/access_restrictions_service.dart';

class SubscriptionStatusBanner extends StatelessWidget {
  final UserModel user;
  final AccessRestrictionsService _restrictionsService = AccessRestrictionsService();

  SubscriptionStatusBanner({
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
        return _buildBanner();
      },
    );
  }

  Widget _buildBanner() {
    // Ne pas afficher si l'utilisateur n'est pas vérifié OU n'a pas de date d'expiration
    if (!user.isVerified || user.verificationExpiresAt == null) {
      return const SizedBox.shrink();
    }

    final daysLeft = user.daysUntilExpiration;
    final isExpired = user.isVerificationExpired;

    // Déterminer la couleur selon le temps restant
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    if (isExpired || daysLeft == 0) {
      backgroundColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
      icon = Icons.error_outline;
      message = 'Votre abonnement a expiré';
    } else if (daysLeft! <= 3) {
      backgroundColor = Colors.orange[50]!;
      textColor = Colors.orange[700]!;
      icon = Icons.warning_amber;
      message = 'Expire dans $daysLeft jour${daysLeft > 1 ? "s" : ""}';
    } else if (daysLeft <= 7) {
      backgroundColor = Colors.yellow[50]!;
      textColor = Colors.orange[600]!;
      icon = Icons.access_time;
      message = 'Expire dans $daysLeft jours';
    } else {
      backgroundColor = Colors.green[50]!;
      textColor = Colors.green[700]!;
      icon = Icons.check_circle_outline;
      message = 'Compte vérifié — expire dans $daysLeft jours';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: textColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isExpired && daysLeft != null && daysLeft > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Jusqu\'au ${_formatDate(user.verificationExpiresAt!)}',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
