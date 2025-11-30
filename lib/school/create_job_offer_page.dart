import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_offer_model.dart';
import '../services/jobs_service.dart';
import '../services/firestore_service.dart';
import '../services/subscription_service.dart';
import '../services/analytics_service.dart';
import '../widgets/zone_search_field.dart';
import '../widgets/subscription_required_dialog.dart';

/// Page pour créer ou éditer une offre d'emploi
class CreateJobOfferPage extends StatefulWidget {
  final JobOfferModel? existingOffer; // Pour l'édition

  const CreateJobOfferPage({super.key, this.existingOffer});

  @override
  State<CreateJobOfferPage> createState() => _CreateJobOfferPageState();
}

class _CreateJobOfferPageState extends State<CreateJobOfferPage> {
  final _formKey = GlobalKey<FormState>();
  final JobsService _jobsService = JobsService();
  final FirestoreService _firestoreService = FirestoreService();
  final AnalyticsService _analytics = AnalyticsService();

  bool _isLoading = false;
  String? _schoolName;

  // Contrôleurs
  final TextEditingController _posteController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _communeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _salaireController = TextEditingController();

  // Sélections multiples
  List<String> _selectedMatieres = [];
  List<String> _selectedNiveaux = [];
  List<String> _selectedExigences = [];
  String _selectedTypeContrat = 'CDI';

  // Listes de choix
  final List<String> _matieresDisponibles = [
    'Mathématiques',
    'Français',
    'Anglais',
    'Histoire-Géographie',
    'Sciences Physiques',
    'SVT',
    'EPS',
    'Arts Plastiques',
    'Musique',
    'Philosophie',
    'Espagnol',
    'Allemand',
    'Économie',
    'Informatique',
    'Autre (précisez dans description)',
  ];

  final List<String> _niveauxDisponibles = [
    // Maternelle
    'Maternel',
    // Primaire
    'CP1', 'CP2', 'CE1', 'CE2', 'CM1', 'CM2',
    // Collège
    '6ème', '5ème', '4ème', '3ème',
    // Lycée
    '2nde', '1ère', 'Terminale',
    // Cours particuliers
    'Répétiteur à Domicile',
  ];

  final List<String> _exigencesDisponibles = [
    'Licence',
    'Master',
    'Doctorat',
    'CAFOP',
    'Agrégation',
    '1-3 ans d\'expérience',
    '3-5 ans d\'expérience',
    '5+ ans d\'expérience',
  ];

  final List<String> _typesContrat = [
    'CDI',
    'CDD',
    'Vacataire',
    'Fonctionnaire',
    'Stage',
  ];

  @override
  void initState() {
    super.initState();
    _loadSchoolName();

    // Si édition, pré-remplir les champs
    if (widget.existingOffer != null) {
      _posteController.text = widget.existingOffer!.poste;
      _villeController.text = widget.existingOffer!.ville;
      _communeController.text = widget.existingOffer!.commune;
      _descriptionController.text = widget.existingOffer!.description;
      _salaireController.text = widget.existingOffer!.salaire ?? '';
      _selectedMatieres = List.from(widget.existingOffer!.matieres);
      _selectedNiveaux = List.from(widget.existingOffer!.niveaux);
      _selectedExigences = List.from(widget.existingOffer!.exigences);
      _selectedTypeContrat = widget.existingOffer!.typeContrat;
    }
  }

  Future<void> _loadSchoolName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _firestoreService.getUser(user.uid);
      if (userData != null && mounted) {
        setState(() {
          _schoolName = userData.nom;
        });
      }
    }
  }

  @override
  void dispose() {
    _posteController.dispose();
    _villeController.dispose();
    _communeController.dispose();
    _descriptionController.dispose();
    _salaireController.dispose();
    super.dispose();
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMatieres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une matière'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedNiveaux.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un niveau'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    setState(() => _isLoading = true);

    try {
      final offer = JobOfferModel(
        id: widget.existingOffer?.id ?? '',
        schoolId: user.uid,
        nomEtablissement: _schoolName ?? 'Établissement',
        poste: _posteController.text.trim(),
        matieres: _selectedMatieres,
        niveaux: _selectedNiveaux,
        typeContrat: _selectedTypeContrat,
        ville: _villeController.text.trim(),
        commune: _communeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? 'Aucune description'
            : _descriptionController.text.trim(),
        exigences: _selectedExigences,
        salaire: _salaireController.text.trim().isEmpty
            ? null
            : _salaireController.text.trim(),
        createdAt: widget.existingOffer?.createdAt ?? DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        status: 'open',
      );

      if (widget.existingOffer != null) {
        // Mise à jour
        await _jobsService.updateJobOffer(
          widget.existingOffer!.id,
          offer.toMap(),
        );

        if (mounted) {
          Navigator.pop(context, true); // true indique succès
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offre mise à jour avec succès'),
              backgroundColor: Color(0xFF009E60),
            ),
          );
        }
      } else {
        // Création d'une nouvelle offre
        await _jobsService.createJobOffer(offer);

        // 📊 Analytics: Track création offre d'emploi
        await _analytics.logCustomEvent(
          'create_job_offer',
          parameters: {
            'poste': offer.poste,
            'ville': offer.ville,
            'type_contrat': offer.typeContrat,
            'matieres_count': offer.matieres.length,
            'niveaux_count': offer.niveaux.length,
          },
        );

        // Consommer le quota après création réussie
        final subscriptionService = SubscriptionService();
        final quotaResult = await subscriptionService.consumeJobOfferQuota(
          user.uid,
        );

        if (mounted) {
          Navigator.pop(context, true); // true indique succès

          // Afficher le message approprié
          if (quotaResult.success) {
            String message = 'Offre créée avec succès';
            if (quotaResult.quotaRemaining >= 0 &&
                quotaResult.quotaRemaining < 10) {
              message +=
                  ' - Il vous reste ${quotaResult.quotaRemaining} offre${quotaResult.quotaRemaining > 1 ? "s" : ""} gratuite${quotaResult.quotaRemaining > 1 ? "s" : ""}';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: const Color(0xFF009E60),
                duration: const Duration(seconds: 4),
              ),
            );

            // Si quota épuisé, afficher le dialogue d'abonnement
            if (quotaResult.needsSubscription) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  SubscriptionRequiredDialog.show(context, 'school');
                }
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildChipSection(
    String title,
    List<String> options,
    List<String> selected,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    selected.add(option);
                  } else {
                    selected.remove(option);
                  }
                });
              },
              selectedColor: accentColor.withValues(alpha: 0.3),
              checkmarkColor: accentColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingOffer != null
              ? 'Modifier l\'offre'
              : 'Créer une offre',
        ),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Rappel sur la visibilité des contacts
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009E60).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF009E60).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFF009E60),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Visibilité de vos contacts',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF009E60),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Vos coordonnées (email et téléphones) peuvent être affichées dans vos offres d\'emploi pour faciliter le contact avec les candidats.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/edit-profile');
                                },
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.settings,
                                      size: 16,
                                      color: Color(0xFF009E60),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Gérer dans Paramètres > Modifier le profil',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF009E60),
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titre du poste
                  TextFormField(
                    controller: _posteController,
                    decoration: const InputDecoration(
                      labelText: 'Titre du poste',
                      hintText: 'Ex: Professeur de Mathématiques',
                      prefixIcon: Icon(Icons.work),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer le titre du poste';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type de contrat
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTypeContrat,
                    decoration: const InputDecoration(
                      labelText: 'Type de contrat',
                      prefixIcon: Icon(Icons.description),
                    ),
                    items: _typesContrat.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTypeContrat = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Matières
                  _buildChipSection(
                    'Matières concernées *',
                    _matieresDisponibles,
                    _selectedMatieres,
                    const Color(0xFFF77F00),
                  ),
                  const SizedBox(height: 24),

                  // Niveaux
                  _buildChipSection(
                    'Niveaux (classes) *',
                    _niveauxDisponibles,
                    _selectedNiveaux,
                    const Color(0xFF009E60),
                  ),
                  const SizedBox(height: 24),

                  // Localisation
                  ZoneSearchField(
                    labelText: 'Ville',
                    hintText: 'Ex: Abidjan',
                    icon: Icons.location_city,
                    initialValue: _villeController.text,
                    onZoneSelected: (zone) {
                      _villeController.text = zone;
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer la ville';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _communeController,
                    decoration: const InputDecoration(
                      labelText: 'Commune / Quartier',
                      hintText: 'Ex: Cocody',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Veuillez entrer la commune';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Exigences
                  const Text(
                    'Exigences',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _exigencesDisponibles.map((exigence) {
                      final isSelected = _selectedExigences.contains(exigence);
                      return FilterChip(
                        label: Text(exigence),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedExigences.add(exigence);
                            } else {
                              _selectedExigences.remove(exigence);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Salaire (optionnel)
                  TextFormField(
                    controller: _salaireController,
                    decoration: const InputDecoration(
                      labelText: 'Salaire (optionnel)',
                      hintText: 'Ex: 150 000 - 200 000 FCFA',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description du poste (optionnel)',
                      hintText: 'Décrivez les responsabilités, avantages, etc.',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 32),

                  // Bouton de soumission
                  ElevatedButton.icon(
                    onPressed: _saveOffer,
                    icon: const Icon(Icons.check),
                    label: Text(
                      widget.existingOffer != null
                          ? 'Mettre à jour l\'offre'
                          : 'Publier l\'offre',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
