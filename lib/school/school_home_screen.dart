import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_job_offers_page.dart';
import 'browse_candidates_page.dart';
import 'edit_school_profile_page.dart';
import 'favorites_page.dart';
import 'notification_settings_page.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/app_update_service.dart';
import '../services/update_checker_service.dart';
import '../models/user_model.dart';
import '../login_screen.dart';
import '../change_password_page.dart';
import '../chat_page.dart';

/// Écran d'accueil pour les établissements (recruteurs)
class SchoolHomeScreen extends StatefulWidget {
  const SchoolHomeScreen({super.key});

  @override
  State<SchoolHomeScreen> createState() => _SchoolHomeScreenState();
}

class _SchoolHomeScreenState extends State<SchoolHomeScreen> {
  int _currentIndex = 0;

  // Les pages de navigation
  final List<Widget> _pages = [
    const MyJobOffersPage(),
    const BrowseCandidatesPage(),
    const SchoolMessagesPage(),
    const SchoolSettingsPage(),
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
            label: 'Mes offres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Candidats',
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

/// Page des messages pour établissements
class SchoolMessagesPage extends StatefulWidget {
  const SchoolMessagesPage({super.key});

  @override
  State<SchoolMessagesPage> createState() => _SchoolMessagesPageState();
}

class _SchoolMessagesPageState extends State<SchoolMessagesPage> {
  final FirestoreService _firestoreService = FirestoreService();

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: Text('Veuillez vous connecter')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getConversations(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          final conversations = snapshot.data?.docs ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyView();
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversationDoc = conversations[index];
              final conversationData = conversationDoc.data() as Map<String, dynamic>;
              return _buildConversationTile(
                conversationDoc.id,
                conversationData,
                currentUser.uid,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
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
            'Vos conversations avec les candidats apparaîtront ici',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    String conversationId,
    Map<String, dynamic> conversationData,
    String currentUserId,
  ) {
    // Récupérer l'ID de l'autre participant
    final participants = conversationData['participants'] as List<dynamic>;
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<UserModel?>(
      future: _firestoreService.getUser(otherUserId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const SizedBox.shrink();
        }

        final otherUser = userSnapshot.data!;
        final lastMessage = conversationData['lastMessage'] as String? ?? '';
        final lastMessageTime = conversationData['lastMessageTime'] as Timestamp?;

        // Récupérer le compteur de messages non lus
        final unreadCount = conversationData['unreadCount'] as Map<String, dynamic>?;
        final unreadMessages = (unreadCount?[currentUserId] as int?) ?? 0;
        final hasUnread = unreadMessages > 0;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.2),
                child: Text(
                  otherUser.nom
                      .split(' ')
                      .map((word) => word.isNotEmpty ? word[0] : '')
                      .take(2)
                      .join()
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFF77F00),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (otherUser.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              // Badge de messages non lus
              if (hasUnread)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      unreadMessages > 9 ? '9+' : '$unreadMessages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            otherUser.nom,
            style: TextStyle(
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                otherUser.fonction,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF009E60),
                ),
              ),
              if (lastMessage.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: hasUnread ? Colors.black87 : Colors.grey[600],
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
          trailing: lastMessageTime != null
              ? Text(
                  _formatTime(lastMessageTime.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                )
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  contactName: otherUser.nom,
                  contactFunction: otherUser.fonction,
                  isOnline: otherUser.isOnline,
                  conversationId: conversationId,
                  contactUserId: otherUser.uid,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Page des paramètres pour établissements
class SchoolSettingsPage extends StatelessWidget {
  const SchoolSettingsPage({super.key});

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SchoolNotificationSettingsPage(),
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
                '📝 Publier une offre',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Accédez à "Mes offres" et cliquez sur le bouton "+" pour créer une nouvelle offre d\'emploi.'),
              SizedBox(height: 12),
              Text(
                '👥 Consulter les candidats',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Naviguez dans l\'onglet "Candidats" pour voir les enseignants qui ont postulé à vos offres.'),
              SizedBox(height: 12),
              Text(
                '✉️ Contacter un candidat',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Cliquez sur "Contacter" pour voir les coordonnées et envoyer un email au candidat.'),
              SizedBox(height: 12),
              Text(
                '⚙️ Gérer vos offres',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('Vous pouvez modifier, dupliquer, suspendre ou supprimer vos offres via le menu "⋮".'),
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
              Text('www.chiasma.pro'),
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
            leading: const Icon(Icons.business),
            title: const Text('Informations de l\'établissement'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditSchoolProfilePage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text('Mes favoris'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SchoolFavoritesPage(),
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
            leading: const Icon(Icons.system_update),
            title: const Text('Vérifier les mises à jour'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Vérifier via Play Store
              await AppUpdateService.checkForUpdateManually(context);
              // Vérifier via serveur Chiasma (pour installations hors Play Store)
              if (context.mounted) {
                await UpdateCheckerService.checkManually(context);
              }
            },
          ),
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
