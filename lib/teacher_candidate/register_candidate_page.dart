import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/jobs_service.dart';
import 'package:myapp/models/job_application_model.dart';
import 'package:myapp/teacher_candidate/candidate_home_screen.dart';

/// Formulaire d'inscription personnalisé pour les candidats enseignants
class RegisterCandidatePage extends StatefulWidget {
  const RegisterCandidatePage({super.key});

  @override
  State<RegisterCandidatePage> createState() => _RegisterCandidatePageState();
}

class _RegisterCandidatePageState extends State<RegisterCandidatePage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _jobsService = JobsService();

  // Contrôleurs de base
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Contrôleurs pour téléphones (max 3)
  final List<TextEditingController> _phoneControllers = [TextEditingController()];

  // Contrôleurs pour matières
  final List<TextEditingController> _matiereControllers = [TextEditingController()];

  // Contrôleurs pour zones souhaitées
  final List<TextEditingController> _zoneControllers = [TextEditingController()];

  // Niveaux sélectionnés
  final List<String> _niveauxSelectionnes = [];

  // Diplômes
  final List<TextEditingController> _diplomeControllers = [TextEditingController()];

  // Expérience et disponibilité
  final _experienceController = TextEditingController();
  String _disponibilite = 'Immédiate';

  // Liste des niveaux disponibles
  final List<String> _niveauxDisponibles = [
    '6ème', '5ème', '4ème', '3ème',
    '2nde', '1ère', 'Terminale',
    'Primaire', 'Maternelle',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _experienceController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    for (var controller in _matiereControllers) {
      controller.dispose();
    }
    for (var controller in _zoneControllers) {
      controller.dispose();
    }
    for (var controller in _diplomeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPhoneField() {
    if (_phoneControllers.length < 3) {
      setState(() {
        _phoneControllers.add(TextEditingController());
      });
    }
  }

  void _removePhoneField(int index) {
    if (_phoneControllers.length > 1) {
      setState(() {
        _phoneControllers[index].dispose();
        _phoneControllers.removeAt(index);
      });
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

  void _addZoneField() {
    setState(() {
      _zoneControllers.add(TextEditingController());
    });
  }

  void _removeZoneField(int index) {
    if (_zoneControllers.length > 1) {
      setState(() {
        _zoneControllers[index].dispose();
        _zoneControllers.removeAt(index);
      });
    }
  }

  void _addDiplomeField() {
    setState(() {
      _diplomeControllers.add(TextEditingController());
    });
  }

  void _removeDiplomeField(int index) {
    if (_diplomeControllers.length > 1) {
      setState(() {
        _diplomeControllers[index].dispose();
        _diplomeControllers.removeAt(index);
      });
    }
  }

  Future<void> _handleRegister() async {
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
      _isLoading = true;
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

      // Créer le compte (accountType: teacher_candidate)
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        accountType: 'teacher_candidate', // Type candidat
        matricule: '', // Pas de matricule pour les candidats
        nom: _nomController.text.trim(),
        telephones: telephones,
        fonction: matieres.join(', '), // Utiliser matieres comme fonction
        zoneActuelle: '', // Pas de zone actuelle
        dren: null,
        infosZoneActuelle: _experienceController.text.trim(), // Utiliser pour stocker l'expérience temporairement
        zonesSouhaitees: zones,
      );

      // Créer le document job_applications avec toutes les infos
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final application = JobApplicationModel(
          id: '', // Sera défini par Firestore
          userId: userId,
          nom: _nomController.text.trim(),
          email: _emailController.text.trim(),
          telephones: telephones,
          matieres: matieres,
          niveaux: _niveauxSelectionnes,
          diplomes: diplomes,
          experience: _experienceController.text.trim(),
          zonesSouhaitees: zones,
          disponibilite: _disponibilite,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: 'active',
        );

        await _jobsService.createJobApplication(application);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie! Bienvenue sur CHIASMA.'),
            backgroundColor: Color(0xFF009E60),
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CandidateHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription Candidat'),
        backgroundColor: const Color(0xFF009E60),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // En-tête
            const Icon(
              Icons.person_add,
              size: 64,
              color: Color(0xFF009E60),
            ),
            const SizedBox(height: 16),
            const Text(
              'Créez votre profil candidat',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Remplissez les informations pour déposer votre candidature',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // Nom complet
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre email';
                }
                if (!value.contains('@')) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Mot de passe
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un mot de passe';
                }
                if (value.length < 6) {
                  return 'Minimum 6 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Section Téléphones
            Text(
              'Numéros de téléphone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_phoneControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Téléphone ${index + 1}',
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (value) {
                          if (index == 0 && (value == null || value.isEmpty)) {
                            return 'Au moins un numéro requis';
                          }
                          if (value != null && value.isNotEmpty && value.length != 10) {
                            return '10 chiffres requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_phoneControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removePhoneField(index),
                      ),
                  ],
                ),
              );
            }),
            if (_phoneControllers.length < 3)
              TextButton.icon(
                onPressed: _addPhoneField,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un numéro'),
              ),
            const SizedBox(height: 24),

            // Section Matières
            Text(
              'Matière(s) enseignée(s)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_matiereControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _matiereControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Matière ${index + 1}',
                          hintText: 'Ex: Mathématiques',
                          prefixIcon: const Icon(Icons.school),
                        ),
                        validator: (value) {
                          if (index == 0 && (value == null || value.isEmpty)) {
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
            const SizedBox(height: 24),

            // Section Niveaux
            Text(
              'Niveau(x) que vous pouvez enseigner',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
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
                  selectedColor: const Color(0xFF009E60).withValues(alpha: 0.3),
                  checkmarkColor: const Color(0xFF009E60),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Section Diplômes
            Text(
              'Diplômes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_diplomeControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _diplomeControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Diplôme ${index + 1}',
                          hintText: 'Ex: CAFOP, Licence',
                          prefixIcon: const Icon(Icons.workspace_premium),
                        ),
                        validator: (value) {
                          if (index == 0 && (value == null || value.isEmpty)) {
                            return 'Au moins un diplôme requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_diplomeControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeDiplomeField(index),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addDiplomeField,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un diplôme'),
            ),
            const SizedBox(height: 24),

            // Expérience
            TextFormField(
              controller: _experienceController,
              decoration: const InputDecoration(
                labelText: 'Expérience',
                hintText: 'Ex: 5 ans, Débutant',
                prefixIcon: Icon(Icons.work_history),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez indiquer votre expérience';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Section Zones souhaitées
            Text(
              'Zones souhaitées',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_zoneControllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _zoneControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Zone ${index + 1}',
                          hintText: 'Ex: Abidjan, Bouaké',
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (index == 0 && (value == null || value.isEmpty)) {
                            return 'Au moins une zone requise';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_zoneControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeZoneField(index),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addZoneField,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une zone'),
            ),
            const SizedBox(height: 24),

            // Disponibilité
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Disponibilité',
                prefixIcon: Icon(Icons.schedule),
              ),
              items: const [
                DropdownMenuItem(value: 'Immédiate', child: Text('Immédiate')),
                DropdownMenuItem(value: 'Dans 1 mois', child: Text('Dans 1 mois')),
                DropdownMenuItem(value: 'Dans 2 mois', child: Text('Dans 2 mois')),
                DropdownMenuItem(value: 'Dans 3 mois', child: Text('Dans 3 mois')),
                DropdownMenuItem(value: 'À discuter', child: Text('À discuter')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _disponibilite = value;
                  });
                }
              },
            ),
            const SizedBox(height: 40),

            // Bouton d'inscription
            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009E60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Créer mon profil candidat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
