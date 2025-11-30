import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/access_restrictions_service.dart';
import '../models/user_model.dart';
import 'subscription_required_dialog.dart';

/// Widget qui contrôle l'accès à l'application
/// Bloque l'utilisation si l'utilisateur n'est ni vérifié ni n'a de quota
/// Prend en compte les restrictions globales configurées par les admins
class AccessControlWrapper extends StatelessWidget {
  static const _orangeColor = Color(0xFFF77F00);
  static const _greenColor = Color(0xFF009E60);
  static const _borderRadius = 12.0;
  static const _iconSize = 80.0;

  final Widget child;
  final FirestoreService _firestoreService = FirestoreService();
  final AccessRestrictionsService _restrictionsService =
      AccessRestrictionsService();

  AccessControlWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return child;
    }

    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserStream(currentUser.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return child;
        }

        final user = userSnapshot.data!;

        return StreamBuilder<Map<String, bool>>(
          stream: _restrictionsService.getRestrictionsStream(),
          builder: (context, restrictionsSnapshot) {
            if (restrictionsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return _buildLoadingScreen();
            }

            final restrictions =
                restrictionsSnapshot.data ?? _getDefaultRestrictions();
            final canAccess = _canAccessApp(user, restrictions);

            return canAccess ? child : _buildBlockedScreen(context, user);
          },
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: _orangeColor)),
    );
  }

  Map<String, bool> _getDefaultRestrictions() {
    return {
      'teacher_transfer': true,
      'teacher_candidate': true,
      'school': true,
    };
  }

  bool _canAccessApp(UserModel user, Map<String, bool> restrictions) {
    final restrictionsEnabled = restrictions[user.accountType] ?? true;

    if (!restrictionsEnabled) return true;
    if (user.isVerified && !user.isVerificationExpired) return true;
    if (!user.isFreeQuotaExhausted) return true;

    return false;
  }

  Widget _buildBlockedScreen(BuildContext context, UserModel user) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLockIcon(),
                const SizedBox(height: 32),
                _buildTitle(),
                const SizedBox(height: 16),
                _buildMessage(user),
                const SizedBox(height: 32),
                _buildQuotaInfo(user),
                const SizedBox(height: 32),
                _buildSubscriptionButton(context, user),
                const SizedBox(height: 16),
                _buildLogoutButton(context),
                const SizedBox(height: 32),
                _buildInfoNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _orangeColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.lock_outline,
        size: _iconSize,
        color: _orangeColor,
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Accès Restreint',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _orangeColor,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage(UserModel user) {
    return Text(
      _getBlockMessage(user),
      style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildQuotaInfo(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quota gratuit utilisé',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                '${user.freeQuotaUsed}/${user.freeQuotaLimit}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.grey[200],
            color: Colors.red,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionButton(BuildContext context, UserModel user) {
    return ElevatedButton.icon(
      onPressed: () =>
          SubscriptionRequiredDialog.show(context, user.accountType),
      style: ElevatedButton.styleFrom(
        backgroundColor: _greenColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        elevation: 2,
      ),
      icon: const Icon(Icons.shopping_bag, size: 24),
      label: const Text(
        'Souscrire à un abonnement',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) Navigator.of(context).pushReplacementNamed('/');
      },
      icon: const Icon(Icons.logout, size: 20),
      label: const Text('Se déconnecter'),
      style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _orangeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: _orangeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: _orangeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Contactez-nous via WhatsApp pour activer votre abonnement après paiement.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Génère le message de blocage selon le type de compte
  String _getBlockMessage(UserModel user) {
    if (user.isFreeQuotaExhausted && !user.isVerified) {
      // Quota épuisé ET pas vérifié
      return 'Votre quota gratuit a été entièrement utilisé. Pour continuer à utiliser l\'application, veuillez souscrire à un abonnement.';
    } else if (!user.isVerified && user.freeQuotaUsed == 0) {
      // Jamais vérifié et pas de quota utilisé
      return 'Votre compte n\'est pas encore vérifié. Veuillez attendre la vérification de votre compte par un administrateur.';
    } else if (user.isVerificationExpired) {
      // Abonnement expiré
      return 'Votre abonnement a expiré. Pour continuer à utiliser l\'application, veuillez renouveler votre abonnement.';
    }

    return 'Vous devez être vérifié ou disposer de quota gratuit pour accéder à l\'application.';
  }
}
