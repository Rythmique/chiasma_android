import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/widgets/zone_search_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  bool _isSaving = false;
  UserModel? _currentUserData;

  // Controllers pour les champs de texte
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _fonctionController = TextEditingController();
  final TextEditingController _infosZoneController = TextEditingController();

  // Liste des contrôleurs pour les téléphones (max 3)
  final List<TextEditingController> _telephoneControllers = [];

  String? _drenActuel;
  String _zoneActuelle = '';
  List<String> _zonesSouhaitees = [];

  final List<String> _drenList = [
    'Abengourou',
    'Abidjan 1',
    'Abidjan 2',
    'Abidjan 3',
    'Abidjan 4',
    'Adzopé',
    'Agnibilékrou',
    'Bangolo',
    'Béoumi',
    'Bettié',
    'Biankouma',
    'Bingerville',
    'Bongouanou',
    'Bondoukou',
    'Bouaflé',
    'Bouaké',
    'Bouna',
    'Boundiali',
    'Dabou',
    'Daloa',
    'Danané',
    'Daoukro',
    'Dimbokro',
    'Divo',
    'Ferkessédougou',
    'Gagnoa',
    'Grand-Bassam',
    'Jacqueville',
    'Katiola',
    'Korhogo',
    'Lakota',
    'Madinani',
    'Man',
    'Minignan',
    'Odienné',
    'San-Pedro',
    'Sassandra',
    'Séguéla',
    'Soubré',
    'Tanda',
    'Tiébissou',
    'Toumodi',
    'Vavoua',
    'Yamoussoukro',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final userData = await _firestoreService.getUser(currentUser.uid);
        if (userData != null && mounted) {
          setState(() {
            _currentUserData = userData;
            _nomController.text = userData.nom;
            _fonctionController.text = userData.fonction;
            _infosZoneController.text = userData.infosZoneActuelle;
            _drenActuel = userData.dren;
            _zoneActuelle = userData.zoneActuelle;
            _zonesSouhaitees = List.from(userData.zonesSouhaitees);

            // Charger les téléphones
            _telephoneControllers.clear();
            for (var phone in userData.telephones) {
              _telephoneControllers.add(TextEditingController(text: phone));
            }
            // S'assurer d'avoir au moins un champ téléphone
            if (_telephoneControllers.isEmpty) {
              _telephoneControllers.add(TextEditingController());
            }

            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur de chargement: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _fonctionController.dispose();
    _infosZoneController.dispose();
    for (var controller in _telephoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modifier le profil'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF77F00),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo de profil
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.2),
                    child: Text(
                      _getInitials(_currentUserData?.nom ?? ''),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF77F00),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF77F00),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Modification de la photo - Fonctionnalité à venir'),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier la photo'),
              ),
            ),
            const SizedBox(height: 24),

            // Section Informations personnelles
            _buildSectionTitle('Informations personnelles'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nomController,
              label: 'Nom complet',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _fonctionController,
              label: 'Fonction',
              icon: Icons.work,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre fonction';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email (lecture seule)
            TextFormField(
              initialValue: _currentUserData?.email ?? '',
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Email (non modifiable)',
                prefixIcon: const Icon(Icons.email, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),

            // Matricule (lecture seule) - Visible uniquement pour les admins
            if (_currentUserData != null && _currentUserData!.isAdmin) ...[
              TextFormField(
                initialValue: _currentUserData?.matricule ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Matricule (non modifiable)',
                  prefixIcon: const Icon(Icons.badge, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Téléphones
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Téléphones',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                if (_telephoneControllers.length < 3)
                  TextButton.icon(
                    onPressed: _addPhoneField,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF009E60),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ..._telephoneControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Téléphone ${index + 1}',
                          prefixIcon: const Icon(Icons.phone, color: Color(0xFFF77F00)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFF77F00), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (index == 0 && (value == null || value.isEmpty)) {
                            return 'Au moins un téléphone requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_telephoneControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removePhoneField(index),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Section Informations professionnelles
            _buildSectionTitle('Informations professionnelles'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _drenActuel != null && _drenList.contains(_drenActuel) ? _drenActuel : null,
              decoration: InputDecoration(
                labelText: 'DREN (optionnel)',
                prefixIcon: const Icon(Icons.apartment, color: Color(0xFFF77F00)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF77F00), width: 2),
                ),
              ),
              items: _drenList.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _drenActuel = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Section Zones de permutation
            _buildSectionTitle('Zones de permutation'),
            const SizedBox(height: 12),
            ZoneSearchField(
              initialValue: _zoneActuelle,
              labelText: 'Zone actuelle',
              hintText: 'Recherchez votre zone...',
              icon: Icons.location_on,
              onZoneSelected: (zone) {
                setState(() {
                  _zoneActuelle = zone;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez sélectionner une zone actuelle';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Informations sur la zone actuelle
            TextFormField(
              controller: _infosZoneController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Informations sur votre zone actuelle',
                hintText: 'Décrivez votre situation actuelle...',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.description),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF77F00), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez décrire votre situation';
                }
                if (value.length < 20) {
                  return 'Minimum 20 caractères requis (${value.length}/20)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Zones souhaitées (multiples)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zones souhaitées',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_zonesSouhaitees.length}/5 zones',
                      style: TextStyle(
                        fontSize: 12,
                        color: _zonesSouhaitees.length >= 5
                            ? Colors.red
                            : const Color(0xFF009E60),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _zonesSouhaitees.length >= 5 ? null : _addZoneSouhaitee,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF009E60),
                    disabledForegroundColor: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Liste des zones souhaitées
            if (_zonesSouhaitees.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aucune zone souhaitée. Ajoutez au moins une zone (maximum 5).',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._zonesSouhaitees.asMap().entries.map((entry) {
                final index = entry.key;
                final zone = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009E60).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF009E60).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF009E60).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_searching,
                          color: Color(0xFF009E60),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          zone,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: const Color(0xFFF77F00),
                        onPressed: () => _editZoneSouhaitee(index),
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        color: Colors.red,
                        onPressed: () => _removeZoneSouhaitee(index),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF77F00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final words = name.split(' ');
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFFF77F00),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFF77F00)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF77F00), width: 2),
        ),
      ),
      validator: validator,
    );
  }


  void _addPhoneField() {
    if (_telephoneControllers.length < 3) {
      setState(() {
        _telephoneControllers.add(TextEditingController());
      });
    }
  }

  void _removePhoneField(int index) {
    if (_telephoneControllers.length > 1) {
      setState(() {
        _telephoneControllers[index].dispose();
        _telephoneControllers.removeAt(index);
      });
    }
  }

  void _addZoneSouhaitee() {
    if (_zonesSouhaitees.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez atteint la limite de 5 zones souhaitées'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String selectedZone = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_location, color: Color(0xFF009E60)),
                  SizedBox(width: 12),
                  Text('Ajouter une zone'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recherchez et sélectionnez une zone souhaitée',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ZoneSearchField(
                      labelText: 'Zone souhaitée',
                      hintText: 'Tapez pour rechercher...',
                      icon: Icons.location_searching,
                      onZoneSelected: (zone) {
                        setDialogState(() {
                          selectedZone = zone;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: selectedZone.isEmpty ||
                             selectedZone == _zoneActuelle ||
                             _zonesSouhaitees.contains(selectedZone)
                      ? null
                      : () {
                          setState(() {
                            _zonesSouhaitees.add(selectedZone);
                          });
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009E60),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editZoneSouhaitee(int index) {
    final currentZone = _zonesSouhaitees[index];
    String selectedZone = currentZone;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.edit_location, color: Color(0xFFF77F00)),
                  SizedBox(width: 12),
                  Text('Modifier la zone'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zone actuelle: $currentZone',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ZoneSearchField(
                      initialValue: currentZone,
                      labelText: 'Nouvelle zone',
                      hintText: 'Recherchez une nouvelle zone...',
                      icon: Icons.location_searching,
                      onZoneSelected: (zone) {
                        setDialogState(() {
                          selectedZone = zone;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _zonesSouhaitees[index] = selectedZone;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF77F00),
                  ),
                  child: const Text('Modifier'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeZoneSouhaitee(int index) {
    final zoneName = _zonesSouhaitees[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Supprimer la zone'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer "$zoneName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _zonesSouhaitees.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    dev.log('_saveProfile appelé', name: 'EditProfilePage');

    // Vérifier la validation du formulaire
    if (!_formKey.currentState!.validate()) {
      dev.log('Validation du formulaire échouée', name: 'EditProfilePage');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs dans le formulaire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    dev.log('Validation du formulaire réussie', name: 'EditProfilePage');

    // Vérifier les zones souhaitées
    if (_zonesSouhaitees.isEmpty) {
      dev.log('Aucune zone souhaitée', name: 'EditProfilePage');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins une zone souhaitée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    dev.log('Zones souhaitées: $_zonesSouhaitees', name: 'EditProfilePage');

    // Vérifier la zone actuelle
    if (_zoneActuelle.isEmpty) {
      dev.log('Zone actuelle vide', name: 'EditProfilePage');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une zone actuelle'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    dev.log('Zone actuelle: $_zoneActuelle', name: 'EditProfilePage');

    setState(() {
      _isSaving = true;
    });
    dev.log('Début de la sauvegarde', name: 'EditProfilePage');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        dev.log('Utilisateur connecté: ${currentUser.uid}', name: 'EditProfilePage');

        // Collecter les téléphones non vides
        List<String> telephones = _telephoneControllers
            .map((c) => c.text.trim())
            .where((phone) => phone.isNotEmpty)
            .toList();
        dev.log('Téléphones: $telephones', name: 'EditProfilePage');

        // Préparer les données à mettre à jour
        Map<String, dynamic> updateData = {
          'nom': _nomController.text.trim(),
          'fonction': _fonctionController.text.trim(),
          'telephones': telephones,
          'dren': _drenActuel,
          'zoneActuelle': _zoneActuelle,
          'infosZoneActuelle': _infosZoneController.text.trim(),
          'zonesSouhaitees': _zonesSouhaitees,
        };
        dev.log('Données à mettre à jour: $updateData', name: 'EditProfilePage');

        await _firestoreService.updateUser(currentUser.uid, updateData);
        dev.log('Sauvegarde réussie', name: 'EditProfilePage');

        if (mounted) {
          // Retourner true pour indiquer que le profil a été mis à jour
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès'),
              backgroundColor: Color(0xFF009E60),
            ),
          );
        }
      } else {
        dev.log('Aucun utilisateur connecté', name: 'EditProfilePage');
      }
    } catch (e) {
      dev.log('Erreur lors de la sauvegarde: $e', name: 'EditProfilePage', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        dev.log('Sauvegarde terminée', name: 'EditProfilePage');
      }
    }
  }
}
