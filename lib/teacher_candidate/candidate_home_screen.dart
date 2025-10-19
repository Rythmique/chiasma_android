import 'package:flutter/material.dart';
import 'my_application_page.dart';
import 'job_offers_list_page.dart';
import '../services/auth_service.dart';
import '../login_screen.dart';
import '../change_password_page.dart';
import 'edit_candidate_profile_page.dart';

/// Écran d'accueil pour les candidats enseignants
class CandidateHomeScreen extends StatefulWidget {
  const CandidateHomeScreen({super.key});

  @override
  State<CandidateHomeScreen> createState() => _CandidateHomeScreenState();
}

class _CandidateHomeScreenState extends State<CandidateHomeScreen> {
  int _currentIndex = 0;

  // Les pages de navigation
  final List<Widget> _pages = [
    const JobOffersListPage(),
    const MyApplicationPage(),
    const CandidateMessagesPage(),
    const CandidateSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Offres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Ma candidature',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Paramètres',
          ),
        ],
      ),
    );
  }
}

/// Page des messages pour candidats
class CandidateMessagesPage extends StatelessWidget {
  const CandidateMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun message',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'À implémenter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page des paramètres pour candidats
class CandidateSettingsPage extends StatelessWidget {
  const CandidateSettingsPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // Afficher une confirmation
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Afficher les paramètres de notifications
  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres de notifications'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configurer vos préférences de notifications :',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Text('• Nouvelles offres d\'emploi'),
              Text('• Réponses aux candidatures'),
              Text('• Messages des établissements'),
              Text('• Recommandations personnalisées'),
              SizedBox(height: 16),
              Text(
                'Cette fonctionnalité sera disponible prochainement.',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Afficher l'aide
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comment utiliser CHIASMA ?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                '🔍 Rechercher des offres',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Parcourez les offres d\'emploi disponibles dans l\'onglet "Offres" et filtrez par matière, niveau ou localisation.'),
              SizedBox(height: 12),
              Text(
                '📝 Postuler à une offre',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Cliquez sur une offre pour voir les détails, puis appuyez sur "Postuler" pour envoyer votre candidature.'),
              SizedBox(height: 12),
              Text(
                '📋 Suivre vos candidatures',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Accédez à "Mes candidatures" pour voir l\'état de vos candidatures (en attente, acceptée, refusée).'),
              SizedBox(height: 12),
              Text(
                '👤 Mettre à jour votre profil',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Gardez votre profil à jour dans "Paramètres > Modifier mon profil" pour maximiser vos chances.'),
              SizedBox(height: 16),
              Text(
                'Pour plus d\'assistance, contactez-nous à support@chiasma.com',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Afficher à propos
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de CHIASMA'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHIASMA',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6F00),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 16),
              Text(
                'Plateforme de mise en relation entre enseignants et établissements scolaires en Côte d\'Ivoire.',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Text(
                '📧 Contact',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('support@chiasma.com'),
              SizedBox(height: 12),
              Text(
                '🌐 Site web',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('www.chiasma.com'),
              SizedBox(height: 16),
              Text(
                '© 2025 CHIASMA. Tous droits réservés.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Modifier mon profil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditCandidateProfilePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showNotificationSettings(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Aide'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showHelpDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('À propos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}
