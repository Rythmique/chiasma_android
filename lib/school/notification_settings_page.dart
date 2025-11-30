import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_settings_model.dart';
import '../services/notification_settings_service.dart';

/// Page des paramètres de notifications pour les écoles
class SchoolNotificationSettingsPage extends StatefulWidget {
  const SchoolNotificationSettingsPage({super.key});

  @override
  State<SchoolNotificationSettingsPage> createState() =>
      _SchoolNotificationSettingsPageState();
}

class _SchoolNotificationSettingsPageState
    extends State<SchoolNotificationSettingsPage> {
  final NotificationSettingsService _settingsService =
      NotificationSettingsService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  NotificationSettingsModel? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_userId == null) return;

    try {
      final settings = await _settingsService.getUserSettings(_userId);
      if (mounted) {
        setState(() {
          _settings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateSetting(String settingKey, bool value) async {
    if (_userId == null || _settings == null) return;

    setState(() => _isSaving = true);

    try {
      await _settingsService.updateSetting(_userId, settingKey, value);

      if (mounted) {
        setState(() {
          _settings = _updateSettingsModel(settingKey, value);
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  NotificationSettingsModel _updateSettingsModel(String key, bool value) {
    return _settings!.copyWith(
      messages: key == 'messages' ? value : _settings!.messages,
      newApplications: key == 'newApplications'
          ? value
          : _settings!.newApplications,
      offerExpiration: key == 'offerExpiration'
          ? value
          : _settings!.offerExpiration,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _resetToDefaults() async {
    if (_userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser'),
        content: const Text(
          'Voulez-vous réinitialiser tous les paramètres de notifications aux valeurs par défaut ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF77F00),
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);

      try {
        await _settingsService.resetToDefaults(_userId);
        await _loadSettings();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paramètres réinitialisés avec succès'),
              backgroundColor: Color(0xFF009E60),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _settings != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetToDefaults,
              tooltip: 'Réinitialiser',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
          ? const Center(child: Text('Erreur de chargement'))
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // En-tête
                    Card(
                      color: const Color(0xFFF77F00).withValues(alpha: 0.1),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: Color(0xFFF77F00),
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gérez vos notifications',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF77F00),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Choisissez les notifications que vous souhaitez recevoir',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Communications
                    _buildSectionHeader('Communications'),
                    _buildSettingTile(
                      title: 'Messages',
                      subtitle:
                          'Notifications des nouveaux messages des candidats',
                      icon: Icons.message,
                      value: _settings!.messages,
                      onChanged: (value) => _updateSetting('messages', value),
                    ),
                    const Divider(height: 32),

                    // Section Candidatures
                    _buildSectionHeader('Candidatures'),
                    _buildSettingTile(
                      title: 'Nouvelles candidatures',
                      subtitle:
                          'Soyez informé quand des candidats postulent à vos offres',
                      icon: Icons.person_add,
                      value: _settings!.newApplications,
                      onChanged: (value) =>
                          _updateSetting('newApplications', value),
                    ),
                    const Divider(height: 32),

                    // Section Offres
                    _buildSectionHeader('Gestion des offres'),
                    _buildSettingTile(
                      title: 'Expiration des offres',
                      subtitle:
                          'Rappels avant l\'expiration de vos offres d\'emploi',
                      icon: Icons.schedule,
                      value: _settings!.offerExpiration,
                      onChanged: (value) =>
                          _updateSetting('offerExpiration', value),
                    ),
                    const SizedBox(height: 24),

                    // Informations supplémentaires
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Les notifications importantes seront toujours affichées dans l\'application pour ne rien manquer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Conseils
                    Card(
                      color: const Color(0xFF009E60).withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Conseil',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Activez les notifications de nouvelles candidatures pour répondre rapidement aux candidats et améliorer vos chances de recruter les meilleurs profils.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Enregistrement...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF009E60),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFFF77F00).withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: value ? const Color(0xFFF77F00) : Colors.grey),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: _isSaving ? null : onChanged,
        activeTrackColor: const Color(0xFFF77F00),
      ),
    );
  }
}
