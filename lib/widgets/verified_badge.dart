import 'package:flutter/material.dart';

/// Badge de vérification pour les utilisateurs vérifiés
class VerifiedBadge extends StatelessWidget {
  final bool isVerified;
  final double size;
  final bool showLabel;

  const VerifiedBadge({
    super.key,
    required this.isVerified,
    this.size = 20,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF009E60).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF009E60).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              size: size,
              color: const Color(0xFF009E60),
            ),
            const SizedBox(width: 4),
            Text(
              'Vérifié',
              style: TextStyle(
                fontSize: size * 0.7,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF009E60),
              ),
            ),
          ],
        ),
      );
    }

    return Icon(
      Icons.verified,
      size: size,
      color: const Color(0xFF009E60),
    );
  }
}

/// Badge de vérification avec tooltip
class VerifiedBadgeWithTooltip extends StatelessWidget {
  final bool isVerified;
  final double size;
  final String? expirationInfo;

  const VerifiedBadgeWithTooltip({
    super.key,
    required this.isVerified,
    this.size = 20,
    this.expirationInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();

    final tooltipMessage = expirationInfo ??
        'Utilisateur vérifié par l\'administration';

    return Tooltip(
      message: tooltipMessage,
      child: Icon(
        Icons.verified,
        size: size,
        color: const Color(0xFF009E60),
      ),
    );
  }
}
