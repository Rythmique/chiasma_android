import 'package:flutter/material.dart';

/// Badge de vérification pour les utilisateurs vérifiés
class VerifiedBadge extends StatelessWidget {
  static const _greenColor = Color(0xFF009E60);
  static const _borderRadius = 12.0;

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

    return showLabel ? _buildBadgeWithLabel() : _buildIcon();
  }

  Widget _buildBadgeWithLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _greenColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: _greenColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(width: 4),
          Text(
            'Vérifié',
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.w600,
              color: _greenColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Icon(Icons.verified, size: size, color: _greenColor);
  }
}

/// Badge de vérification avec tooltip
class VerifiedBadgeWithTooltip extends StatelessWidget {
  static const _greenColor = Color(0xFF009E60);
  static const _defaultTooltip = 'Utilisateur vérifié par l\'administration';

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

    return Tooltip(
      message: expirationInfo ?? _defaultTooltip,
      child: Icon(Icons.verified, size: size, color: _greenColor),
    );
  }
}
