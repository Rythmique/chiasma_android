import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_offer_model.dart';
import '../models/offer_application_model.dart';
import '../services/jobs_service.dart';

/// Page de liste des offres d'emploi pour les candidats
class JobOffersListPage extends StatefulWidget {
  const JobOffersListPage({super.key});

  @override
  State<JobOffersListPage> createState() => _JobOffersListPageState();
}

class _JobOffersListPageState extends State<JobOffersListPage> {
  final JobsService _jobsService = JobsService();

  // Filtres
  String? _selectedVille;
  String? _selectedTypeContrat;
  List<String> _selectedMatieres = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offres d\'emploi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<JobOfferModel>>(
        stream: _jobsService.streamActiveOffers(limit: 50),
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

          // Appliquer les filtres
          final filteredOffers = _applyFilters(offers);

          if (filteredOffers.isEmpty) {
            return _buildEmptyView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Force rebuild du stream
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOffers.length,
              itemBuilder: (context, index) {
                return _buildOfferCard(filteredOffers[index]);
              },
            ),
          );
        },
      ),
    );
  }

  /// Appliquer les filtres aux offres
  List<JobOfferModel> _applyFilters(List<JobOfferModel> offers) {
    return offers.where((offer) {
      // Filtre par ville
      if (_selectedVille != null &&
          _selectedVille!.isNotEmpty &&
          offer.ville != _selectedVille) {
        return false;
      }

      // Filtre par type de contrat
      if (_selectedTypeContrat != null &&
          _selectedTypeContrat!.isNotEmpty &&
          offer.typeContrat != _selectedTypeContrat) {
        return false;
      }

      // Filtre par matières
      if (_selectedMatieres.isNotEmpty) {
        bool hasMatchingMatiere = false;
        for (var matiere in _selectedMatieres) {
          if (offer.matieres.contains(matiere)) {
            hasMatchingMatiere = true;
            break;
          }
        }
        if (!hasMatchingMatiere) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Vue vide
  Widget _buildEmptyView() {
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
              'Aucune offre disponible',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune offre d\'emploi ne correspond à vos critères.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_selectedVille != null ||
                _selectedTypeContrat != null ||
                _selectedMatieres.isNotEmpty) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Effacer les filtres'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Carte d'une offre d'emploi
  Widget _buildOfferCard(JobOfferModel offer) {
    final expirationDate = offer.expiresAt ?? DateTime.now().add(const Duration(days: 30));
    final daysRemaining = expirationDate.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysRemaining <= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOfferDetails(offer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec établissement et date
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.nomEtablissement,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${offer.commune}, ${offer.ville}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isExpiringSoon)
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

              // Poste
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  offer.poste,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Matières et niveaux
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...offer.matieres.take(3).map((matiere) => Chip(
                        label: Text(matiere),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                      )),
                  if (offer.matieres.length > 3)
                    Chip(
                      label: Text('+${offer.matieres.length - 3}'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: const TextStyle(fontSize: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Type de contrat et statistiques
              Row(
                children: [
                  Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    offer.typeContrat,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${offer.viewsCount}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${offer.applicantsCount} candidat(s)',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Afficher les détails d'une offre
  void _showOfferDetails(JobOfferModel offer) {
    // Incrémenter le compteur de vues
    _jobsService.incrementOfferViews(offer.id);

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
              // Header
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
                offer.nomEtablissement,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${offer.commune}, ${offer.ville}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Poste
              _buildDetailSection('Poste', offer.poste),
              const SizedBox(height: 16),

              // Matières
              _buildDetailSection('Matières', offer.matieresString),
              const SizedBox(height: 16),

              // Niveaux
              _buildDetailSection('Niveaux', offer.niveauxString),
              const SizedBox(height: 16),

              // Type de contrat
              _buildDetailSection('Type de contrat', offer.typeContrat),
              const SizedBox(height: 16),

              // Description
              if (offer.description.isNotEmpty && offer.description != 'Aucune description') ...[
                _buildDetailSection('Description', offer.description),
                const SizedBox(height: 16),
              ],

              // Date limite
              if (offer.expiresAt != null)
                _buildDetailSection(
                  'Date limite',
                  '${offer.expiresAt!.day}/${offer.expiresAt!.month}/${offer.expiresAt!.year}',
                ),
              const SizedBox(height: 24),

              // Bouton Postuler
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyToOffer(offer);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Postuler'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
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
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  /// Postuler à une offre
  Future<void> _applyToOffer(JobOfferModel offer) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez être connecté pour postuler'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Vérifier si l'utilisateur a déjà postulé
      final hasApplied = await _jobsService.hasUserAppliedToOffer(userId, offer.id);
      if (hasApplied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez déjà postulé à cette offre'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Récupérer les informations de l'utilisateur
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('Profil utilisateur non trouvé');
      }

      final userData = userDoc.data()!;

      // Afficher le dialogue de confirmation avec option de lettre de motivation
      if (!mounted) return;
      final result = await showDialog<String>(
        context: context,
        builder: (context) => _ApplicationConfirmDialog(
          jobTitle: offer.poste,
          schoolName: offer.nomEtablissement,
        ),
      );

      if (result == null) return; // L'utilisateur a annulé

      // Créer la candidature
      final application = OfferApplicationModel(
        id: '',
        offerId: offer.id,
        userId: userId,
        candidateName: userData['nom'] ?? '',
        candidateEmail: userData['email'] ?? '',
        candidatePhones: List<String>.from(userData['telephones'] ?? []),
        coverLetter: result.isEmpty ? null : result,
        createdAt: DateTime.now(),
        jobTitle: offer.poste,
        schoolName: offer.nomEtablissement,
        schoolId: offer.schoolId,
      );

      await _jobsService.applyToOffer(application);
      await _jobsService.incrementOfferApplications(offer.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Candidature à "${offer.poste}" envoyée avec succès!'),
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

  /// Afficher le dialogue de filtres
  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ville',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(
                initialValue: _selectedVille,
                decoration: const InputDecoration(
                  hintText: 'Ex: Abidjan',
                  isDense: true,
                ),
                onChanged: (value) {
                  _selectedVille = value.isEmpty ? null : value;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Type de contrat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(isDense: true),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tous')),
                  DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                  DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                  DropdownMenuItem(value: 'Vacation', child: Text('Vacation')),
                  DropdownMenuItem(value: 'Stage', child: Text('Stage')),
                ],
                onChanged: (value) {
                  _selectedTypeContrat = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Effacer'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Appliquer les filtres
              Navigator.pop(context);
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  /// Effacer tous les filtres
  void _clearFilters() {
    setState(() {
      _selectedVille = null;
      _selectedTypeContrat = null;
      _selectedMatieres = [];
    });
  }
}

/// Dialogue de confirmation de candidature avec option de lettre de motivation
class _ApplicationConfirmDialog extends StatefulWidget {
  final String jobTitle;
  final String schoolName;

  const _ApplicationConfirmDialog({
    required this.jobTitle,
    required this.schoolName,
  });

  @override
  State<_ApplicationConfirmDialog> createState() => _ApplicationConfirmDialogState();
}

class _ApplicationConfirmDialogState extends State<_ApplicationConfirmDialog> {
  final _coverLetterController = TextEditingController();
  bool _includeCoverLetter = false;

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmer la candidature'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous postulez pour :',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.jobTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.schoolName,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Ajouter une lettre de motivation'),
              subtitle: const Text('(Optionnel mais recommandé)'),
              value: _includeCoverLetter,
              onChanged: (value) {
                setState(() {
                  _includeCoverLetter = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (_includeCoverLetter) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _coverLetterController,
                decoration: const InputDecoration(
                  labelText: 'Lettre de motivation',
                  hintText: 'Expliquez pourquoi vous êtes le candidat idéal...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                maxLength: 500,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final coverLetter = _includeCoverLetter
                ? _coverLetterController.text.trim()
                : '';
            Navigator.pop(context, coverLetter);
          },
          icon: const Icon(Icons.send),
          label: const Text('Envoyer ma candidature'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
