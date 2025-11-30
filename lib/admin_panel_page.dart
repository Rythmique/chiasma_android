import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/jobs_service.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/services/access_restrictions_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/job_application_model.dart';
import 'package:myapp/models/job_offer_model.dart';
import 'package:myapp/admin/manage_announcements_page.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final JobsService _jobsService = JobsService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AccessRestrictionsService _restrictionsService =
      AccessRestrictionsService();
  int _selectedTab = 0;

  // Variables pour la pagination des utilisateurs
  List<UserModel> _allUsers = [];
  bool _isLoadingUsers = false;
  bool _isLoadingMore = false;
  bool _hasMoreUsers = true;
  DocumentSnapshot? _lastUserDocument;
  final int _userPageSize = 20;
  final ScrollController _userScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _userScrollController.addListener(_onUserScroll);
  }

  @override
  void dispose() {
    _userScrollController.dispose();
    super.dispose();
  }

  // Détecter le scroll pour charger plus d'utilisateurs
  void _onUserScroll() {
    if (_selectedTab != 1) return; // Uniquement pour l'onglet Utilisateurs

    if (_userScrollController.position.pixels >=
        _userScrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMoreUsers) {
        _loadMoreUsers();
      }
    }
  }

  // Charger la première page d'utilisateurs
  Future<void> _loadUsers() async {
    if (_isLoadingUsers) return;

    setState(() {
      _isLoadingUsers = true;
      _allUsers = [];
      _lastUserDocument = null;
      _hasMoreUsers = true;
    });

    try {
      final result = await _firestoreService.getAllUsersPaginated(
        limit: _userPageSize,
      );

      if (mounted) {
        setState(() {
          _allUsers = result['users'];
          // Trier par expiration de vérification (expirés/proches expiration en premier)
          _sortUsersByVerificationExpiration();
          _lastUserDocument = result['lastDocument'];
          _hasMoreUsers = result['users'].length >= _userPageSize;
          _isLoadingUsers = false;

          debugPrint(
            '📊 [Admin] Première page chargée: ${_allUsers.length} utilisateurs',
          );
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement utilisateurs admin: $e');
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
          _hasMoreUsers = false;
        });
      }
    }
  }

  // Charger plus d'utilisateurs
  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore || !_hasMoreUsers || _lastUserDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _firestoreService.getAllUsersPaginated(
        limit: _userPageSize,
        startAfterDocument: _lastUserDocument,
      );

      if (mounted) {
        setState(() {
          _allUsers.addAll(result['users']);
          // Trier par expiration de vérification après chaque ajout
          _sortUsersByVerificationExpiration();
          _lastUserDocument = result['lastDocument'];
          _hasMoreUsers = result['users'].length >= _userPageSize;
          _isLoadingMore = false;

          debugPrint(
            '📊 [Admin] Page suivante chargée: +${result['users'].length} (Total: ${_allUsers.length})',
          );
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement page suivante admin: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreUsers = false;
        });
      }
    }
  }

  // Trier les utilisateurs par expiration de vérification
  // Priorité: 1) Expirés, 2) Proche expiration (< 7 jours), 3) Autres
  void _sortUsersByVerificationExpiration() {
    _allUsers.sort((a, b) {
      final now = DateTime.now();

      // Calculer les jours avant expiration pour chaque utilisateur
      int getDaysUntilExpiration(UserModel user) {
        if (user.verificationExpiresAt == null) {
          return 999999; // Non vérifié = dernier
        }
        final diff = user.verificationExpiresAt!.difference(now);
        return diff.inDays;
      }

      final aDays = getDaysUntilExpiration(a);
      final bDays = getDaysUntilExpiration(b);

      // 1. Utilisateurs avec vérification expirée (jours négatifs) en premier
      if (aDays < 0 && bDays >= 0) return -1;
      if (bDays < 0 && aDays >= 0) return 1;

      // 2. Si les deux sont expirés, trier par date d'expiration (plus ancien en premier)
      if (aDays < 0 && bDays < 0) {
        return aDays.compareTo(bDays);
      }

      // 3. Utilisateurs proches de l'expiration (< 7 jours) avant les autres
      if (aDays < 7 && bDays >= 7) return -1;
      if (bDays < 7 && aDays >= 7) return 1;

      // 4. Si les deux sont dans la même catégorie, trier par jours restants (moins de jours en premier)
      return aDays.compareTo(bDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panneau d\'administration'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Onglets de navigation
          Container(
            color: const Color(0xFFF77F00),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'Vérifications',
                    Icons.verified_user,
                    0,
                  ),
                ),
                Expanded(
                  child: _buildTabButton('Utilisateurs', Icons.people, 1),
                ),
                Expanded(
                  child: _buildTabButton('Statistiques', Icons.analytics, 2),
                ),
                Expanded(child: _buildTabButton('Annonces', Icons.campaign, 3)),
                Expanded(
                  child: _buildTabButton('Signalements', Icons.bug_report, 4),
                ),
                Expanded(
                  child: _buildTabButton('Paramètres', Icons.settings, 5),
                ),
              ],
            ),
          ),

          // Contenu selon l'onglet sélectionné
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final isSelected = _selectedTab == index;
    final color = isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.6);

    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildVerificationTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildStatisticsTab();
      case 3:
        return const ManageAnnouncementsPage();
      case 4:
        return _buildProblemReportsTab();
      case 5:
        return _buildSettingsTab();
      default:
        return const Center(child: Text('Contenu non disponible'));
    }
  }

  // Onglet Vérifications
  Widget _buildVerificationTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getAllUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF77F00)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final allUsers = snapshot.data ?? [];
        final unverifiedUsers = allUsers
            .where((user) => !user.isVerified)
            .toList();

        if (unverifiedUsers.isEmpty) {
          return _buildEmptyState(
            Icons.check_circle_outline,
            'Aucune vérification en attente',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: unverifiedUsers.length,
          itemBuilder: (context, index) {
            final user = unverifiedUsers[index];
            return _buildVerificationCard(user);
          },
        );
      },
    );
  }

  Widget _buildVerificationCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et statut
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(
                    0xFFF77F00,
                  ).withValues(alpha: 0.2),
                  child: Text(
                    _getInitials(user.nom),
                    style: const TextStyle(
                      color: Color(0xFFF77F00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.fonction,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.pending, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      const Text(
                        'En attente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Informations détaillées
            _buildDetailRow(Icons.badge, 'Matricule', user.matricule),
            _buildDetailRow(Icons.email, 'Email', user.email),
            if (user.telephones.isNotEmpty)
              _buildDetailRow(Icons.phone, 'Téléphone', user.telephones.first),
            _buildDetailRow(
              Icons.location_on,
              'Zone actuelle',
              user.zoneActuelle,
            ),
            if (user.dren != null)
              _buildDetailRow(Icons.account_balance, 'DREN', user.dren!),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Rejeter',
                    icon: Icons.close,
                    onPressed: () => _rejectVerification(user),
                    color: Colors.red,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Approuver',
                    icon: Icons.check,
                    onPressed: () => _approveVerification(user),
                    color: const Color(0xFF009E60),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Onglet Utilisateurs avec pagination
  Widget _buildUsersTab() {
    // Charger la première page si pas encore chargée
    if (_allUsers.isEmpty && !_isLoadingUsers && _hasMoreUsers) {
      Future.microtask(() => _loadUsers());
    }

    if (_isLoadingUsers && _allUsers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF77F00)),
      );
    }

    return Column(
      children: [
        // Bannière de comptage
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF77F00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF77F00), width: 2),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, color: Color(0xFFF77F00), size: 24),
              const SizedBox(width: 12),
              Text(
                'Chargés: ${_allUsers.length} utilisateur${_allUsers.length > 1 ? 's' : ''}${!_hasMoreUsers ? '' : '+'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF77F00),
                ),
              ),
            ],
          ),
        ),
        // Liste des utilisateurs
        Expanded(
          child: ListView.builder(
            controller: _userScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount:
                _allUsers.length +
                (_isLoadingMore ? 1 : 0) +
                (!_isLoadingMore && !_hasMoreUsers ? 1 : 0),
            itemBuilder: (context, index) {
              // Afficher les utilisateurs
              if (index < _allUsers.length) {
                final user = _allUsers[index];
                return _buildUserCard(user);
              }

              // Indicateur de chargement
              if (_isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFF77F00)),
                  ),
                );
              }

              // Indicateur de fin de liste
              if (!_hasMoreUsers) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Tous les utilisateurs ont été chargés',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.2),
          child: Text(
            _getInitials(user.nom),
            style: const TextStyle(
              color: Color(0xFFF77F00),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          user.nom,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                if (user.isVerified)
                  _buildStatusBadge('Vérifié', const Color(0xFF009E60)),
                if (user.isAdmin) ...[
                  const SizedBox(width: 4),
                  _buildStatusBadge('Admin', Colors.purple),
                ],
              ],
            ),
            if (user.isVerified && user.verificationExpiresAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 12,
                    color:
                        user.daysUntilExpiration != null &&
                            user.daysUntilExpiration! < 7
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expire: ${_formatDate(user.verificationExpiresAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          user.daysUntilExpiration != null &&
                              user.daysUntilExpiration! < 7
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                  ),
                  if (user.daysUntilExpiration != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${user.daysUntilExpiration} jours)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: user.daysUntilExpiration! < 7
                            ? Colors.red
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            if (user.isVerified) ...[
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(
                    Icons.update,
                    size: 20,
                    color: Color(0xFFF77F00),
                  ),
                  title: Text('Étendre vérification'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _extendVerification(user),
              ),
            ],
            PopupMenuItem(
              child: ListTile(
                leading: Icon(
                  user.isVerified ? Icons.cancel : Icons.verified_user,
                  size: 20,
                ),
                title: Text(
                  user.isVerified ? 'Retirer vérification' : 'Vérifier',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _toggleVerification(user),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(
                  user.isAdmin
                      ? Icons.remove_moderator
                      : Icons.admin_panel_settings,
                  size: 20,
                ),
                title: Text(
                  user.isAdmin ? 'Retirer admin' : 'Promouvoir admin',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _toggleAdmin(user),
            ),
          ],
        ),
      ),
    );
  }

  // Onglet Statistiques
  Widget _buildStatisticsTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getAllUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF77F00)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];
        final verifiedCount = users.where((u) => u.isVerified).length;
        final unverifiedCount = users.where((u) => !u.isVerified).length;
        final adminCount = users.where((u) => u.isAdmin).length;
        final onlineCount = users.where((u) => u.isOnline).length;

        // Statistiques par type de compte
        final teacherTransferCount = users
            .where((u) => u.accountType == 'teacher_transfer')
            .length;
        final teacherCandidateCount = users
            .where((u) => u.accountType == 'teacher_candidate')
            .length;
        final schoolCount = users
            .where((u) => u.accountType == 'school')
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vue d\'ensemble',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Total utilisateurs',
                users.length.toString(),
                Icons.people,
                const Color(0xFFF77F00),
              ),
              _buildStatCard(
                'Utilisateurs vérifiés',
                verifiedCount.toString(),
                Icons.verified_user,
                const Color(0xFF009E60),
              ),
              _buildStatCard(
                'En attente de vérification',
                unverifiedCount.toString(),
                Icons.pending,
                Colors.orange,
              ),
              _buildStatCard(
                'Administrateurs',
                adminCount.toString(),
                Icons.admin_panel_settings,
                Colors.purple,
              ),
              _buildStatCard(
                'Utilisateurs en ligne',
                onlineCount.toString(),
                Icons.online_prediction,
                Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Par type de compte',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Enseignants (Permutation)',
                teacherTransferCount.toString(),
                Icons.swap_horiz,
                const Color(0xFFF77F00),
              ),
              _buildStatCard(
                'Candidats Enseignants',
                teacherCandidateCount.toString(),
                Icons.person_search,
                const Color(0xFF009E60),
              ),
              _buildStatCard(
                'Établissements',
                schoolCount.toString(),
                Icons.business,
                const Color(0xFF2196F3),
              ),
              const SizedBox(height: 24),
              const Text(
                'Système de recrutement',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<JobApplicationModel>>(
                stream: _jobsService.streamActiveApplications(limit: 1000),
                builder: (context, appSnapshot) {
                  final applications = appSnapshot.data ?? [];
                  return _buildStatCard(
                    'Candidatures actives',
                    applications.length.toString(),
                    Icons.work,
                    const Color(0xFF009E60),
                  );
                },
              ),
              StreamBuilder<List<JobOfferModel>>(
                stream: _jobsService.streamActiveOffers(limit: 1000),
                builder: (context, offerSnapshot) {
                  final offers = offerSnapshot.data ?? [];
                  return _buildStatCard(
                    'Offres d\'emploi actives',
                    offers.length.toString(),
                    Icons.business_center,
                    const Color(0xFFF77F00),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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

  // Méthodes utilitaires
  Widget _buildEmptyState(IconData icon, String message, {String? subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF009E60),
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '??';
    if (words.length == 1 && words[0].isNotEmpty)
      return words[0][0].toUpperCase();
    if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return '??';
  }

  Future<void> _approveVerification(UserModel user) async {
    final duration = await showDialog<String>(
      context: context,
      builder: (context) => _buildDurationSelectionDialog(user),
    );

    if (duration == null) return;

    try {
      await _subscriptionService.activateSubscription(user.uid, duration);
      _showSnackBar(
        '${user.nom} a été vérifié pour ${SubscriptionService.getDurationLabel(duration)}',
      );
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  Widget _buildDurationSelectionDialog(UserModel user) {
    // Options de durée disponibles
    final durations = [
      {'value': '1_week', 'label': '1 semaine'},
      {'value': '1_month', 'label': '1 mois'},
      {'value': '3_months', 'label': '3 mois'},
      {'value': '6_months', 'label': '6 mois'},
      {'value': '12_months', 'label': '12 mois'},
    ];

    return AlertDialog(
      title: const Text('Durée de vérification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionnez la durée de vérification pour ${user.nom}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...durations.map((duration) {
            return InkWell(
              onTap: () => Navigator.of(context).pop(duration['value']),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Color(0xFFF77F00),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        duration['label']!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }

  Future<void> _rejectVerification(UserModel user) async {
    _showSnackBar('Vérification de ${user.nom} rejetée', isError: true);
  }

  Future<void> _toggleVerification(UserModel user) async {
    try {
      await _firestoreService.updateUserVerificationStatus(
        user.uid,
        !user.isVerified,
      );
      _showSnackBar(
        user.isVerified
            ? 'Vérification retirée pour ${user.nom}'
            : '${user.nom} a été vérifié',
      );
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  Future<void> _extendVerification(UserModel user) async {
    // Afficher les informations actuelles de vérification
    final daysRemaining = user.daysUntilExpiration;
    final expiresAt = user.verificationExpiresAt;

    // Afficher le dialogue de sélection de durée supplémentaire
    final additionalDuration = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Étendre la vérification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Utilisateur: ${user.nom}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (expiresAt != null) ...[
              Text(
                'Expire le: ${_formatDate(expiresAt)}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
            ],
            if (daysRemaining != null) ...[
              Text(
                'Jours restants: $daysRemaining',
                style: TextStyle(
                  color: daysRemaining < 7 ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Sélectionnez la durée à ajouter:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ..._buildExtensionOptions(user),
        ],
      ),
    );

    if (additionalDuration == null) return;

    try {
      // Calculer la nouvelle date d'expiration
      final currentExpiration = user.verificationExpiresAt ?? DateTime.now();
      final newExpiration = _calculateNewExpiration(
        currentExpiration,
        additionalDuration,
      );

      // Mettre à jour la vérification avec la nouvelle date
      await _subscriptionService.extendSubscription(
        user.uid,
        additionalDuration,
        newExpiration,
      );

      if (mounted) {
        _showSnackBar(
          'Vérification de ${user.nom} étendue de ${SubscriptionService.getDurationLabel(additionalDuration)}\n'
          'Nouvelle expiration: ${_formatDate(newExpiration)}',
        );
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  List<Widget> _buildExtensionOptions(UserModel user) {
    final durations = [
      {'key': '1_week', 'label': '+ 1 semaine'},
      {'key': '1_month', 'label': '+ 1 mois'},
      {'key': '3_months', 'label': '+ 3 mois'},
      {'key': '6_months', 'label': '+ 6 mois'},
      {'key': '12_months', 'label': '+ 12 mois'},
    ];

    return durations.map((duration) {
      return TextButton(
        onPressed: () => Navigator.pop(context, duration['key']),
        child: Text(duration['label']!),
      );
    }).toList();
  }

  DateTime _calculateNewExpiration(
    DateTime currentExpiration,
    String duration,
  ) {
    switch (duration) {
      case '1_week':
        return currentExpiration.add(const Duration(days: 7));
      case '1_month':
        return DateTime(
          currentExpiration.year,
          currentExpiration.month + 1,
          currentExpiration.day,
        );
      case '3_months':
        return DateTime(
          currentExpiration.year,
          currentExpiration.month + 3,
          currentExpiration.day,
        );
      case '6_months':
        return DateTime(
          currentExpiration.year,
          currentExpiration.month + 6,
          currentExpiration.day,
        );
      case '12_months':
        return DateTime(
          currentExpiration.year + 1,
          currentExpiration.month,
          currentExpiration.day,
        );
      default:
        return currentExpiration.add(const Duration(days: 30));
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _toggleAdmin(UserModel user) async {
    try {
      await _firestoreService.updateUserAdminStatus(user.uid, !user.isAdmin);
      _showSnackBar(
        user.isAdmin
            ? '${user.nom} n\'est plus administrateur'
            : '${user.nom} est maintenant administrateur',
      );
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  // Onglet Signalements de problèmes
  Widget _buildProblemReportsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getProblemReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return _buildEmptyState(
            Icons.check_circle,
            'Aucun signalement',
            subtitle: 'Tous les problèmes ont été résolus !',
          );
        }

        // Compter les signalements par statut
        final newCount = reports.where((r) => r['status'] == 'new').length;
        final readCount = reports.where((r) => r['status'] == 'read').length;
        final resolvedCount = reports
            .where((r) => r['status'] == 'resolved')
            .length;

        return Column(
          children: [
            // Statistiques en haut
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildReportStatCard(
                    'Nouveaux',
                    newCount,
                    Colors.red,
                    Icons.fiber_new,
                  ),
                  _buildReportStatCard(
                    'Lus',
                    readCount,
                    Colors.orange,
                    Icons.visibility,
                  ),
                  _buildReportStatCard(
                    'Résolus',
                    resolvedCount,
                    Colors.green,
                    Icons.check_circle,
                  ),
                ],
              ),
            ),

            // Liste des signalements
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _buildProblemReportCard(report);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportStatCard(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemReportCard(Map<String, dynamic> report) {
    final status = report['status'] as String;
    final userId = report['userId'] as String?;
    final userName = report['userName'] as String? ?? 'Utilisateur inconnu';
    final userEmail = report['userEmail'] as String? ?? '';
    final accountType = report['accountType'] as String? ?? '';
    final problemDescription = report['problemDescription'] as String? ?? '';
    final createdAt = report['createdAt'] as Timestamp?;
    final reportId = report['id'] as String;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'new':
        statusColor = Colors.red;
        statusLabel = 'Nouveau';
        statusIcon = Icons.fiber_new;
        break;
      case 'read':
        statusColor = Colors.orange;
        statusLabel = 'Lu';
        statusIcon = Icons.visibility;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusLabel = 'Résolu';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
        statusIcon = Icons.help;
    }

    String accountTypeLabel;
    switch (accountType) {
      case 'school':
        accountTypeLabel = 'École';
        break;
      case 'teacher_candidate':
        accountTypeLabel = 'Candidat';
        break;
      case 'teacher_transfer':
        accountTypeLabel = 'Permutation';
        break;
      default:
        accountTypeLabel = accountType;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(statusIcon, color: statusColor, size: 24),
        ),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              accountTypeLabel,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (createdAt != null)
              Text(
                _formatTimestamp(createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description du problème:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    problemDescription,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                if (userId != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ID: $userId',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'new') ...[
                      OutlinedButton.icon(
                        onPressed: () => _updateReportStatus(reportId, 'read'),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Marquer comme lu'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (status != 'resolved') ...[
                      ElevatedButton.icon(
                        onPressed: () =>
                            _updateReportStatus(reportId, 'resolved'),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Marquer comme résolu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      onPressed: () => _deleteProblemReport(reportId),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _updateReportStatus(String reportId, String status) async {
    try {
      await _firestoreService.updateProblemReportStatus(
        reportId: reportId,
        status: status,
      );
      _showSnackBar('Statut mis à jour: ${status == 'read' ? 'Lu' : 'Résolu'}');
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  Future<void> _deleteProblemReport(String reportId) async {
    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le signalement'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce signalement ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteProblemReport(reportId);
        _showSnackBar('Signalement supprimé');
      } catch (e) {
        _showSnackBar('Erreur: $e', isError: true);
      }
    }
  }

  // Onglet Paramètres
  Widget _buildSettingsTab() {
    return StreamBuilder<Map<String, bool>>(
      stream: _restrictionsService.getRestrictionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF77F00)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        }

        final restrictions =
            snapshot.data ??
            {
              'teacher_transfer': true,
              'teacher_candidate': true,
              'school': true,
            };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF77F00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Color(0xFFF77F00),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contrôle d\'accès global',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Gérer les restrictions par type de compte',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Bannière d'information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Les restrictions contrôlent l\'accès à l\'application par type de compte. '
                        'Désactiver les restrictions donne un accès illimité sans vérification ni quota.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Toggle pour Enseignants (Permutation)
              _buildRestrictionCard(
                title: 'Enseignants (Permutation)',
                subtitle:
                    'Contrôle d\'accès pour les enseignants cherchant à permuter',
                icon: Icons.swap_horiz,
                iconColor: const Color(0xFFF77F00),
                enabled: restrictions['teacher_transfer'] ?? true,
                accountType: 'teacher_transfer',
                quotaLimit: 5,
                description: 'consultation de profils',
              ),
              const SizedBox(height: 16),

              // Toggle pour Candidats Enseignants
              _buildRestrictionCard(
                title: 'Candidats Enseignants',
                subtitle:
                    'Contrôle d\'accès pour les candidats cherchant un emploi',
                icon: Icons.person_add,
                iconColor: const Color(0xFF009E60),
                enabled: restrictions['teacher_candidate'] ?? true,
                accountType: 'teacher_candidate',
                quotaLimit: 2,
                description: 'candidatures',
              ),
              const SizedBox(height: 16),

              // Toggle pour Écoles
              _buildRestrictionCard(
                title: 'Établissements',
                subtitle: 'Contrôle d\'accès pour les écoles recrutant',
                icon: Icons.business,
                iconColor: const Color(0xFF2196F3),
                enabled: restrictions['school'] ?? true,
                accountType: 'school',
                quotaLimit: 1,
                description: 'offre d\'emploi',
              ),
              const SizedBox(height: 32),

              // 🔥 Section Crashlytics
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepOrange.shade50, Colors.orange.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bug_report,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Firebase Crashlytics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tests de monitoring des erreurs',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Testez l\'intégration Crashlytics en forçant différents types d\'erreurs :',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildCrashlyticsButton(
                          label: 'Force Crash',
                          icon: Icons.warning,
                          color: Colors.red,
                          onPressed: () => _forceCrash(),
                        ),
                        _buildCrashlyticsButton(
                          label: 'Test Exception',
                          icon: Icons.error_outline,
                          color: Colors.orange,
                          onPressed: () => _testException(),
                        ),
                        _buildCrashlyticsButton(
                          label: 'Log Message',
                          icon: Icons.message,
                          color: Colors.blue,
                          onPressed: () => _logMessage(),
                        ),
                        _buildCrashlyticsButton(
                          label: 'Set User ID',
                          icon: Icons.person,
                          color: Colors.green,
                          onPressed: () => _setUserId(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Légende
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Légende',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      Icons.check_circle,
                      Colors.green,
                      'Restrictions activées',
                      'Quota + vérification admin requis',
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      Icons.cancel,
                      Colors.red,
                      'Restrictions désactivées',
                      'Accès illimité pour tous',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget pour une carte de restriction
  Widget _buildRestrictionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool enabled,
    required String accountType,
    required int quotaLimit,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: enabled ? Colors.green[200]! : Colors.red[200]!,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icône
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),

              // Titre et sous-titre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Toggle Switch
              Transform.scale(
                scale: 1.2,
                child: Switch(
                  value: enabled,
                  activeTrackColor: Colors.green[200],
                  activeThumbColor: Colors.green,
                  inactiveThumbColor: Colors.red,
                  inactiveTrackColor: Colors.red[100],
                  onChanged: (value) => _updateRestriction(accountType, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statut actuel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: enabled ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  enabled ? Icons.check_circle : Icons.cancel,
                  color: enabled ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    enabled
                        ? 'Restrictions activées • Quota: $quotaLimit $description gratuit${quotaLimit > 1 ? 's' : ''}'
                        : 'Restrictions désactivées • Accès illimité',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: enabled ? Colors.green[900] : Colors.red[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour un élément de légende
  // 🔥 Méthodes Crashlytics
  Widget _buildCrashlyticsButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: kIsWeb ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _forceCrash() {
    if (kIsWeb) {
      _showWebNotSupported();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('Force Crash'),
          ],
        ),
        content: const Text(
          'Cette action va faire crasher l\'application pour tester Crashlytics.\n\n'
          'Le rapport sera visible dans la console Firebase dans quelques minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Forcer un crash après 1 seconde
              Future.delayed(const Duration(seconds: 1), () {
                FirebaseCrashlytics.instance.crash();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Crash Now'),
          ),
        ],
      ),
    );
  }

  void _testException() {
    if (kIsWeb) {
      _showWebNotSupported();
      return;
    }

    try {
      throw Exception(
        '🔥 Test Exception depuis Admin Panel - ${DateTime.now()}',
      );
    } catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Exception enregistrée dans Crashlytics'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _logMessage() {
    if (kIsWeb) {
      _showWebNotSupported();
      return;
    }

    FirebaseCrashlytics.instance.log(
      '📝 Message de test depuis Admin Panel - ${DateTime.now()}',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Message logué dans Crashlytics'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _setUserId() {
    if (kIsWeb) {
      _showWebNotSupported();
      return;
    }

    final userId = 'admin_${DateTime.now().millisecondsSinceEpoch}';
    FirebaseCrashlytics.instance.setUserIdentifier(userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ User ID défini: $userId'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showWebNotSupported() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Crashlytics n\'est pas disponible sur le Web'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildLegendItem(
    IconData icon,
    Color color,
    String title,
    String description,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mettre à jour une restriction
  Future<void> _updateRestriction(String accountType, bool enabled) async {
    try {
      await _restrictionsService.updateRestrictions(accountType, enabled);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Restrictions activées pour ${_getAccountTypeName(accountType)}'
                  : 'Restrictions désactivées pour ${_getAccountTypeName(accountType)}',
            ),
            backgroundColor: enabled ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  /// Obtenir le nom lisible du type de compte
  String _getAccountTypeName(String accountType) {
    switch (accountType) {
      case 'teacher_transfer':
        return 'les enseignants';
      case 'teacher_candidate':
        return 'les candidats';
      case 'school':
        return 'les établissements';
      default:
        return accountType;
    }
  }
}
