import 'package:flutter/material.dart';
import 'package:myapp/privacy_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _messageNotifications = true;
  bool _matchNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Section Compte
          _buildSectionHeader('Compte'),
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Modifier le profil',
            subtitle: 'Nom, fonction, zones...',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Édition du profil - Fonctionnalité à venir'),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Changer le mot de passe',
            subtitle: 'Modifier votre mot de passe',
            onTap: () {
              _showChangePasswordDialog(context);
            },
          ),
          _buildSettingsTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: 'jean.dupont@education.ci',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Modification email - Fonctionnalité à venir'),
                ),
              );
            },
          ),

          const Divider(height: 32),

          // Section Notifications
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Activer les notifications',
            subtitle: 'Recevoir toutes les notifications',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Notifications par email',
            subtitle: 'Recevoir des emails de notification',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
            enabled: _notificationsEnabled,
          ),
          _buildSwitchTile(
            icon: Icons.message_outlined,
            title: 'Nouveaux messages',
            subtitle: 'Alertes pour les nouveaux messages',
            value: _messageNotifications,
            onChanged: (value) {
              setState(() {
                _messageNotifications = value;
              });
            },
            enabled: _notificationsEnabled,
          ),
          _buildSwitchTile(
            icon: Icons.people_outline,
            title: 'Matchs mutuels',
            subtitle: 'Alertes pour les correspondances trouvées',
            value: _matchNotifications,
            onChanged: (value) {
              setState(() {
                _matchNotifications = value;
              });
            },
            enabled: _notificationsEnabled,
          ),

          const Divider(height: 32),

          // Section Confidentialité
          _buildSectionHeader('Confidentialité et sécurité'),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Confidentialité',
            subtitle: 'Gérer la visibilité de votre profil',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsPage(),
                ),
              );
            },
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          _buildSettingsTile(
            icon: Icons.block,
            title: 'Utilisateurs bloqués',
            subtitle: 'Gérer les utilisateurs bloqués',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Liste des bloqués - Fonctionnalité à venir'),
                ),
              );
            },
          ),

          const Divider(height: 32),

          // Section Application
          _buildSectionHeader('Application'),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Langue',
            subtitle: 'Français',
            onTap: () {
              _showLanguageDialog(context);
            },
          ),
          _buildSettingsTile(
            icon: Icons.storage,
            title: 'Données et stockage',
            subtitle: 'Gérer le cache et les données',
            onTap: () {
              _showStorageDialog(context);
            },
          ),

          const Divider(height: 32),

          // Section Support
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Aide',
            subtitle: 'FAQ et support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Page d\'aide - Fonctionnalité à venir'),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.bug_report,
            title: 'Signaler un problème',
            subtitle: 'Nous aider à améliorer l\'application',
            onTap: () {
              _showReportDialog(context);
            },
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'À propos',
            subtitle: 'Version 1.0.0',
            onTap: () {
              _showAboutDialog(context);
            },
          ),

          const SizedBox(height: 16),

          // Bouton de déconnexion
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Déconnexion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF77F00),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF77F00).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFF77F00), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF77F00).withValues(alpha: enabled ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFFF77F00) : Colors.grey,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: enabled ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: const Color(0xFFF77F00),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mot de passe modifié avec succès'),
                  backgroundColor: Color(0xFF009E60),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF77F00),
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Choisir la langue'),
        content: RadioGroup<String>(
          groupValue: 'fr',
          onChanged: (value) {
            if (value == 'fr') {
              Navigator.pop(context);
            } else {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Langue modifiée - Fonctionnalité à venir'),
                ),
              );
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text('Français'),
                value: 'fr',
                activeColor: const Color(0xFFF77F00),
              ),
              RadioListTile(
                title: const Text('English'),
                value: 'en',
                activeColor: const Color(0xFFF77F00),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStorageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Données et stockage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache: 24 MB',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Données: 156 MB',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Effacer le cache libérera de l\'espace de stockage.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache effacé'),
                  backgroundColor: Color(0xFF009E60),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF77F00),
            ),
            child: const Text('Effacer le cache'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Signaler un problème'),
        content: TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Décrivez le problème rencontré...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Merci pour votre retour !'),
                  backgroundColor: Color(0xFF009E60),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF77F00),
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF77F00), Color(0xFF009E60)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.swap_horiz, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('CHIASMA'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Plateforme de permutation d\'enseignants en Côte d\'Ivoire.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2024 CHIASMA',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
