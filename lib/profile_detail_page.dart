import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/chat_page.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/utils/string_utils.dart';
import 'package:myapp/widgets/subscription_required_dialog.dart';

class ProfileDetailPage extends StatefulWidget {
  final String userId; // ID de l'utilisateur dont on consulte le profil

  const ProfileDetailPage({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  final _firestoreService = FirestoreService();
  UserModel? _profileUserData;
  UserModel? _currentUserData; // Données de l'utilisateur connecté
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _loadProfileData();
    _loadCurrentUserData();
    _recordProfileView();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userData = await _firestoreService.getUser(currentUser.uid);
        if (mounted) {
          setState(() {
            _currentUserData = userData;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  Future<void> _recordProfileView() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _firestoreService.recordProfileView(
          viewerId: currentUser.uid,
          profileUserId: widget.userId,
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement de la vue de profil: $e');
      // Ne pas afficher d'erreur à l'utilisateur car ce n'est pas critique
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final profileData = await _firestoreService.getUser(widget.userId);

      if (mounted) {
        setState(() {
          _profileUserData = profileData;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final isFav = await _firestoreService.isFavorite(
          currentUser.uid,
          widget.userId,
        );
        if (mounted) {
          setState(() {
            _isFavorite = isFav;
            _isLoadingFavorite = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du statut favori: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Vérifier si c'est une école qui veut ajouter aux favoris
    final userData = await _firestoreService.getUser(currentUser.uid);
    if (userData != null && userData.accountType == 'school') {
      // Bloquer si quota épuisé ET non vérifié (sauf pour retirer des favoris)
      if (!_isFavorite &&
          userData.freeQuotaUsed >= userData.freeQuotaLimit &&
          (!userData.isVerified || userData.isVerificationExpired)) {
        if (mounted) {
          SubscriptionRequiredDialog.show(context, 'school');
        }
        return;
      }
    }

    try {
      if (_isFavorite) {
        await _firestoreService.removeFavorite(currentUser.uid, widget.userId);
      } else {
        await _firestoreService.addFavorite(currentUser.uid, widget.userId);
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite
                  ? 'Ajouté aux favoris ❤️'
                  : 'Retiré des favoris',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: _isFavorite ? Colors.red : const Color(0xFF009E60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF77F00),
          ),
        ),
      );
    }

    if (_profileUserData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Profil introuvable'),
        ),
      );
    }

    final profile = _profileUserData!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              profile.nom
                                  .split(' ')
                                  .map((word) => word.isNotEmpty ? word[0] : '')
                                  .take(2)
                                  .join()
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF77F00),
                              ),
                            ),
                          ),
                          if (profile.isOnline)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.nom,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.fonction,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: _isLoadingFavorite
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                onPressed: _isLoadingFavorite ? null : _toggleFavorite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Affichage différent selon le type de compte
                  if (profile.accountType == 'teacher_candidate')
                    ..._buildCandidateProfile(profile)
                  else
                    ..._buildTeacherTransferProfile(profile),
                  const SizedBox(height: 16),

                  // Contact (affichage conditionnel pour les écoles)
                  if (profile.accountType != 'school' || profile.showContactInfo)
                    _buildSectionCard(
                      'Contact',
                      [
                        // Email avec masquage pour écoles non vérifiées
                        () {
                          // Masquer si l'utilisateur actuel est une école non vérifiée
                          final shouldMask = _currentUserData?.accountType == 'school' &&
                              !(_currentUserData?.isVerified ?? false);
                          final displayEmail = shouldMask
                              ? maskEmail(profile.email)
                              : profile.email;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(
                                Icons.email,
                                'Email',
                                displayEmail,
                                const Color(0xFFF77F00),
                              ),
                              if (shouldMask) ...[
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 48),
                                  child: Text(
                                    'Email masqué - Vérification requise',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        }(),
                        if (profile.telephones.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ...profile.telephones.asMap().entries.map((entry) {
                            // Masquer le téléphone si l'utilisateur actuel est une école non vérifiée
                            final shouldMask = _currentUserData?.accountType == 'school' &&
                                !(_currentUserData?.isVerified ?? false);
                            final displayPhone = shouldMask
                                ? maskPhoneNumber(entry.value)
                                : entry.value;

                            return Padding(
                              padding: EdgeInsets.only(
                                top: entry.key > 0 ? 16 : 0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    Icons.phone,
                                    profile.telephones.length > 1
                                        ? 'Téléphone ${entry.key + 1}'
                                        : 'Téléphone',
                                    displayPhone,
                                    const Color(0xFF009E60),
                                  ),
                                  if (shouldMask) ...[
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 48),
                                      child: Text(
                                        'Numéro masqué - Vérification requise',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange[700],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    )
                  else
                    _buildSectionCard(
                      'Contact',
                      [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF77F00).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                color: Colors.orange[700],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Coordonnées privées',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cet établissement a choisi de ne pas afficher ses coordonnées publiquement. Utilisez la messagerie pour le contacter.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  contactName: profile.nom,
                                  contactFunction: profile.fonction,
                                  isOnline: profile.isOnline,
                                  contactUserId: profile.uid,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF77F00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.message),
                          label: const Text(
                            'Envoyer un message',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C2C2C),
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
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
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Construire le profil pour un candidat enseignant (teacher_candidate)
  List<Widget> _buildCandidateProfile(UserModel profile) {
    return [
      // Zones souhaitées (pour les candidats, c'est le plus important)
      if (profile.zonesSouhaitees.isNotEmpty)
        _buildSectionCard(
          'Zones souhaitées',
          [
            _buildInfoRow(
              Icons.location_searching,
              profile.zonesSouhaitees.length == 1
                  ? 'Zone souhaitée'
                  : 'Zones souhaitées',
              profile.zonesSouhaitees.join(' • '),
              const Color(0xFF009E60),
            ),
          ],
        ),
      const SizedBox(height: 16),

      // Informations professionnelles
      _buildSectionCard(
        'Informations professionnelles',
        [
          _buildInfoRow(
            Icons.subject,
            'Matières enseignées',
            profile.fonction,
            const Color(0xFF2196F3),
          ),
          if (profile.infosZoneActuelle.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.work_history,
              'Expérience professionnelle',
              profile.infosZoneActuelle,
              Colors.orange[800]!,
            ),
          ],
        ],
      ),
    ];
  }

  /// Construire le profil pour un enseignant en permutation (teacher_transfer)
  List<Widget> _buildTeacherTransferProfile(UserModel profile) {
    return [
      // Zones
      _buildSectionCard(
        'Localisation',
        [
          _buildInfoRow(
            Icons.location_on,
            'Zone actuelle',
            profile.zoneActuelle,
            const Color(0xFFF77F00),
          ),
          if (profile.zonesSouhaitees.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.location_searching,
              profile.zonesSouhaitees.length == 1
                  ? 'Zone souhaitée'
                  : 'Zones souhaitées',
              profile.zonesSouhaitees.join(' • '),
              const Color(0xFF009E60),
            ),
          ],
        ],
      ),
      const SizedBox(height: 16),

      // Informations professionnelles
      _buildSectionCard(
        'Informations professionnelles',
        [
          _buildInfoRow(
            Icons.work,
            'Fonction',
            profile.fonction,
            const Color(0xFF2196F3),
          ),
          if (profile.dren != null && profile.dren!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.apartment,
              'DREN',
              profile.dren!,
              const Color(0xFF9C27B0),
            ),
          ],
          if (profile.infosZoneActuelle.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.school,
              'Établissement',
              profile.infosZoneActuelle,
              Colors.orange[800]!,
            ),
          ],
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.badge,
            'Matricule',
            profile.matricule,
            Colors.grey[700]!,
          ),
        ],
      ),
    ];
  }
}
