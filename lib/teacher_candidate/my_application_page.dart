import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_application_model.dart';
import '../services/jobs_service.dart';
import '../services/firestore_service.dart';
import 'edit_candidate_profile_page.dart';
import 'register_candidate_page.dart';
import 'profile_views_page.dart';

/// Page détaillée de la candidature de l'utilisateur
class MyApplicationPage extends StatefulWidget {
  const MyApplicationPage({super.key});

  @override
  State<MyApplicationPage> createState() => _MyApplicationPageState();
}

class _MyApplicationPageState extends State<MyApplicationPage> {
  final JobsService _jobsService = JobsService();
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  int _profileViewsCount = 0;
  bool _isLoadingViewsCount = true;

  @override
  void initState() {
    super.initState();
    _loadProfileViewsCount();
  }

  Future<void> _loadProfileViewsCount() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final count = await _firestoreService.getProfileViewsCount(userId);
      if (mounted) {
        setState(() {
          _profileViewsCount = count;
          _isLoadingViewsCount = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du compteur de vues: $e');
      if (mounted) {
        setState(() {
          _isLoadingViewsCount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('Erreur: utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma candidature'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditCandidateProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<JobApplicationModel?>(
        stream: _jobsService.streamUserApplication(_userId),
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

          final application = snapshot.data;

          if (application == null) {
            return _buildNoApplicationView(context);
          }

          return _buildApplicationView(context, application);
        },
      ),
    );
  }

  /// Vue quand aucune candidature n'existe
  Widget _buildNoApplicationView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Aucune candidature',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Votre candidature n\'a pas encore été créée.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterCandidatePage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer ma candidature'),
            ),
          ],
        ),
      ),
    );
  }

  /// Vue avec les détails de la candidature
  Widget _buildApplicationView(
    BuildContext context,
    JobApplicationModel application,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte de statut
          _buildStatusCard(context, application),
          const SizedBox(height: 16),

          // Statistiques
          _buildStatsCard(context, application),
          const SizedBox(height: 16),

          // Informations personnelles
          _buildSectionCard(
            context,
            title: 'Informations personnelles',
            icon: Icons.person,
            children: [
              _buildInfoRow('Nom', application.nom),
              _buildInfoRow('Email', application.email),
              if (application.telephones.isNotEmpty)
                _buildInfoRow(
                  'Téléphone(s)',
                  application.telephones.join(', '),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Informations professionnelles
          _buildSectionCard(
            context,
            title: 'Informations professionnelles',
            icon: Icons.school,
            children: [
              _buildInfoRow('Matières', application.matieresString),
              _buildInfoRow('Niveaux', application.niveauxString),
              _buildInfoRow('Diplômes', application.diplomes.join(', ')),
              _buildInfoRow('Expérience', application.experience),
            ],
          ),
          const SizedBox(height: 16),

          // Disponibilité et localisation
          _buildSectionCard(
            context,
            title: 'Disponibilité et localisation',
            icon: Icons.location_on,
            children: [
              _buildInfoRow('Zones souhaitées', application.zonesString),
              _buildInfoRow('Disponibilité', application.disponibilite),
            ],
          ),
          const SizedBox(height: 16),

          // Documents
          if (application.cvUrl != null ||
              application.lettreMotivationUrl != null ||
              application.photoUrl != null)
            _buildDocumentsCard(context, application),

          const SizedBox(height: 24),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: application.status == 'active'
                      ? () => _toggleStatus(application, 'inactive')
                      : () => _toggleStatus(application, 'active'),
                  icon: Icon(
                    application.status == 'active'
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  label: Text(
                    application.status == 'active' ? 'Désactiver' : 'Activer',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditCandidateProfilePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Carte de statut
  Widget _buildStatusCard(
    BuildContext context,
    JobApplicationModel application,
  ) {
    final isActive = application.status == 'active';
    return Card(
      color: isActive ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.pause_circle,
              color: isActive ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Candidature active' : 'Candidature inactive',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green[900] : Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive
                        ? 'Votre candidature est visible par les recruteurs'
                        : 'Votre candidature n\'est pas visible',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.green[700] : Colors.orange[700],
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

  /// Carte de statistiques
  Widget _buildStatsCard(
    BuildContext context,
    JobApplicationModel application,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileViewsPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _isLoadingViewsCount
                          ? Column(
                              children: [
                                Icon(
                                  Icons.visibility,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 4),
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vues de profil',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            )
                          : _buildStatItem(
                              context,
                              icon: Icons.visibility,
                              label: 'Vues de profil',
                              value: _profileViewsCount.toString(),
                            ),
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.contact_mail,
                    label: 'Contacts',
                    value: application.contactsCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur "Vues de profil" pour voir qui a consulté votre profil',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  /// Carte de section générique
  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte des documents
  Widget _buildDocumentsCard(
    BuildContext context,
    JobApplicationModel application,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Documents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (application.cvUrl != null)
              ListTile(
                leading: const Icon(Icons.description, color: Colors.blue),
                title: const Text('CV'),
                trailing: const Icon(Icons.download),
                onTap: () => _openDocument(application.cvUrl!, 'CV'),
              ),
            if (application.lettreMotivationUrl != null)
              ListTile(
                leading: const Icon(Icons.mail, color: Colors.green),
                title: const Text('Lettre de motivation'),
                trailing: const Icon(Icons.download),
                onTap: () => _openDocument(
                  application.lettreMotivationUrl!,
                  'Lettre de motivation',
                ),
              ),
            if (application.photoUrl != null)
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.orange),
                title: const Text('Photo'),
                trailing: const Icon(Icons.visibility),
                onTap: () => _showPhoto(application.photoUrl!),
              ),
          ],
        ),
      ),
    );
  }

  /// Basculer le statut de la candidature
  Future<void> _toggleStatus(
    JobApplicationModel application,
    String newStatus,
  ) async {
    try {
      await _jobsService.updateJobApplication(application.id, {
        'status': newStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'active'
                  ? 'Candidature activée'
                  : 'Candidature désactivée',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Ouvrir un document (CV ou lettre de motivation)
  Future<void> _openDocument(String url, String documentType) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'ouvrir le $documentType'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Afficher la photo dans une boîte de dialogue
  void _showPhoto(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Photo'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    final uri = Uri.parse(photoUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(64.0),
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(64.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Erreur de chargement de la photo'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
