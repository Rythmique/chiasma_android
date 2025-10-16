import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toutes les notifications marquées comme lues'),
                  backgroundColor: Color(0xFF009E60),
                ),
              );
            },
            child: const Text(
              'Tout marquer lu',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildNotificationItem(
            context,
            icon: Icons.people,
            iconColor: const Color(0xFF009E60),
            title: 'Nouveau match mutuel trouvé !',
            subtitle: 'Un enseignant de Yamoussoukro correspond à vos critères',
            time: 'Il y a 5 min',
            isUnread: true,
          ),
          const Divider(height: 1),
          _buildNotificationItem(
            context,
            icon: Icons.message,
            iconColor: const Color(0xFF2196F3),
            title: 'Nouveau message',
            subtitle: 'Jean Dupont vous a envoyé un message',
            time: 'Il y a 1h',
            isUnread: true,
          ),
          const Divider(height: 1),
          _buildNotificationItem(
            context,
            icon: Icons.favorite,
            iconColor: Colors.red,
            title: 'Votre profil a été ajouté aux favoris',
            subtitle: 'Un enseignant s\'intéresse à votre profil',
            time: 'Il y a 2h',
            isUnread: false,
          ),
          const Divider(height: 1),
          _buildNotificationItem(
            context,
            icon: Icons.visibility,
            iconColor: const Color(0xFF9C27B0),
            title: 'Profil consulté',
            subtitle: '3 enseignants ont consulté votre profil aujourd\'hui',
            time: 'Il y a 3h',
            isUnread: false,
          ),
          const Divider(height: 1),
          _buildNotificationItem(
            context,
            icon: Icons.campaign,
            iconColor: const Color(0xFFF77F00),
            title: 'Nouvelle fonctionnalité',
            subtitle: 'Découvrez la messagerie instantanée !',
            time: 'Hier',
            isUnread: false,
          ),
          const Divider(height: 1),
          _buildNotificationItem(
            context,
            icon: Icons.workspace_premium,
            iconColor: Colors.orange[700]!,
            title: 'Offre Premium',
            subtitle: 'Profitez de 20% de réduction sur l\'abonnement annuel',
            time: 'Hier',
            isUnread: false,
          ),
          const Divider(height: 1),
          _buildNotificationItem(
            context,
            icon: Icons.message,
            iconColor: const Color(0xFF2196F3),
            title: 'Nouveau message',
            subtitle: 'Marie Kouassi: "Bonjour, pouvons-nous discuter..."',
            time: 'Il y a 2 jours',
            isUnread: false,
          ),
          const Divider(height: 1),
          _buildNotificationItem(
            context,
            icon: Icons.people,
            iconColor: const Color(0xFF009E60),
            title: 'Match mutuel',
            subtitle: 'Vous avez 2 nouveaux matchs mutuels',
            time: 'Il y a 3 jours',
            isUnread: false,
          ),
          const Divider(height: 1),
          _buildNotificationItem(
            context,
            icon: Icons.security,
            iconColor: const Color(0xFF009E60),
            title: 'Connexion depuis un nouveau appareil',
            subtitle: 'Si ce n\'était pas vous, changez votre mot de passe',
            time: 'Il y a 5 jours',
            isUnread: false,
          ),
          const Divider(height: 1),
          _buildNotificationItem(
            context,
            icon: Icons.info,
            iconColor: const Color(0xFF2196F3),
            title: 'Bienvenue sur CHIASMA',
            subtitle: 'Complétez votre profil pour augmenter vos chances',
            time: 'Il y a 1 semaine',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      color: isUnread
          ? const Color(0xFFF77F00).withValues(alpha: 0.05)
          : Colors.white,
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            if (isUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF77F00),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert, size: 20),
          onPressed: () {
            _showNotificationOptions(context);
          },
        ),
        onTap: () {
          // Action selon le type de notification
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification consultée'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  void _showNotificationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check, color: Color(0xFF009E60)),
              title: const Text('Marquer comme lu'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Marqué comme lu'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification supprimée'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
