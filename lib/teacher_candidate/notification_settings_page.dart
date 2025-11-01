import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_settings_model.dart';
import '../services/notification_settings_service.dart';

/// Page des paramètres de notifications pour les candidats
class CandidateNotificationSettingsPage extends StatefulWidget {
  const CandidateNotificationSettingsPage({super.key});

  @override
  State<CandidateNotificationSettingsPage> createState() =>
      _CandidateNotificationSettingsPageState();
}

class _CandidateNotificationSettingsPageState
    extends State<CandidateNotificationSettingsPage> {
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
          _settings = _settings!.copyWith(
            messages: settingKey == 'messages' ? value : _settings!.messages,
            newJobOffers: settingKey == 'newJobOffers' ? value : _settings!.newJobOffers,
            applicationStatus: settingKey == 'applicationStatus' ? value : _settings!.applicationStatus,
            jobRecommendations: settingKey == 'jobRecommendations' ? value : _settings!.jobRecommendations,
            updatedAt: DateTime.now(),
          );
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
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
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
                          subtitle: 'Notifications des nouveaux messages des établissements',
                          icon: Icons.message,
                          value: _settings!.messages,
                          onChanged: (value) => _updateSetting('messages', value),
                        ),
                        const Divider(height: 32),

                        // Section Offres d'emploi
                        _buildSectionHeader('Offres d\'emploi'),
                        _buildSettingTile(
                          title: 'Nouvelles offres',
                          subtitle: 'Soyez informé des nouvelles offres correspondant à votre profil',
                          icon: Icons.work,
                          value: _settings!.newJobOffers,
                          onChanged: (value) => _updateSetting('newJobOffers', value),
                        ),
                        _buildSettingTile(
                          title: 'Recommandations',
                          subtitle: 'Recevez des offres personnalisées selon vos préférences',
                          icon: Icons.star,
                          value: _settings!.jobRecommendations,
                          onChanged: (value) =>
                              _updateSetting('jobRecommendations', value),
                        ),
                        const Divider(height: 32),

                        // Section Candidatures
                        _buildSectionHeader('Candidatures'),
                        _buildSettingTile(
                          title: 'Statut des candidatures',
                          subtitle: 'Notifications lorsque vos candidatures sont acceptées ou refusées',
                          icon: Icons.check_circle,
                          value: _settings!.applicationStatus,
                          onChanged: (value) =>
                              _updateSetting('applicationStatus', value),
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
                                    'Les notifications importantes (comme les réponses aux candidatures) seront toujours affichées dans l\'application',
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
        child: Icon(
          icon,
          color: value ? const Color(0xFFF77F00) : Colors.grey,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: _isSaving ? null : onChanged,
        activeTrackColor: const Color(0xFFF77F00),
      ),
    );
  }
}
