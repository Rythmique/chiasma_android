import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/edit_profile_page.dart';

/// Page dédiée pour afficher toutes les informations de l'utilisateur connecté
/// Utile pour les tests et la vérification des données
class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  // Clé pour forcer le rafraîchissement du FutureBuilder
  int _refreshKey = 0;

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfilePage(),
      ),
    );

    // Si le profil a été modifié, rafraîchir la page
    if (result == true && mounted) {
      setState(() {
        _refreshKey++; // Changer la clé force le FutureBuilder à se reconstruire
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Informations Utilisateur'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Aucun utilisateur connecté'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations Utilisateur'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProfile,
            tooltip: 'Modifier le profil',
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        key: ValueKey(_refreshKey), // Utiliser la clé pour forcer le rafraîchissement
        future: FirestoreService().getUser(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF77F00),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          final userData = snapshot.data;

          if (userData == null) {
            return const Center(
              child: Text('Aucune donnée utilisateur trouvée'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // En-tête avec gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF77F00),
                        const Color(0xFFF77F00).withValues(alpha: 0.8),
                        const Color(0xFF009E60),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          _getInitials(userData.nom),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF77F00),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData.nom,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData.fonction,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              userData.isVerified
                                  ? Icons.verified_user
                                  : Icons.pending,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userData.isVerified
                                  ? 'Compte vérifié'
                                  : 'En attente de vérification',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Corps avec les informations
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Informations de base'),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        // Matricule et UID Firebase uniquement pour les admins
                        if (userData.isAdmin) ...[
                          _buildInfoRow(
                            Icons.badge,
                            'Matricule',
                            userData.matricule,
                            const Color(0xFFF77F00),
                          ),
                        ],
                        _buildInfoRow(
                          Icons.email,
                          'Email',
                          userData.email,
                          const Color(0xFFF77F00),
                        ),
                        if (userData.isAdmin)
                          _buildInfoRow(
                            Icons.perm_identity,
                            'UID Firebase',
                            userData.uid,
                            const Color(0xFFF77F00),
                          ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Contacts'),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        ...userData.telephones.asMap().entries.map((entry) {
                          return _buildInfoRow(
                            Icons.phone,
                            'Téléphone ${entry.key + 1}',
                            entry.value,
                            const Color(0xFF009E60),
                          );
                        }),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Localisation professionnelle'),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        _buildInfoRow(
                          Icons.location_on,
                          'Zone actuelle',
                          userData.zoneActuelle,
                          const Color(0xFFF77F00),
                        ),
                        if (userData.dren != null)
                          _buildInfoRow(
                            Icons.account_balance,
                            'DREN',
                            userData.dren!,
                            const Color(0xFFF77F00),
                          ),
                        _buildInfoRow(
                          Icons.description,
                          'Informations sur la zone actuelle',
                          userData.infosZoneActuelle,
                          const Color(0xFFF77F00),
                          isLongText: true,
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Zones souhaitées'),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        ...userData.zonesSouhaitees.asMap().entries.map((entry) {
                          return _buildInfoRow(
                            Icons.location_searching,
                            'Zone ${entry.key + 1}',
                            entry.value,
                            const Color(0xFF009E60),
                          );
                        }),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Informations système'),
                      const SizedBox(height: 8),
                      _buildInfoCard([
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Créé le',
                          _formatDate(userData.createdAt),
                          Colors.grey,
                        ),
                        _buildInfoRow(
                          Icons.update,
                          'Mis à jour le',
                          _formatDate(userData.updatedAt),
                          Colors.grey,
                        ),
                        _buildInfoRow(
                          Icons.circle,
                          'Statut',
                          userData.isOnline ? 'En ligne' : 'Hors ligne',
                          userData.isOnline
                              ? const Color(0xFF4CAF50)
                              : Colors.grey,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Bouton Modifier le profil
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToEditProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF77F00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text(
                            'Modifier le profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFFF77F00),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
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
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    bool isLongText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isLongText ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.isEmpty) return '??';
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  String _formatDate(DateTime date) {
    final months = [
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'juin',
      'juil',
      'août',
      'sep',
      'oct',
      'nov',
      'déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
