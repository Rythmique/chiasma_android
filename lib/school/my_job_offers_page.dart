import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_offer_model.dart';
import '../services/jobs_service.dart';
import '../services/firestore_service.dart';
import '../widgets/subscription_status_banner.dart';
import '../widgets/quota_status_widget.dart';
import '../widgets/welcome_quota_dialog.dart';
import '../widgets/subscription_required_dialog.dart';
import '../widgets/announcements_banner.dart';
import '../widgets/notification_bell_icon.dart';
import 'create_job_offer_page.dart';
import 'view_applications_page.dart';

/// Page de gestion des offres d'emploi de l'établissement
class MyJobOffersPage extends StatefulWidget {
  const MyJobOffersPage({super.key});

  @override
  State<MyJobOffersPage> createState() => _MyJobOffersPageState();
}

class _MyJobOffersPageState extends State<MyJobOffersPage> {
  final JobsService _jobsService = JobsService();
  final FirestoreService _firestoreService = FirestoreService();
  final String? _schoolId = FirebaseAuth.instance.currentUser?.uid;

  /// Vérifier si l'utilisateur peut créer une offre et naviguer ou afficher le dialogue
  Future<void> _handleCreateJobOffer(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Récupérer l'utilisateur actuel
    final user = await _firestoreService.getUser(userId);
    if (user == null) return;

    // Vérifier si l'utilisateur peut créer une offre
    final bool canCreateOffer = user.isVerified || user.freeQuotaUsed < user.freeQuotaLimit;

    if (!context.mounted) return;

    if (!canCreateOffer) {
      // Afficher le dialogue d'abonnement
      SubscriptionRequiredDialog.show(context, 'school');
      return;
    }

    // Naviguer vers la page de création
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateJobOfferPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Erreur: utilisateur non connecté'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes offres d\'emploi'),
        actions: [
          const NotificationBellIcon(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _handleCreateJobOffer(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Annonces
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AnnouncementsBanner(accountType: 'school'),
          ),

          // Statut de vérification et quota
          StreamBuilder(
            stream: _firestoreService.getUserStream(_schoolId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final user = snapshot.data!;

              // Afficher le dialogue de bienvenue si première connexion
              WidgetsBinding.instance.addPostFrameCallback((_) {
                WelcomeQuotaDialog.showIfFirstTime(context, user);

                // Vérifier si le quota est épuisé
                if (user.isFreeQuotaExhausted && !user.hasAccess) {
                  SubscriptionRequiredDialog.show(context, user.accountType);
                }
              });

              return Column(
                children: [
                  SubscriptionStatusBanner(user: user),
                  QuotaStatusWidget(user: user),
                ],
              );
            },
          ),

          // Liste des offres
          Expanded(
            child: StreamBuilder<List<JobOfferModel>>(
              stream: _jobsService.streamJobOffersBySchoolId(_schoolId),
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

          final offers = snapshot.data ?? [];

          if (offers.isEmpty) {
            return _buildEmptyView(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return _buildOfferCard(offers[index]);
            },
          );
        },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleCreateJobOffer(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle offre'),
      ),
    );
  }

  /// Vue vide
  Widget _buildEmptyView(BuildContext context) {
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
              'Aucune offre publiée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Commencez à recruter en publiant votre première offre d\'emploi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _handleCreateJobOffer(context),
              icon: const Icon(Icons.add),
              label: const Text('Créer une offre'),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte d'une offre
  Widget _buildOfferCard(JobOfferModel offer) {
    final isActive = offer.status == 'open';
    final expirationDate = offer.expiresAt ?? DateTime.now().add(const Duration(days: 30));
    final daysRemaining = expirationDate.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysRemaining <= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    offer.poste,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Ouverte' : 'Fermée',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green[900] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Type de contrat
            Row(
              children: [
                Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  offer.typeContrat,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Matières
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: offer.matieres.take(3).map((matiere) {
                return Chip(
                  label: Text(matiere),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelStyle: const TextStyle(fontSize: 11),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Statistiques
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${offer.viewsCount} vues',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${offer.applicantsCount} candidats',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const Spacer(),
                if (isExpiringSoon && isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$daysRemaining j restants',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOfferDetails(offer),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: offer.applicantsCount > 0
                        ? () => _viewApplications(offer)
                        : null,
                    icon: const Icon(Icons.people, size: 18),
                    label: Text('${offer.applicantsCount}'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: offer.applicantsCount > 0
                          ? const Color(0xFF009E60)
                          : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOfferMenu(offer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Voir les candidatures pour une offre
  void _viewApplications(JobOfferModel offer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewApplicationsPage(offer: offer),
      ),
    );
  }

  /// Afficher les détails d'une offre
  void _showOfferDetails(JobOfferModel offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                offer.poste,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                offer.nomEtablissement,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const Divider(height: 32),
              _buildDetailSection('Matières', offer.matieresString),
              const SizedBox(height: 16),
              _buildDetailSection('Niveaux', offer.niveauxString),
              const SizedBox(height: 16),
              _buildDetailSection('Type de contrat', offer.typeContrat),
              const SizedBox(height: 16),
              if (offer.description.isNotEmpty && offer.description != 'Aucune description')
                _buildDetailSection('Description', offer.description),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  /// Basculer le statut d'une offre
  Future<void> _toggleOfferStatus(JobOfferModel offer) async {
    final newStatus = offer.status == 'open' ? 'closed' : 'open';

    try {
      await _jobsService.updateJobOffer(offer.id, {'status': newStatus});

      if (mounted) {
        setState(() {}); // Refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'open'
                  ? 'Offre activée'
                  : 'Offre suspendue',
            ),
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

  /// Afficher le menu d'une offre
  void _showOfferMenu(JobOfferModel offer) {
    final isActive = offer.status == 'open';

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(isActive ? Icons.pause : Icons.play_arrow),
            title: Text(isActive ? 'Suspendre l\'offre' : 'Activer l\'offre'),
            onTap: () {
              Navigator.pop(context);
              _toggleOfferStatus(offer);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modifier'),
            onTap: () {
              Navigator.pop(context);
              _editOffer(offer);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Dupliquer'),
            onTap: () {
              Navigator.pop(context);
              _duplicateOffer(offer);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteOffer(offer);
            },
          ),
        ],
      ),
    );
  }

  /// Éditer une offre
  void _editOffer(JobOfferModel offer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateJobOfferPage(existingOffer: offer),
      ),
    ).then((result) {
      if (result == true && mounted) {
        // Pas besoin de setState car on utilise StreamBuilder
      }
    });
  }

  /// Dupliquer une offre
  Future<void> _duplicateOffer(JobOfferModel offer) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Créer une copie de l'offre
      final duplicatedOffer = JobOfferModel(
        id: '', // Sera défini par Firestore
        schoolId: userId,
        nomEtablissement: offer.nomEtablissement,
        ville: offer.ville,
        commune: offer.commune,
        poste: '${offer.poste} (copie)',
        matieres: List<String>.from(offer.matieres),
        niveaux: List<String>.from(offer.niveaux),
        typeContrat: offer.typeContrat,
        description: offer.description,
        exigences: List<String>.from(offer.exigences),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        status: 'open',
      );

      await _jobsService.createJobOffer(duplicatedOffer);

      if (mounted) {
        setState(() {}); // Refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre dupliquée avec succès!'),
            backgroundColor: Color(0xFF009E60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la duplication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Confirmer la suppression d'une offre
  void _confirmDeleteOffer(JobOfferModel offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'offre?'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'offre "${offer.poste}"? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              try {
                await _jobsService.deleteJobOffer(offer.id);
                if (mounted) {
                  setState(() {}); // Refresh
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Offre supprimée')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
