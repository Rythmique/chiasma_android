import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/job_offer_model.dart';
import 'package:myapp/services/jobs_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/teacher_candidate/job_offer_detail_page.dart';
import 'package:myapp/widgets/subscription_status_banner.dart';
import 'package:myapp/widgets/quota_status_widget.dart';
import 'package:myapp/widgets/welcome_quota_dialog.dart';
import 'package:myapp/widgets/subscription_required_dialog.dart';
import 'package:myapp/widgets/announcements_banner.dart';
import 'package:myapp/widgets/notification_bell_icon.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Page pour consulter les offres d'emploi disponibles
class JobOffersListPage extends StatefulWidget {
  const JobOffersListPage({super.key});

  @override
  State<JobOffersListPage> createState() => _JobOffersListPageState();
}

class _JobOffersListPageState extends State<JobOffersListPage> {
  final JobsService _jobsService = JobsService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedVille;
  String? _selectedTypeContrat;

  @override
  void initState() {
    super.initState();
    // Configuration de timeago en français
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offres d\'emploi'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [
          NotificationBellIcon(),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            color: const Color(0xFFF77F00),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Champ de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un poste, une matière...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filtres
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterChip(
                        icon: Icons.location_on,
                        label: _selectedVille ?? 'Toutes les villes',
                        onTap: () => _showVilleFilter(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip(
                        icon: Icons.work,
                        label: _selectedTypeContrat ?? 'Tous contrats',
                        onTap: () => _showContratFilter(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Annonces
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AnnouncementsBanner(accountType: 'teacher_candidate'),
          ),

          // Statut de vérification et quota
          StreamBuilder(
            stream: _firestoreService.getUserStream(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
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
              stream: _jobsService.streamOpenJobOffers(),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                List<JobOfferModel> offers = snapshot.data ?? [];

                // Appliquer les filtres
                offers = offers.where((offer) {
                  // Filtre de recherche
                  if (_searchQuery.isNotEmpty) {
                    final matchesSearch =
                        offer.poste.toLowerCase().contains(_searchQuery) ||
                        offer.nomEtablissement.toLowerCase().contains(_searchQuery) ||
                        offer.matieresString.toLowerCase().contains(_searchQuery) ||
                        offer.ville.toLowerCase().contains(_searchQuery);
                    if (!matchesSearch) return false;
                  }

                  // Filtre ville
                  if (_selectedVille != null && offer.ville != _selectedVille) {
                    return false;
                  }

                  // Filtre type de contrat
                  if (_selectedTypeContrat != null && offer.typeContrat != _selectedTypeContrat) {
                    return false;
                  }

                  return true;
                }).toList();

                if (offers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty || _selectedVille != null || _selectedTypeContrat != null
                                ? Icons.search_off
                                : Icons.work_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _selectedVille != null || _selectedTypeContrat != null
                                ? 'Aucune offre ne correspond à vos critères'
                                : 'Aucune offre disponible pour le moment',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty || _selectedVille != null || _selectedTypeContrat != null
                                ? 'Essayez de modifier vos filtres'
                                : 'Revenez plus tard pour découvrir de nouvelles opportunités',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isNotEmpty || _selectedVille != null || _selectedTypeContrat != null) ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _selectedVille = null;
                                  _selectedTypeContrat = null;
                                });
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Effacer les filtres'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    return _buildJobOfferCard(context, offers[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFF77F00)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildJobOfferCard(BuildContext context, JobOfferModel offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobOfferDetailPage(offer: offer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec établissement et date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF77F00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Color(0xFFF77F00),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.nomEtablissement,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeago.format(offer.createdAt, locale: 'fr'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009E60).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      offer.typeContrat,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF009E60),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Titre du poste
              Text(
                offer.poste,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 8),

              // Matières
              if (offer.matieres.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: offer.matieres.take(3).map((matiere) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        matiere,
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList()
                    ..addAll([
                      if (offer.matieres.length > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${offer.matieres.length - 3}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ]),
                ),
              const SizedBox(height: 12),

              // Localisation et salaire
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    offer.localisationComplete,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  if (offer.salaire != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.payments, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      offer.salaire!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Statistiques
              Row(
                children: [
                  Icon(Icons.visibility, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${offer.viewsCount} vues',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${offer.applicantsCount} candidature${offer.applicantsCount > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVilleFilter() {
    // Liste des villes populaires (à adapter selon vos besoins)
    final villes = [
      'Toutes les villes',
      'Abidjan',
      'Bouaké',
      'Yamoussoukro',
      'Daloa',
      'San-Pédro',
      'Korhogo',
      'Man',
      'Gagnoa',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: villes.length,
          itemBuilder: (context, index) {
            final ville = villes[index];
            final isSelected = ville == 'Toutes les villes'
                ? _selectedVille == null
                : _selectedVille == ville;

            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.location_city,
                color: isSelected ? const Color(0xFF009E60) : Colors.grey,
              ),
              title: Text(ville),
              selected: isSelected,
              onTap: () {
                setState(() {
                  _selectedVille = ville == 'Toutes les villes' ? null : ville;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  void _showContratFilter() {
    final contrats = [
      'Tous contrats',
      'CDI',
      'CDD',
      'Vacataire',
      'Fonctionnaire',
      'Stage',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: contrats.length,
          itemBuilder: (context, index) {
            final contrat = contrats[index];
            final isSelected = contrat == 'Tous contrats'
                ? _selectedTypeContrat == null
                : _selectedTypeContrat == contrat;

            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.work_outline,
                color: isSelected ? const Color(0xFF009E60) : Colors.grey,
              ),
              title: Text(contrat),
              selected: isSelected,
              onTap: () {
                setState(() {
                  _selectedTypeContrat = contrat == 'Tous contrats' ? null : contrat;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}
