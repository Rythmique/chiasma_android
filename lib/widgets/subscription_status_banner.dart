import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/access_restrictions_service.dart';

class SubscriptionStatusBanner extends StatelessWidget {
  static const _borderRadius = 12.0;
  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  final UserModel user;
  final AccessRestrictionsService _restrictionsService =
      AccessRestrictionsService();

  SubscriptionStatusBanner({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, bool>>(
      stream: _restrictionsService.getRestrictionsStream(),
      builder: (context, snapshot) {
        final restrictions = snapshot.data ?? _getDefaultRestrictions();
        final restrictionsEnabled = restrictions[user.accountType] ?? true;

        return restrictionsEnabled ? _buildBanner() : const SizedBox.shrink();
      },
    );
  }

  Map<String, bool> _getDefaultRestrictions() {
    return {
      'teacher_transfer': true,
      'teacher_candidate': true,
      'school': true,
    };
  }

  Widget _buildBanner() {
    if (!user.isVerified || user.verificationExpiresAt == null) {
      return const SizedBox.shrink();
    }

    final daysLeft = user.daysUntilExpiration;
    final isExpired = user.isVerificationExpired;
    final bannerData = _getBannerData(daysLeft, isExpired);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerData.backgroundColor,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: bannerData.textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(bannerData.icon, color: bannerData.textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerData.message,
                  style: TextStyle(
                    color: bannerData.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isExpired && daysLeft != null && daysLeft > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Jusqu\'au ${_formatDate(user.verificationExpiresAt!)}',
                    style: TextStyle(
                      color: bannerData.textColor.withValues(alpha: 0.8),
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

  _BannerData _getBannerData(int? daysLeft, bool isExpired) {
    if (isExpired || daysLeft == 0) {
      return _BannerData(
        backgroundColor: Colors.red[50]!,
        textColor: Colors.red[700]!,
        icon: Icons.error_outline,
        message: 'Votre abonnement a expiré',
      );
    } else if (daysLeft! <= 3) {
      return _BannerData(
        backgroundColor: Colors.orange[50]!,
        textColor: Colors.orange[700]!,
        icon: Icons.warning_amber,
        message: 'Expire dans $daysLeft jour${daysLeft > 1 ? "s" : ""}',
      );
    } else if (daysLeft <= 7) {
      return _BannerData(
        backgroundColor: Colors.yellow[50]!,
        textColor: Colors.orange[600]!,
        icon: Icons.access_time,
        message: 'Expire dans $daysLeft jours',
      );
    }
    return _BannerData(
      backgroundColor: Colors.green[50]!,
      textColor: Colors.green[700]!,
      icon: Icons.check_circle_outline,
      message: 'Compte vérifié — expire dans $daysLeft jours',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }
}

class _BannerData {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final String message;

  _BannerData({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.message,
  });
}
