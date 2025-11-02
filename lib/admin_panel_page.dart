import 'package:flutter/material.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/jobs_service.dart';
import 'package:myapp/services/subscription_service.dart';
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
  int _selectedTab = 0;

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
                  child: _buildTabButton(
                    'Utilisateurs',
                    Icons.people,
                    1,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    'Statistiques',
                    Icons.analytics,
                    2,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    'Annonces',
                    Icons.campaign,
                    3,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    'Paramètres',
                    Icons.settings,
                    4,
                  ),
                ),
              ],
            ),
          ),

          // Contenu selon l'onglet sélectionné
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, int index) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
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
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
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
            child: CircularProgressIndicator(
              color: Color(0xFFF77F00),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final allUsers = snapshot.data ?? [];
        final unverifiedUsers = allUsers.where((user) => !user.isVerified).toList();

        if (unverifiedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune vérification en attente',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                  backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.2),
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
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
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
                      const Icon(
                        Icons.pending,
                        size: 14,
                        color: Colors.orange,
                      ),
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
            _buildDetailRow(Icons.location_on, 'Zone actuelle', user.zoneActuelle),
            if (user.dren != null)
              _buildDetailRow(Icons.account_balance, 'DREN', user.dren!),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectVerification(user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rejeter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveVerification(user),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009E60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approuver'),
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Onglet Utilisateurs
  Widget _buildUsersTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getAllUsersStream(),
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
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final users = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(user);
          },
        );
      },
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Vérifié',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF009E60),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (user.isAdmin) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
                    color: user.daysUntilExpiration != null && user.daysUntilExpiration! < 7
                        ? Colors.red
                        : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expire: ${_formatDate(user.verificationExpiresAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: user.daysUntilExpiration != null && user.daysUntilExpiration! < 7
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
                        color: user.daysUntilExpiration! < 7 ? Colors.red : Colors.grey[600],
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
                  user.isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
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
            child: CircularProgressIndicator(
              color: Color(0xFFF77F00),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final users = snapshot.data ?? [];
        final verifiedCount = users.where((u) => u.isVerified).length;
        final unverifiedCount = users.where((u) => !u.isVerified).length;
        final adminCount = users.where((u) => u.isAdmin).length;
        final onlineCount = users.where((u) => u.isOnline).length;

        // Statistiques par type de compte
        final teacherTransferCount = users.where((u) => u.accountType == 'teacher_transfer').length;
        final teacherCandidateCount = users.where((u) => u.accountType == 'teacher_candidate').length;
        final schoolCount = users.where((u) => u.accountType == 'school').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vue d\'ensemble',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
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

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.isEmpty) return '??';
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  Future<void> _approveVerification(UserModel user) async {
    // Afficher le dialogue de sélection de durée
    final duration = await showDialog<String>(
      context: context,
      builder: (context) => _buildDurationSelectionDialog(user),
    );

    if (duration == null) return; // L'utilisateur a annulé

    try {
      // Activer l'abonnement avec la durée sélectionnée
      await _subscriptionService.activateSubscription(user.uid, duration);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${user.nom} a été vérifié pour ${SubscriptionService.getDurationLabel(duration)}',
            ),
            backgroundColor: const Color(0xFF009E60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    // Pour l'instant, on ne fait que montrer un message
    // Vous pouvez ajouter une logique de suppression ou de notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vérification de ${user.nom} rejetée'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleVerification(UserModel user) async {
    try {
      await _firestoreService.updateUserVerificationStatus(user.uid, !user.isVerified);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isVerified
                  ? 'Vérification retirée pour ${user.nom}'
                  : '${user.nom} a été vérifié',
            ),
            backgroundColor: const Color(0xFF009E60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      final newExpiration = _calculateNewExpiration(currentExpiration, additionalDuration);

      // Mettre à jour la vérification avec la nouvelle date
      await _subscriptionService.extendSubscription(
        user.uid,
        additionalDuration,
        newExpiration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vérification de ${user.nom} étendue de ${SubscriptionService.getDurationLabel(additionalDuration)}\nNouvelle expiration: ${_formatDate(newExpiration)}',
            ),
            backgroundColor: const Color(0xFF009E60),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  DateTime _calculateNewExpiration(DateTime currentExpiration, String duration) {
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
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _toggleAdmin(UserModel user) async {
    try {
      await _firestoreService.updateUserAdminStatus(user.uid, !user.isAdmin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              user.isAdmin
                  ? '${user.nom} n\'est plus administrateur'
                  : '${user.nom} est maintenant administrateur',
            ),
            backgroundColor: const Color(0xFF009E60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Onglet Paramètres
  Widget _buildSettingsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: 64,
              color: Color(0xFFF77F00),
            ),
            SizedBox(height: 16),
            Text(
              'Paramètres',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Aucun paramètre disponible pour le moment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
