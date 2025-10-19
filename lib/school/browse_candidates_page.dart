import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_application_model.dart';
import '../services/jobs_service.dart';

/// Page pour consulter les candidatures d'enseignants
class BrowseCandidatesPage extends StatefulWidget {
  const BrowseCandidatesPage({super.key});

  @override
  State<BrowseCandidatesPage> createState() => _BrowseCandidatesPageState();
}

class _BrowseCandidatesPageState extends State<BrowseCandidatesPage> {
  final JobsService _jobsService = JobsService();

  // Filtres
  String? _selectedMatiere;
  List<String> _selectedNiveaux = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidats enseignants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<JobApplicationModel>>(
        stream: _jobsService.streamActiveApplications(limit: 50),
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

          final applications = snapshot.data ?? [];

          // Appliquer les filtres
          final filteredApplications = _applyFilters(applications);

          if (filteredApplications.isEmpty) {
            return _buildEmptyView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Force rebuild du stream
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredApplications.length,
              itemBuilder: (context, index) {
                return _buildCandidateCard(filteredApplications[index]);
              },
            ),
          );
        },
      ),
    );
  }

  /// Appliquer les filtres
  List<JobApplicationModel> _applyFilters(List<JobApplicationModel> applications) {
    return applications.where((app) {
      // Filtre par matière
      if (_selectedMatiere != null &&
          _selectedMatiere!.isNotEmpty &&
          !app.matieres.contains(_selectedMatiere)) {
        return false;
      }

      // Filtre par niveaux
      if (_selectedNiveaux.isNotEmpty) {
        bool hasMatchingNiveau = false;
        for (var niveau in _selectedNiveaux) {
          if (app.niveaux.contains(niveau)) {
            hasMatchingNiveau = true;
            break;
          }
        }
        if (!hasMatchingNiveau) {
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
              Icons.people_outline,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun candidat disponible',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun candidat ne correspond à vos critères de recherche.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_selectedMatiere != null || _selectedNiveaux.isNotEmpty) ...[
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

  /// Carte d'un candidat
  Widget _buildCandidateCard(JobApplicationModel application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCandidateDetails(application),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec nom
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      application.nom.isNotEmpty
                          ? application.nom[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.nom,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.experience,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      application.disponibilite,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Matières
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...application.matieres.take(3).map((matiere) => Chip(
                        label: Text(matiere),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      )),
                  if (application.matieres.length > 3)
                    Chip(
                      label: Text('+${application.matieres.length - 3}'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelStyle: const TextStyle(fontSize: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Niveaux
              Text(
                'Niveaux: ${application.niveauxString}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),

              // Zones et diplômes
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      application.zonesString,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.school, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      application.diplomes.join(', '),
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Afficher les détails d'un candidat
  void _showCandidateDetails(JobApplicationModel application) {
    // Incrémenter le compteur de vues
    _jobsService.incrementApplicationViews(application.id);

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

              // Photo/Avatar
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    application.nom.isNotEmpty
                        ? application.nom[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  application.nom,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Disponibilité: ${application.disponibilite}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ),
              ),
              const Divider(height: 32),

              // Coordonnées
              _buildDetailSection('Contact', ''),
              _buildInfoRow(Icons.email, application.email),
              if (application.telephones.isNotEmpty)
                ...application.telephones
                    .map((phone) => _buildInfoRow(Icons.phone, phone)),
              const SizedBox(height: 16),

              // Matières
              _buildDetailSection('Matières enseignées', application.matieresString),
              const SizedBox(height: 16),

              // Niveaux
              _buildDetailSection('Niveaux d\'enseignement', application.niveauxString),
              const SizedBox(height: 16),

              // Diplômes
              _buildDetailSection('Diplômes', application.diplomes.join(', ')),
              const SizedBox(height: 16),

              // Expérience
              _buildDetailSection('Expérience professionnelle', application.experience),
              const SizedBox(height: 16),

              // Zones souhaitées
              _buildDetailSection('Zones souhaitées', application.zonesString),
              const SizedBox(height: 24),

              // Statistiques
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.visibility, color: Colors.blue[700]),
                          const SizedBox(height: 4),
                          Text(
                            '${application.viewsCount}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Vues',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.grey[300],
                      ),
                      Column(
                        children: [
                          Icon(Icons.contact_mail, color: Colors.blue[700]),
                          const SizedBox(height: 4),
                          Text(
                            '${application.contactsCount}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Contacts',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bouton Contact
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _contactCandidate(application);
                  },
                  icon: const Icon(Icons.mail),
                  label: const Text('Contacter le candidat'),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  /// Contacter un candidat
  void _contactCandidate(JobApplicationModel application) {
    _jobsService.incrementApplicationContacts(application.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter le candidat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coordonnées du candidat:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _launchEmail(application.email),
              child: Row(
                children: [
                  const Icon(Icons.email, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      application.email,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (application.telephones.isNotEmpty)
              InkWell(
                onTap: () => _launchPhone(application.telephones.first),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        application.telephones.join(', '),
                        style: const TextStyle(
                          color: Colors.green,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _launchEmail(application.email);
            },
            icon: const Icon(Icons.email),
            label: const Text('Envoyer un email'),
          ),
        ],
      ),
    );
  }

  /// Ouvrir l'application email
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Candidature CHIASMA',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir l\'application email'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  /// Ouvrir l'application téléphone
  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir l\'application téléphone'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    String? tempMatiere = _selectedMatiere;
    List<String> tempNiveaux = List.from(_selectedNiveaux);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Filtres de recherche'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Matière',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: tempMatiere,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Mathématiques',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    tempMatiere = value.isEmpty ? null : value;
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Niveaux',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    '6ème', '5ème', '4ème', '3ème',
                    '2nde', '1ère', 'Terminale',
                    'Primaire', 'Maternelle'
                  ].map((niveau) {
                    final isSelected = tempNiveaux.contains(niveau);
                    return FilterChip(
                      label: Text(niveau),
                      selected: isSelected,
                      onSelected: (selected) {
                        setStateDialog(() {
                          if (selected) {
                            tempNiveaux.add(niveau);
                          } else {
                            tempNiveaux.remove(niveau);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedMatiere = null;
                  _selectedNiveaux = [];
                });
                Navigator.pop(context);
              },
              child: const Text('Effacer'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedMatiere = tempMatiere;
                  _selectedNiveaux = tempNiveaux;
                });
                Navigator.pop(context);
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Effacer tous les filtres
  void _clearFilters() {
    setState(() {
      _selectedMatiere = null;
      _selectedNiveaux = [];
    });
  }
}
