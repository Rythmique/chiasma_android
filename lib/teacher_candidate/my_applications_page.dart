import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/offer_application_model.dart';
import '../services/jobs_service.dart';
import '../chat_page.dart';

/// Page pour voir toutes les candidatures envoyées par le candidat
class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  final JobsService _jobsService = JobsService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  String _selectedFilter = 'all'; // all, pending, accepted, rejected

  @override
  void initState() {
    super.initState();
    // Configuration de timeago en français
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes candidatures'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Erreur: utilisateur non connecté'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes candidatures'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Toutes'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('En attente'),
              ),
              const PopupMenuItem(
                value: 'accepted',
                child: Text('Acceptées'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Refusées'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<OfferApplicationModel>>(
        stream: _jobsService.streamUserOfferApplications(_userId),
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

          final allApplications = snapshot.data ?? [];

          // Filtrer selon le statut sélectionné
          final filteredApplications = _selectedFilter == 'all'
              ? allApplications
              : allApplications
                  .where((app) => app.status == _selectedFilter)
                  .toList();

          if (filteredApplications.isEmpty) {
            return _buildEmptyView();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredApplications.length,
            itemBuilder: (context, index) {
              return _buildApplicationCard(filteredApplications[index]);
            },
          );
        },
      ),
    );
  }

  /// Vue vide
  Widget _buildEmptyView() {
    String message;
    String subtitle;

    switch (_selectedFilter) {
      case 'pending':
        message = 'Aucune candidature en attente';
        subtitle = 'Vos candidatures en attente apparaîtront ici';
        break;
      case 'accepted':
        message = 'Aucune candidature acceptée';
        subtitle = 'Vos candidatures acceptées apparaîtront ici';
        break;
      case 'rejected':
        message = 'Aucune candidature refusée';
        subtitle = 'Vos candidatures refusées apparaîtront ici';
        break;
      default:
        message = 'Aucune candidature envoyée';
        subtitle = 'Commencez à postuler aux offres qui vous intéressent !';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte d'une candidature
  Widget _buildApplicationCard(OfferApplicationModel application) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (application.status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Acceptée';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusLabel = 'Refusée';
        break;
      case 'withdrawn':
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle;
        statusLabel = 'Retirée';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusLabel = 'En attente';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // On pourrait naviguer vers les détails de l'offre si disponible
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec poste et statut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.jobTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.business, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                application.schoolName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Informations de la candidature
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Postulé ${timeago.format(application.createdAt, locale: 'fr')}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  if (application.viewsCount > 0) ...[
                    Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${application.viewsCount} vue${application.viewsCount > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),

              // Message si acceptée
              if (application.status == 'accepted') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.celebration, size: 20, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Félicitations ! Contactez l\'établissement pour la suite.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Boutons d'action
              Row(
                children: [
                  if (application.status == 'accepted') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _contactSchool(application),
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Contacter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009E60),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ] else if (application.status == 'pending') ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _withdrawApplication(application),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Retirer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _deleteApplication(application),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Supprimer'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Contacter l'établissement
  Future<void> _contactSchool(OfferApplicationModel application) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          contactUserId: application.schoolId,
          contactName: application.schoolName,
          contactFunction: 'Établissement',
          isOnline: false,
        ),
      ),
    );
  }

  /// Retirer une candidature (suppression complète)
  Future<void> _withdrawApplication(OfferApplicationModel application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer la candidature ?'),
        content: Text(
          'Voulez-vous vraiment retirer votre candidature pour ${application.jobTitle} ?\n\nVous pourrez postuler à nouveau si vous le souhaitez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Supprimer complètement la candidature de Firestore
        await _jobsService.deleteOfferApplication(application.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Candidature retirée avec succès. Vous pouvez postuler à nouveau.'),
              backgroundColor: Color(0xFF009E60),
              duration: Duration(seconds: 3),
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

  /// Supprimer une candidature de l'historique
  Future<void> _deleteApplication(OfferApplicationModel application) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer de l\'historique ?'),
        content: const Text(
          'Cette action est irréversible. Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Supprimer complètement la candidature
        await _jobsService.deleteOfferApplication(application.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Candidature supprimée de l\'historique'),
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
}
