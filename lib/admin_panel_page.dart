import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/services/jobs_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/subscription_model.dart';
import 'package:myapp/models/job_application_model.dart';
import 'package:myapp/models/job_offer_model.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final JobsService _jobsService = JobsService();
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
                    'Paramètres',
                    Icons.settings,
                    3,
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
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
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
    try {
      await _firestoreService.updateUserVerificationStatus(user.uid, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.nom} a été vérifié avec succès'),
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

  // Onglet Paramètres - Gestion du système d'abonnement
  Widget _buildSettingsTab() {
    return StreamBuilder<AppConfigModel>(
      stream: _subscriptionService.getAppConfigStream(),
      builder: (context, configSnapshot) {
        if (configSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFF77F00),
            ),
          );
        }

        final config = configSnapshot.data ?? AppConfigModel(
          subscriptionSystemEnabled: false,
          freeConsultationsLimit: 5,
          updatedAt: DateTime.now(),
        );

        return FutureBuilder<Map<String, int>>(
          future: _subscriptionService.getSubscriptionStats(),
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data ?? {
              'total': 0,
              'active': 0,
              'expired': 0,
              'revenue': 0,
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestion du système d\'abonnement',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle principal du système
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: config.subscriptionSystemEnabled
                                      ? const Color(0xFF009E60).withValues(alpha: 0.1)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  config.subscriptionSystemEnabled
                                      ? Icons.lock_open
                                      : Icons.lock,
                                  color: config.subscriptionSystemEnabled
                                      ? const Color(0xFF009E60)
                                      : Colors.grey[600],
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      config.subscriptionSystemEnabled
                                          ? 'Système activé'
                                          : 'Système désactivé',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      config.subscriptionSystemEnabled
                                          ? 'Les utilisateurs doivent souscrire après ${config.freeConsultationsLimit} consultations'
                                          : 'Tous les utilisateurs ont un accès illimité gratuit',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: config.subscriptionSystemEnabled,
                                activeTrackColor: const Color(0xFF009E60),
                                onChanged: (value) => _toggleSubscriptionSystem(value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Consultations gratuites: ${config.freeConsultationsLimit} par nouvel utilisateur',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tarifs d'abonnement
                  const Text(
                    'Tarifs d\'abonnement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPricingCard(
                    '1 mois',
                    '500 FCFA',
                    Icons.calendar_today,
                    const Color(0xFFF77F00),
                  ),
                  const SizedBox(height: 8),
                  _buildPricingCard(
                    '3 mois',
                    '1 500 FCFA',
                    Icons.calendar_month,
                    const Color(0xFF009E60),
                  ),
                  const SizedBox(height: 8),
                  _buildPricingCard(
                    '12 mois (Meilleure offre)',
                    '5 000 FCFA',
                    Icons.calendar_view_month,
                    const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 24),

                  // Statistiques des abonnements
                  const Text(
                    'Statistiques des abonnements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatMiniCard(
                          'Total',
                          stats['total'].toString(),
                          Icons.subscriptions,
                          const Color(0xFFF77F00),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatMiniCard(
                          'Actifs',
                          stats['active'].toString(),
                          Icons.check_circle,
                          const Color(0xFF009E60),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatMiniCard(
                          'Expirés',
                          stats['expired'].toString(),
                          Icons.cancel,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatMiniCard(
                          'Revenus',
                          '${stats['revenue']} F',
                          Icons.money,
                          const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Informations de configuration
                  if (config.updatedBy != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dernière modification: ${_formatDate(config.updatedAt)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPricingCard(String duration, String price, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                duration,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatMiniCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleSubscriptionSystem(bool enabled) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _subscriptionService.updateAppConfig(
        subscriptionSystemEnabled: enabled,
        adminUid: currentUser.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Système d\'abonnement activé'
                  : 'Système d\'abonnement désactivé - Mode gratuit illimité',
            ),
            backgroundColor: const Color(0xFF009E60),
            duration: const Duration(seconds: 3),
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
}
