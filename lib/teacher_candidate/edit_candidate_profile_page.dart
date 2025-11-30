import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/jobs_service.dart';
import '../utils/contact_validator.dart';

/// Page pour modifier le profil d'un candidat enseignant
class EditCandidateProfilePage extends StatefulWidget {
  const EditCandidateProfilePage({super.key});

  @override
  State<EditCandidateProfilePage> createState() =>
      _EditCandidateProfilePageState();
}

class _EditCandidateProfilePageState extends State<EditCandidateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _jobsService = JobsService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  bool _isLoading = true;
  bool _isSaving = false;

  // Contrôleurs
  final _nomController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [];
  final List<TextEditingController> _matiereControllers = [];
  final List<TextEditingController> _diplomeControllers = [];
  final List<TextEditingController> _zoneControllers = [];
  final _experienceController = TextEditingController();

  // État
  List<String> _niveauxSelectionnes = [];
  String _disponibilite = 'Immédiate';
  String? _applicationId;

  final List<String> _niveauxDisponibles = [
    '6ème',
    '5ème',
    '4ème',
    '3ème',
    '2nde',
    '1ère',
    'Terminale',
    'Primaire',
    'Maternelle',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _experienceController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    for (var controller in _matiereControllers) {
      controller.dispose();
    }
    for (var controller in _diplomeControllers) {
      controller.dispose();
    }
    for (var controller in _zoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_userId == null) return;

    try {
      final application = await _jobsService.getJobApplicationByUserId(_userId);

      if (application != null && mounted) {
        setState(() {
          _applicationId = application.id;
          _nomController.text = application.nom;
          _experienceController.text = application.experience;
          _niveauxSelectionnes = List.from(application.niveaux);
          _disponibilite = application.disponibilite;

          // Téléphones
          for (var phone in application.telephones) {
            _phoneControllers.add(TextEditingController(text: phone));
          }
          if (_phoneControllers.isEmpty) {
            _phoneControllers.add(TextEditingController());
          }

          // Matières
          for (var matiere in application.matieres) {
            _matiereControllers.add(TextEditingController(text: matiere));
          }
          if (_matiereControllers.isEmpty) {
            _matiereControllers.add(TextEditingController());
          }

          // Diplômes
          for (var diplome in application.diplomes) {
            _diplomeControllers.add(TextEditingController(text: diplome));
          }
          if (_diplomeControllers.isEmpty) {
            _diplomeControllers.add(TextEditingController());
          }

          // Zones
          for (var zone in application.zonesSouhaitees) {
            _zoneControllers.add(TextEditingController(text: zone));
          }
          if (_zoneControllers.isEmpty) {
            _zoneControllers.add(TextEditingController());
          }

          _isLoading = false;
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

  Future<void> _saveProfile() async {
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

    setState(() {
      _isSaving = true;
    });

    try {
      // Collecter les données
      List<String> telephones = _phoneControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      List<String> matieres = _matiereControllers
          .map((c) => c.text.trim())
          .where((m) => m.isNotEmpty)
          .toList();

      List<String> zones = _zoneControllers
          .map((c) => c.text.trim())
          .where((z) => z.isNotEmpty)
          .toList();

      List<String> diplomes = _diplomeControllers
          .map((c) => c.text.trim())
          .where((d) => d.isNotEmpty)
          .toList();

      if (_applicationId != null) {
        // Mettre à jour job_application
        await _jobsService.updateJobApplication(_applicationId!, {
          'nom': _nomController.text.trim(),
          'telephones': telephones,
          'matieres': matieres,
          'niveaux': _niveauxSelectionnes,
          'diplomes': diplomes,
          'experience': _experienceController.text.trim(),
          'zonesSouhaitees': zones,
          'disponibilite': _disponibilite,
        });

        // Mettre à jour aussi le document user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .update({
              'nom': _nomController.text.trim(),
              'telephones': telephones,
              'fonction': matieres.join(', '),
              'zonesSouhaitees': zones,
              'updatedAt': Timestamp.now(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès!'),
              backgroundColor: Color(0xFF009E60),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addField(List<TextEditingController> controllers, {int? maxCount}) {
    if (maxCount == null || controllers.length < maxCount) {
      setState(() {
        controllers.add(TextEditingController());
      });
    }
  }

  void _removeField(List<TextEditingController> controllers, int index) {
    if (controllers.length > 1) {
      setState(() {
        controllers[index].dispose();
        controllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier mon profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nom
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Téléphones
              const Text(
                'Numéros de téléphone *',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ..._phoneControllers.asMap().entries.map((entry) {
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
                            labelText: 'Téléphone ${index + 1}',
                            prefixIcon: const Icon(Icons.phone),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (index == 0 &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Au moins un numéro requis';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_phoneControllers.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _removeField(_phoneControllers, index),
                        ),
                    ],
                  ),
                );
              }),
              if (_phoneControllers.length < 3)
                TextButton.icon(
                  onPressed: () => _addField(_phoneControllers, maxCount: 3),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un numéro'),
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
                          ),
                          validator: (value) {
                            // Vérifier les informations de contact
                            if (value != null &&
                                ContactValidator.containsContactInfo(value)) {
                              return 'Pas de contact dans ce champ';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_matiereControllers.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _removeField(_matiereControllers, index),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => _addField(_matiereControllers),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une matière'),
              ),
              const SizedBox(height: 16),

              // Niveaux
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

              // Diplômes
              const Text(
                'Diplômes',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ..._diplomeControllers.asMap().entries.map((entry) {
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
                            labelText: 'Diplôme ${index + 1}',
                            prefixIcon: const Icon(Icons.school),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            // Vérifier les informations de contact
                            if (value != null &&
                                ContactValidator.containsContactInfo(value)) {
                              return 'Pas de contact dans ce champ';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_diplomeControllers.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _removeField(_diplomeControllers, index),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => _addField(_diplomeControllers),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un diplôme'),
              ),
              const SizedBox(height: 16),

              // Expérience
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Expérience professionnelle *',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 5 ans d\'enseignement',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez décrire votre expérience';
                  }
                  // Vérifier les informations de contact
                  if (ContactValidator.containsContactInfo(value)) {
                    return ContactValidator.getErrorMessage();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Zones souhaitées
              const Text(
                'Zones souhaitées',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ..._zoneControllers.asMap().entries.map((entry) {
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
                            labelText: 'Zone ${index + 1}',
                            prefixIcon: const Icon(Icons.location_on),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      if (_zoneControllers.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _removeField(_zoneControllers, index),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => _addField(_zoneControllers),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une zone'),
              ),
              const SizedBox(height: 16),

              // Disponibilité
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Disponibilité',
                  prefixIcon: Icon(Icons.schedule),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Immédiate',
                    child: Text('Immédiate'),
                  ),
                  DropdownMenuItem(
                    value: 'Dans 1 mois',
                    child: Text('Dans 1 mois'),
                  ),
                  DropdownMenuItem(
                    value: 'Dans 2 mois',
                    child: Text('Dans 2 mois'),
                  ),
                  DropdownMenuItem(
                    value: 'Dans 3 mois',
                    child: Text('Dans 3 mois'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _disponibilite = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Bouton enregistrer
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
