import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Page pour modifier le profil de l'établissement
class EditSchoolProfilePage extends StatefulWidget {
  const EditSchoolProfilePage({super.key});

  @override
  State<EditSchoolProfilePage> createState() => _EditSchoolProfilePageState();
}

class _EditSchoolProfilePageState extends State<EditSchoolProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  UserModel? _schoolInfo;

  // Contrôleurs
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _zoneActuelleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchoolInfo();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _zoneActuelleController.dispose();
    super.dispose();
  }

  /// Charger les informations de l'établissement
  Future<void> _loadSchoolInfo() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final schoolInfo = UserModel.fromFirestore(doc);
        setState(() {
          _schoolInfo = schoolInfo;
          _nomController.text = schoolInfo.nom;
          _emailController.text = schoolInfo.email;
          _telephoneController.text = schoolInfo.telephones.isNotEmpty
              ? schoolInfo.telephones.first
              : '';
          _zoneActuelleController.text = schoolInfo.zoneActuelle;
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Sauvegarder les modifications
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      final updateData = {
        'nom': _nomController.text.trim(),
        'zoneActuelle': _zoneActuelleController.text.trim(),
        'telephones': _telephoneController.text.trim().isNotEmpty
            ? [_telephoneController.text.trim()]
            : [],
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès!'),
            backgroundColor: Color(0xFF009E60),
          ),
        );
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        centerTitle: true,
      ),
      body: _isLoading && _schoolInfo == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icône
                    Icon(
                      Icons.business,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Informations de l\'établissement',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mettez à jour les informations de votre établissement',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Nom de l'établissement
                    TextFormField(
                      controller: _nomController,
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

                    // Email (lecture seule)
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                        helperText: 'L\'email ne peut pas être modifié',
                      ),
                      enabled: false,
                    ),
                    const SizedBox(height: 16),

                    // Téléphone
                    TextFormField(
                      controller: _telephoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                        hintText: 'Ex: +225 07 XX XX XX XX',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Zone actuelle (Localisation)
                    TextFormField(
                      controller: _zoneActuelleController,
                      decoration: const InputDecoration(
                        labelText: 'Localisation *',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Cocody, Abidjan',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir la localisation';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Informations du compte
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
                                    'Informations du compte',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Text('Type de compte: ${_schoolInfo!.accountType}'),
                              Text('Matricule: ${_schoolInfo!.matricule}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Bouton de sauvegarde
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
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
