import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_offer_model.dart';
import '../models/user_model.dart';
import '../services/jobs_service.dart';

/// Page pour créer ou modifier une offre d'emploi
class CreateJobOfferPage extends StatefulWidget {
  final JobOfferModel? existingOffer;

  const CreateJobOfferPage({super.key, this.existingOffer});

  @override
  State<CreateJobOfferPage> createState() => _CreateJobOfferPageState();
}

class _CreateJobOfferPageState extends State<CreateJobOfferPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _jobsService = JobsService();

  // Contrôleurs
  final _posteController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Matières
  final List<TextEditingController> _matiereControllers = [TextEditingController()];

  // Niveaux sélectionnés
  final List<String> _niveauxSelectionnes = [];

  // Type de contrat
  String _typeContrat = 'CDI';

  // Durée de publication (en jours)
  int _dureePublication = 30;

  // Liste des niveaux disponibles
  final List<String> _niveauxDisponibles = [
    '6ème', '5ème', '4ème', '3ème',
    '2nde', '1ère', 'Terminale',
    'Primaire', 'Maternelle',
  ];

  // Informations de l'établissement (chargées depuis Firestore)
  UserModel? _schoolInfo;

  @override
  void initState() {
    super.initState();
    _loadSchoolInfo();
    _initializeWithExistingOffer();
  }

  /// Initialiser les champs avec une offre existante (pour l'édition)
  void _initializeWithExistingOffer() {
    final offer = widget.existingOffer;
    if (offer == null) return;

    _posteController.text = offer.poste;
    _descriptionController.text = offer.description != 'Aucune description'
        ? offer.description
        : '';
    _typeContrat = offer.typeContrat;
    _niveauxSelectionnes.addAll(offer.niveaux);

    // Initialiser les matières
    _matiereControllers.clear();
    for (var matiere in offer.matieres) {
      _matiereControllers.add(TextEditingController(text: matiere));
    }
    if (_matiereControllers.isEmpty) {
      _matiereControllers.add(TextEditingController());
    }

    // Calculer la durée de publication restante
    if (offer.expiresAt != null) {
      final daysRemaining = offer.expiresAt!.difference(DateTime.now()).inDays;
      if (daysRemaining > 0 && daysRemaining <= 90) {
        _dureePublication = daysRemaining;
      }
    }
  }

  @override
  void dispose() {
    _posteController.dispose();
    _descriptionController.dispose();
    for (var controller in _matiereControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Charger les informations de l'établissement
  Future<void> _loadSchoolInfo() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _schoolInfo = UserModel.fromFirestore(doc);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addMatiereField() {
    setState(() {
      _matiereControllers.add(TextEditingController());
    });
  }

  void _removeMatiereField(int index) {
    if (_matiereControllers.length > 1) {
      setState(() {
        _matiereControllers[index].dispose();
        _matiereControllers.removeAt(index);
      });
    }
  }

  Future<void> _handleCreateOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_niveauxSelectionnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un niveau'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_schoolInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: informations de l\'établissement non chargées'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Collecter les matières
      List<String> matieres = _matiereControllers
          .map((c) => c.text.trim())
          .where((m) => m.isNotEmpty)
          .toList();

      if (matieres.isEmpty) {
        throw Exception('Veuillez ajouter au moins une matière');
      }

      final isEditing = widget.existingOffer != null;

      if (isEditing) {
        // Mode édition : mettre à jour l'offre existante
        final updatedData = {
          'poste': _posteController.text.trim(),
          'matieres': matieres,
          'niveaux': _niveauxSelectionnes,
          'typeContrat': _typeContrat,
          'description': _descriptionController.text.trim().isEmpty
              ? 'Aucune description'
              : _descriptionController.text.trim(),
          'expiresAt': DateTime.now().add(Duration(days: _dureePublication)),
        };

        await _jobsService.updateJobOffer(widget.existingOffer!.id, updatedData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offre modifiée avec succès!'),
              backgroundColor: Color(0xFF009E60),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Mode création : créer une nouvelle offre
        final offer = JobOfferModel(
          id: '', // Sera défini par Firestore
          schoolId: userId,
          nomEtablissement: _schoolInfo!.nom,
          ville: _extractVille(_schoolInfo!.zoneActuelle),
          commune: _extractCommune(_schoolInfo!.zoneActuelle),
          poste: _posteController.text.trim(),
          matieres: matieres,
          niveaux: _niveauxSelectionnes,
          typeContrat: _typeContrat,
          description: _descriptionController.text.trim().isEmpty
              ? 'Aucune description'
              : _descriptionController.text.trim(),
          exigences: [], // Pourra être ajouté dans une version future
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(days: _dureePublication)),
          status: 'open',
        );

        await _jobsService.createJobOffer(offer);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offre publiée avec succès!'),
              backgroundColor: Color(0xFF009E60),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Extraire la ville depuis zoneActuelle (format: "Commune, Ville")
  String _extractVille(String zoneActuelle) {
    final parts = zoneActuelle.split(',');
    return parts.length > 1 ? parts[1].trim() : zoneActuelle;
  }

  /// Extraire la commune depuis zoneActuelle (format: "Commune, Ville")
  String _extractCommune(String zoneActuelle) {
    final parts = zoneActuelle.split(',');
    return parts.isNotEmpty ? parts[0].trim() : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingOffer != null
            ? 'Modifier l\'offre'
            : 'Créer une offre d\'emploi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icône
              Icon(
                Icons.work,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                widget.existingOffer != null
                    ? 'Modifiez votre offre d\'emploi'
                    : 'Publiez votre offre d\'emploi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.existingOffer != null
                    ? 'Mettez à jour les informations de votre offre'
                    : 'Recrutez les meilleurs enseignants pour votre établissement',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Poste
              TextFormField(
                controller: _posteController,
                decoration: const InputDecoration(
                  labelText: 'Intitulé du poste *',
                  prefixIcon: Icon(Icons.work_outline),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Professeur de Mathématiques',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir l\'intitulé du poste';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Matières
              const Text(
                'Matières enseignées *',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ..._matiereControllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'Matière ${index + 1}',
                            prefixIcon: const Icon(Icons.book),
                            border: const OutlineInputBorder(),
                            hintText: 'Ex: Mathématiques',
                          ),
                          validator: (value) {
                            if (index == 0 &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Au moins une matière requise';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_matiereControllers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeMatiereField(index),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: _addMatiereField,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une matière'),
              ),
              const SizedBox(height: 16),

              // Niveaux d'enseignement
              const Text(
                'Niveaux d\'enseignement *',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _niveauxDisponibles.map((niveau) {
                  final isSelected = _niveauxSelectionnes.contains(niveau);
                  return FilterChip(
                    label: Text(niveau),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _niveauxSelectionnes.add(niveau);
                        } else {
                          _niveauxSelectionnes.remove(niveau);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Type de contrat
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Type de contrat *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                  DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                  DropdownMenuItem(value: 'Vacation', child: Text('Vacation')),
                  DropdownMenuItem(value: 'Stage', child: Text('Stage')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _typeContrat = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Durée de publication
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Durée de publication: $_dureePublication jours',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                  Slider(
                    value: _dureePublication.toDouble(),
                    min: 7,
                    max: 90,
                    divisions: 11,
                    label: '$_dureePublication jours',
                    onChanged: (value) {
                      setState(() {
                        _dureePublication = value.toInt();
                      });
                    },
                  ),
                  Text(
                    'L\'offre expirera le ${DateTime.now().add(Duration(days: _dureePublication)).day}/${DateTime.now().add(Duration(days: _dureePublication)).month}/${DateTime.now().add(Duration(days: _dureePublication)).year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description du poste (optionnel)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  hintText: 'Décrivez les missions, compétences requises...',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),

              // Informations de l'établissement (lecture seule)
              if (_schoolInfo != null) ...[
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Informations établissement',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text('Nom: ${_schoolInfo!.nom}'),
                        Text('Localisation: ${_schoolInfo!.zoneActuelle}'),
                        if (_schoolInfo!.telephones.isNotEmpty)
                          Text('Contact: ${_schoolInfo!.telephones.first}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Bouton de publication
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreateOffer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.existingOffer != null
                            ? 'Enregistrer les modifications'
                            : 'Publier l\'offre',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
