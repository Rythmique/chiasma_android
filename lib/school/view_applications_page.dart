import 'package:flutter/material.dart';
import '../models/offer_application_model.dart';
import '../models/job_offer_model.dart';
import '../services/jobs_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../profile_detail_page.dart';
import '../chat_page.dart';

/// Page pour visualiser les candidatures à une offre d'emploi
class ViewApplicationsPage extends StatefulWidget {
  final JobOfferModel offer;

  const ViewApplicationsPage({
    super.key,
    required this.offer,
  });

  @override
  State<ViewApplicationsPage> createState() => _ViewApplicationsPageState();
}

class _ViewApplicationsPageState extends State<ViewApplicationsPage> {
  final JobsService _jobsService = JobsService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  String _selectedFilter = 'all'; // all, pending, accepted, rejected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidatures'),
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
      body: Column(
        children: [
          // En-tête avec info de l'offre
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.offer.poste,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.offer.nomEtablissement,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.offer.applicantsCount} candidature(s)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des candidatures
          Expanded(
            child: StreamBuilder<List<OfferApplicationModel>>(
              stream: _jobsService.streamOfferApplications(widget.offer.id),
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
          ),
        ],
      ),
    );
  }

  /// Vue vide
  Widget _buildEmptyView() {
    String message;
    switch (_selectedFilter) {
      case 'pending':
        message = 'Aucune candidature en attente';
        break;
      case 'accepted':
        message = 'Aucune candidature acceptée';
        break;
      case 'rejected':
        message = 'Aucune candidature refusée';
        break;
      default:
        message = 'Aucune candidature reçue';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
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
              _selectedFilter == 'all'
                  ? 'Les candidats intéressés apparaîtront ici'
                  : 'Changez le filtre pour voir d\'autres candidatures',
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

    switch (application.status) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'withdrawn':
        statusColor = Colors.grey;
        statusIcon = Icons.remove_circle;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec nom et statut
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    application.candidateName.isNotEmpty
                        ? application.candidateName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
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
                        application.candidateName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        application.candidateEmail,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        application.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Téléphones
            if (application.candidatePhones.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: application.candidatePhones.map((phone) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],

            // Lettre de motivation
            if (application.coverLetter != null &&
                application.coverLetter!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Lettre de motivation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                application.coverLetter!,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Date de candidature
            Text(
              'Candidature du ${_formatDate(application.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewCandidateProfile(application),
                    icon: const Icon(Icons.person, size: 18),
                    label: const Text('Profil'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _contactCandidate(application),
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Contacter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009E60),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showApplicationMenu(application),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Formater la date
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
      'déc.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Voir le profil du candidat
  Future<void> _viewCandidateProfile(OfferApplicationModel application) async {
    // Incrémenter le compteur de vues
    await _jobsService.incrementApplicationViewCount(application.id);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailPage(userId: application.userId),
      ),
    );
  }

  /// Contacter le candidat
  Future<void> _contactCandidate(OfferApplicationModel application) async {
    try {
      // Charger les infos du candidat
      final candidateData = await _firestoreService.getUser(application.userId);
      if (candidateData == null) {
        throw Exception('Candidat introuvable');
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            contactUserId: application.userId,
            contactName: candidateData.nom,
            contactFunction: candidateData.fonction,
            isOnline: false, // On peut améliorer cela plus tard avec une vraie détection
          ),
        ),
      );
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

  /// Afficher le menu d'une candidature
  void _showApplicationMenu(OfferApplicationModel application) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (application.isPending) ...[
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Accepter'),
              onTap: () {
                Navigator.pop(context);
                _updateApplicationStatus(application, 'accepted');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Refuser'),
              onTap: () {
                Navigator.pop(context);
                _updateApplicationStatus(application, 'rejected');
              },
            ),
          ],
          if (application.isAccepted || application.isRejected) ...[
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Remettre en attente'),
              onTap: () {
                Navigator.pop(context);
                _updateApplicationStatus(application, 'pending');
              },
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Fermer'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Mettre à jour le statut d'une candidature
  Future<void> _updateApplicationStatus(
    OfferApplicationModel application,
    String newStatus,
  ) async {
    try {
      await _jobsService.updateApplicationStatus(application.id, newStatus);

      // Envoyer une notification au candidat
      if (newStatus == 'accepted' || newStatus == 'rejected') {
        await _notificationService.sendNotification(
          userId: application.userId,
          type: 'application_status',
          title: newStatus == 'accepted'
              ? 'Candidature acceptée'
              : 'Candidature refusée',
          message: newStatus == 'accepted'
              ? 'Votre candidature pour le poste de ${application.jobTitle} chez ${application.schoolName} a été acceptée !'
              : 'Votre candidature pour le poste de ${application.jobTitle} chez ${application.schoolName} a été refusée.',
          data: {
            'applicationId': application.id,
            'offerId': application.offerId,
            'schoolId': application.schoolId,
            'status': newStatus,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'accepted'
                  ? 'Candidature acceptée et candidat notifié'
                  : newStatus == 'rejected'
                      ? 'Candidature refusée et candidat notifié'
                      : 'Statut mis à jour',
            ),
            backgroundColor: newStatus == 'accepted'
                ? Colors.green
                : newStatus == 'rejected'
                    ? Colors.red
                    : null,
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
