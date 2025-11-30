import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/privacy_settings_page.dart';
import 'package:myapp/edit_profile_page.dart';
import 'package:myapp/admin_panel_page.dart';
import 'package:myapp/change_password_page.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/notification_settings_service.dart';
import 'package:myapp/services/update_checker_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  final bool _emailNotifications = true;
  bool _messageNotifications = true;
  bool _matchNotifications = true;
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationSettingsService _notificationService =
      NotificationSettingsService();
  UserModel? _currentUserData;
  bool _isLoadingUserData = true;
  String _cacheSize = 'Calcul...';
  final String _dataSize = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    _loadNotificationSettings();
  }

  /// Calculer la taille d'un répertoire
  Future<int> _getDirectorySize(Directory directory) async {
    int size = 0;
    try {
      if (await directory.exists()) {
        await for (var entity in directory.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur calcul taille: $e');
    }
    return size;
  }

  /// Formater la taille en MB
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Calculer la taille du cache
  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheSize = await _getDirectorySize(tempDir);

      if (mounted) {
        setState(() {
          _cacheSize = _formatBytes(cacheSize);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cacheSize = 'N/A';
        });
      }
    }
  }

  /// Effacer le cache
  Future<bool> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();

        // Effacer le cache d'images Flutter
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur lors de l\'effacement du cache: $e');
      return false;
    }
  }

  Future<void> _loadCurrentUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userData = await _firestoreService.getUser(currentUser.uid);
        if (mounted) {
          setState(() {
            _currentUserData = userData;
            _isLoadingUserData = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingUserData = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  Future<void> _loadNotificationSettings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final settings = await _notificationService.getUserSettings(
          currentUser.uid,
        );
        if (mounted) {
          setState(() {
            _messageNotifications = settings.messages;
            _matchNotifications =
                settings.newJobOffers ||
                settings.applicationStatus ||
                settings.jobRecommendations;
            _notificationsEnabled =
                _messageNotifications || _matchNotifications;
          });
        }
      } catch (e) {
        // Garder les valeurs par défaut en cas d'erreur
      }
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await _notificationService.updateSetting(currentUser.uid, key, value);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
          );
        }
      }
    }
  }

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
          // Section Administration (visible uniquement pour les admins)
          if (!_isLoadingUserData &&
              _currentUserData != null &&
              _currentUserData!.isAdmin) ...[
            _buildSectionHeader('Administration'),
            _buildSettingsTile(
              icon: Icons.admin_panel_settings,
              title: 'Panneau d\'administration',
              subtitle: 'Gérer les utilisateurs et vérifications',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelPage(),
                  ),
                );
              },
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Divider(height: 32),
          ],

          // Section Compte
          _buildSectionHeader('Compte'),
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Modifier le profil',
            subtitle: 'Nom, fonction, zones...',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
              // Si le profil a été modifié, rafraîchir les données utilisateur
              if (result == true && mounted) {
                _loadCurrentUserData();
                // Informer la page parente qu'une modification a eu lieu
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
          ),
          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Changer le mot de passe',
            subtitle: 'Modifier votre mot de passe',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                ),
              );
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
            onChanged: (value) async {
              setState(() {
                _notificationsEnabled = value;
              });
              // Activer/désactiver toutes les notifications
              if (!value) {
                await _updateNotificationSetting('messages', false);
                await _updateNotificationSetting('newJobOffers', false);
                await _updateNotificationSetting('applicationStatus', false);
                await _updateNotificationSetting('jobRecommendations', false);
                setState(() {
                  _messageNotifications = false;
                  _matchNotifications = false;
                });
              } else {
                await _updateNotificationSetting('messages', true);
                await _updateNotificationSetting('newJobOffers', true);
                setState(() {
                  _messageNotifications = true;
                  _matchNotifications = true;
                });
              }
            },
          ),
          _buildSwitchTile(
            icon: Icons.email_outlined,
            title: 'Notifications par email',
            subtitle: 'Fonctionnalité à venir',
            value: _emailNotifications,
            onChanged: (value) {
              // Ne fait rien - fonctionnalité désactivée
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Notifications par email - Fonctionnalité à venir',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            enabled: false,
          ),
          _buildSwitchTile(
            icon: Icons.message_outlined,
            title: 'Nouveaux messages',
            subtitle: 'Alertes pour les nouveaux messages',
            value: _messageNotifications,
            onChanged: (value) async {
              setState(() {
                _messageNotifications = value;
              });
              await _updateNotificationSetting('messages', value);
            },
            enabled: _notificationsEnabled,
          ),
          _buildSwitchTile(
            icon: Icons.people_outline,
            title: 'Matchs mutuels',
            subtitle: 'Alertes pour les correspondances trouvées',
            value: _matchNotifications,
            onChanged: (value) async {
              setState(() {
                _matchNotifications = value;
              });
              // Mettre à jour toutes les notifications de "match"
              await _updateNotificationSetting('newJobOffers', value);
              await _updateNotificationSetting('applicationStatus', value);
              await _updateNotificationSetting('jobRecommendations', value);
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
          _buildSettingsTile(
            icon: Icons.system_update,
            title: 'Vérifier les mises à jour',
            subtitle: 'Rechercher une nouvelle version',
            onTap: () async {
              // Vérifier via Firebase Cloud Functions
              if (context.mounted) {
                await UpdateCheckerService.checkManually(context);
              }
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing:
          trailing ??
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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
          color: const Color(
            0xFFF77F00,
          ).withValues(alpha: enabled ? 0.1 : 0.05),
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

  void _showStorageDialog(BuildContext context) async {
    // Calculer la taille du cache au moment de l'ouverture
    await _calculateCacheSize();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Données et stockage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cache:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    _cacheSize,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Données app:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    _dataSize,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Effacer le cache libérera de l\'espace de stockage sans supprimer vos données.',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Afficher un indicateur de chargement
                setDialogState(() {
                  _cacheSize = 'Effacement...';
                });

                // Effacer le cache
                final success = await _clearCache();

                // Recalculer la taille
                await _calculateCacheSize();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Cache effacé avec succès !'
                            : 'Erreur lors de l\'effacement du cache',
                      ),
                      backgroundColor: success
                          ? const Color(0xFF009E60)
                          : Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF77F00),
                foregroundColor: Colors.white,
              ),
              child: const Text('Effacer le cache'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final problemController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Signaler un problème'),
        content: TextField(
          controller: problemController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Décrivez le problème rencontré...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              problemController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final problemText = problemController.text.trim();

              if (problemText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez décrire le problème'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && _currentUserData != null) {
                  await _firestoreService.submitProblemReport(
                    userId: user.uid,
                    userName: _currentUserData!.nom,
                    userEmail: user.email ?? '',
                    accountType: _currentUserData!.accountType,
                    problemDescription: problemText,
                  );

                  problemController.dispose();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Merci pour votre retour ! Nous examinerons votre signalement.',
                        ),
                        backgroundColor: Color(0xFF009E60),
                      ),
                    );
                  }
                }
              } catch (e) {
                problemController.dispose();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de l\'envoi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF77F00), Color(0xFF009E60)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF77F00).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_horiz,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHIASMA',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF77F00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Plateforme de permutation et de matching professionnel pour les enseignants de Côte d\'Ivoire.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),

              const SizedBox(height: 20),

              // Objectif
              const Text(
                'Notre mission',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFFF77F00),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Faciliter les échanges de postes entre enseignants pour améliorer leur qualité de vie tout en maintenant l\'excellence de l\'enseignement.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Fonctionnalités principales
              const Text(
                'Fonctionnalités clés',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFFF77F00),
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureItem(
                Icons.search,
                'Recherche avancée par zone et critères',
              ),
              _buildFeatureItem(
                Icons.people,
                'Matching intelligent entre profils',
              ),
              _buildFeatureItem(Icons.chat_bubble, 'Messagerie sécurisée'),
              _buildFeatureItem(Icons.star, 'Gestion des favoris et alertes'),
              _buildFeatureItem(
                Icons.verified_user,
                'Vérification des profils',
              ),

              const SizedBox(height: 16),

              const Divider(),

              // Informations légales
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.copyright, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '2025 CHIASMA - Tous droits réservés',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.language, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'www.chiasma.pro',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Abidjan, Côte d\'Ivoire',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.email, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'contact@chiasma.ci',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Développeur
              Text(
                'Développé par N\'da',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Ouverture des conditions d\'utilisation - Fonctionnalité à venir',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.description, size: 16),
            label: const Text('CGU'),
          ),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Ouverture de la politique de confidentialité - Fonctionnalité à venir',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.privacy_tip, size: 16),
            label: const Text('Confidentialité'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF77F00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF009E60)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
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
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
