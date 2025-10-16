import 'package:flutter/material.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _hideProfile = false;
  bool _hidePhoneNumber = true;
  bool _showOnlineStatus = true;
  bool _allowMessages = true;
  String _profileVisibility = 'all'; // all, verified, none

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confidentialité'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Visibilité du profil
          _buildSectionCard(
            'Visibilité du profil',
            [
              _buildSwitchTile(
                icon: Icons.visibility_off,
                title: 'Masquer mon profil',
                subtitle: 'Votre profil ne sera pas visible dans les recherches',
                value: _hideProfile,
                onChanged: (value) {
                  setState(() {
                    _hideProfile = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Profil masqué'
                            : 'Profil visible',
                      ),
                      backgroundColor: const Color(0xFF009E60),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Qui peut voir mon profil',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              _buildRadioTile(
                title: 'Tout le monde',
                subtitle: 'Tous les utilisateurs peuvent voir votre profil',
                value: 'all',
                groupValue: _profileVisibility,
                onChanged: (value) {
                  setState(() {
                    _profileVisibility = value!;
                  });
                },
              ),
              _buildRadioTile(
                title: 'Utilisateurs vérifiés uniquement',
                subtitle: 'Seuls les enseignants vérifiés',
                value: 'verified',
                groupValue: _profileVisibility,
                onChanged: (value) {
                  setState(() {
                    _profileVisibility = value!;
                  });
                },
              ),
              _buildRadioTile(
                title: 'Personne',
                subtitle: 'Votre profil est complètement masqué',
                value: 'none',
                groupValue: _profileVisibility,
                onChanged: (value) {
                  setState(() {
                    _profileVisibility = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section Informations personnelles
          _buildSectionCard(
            'Informations personnelles',
            [
              _buildSwitchTile(
                icon: Icons.phone,
                title: 'Masquer mon numéro de téléphone',
                subtitle: 'Le numéro sera partiellement caché',
                value: _hidePhoneNumber,
                onChanged: (value) {
                  setState(() {
                    _hidePhoneNumber = value;
                  });
                },
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
                        'Votre matricule n\'est jamais visible par les autres utilisateurs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section Activité
          _buildSectionCard(
            'Activité',
            [
              _buildSwitchTile(
                icon: Icons.circle,
                title: 'Afficher mon statut en ligne',
                subtitle: 'Les autres verront quand vous êtes connecté',
                value: _showOnlineStatus,
                onChanged: (value) {
                  setState(() {
                    _showOnlineStatus = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section Messagerie
          _buildSectionCard(
            'Messagerie',
            [
              _buildSwitchTile(
                icon: Icons.message,
                title: 'Autoriser les messages',
                subtitle: 'Recevoir des messages d\'autres enseignants',
                value: _allowMessages,
                onChanged: (value) {
                  setState(() {
                    _allowMessages = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Informations
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF77F00).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Confidentialité et sécurité',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'CHIASMA respecte votre vie privée. Vos informations personnelles ne sont jamais partagées avec des tiers sans votre consentement.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF77F00),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF77F00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFF77F00), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFF77F00),
        ),
      ],
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF77F00).withValues(alpha: 0.05)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFFF77F00).withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFFF77F00),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
