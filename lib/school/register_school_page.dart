import 'package:flutter/material.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/school/school_home_screen.dart';

/// Formulaire d'inscription personnalisé pour les établissements
class RegisterSchoolPage extends StatefulWidget {
  const RegisterSchoolPage({super.key});

  @override
  State<RegisterSchoolPage> createState() => _RegisterSchoolPageState();
}

class _RegisterSchoolPageState extends State<RegisterSchoolPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Contrôleurs
  final _nomEtablissementController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _villeController = TextEditingController();
  final _communeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _nomContactController = TextEditingController();

  // Contrôleurs pour téléphones (max 3)
  final List<TextEditingController> _phoneControllers = [
    TextEditingController(),
  ];

  // Type d'établissement
  String _typeEtablissement = 'Privé';

  // Niveaux d'enseignement
  final List<String> _niveauxSelectionnes = [];

  // Liste des niveaux disponibles
  final List<String> _niveauxDisponibles = [
    'Maternelle',
    'Primaire',
    'Collège (6ème-3ème)',
    'Lycée (2nde-Terminale)',
    'Supérieur',
  ];

  @override
  void dispose() {
    _nomEtablissementController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _villeController.dispose();
    _communeController.dispose();
    _adresseController.dispose();
    _nomContactController.dispose();
    for (var controller in _phoneControllers) {
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

  Widget _buildPhoneField(int index, TextEditingController controller) {
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
                if (index == 0 && (value == null || value.trim().isEmpty)) {
                  return 'Au moins un numéro requis';
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
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_niveauxSelectionnes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez sélectionner au moins un niveau d\'enseignement',
          ),
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

      // Créer le compte (accountType: school)
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        accountType: 'school', // Type établissement
        matricule: '', // Pas de matricule pour les établissements
        nom: _nomEtablissementController.text.trim(),
        telephones: telephones,
        fonction: _typeEtablissement, // Utiliser pour stocker le type
        zoneActuelle:
            '${_communeController.text.trim()}, ${_villeController.text.trim()}',
        dren: null,
        infosZoneActuelle: _adresseController.text.trim(),
        zonesSouhaitees:
            _niveauxSelectionnes, // Utiliser pour stocker les niveaux
      );

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
          MaterialPageRoute(builder: (context) => const SchoolHomeScreen()),
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
        title: const Text('Inscription Établissement'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Icon(
                Icons.school,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Créer un compte établissement',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recrutez les meilleurs enseignants pour votre établissement',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Nom de l'établissement
              TextFormField(
                controller: _nomEtablissementController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'établissement *',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir le nom de l\'établissement';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type d'établissement
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Type d\'établissement *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Privé', child: Text('Privé')),
                  DropdownMenuItem(value: 'Public', child: Text('Public')),
                  DropdownMenuItem(
                    value: 'Confessionnel',
                    child: Text('Confessionnel'),
                  ),
                  DropdownMenuItem(
                    value: 'International',
                    child: Text('International'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _typeEtablissement = value;
                    });
                  }
                },
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

              // Ville
              TextFormField(
                controller: _villeController,
                decoration: const InputDecoration(
                  labelText: 'Ville *',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Abidjan',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir la ville';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Commune
              TextFormField(
                controller: _communeController,
                decoration: const InputDecoration(
                  labelText: 'Commune *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Cocody',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir la commune';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Adresse complète
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse complète *',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                  hintText: 'Quartier, rue, repères...',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir l\'adresse';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nom du contact
              TextFormField(
                controller: _nomContactController,
                decoration: const InputDecoration(
                  labelText: 'Nom du responsable RH/Contact *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir le nom du contact';
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
              ..._phoneControllers.asMap().entries.map(
                (entry) => _buildPhoneField(entry.key, entry.value),
              ),
              if (_phoneControllers.length < 3)
                TextButton.icon(
                  onPressed: _addPhoneField,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un numéro'),
                ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Adresse email *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir votre adresse email';
                  }
                  if (!value.contains('@')) {
                    return 'L\'adresse email n\'est pas valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mot de passe
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe *',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Bouton d'inscription
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
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
                    : const Text(
                        'Créer mon compte',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Lien vers connexion
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Vous avez déjà un compte?'),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
