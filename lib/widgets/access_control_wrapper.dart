import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'subscription_required_dialog.dart';

/// Widget qui contrôle l'accès à l'application
/// Bloque l'utilisation si l'utilisateur n'est ni vérifié ni n'a de quota
class AccessControlWrapper extends StatelessWidget {
  final Widget child;
  final FirestoreService _firestoreService = FirestoreService();

  AccessControlWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return child;
    }

    return StreamBuilder<UserModel?>(
      stream: _firestoreService.getUserStream(currentUser.uid),
      builder: (context, snapshot) {
        // Afficher un loader pendant le chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF77F00),
              ),
            ),
          );
        }

        // Si erreur ou pas de données, afficher l'enfant par défaut
        if (snapshot.hasError || !snapshot.hasData) {
          return child;
        }

        final user = snapshot.data!;

        // Vérifier si l'utilisateur peut accéder à l'application
        final canAccess = _canAccessApp(user);

        if (!canAccess) {
          // Bloquer l'accès et afficher l'écran de blocage
          return _buildBlockedScreen(context, user);
        }

        // Accès autorisé
        return child;
      },
    );
  }

  /// Vérifie si l'utilisateur peut accéder à l'application
  bool _canAccessApp(UserModel user) {
    // 1. Si l'utilisateur est vérifié et l'abonnement n'est pas expiré → Accès autorisé
    if (user.isVerified && !user.isVerificationExpired) {
      return true;
    }

    // 2. Si l'utilisateur a du quota gratuit disponible → Accès autorisé
    if (!user.isFreeQuotaExhausted) {
      return true;
    }

    // 3. Sinon → Accès bloqué
    return false;
  }

  /// Écran de blocage affiché quand l'accès est refusé
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
                // Icône de verrouillage
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF77F00).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Color(0xFFF77F00),
                  ),
                ),

                const SizedBox(height: 32),

                // Titre
                const Text(
                  'Accès Restreint',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF77F00),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Message explicatif
                Text(
                  _getBlockMessage(user),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Informations sur le quota
                Container(
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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
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
                        value: 1.0, // Quota épuisé
                        backgroundColor: Colors.grey[200],
                        color: Colors.red,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton pour prendre un abonnement
                ElevatedButton.icon(
                  onPressed: () {
                    SubscriptionRequiredDialog.show(context, user.accountType);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009E60),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.shopping_bag, size: 24),
                  label: const Text(
                    'Souscrire à un abonnement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bouton de déconnexion
                TextButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/');
                    }
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Se déconnecter'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 32),

                // Note informative
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF77F00).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF77F00).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFF77F00),
                        size: 24,
                      ),
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
                ),
              ],
            ),
          ),
        ),
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
