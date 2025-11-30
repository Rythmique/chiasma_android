import 'package:flutter/material.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/access_restrictions_service.dart';

class QuotaStatusWidget extends StatelessWidget {
  static const _greenColor = Color(0xFF009E60);
  static const _borderRadius = 12.0;

  final UserModel user;
  final AccessRestrictionsService _restrictionsService =
      AccessRestrictionsService();

  QuotaStatusWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, bool>>(
      stream: _restrictionsService.getRestrictionsStream(),
      builder: (context, snapshot) {
        final restrictions = snapshot.data ?? _getDefaultRestrictions();
        final restrictionsEnabled = restrictions[user.accountType] ?? true;

        return restrictionsEnabled
            ? _buildQuotaWidget()
            : const SizedBox.shrink();
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

  Widget _buildQuotaWidget() {
    // Pour teacher_transfer: masquer le widget complètement si vérifié (peu importe le quota)
    if (user.accountType == 'teacher_transfer' &&
        user.isVerified &&
        !user.isVerificationExpired) {
      return const SizedBox.shrink();
    }

    // Pour les autres types de compte: masquer si vérifié ET quota non épuisé
    if (user.isVerified &&
        !user.isVerificationExpired &&
        !user.isFreeQuotaExhausted) {
      return const SizedBox.shrink();
    }

    final quotaRemaining = user.freeQuotaLimit - user.freeQuotaUsed;
    final percentage = user.freeQuotaLimit > 0
        ? user.freeQuotaUsed / user.freeQuotaLimit
        : 0.0;
    final color = _getQuotaColor(quotaRemaining);
    final actionLabel = _getActionLabel(user.accountType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
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
          _buildHeader(color, quotaRemaining),
          const SizedBox(height: 12),
          _buildProgressBar(percentage, color),
          const SizedBox(height: 8),
          _buildStatusText(quotaRemaining, actionLabel),
        ],
      ),
    );
  }

  Color _getQuotaColor(int remaining) {
    if (remaining == 0) return Colors.red;
    if (remaining <= 1) return Colors.orange;
    return _greenColor;
  }

  Widget _buildHeader(Color color, int quotaRemaining) {
    return Row(
      children: [
        Icon(Icons.stars, color: color, size: 24),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Text(
            '$quotaRemaining / ${user.freeQuotaLimit}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double percentage, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: percentage,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: 8,
      ),
    );
  }

  Widget _buildStatusText(int quotaRemaining, String actionLabel) {
    return Text(
      quotaRemaining > 0
          ? 'Il vous reste $quotaRemaining $actionLabel'
          : 'Quota épuisé - Prenez un abonnement pour continuer',
      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
