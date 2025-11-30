import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/home_screen.dart';
import 'package:myapp/widgets/zone_search_field.dart';

class RegisterScreen extends StatefulWidget {
  final String accountType; // 'teacher_transfer', 'teacher_candidate', 'school'

  const RegisterScreen({
    super.key,
    this.accountType = 'teacher_transfer', // Par défaut pour compatibilité
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Contrôleurs pour les champs de base
  final _nomController = TextEditingController();
  final _matriculeController = TextEditingController();
  final _emailController = TextEditingController();
  final _fonctionController = TextEditingController();
  final _drenController = TextEditingController();
  final _infosZoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Contrôleurs pour les numéros de téléphone (max 3)
  final List<TextEditingController> _phoneControllers = [
    TextEditingController(),
  ];

  // Zones (stockées comme String, pas TextEditingController)
  String _zoneActuelle = '';
  final List<String> _zonesSouhaitees = [];

  @override
  void dispose() {
    _nomController.dispose();
    _matriculeController.dispose();
    _emailController.dispose();
    _fonctionController.dispose();
    _drenController.dispose();
    _infosZoneController.dispose();
    _passwordController.dispose();
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

  void _addZoneSouhaitee() {
    if (_zonesSouhaitees.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez atteint la limite de 5 zones souhaitées'),
          backgroundColor: Colors.orange,
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
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                  onPressed:
                      selectedZone.isEmpty ||
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

  void _removeZoneSouhaitee(int index) {
    setState(() {
      _zonesSouhaitees.removeAt(index);
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Collecter les téléphones (uniquement les champs remplis)
      List<String> telephones = _phoneControllers
          .map((controller) => controller.text.trim())
          .where((phone) => phone.isNotEmpty)
          .toList();

      // Vérifier qu'au moins une zone souhaitée a été ajoutée
      if (_zonesSouhaitees.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez ajouter au moins une zone souhaitée'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Créer le compte
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        accountType: widget.accountType, // Passer le type de compte
        matricule: _matriculeController.text.trim(),
        nom: _nomController.text.trim(),
        telephones: telephones,
        fonction: _fonctionController.text.trim(),
        zoneActuelle: _zoneActuelle,
        dren: _drenController.text.trim().isEmpty
            ? null
            : _drenController.text.trim(),
        infosZoneActuelle: _infosZoneController.text.trim(),
        zonesSouhaitees: _zonesSouhaitees,
      );

      // Connexion automatique et redirection vers HomeScreen
      if (mounted) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie! Bienvenue sur CHIASMA.'),
            backgroundColor: Color(0xFF009E60),
            duration: Duration(seconds: 3),
          ),
        );

        // Rediriger vers l'écran d'accueil (l'utilisateur est déjà connecté)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Afficher l'erreur
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF77F00).withValues(alpha: 0.1),
              Colors.white,
              const Color(0xFF009E60).withValues(alpha: 0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Bouton retour
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xFFF77F00),
                  ),
                ),
              ),

              // Contenu scrollable
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo section avec drapeau stylisé
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFF77F00,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        const Color(0xFFF77F00),
                                        const Color(0xFFF77F00),
                                        Colors.white,
                                        const Color(0xFF009E60),
                                        const Color(0xFF009E60),
                                      ],
                                      stops: const [0.0, 0.33, 0.5, 0.67, 1.0],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_outlined,
                                    size: 45,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Titre
                              Text(
                                'Créer un compte',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFF77F00),
                                  letterSpacing: 1,
                                  shadows: [
                                    Shadow(
                                      color: const Color(
                                        0xFFF77F00,
                                      ).withValues(alpha: 0.3),
                                      offset: const Offset(0, 3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),

                              Text(
                                'Rejoignez CHIASMA',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Card contenant le formulaire
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Barre décorative avec couleurs du drapeau
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF77F00),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 30,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 30,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF009E60),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Champ Nom complet
                                      TextFormField(
                                        controller: _nomController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nom complet',
                                          hintText: 'Entrez votre nom complet',
                                          prefixIcon: Icon(
                                            Icons.person_outline,
                                            color: Color(0xFFF77F00),
                                          ),
                                        ),
                                        keyboardType: TextInputType.name,
                                        enabled: !_isLoading,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez entrer votre nom complet';
                                          }
                                          if (value.length < 3) {
                                            return 'Le nom doit contenir au moins 3 caractères';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Champ Matricule
                                      TextFormField(
                                        controller: _matriculeController,
                                        decoration: const InputDecoration(
                                          labelText: 'Numéro de matricule',
                                          hintText: '123456A',
                                          prefixIcon: Icon(
                                            Icons.badge_outlined,
                                            color: Color(0xFFF77F00),
                                          ),
                                        ),
                                        keyboardType: TextInputType.text,
                                        enabled: !_isLoading,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(7),
                                          UpperCaseTextFormatter(),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez entrer votre matricule';
                                          }
                                          // Validation stricte: 6 chiffres + 1 lettre
                                          final matriculeRegex = RegExp(
                                            r'^\d{6}[A-Z]$',
                                          );
                                          if (!matriculeRegex.hasMatch(value)) {
                                            return 'Format: 6 chiffres + 1 lettre (ex: 123456A)';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Champ Email
                                      TextFormField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                          labelText: 'Adresse email',
                                          hintText: 'exemple@email.ci',
                                          prefixIcon: Icon(
                                            Icons.email_outlined,
                                            color: Color(0xFFF77F00),
                                          ),
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        enabled: !_isLoading,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez entrer votre adresse email';
                                          }
                                          if (!value.contains('@')) {
                                            return 'L\'adresse email n\'est pas valide';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Section Numéros de téléphone
                                      Text(
                                        'Numéro(s) de téléphone',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Vous pouvez ajouter jusqu\'à 3 numéros',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Liste des champs téléphone
                                      ..._phoneControllers.asMap().entries.map((
                                        entry,
                                      ) {
                                        int index = entry.key;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller: entry.value,
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        'Téléphone ${index + 1}',
                                                    hintText: '1234561234',
                                                    prefixIcon: const Icon(
                                                      Icons.phone_outlined,
                                                      color: Color(0xFFF77F00),
                                                    ),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                    LengthLimitingTextInputFormatter(
                                                      10,
                                                    ),
                                                  ],
                                                  validator: (value) {
                                                    if (index == 0 &&
                                                        (value == null ||
                                                            value.isEmpty)) {
                                                      return 'Au moins un numéro est requis';
                                                    }
                                                    if (value != null &&
                                                        value.isNotEmpty &&
                                                        value.length != 10) {
                                                      return 'Exactement 10 chiffres requis';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                              if (_phoneControllers.length > 1)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () =>
                                                      _removePhoneField(index),
                                                ),
                                            ],
                                          ),
                                        );
                                      }),

                                      if (_phoneControllers.length < 3)
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: _addPhoneField,
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                            ),
                                            label: const Text(
                                              'Ajouter un numéro',
                                            ),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF009E60,
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 20),

                                      // Champ Fonction
                                      TextFormField(
                                        controller: _fonctionController,
                                        decoration: const InputDecoration(
                                          labelText: 'Fonction',
                                          hintText: 'Votre fonction actuelle',
                                          prefixIcon: Icon(
                                            Icons.work_outline,
                                            color: Color(0xFFF77F00),
                                          ),
                                        ),
                                        keyboardType: TextInputType.text,
                                        enabled: !_isLoading,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez entrer votre fonction';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Champ Zone actuelle (avec recherche)
                                      ZoneSearchField(
                                        initialValue: _zoneActuelle,
                                        labelText: 'Zone actuelle',
                                        hintText:
                                            'Recherchez votre zone de travail actuelle...',
                                        icon: Icons.location_on_outlined,
                                        onZoneSelected: (zone) {
                                          setState(() {
                                            _zoneActuelle = zone;
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez sélectionner votre zone actuelle';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Champ DREN (optionnel)
                                      TextFormField(
                                        controller: _drenController,
                                        decoration: InputDecoration(
                                          labelText: 'DREN (optionnel)',
                                          hintText:
                                              'Direction Régionale de l\'Éducation Nationale',
                                          prefixIcon: const Icon(
                                            Icons.account_balance_outlined,
                                            color: Color(0xFFF77F00),
                                          ),
                                          suffixIcon: Tooltip(
                                            message: 'Champ optionnel',
                                            child: Icon(
                                              Icons.info_outline,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.text,
                                        enabled: !_isLoading,
                                      ),
                                      const SizedBox(height: 20),

                                      // Champ Informations sur la zone actuelle
                                      TextFormField(
                                        controller: _infosZoneController,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Informations sur votre zone actuelle',
                                          hintText:
                                              'Ex: Proximité des commerces, écoles, centres de santé, accès routier, conditions de vie, etc. (min. 50 caractères)',
                                          prefixIcon: Icon(
                                            Icons.description_outlined,
                                            color: Color(0xFFF77F00),
                                          ),
                                          alignLabelWithHint: true,
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        maxLines: 4,
                                        enabled: !_isLoading,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez décrire votre zone actuelle';
                                          }
                                          if (value.length < 50) {
                                            return 'Minimum 50 caractères (${value.length}/50)';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Section Zones souhaitées
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Zones souhaitées',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_zonesSouhaitees.length}/5 zones',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      _zonesSouhaitees.length >=
                                                          5
                                                      ? Colors.red
                                                      : const Color(0xFF009E60),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton.icon(
                                            onPressed:
                                                _zonesSouhaitees.length >= 5
                                                ? null
                                                : _addZoneSouhaitee,
                                            icon: const Icon(
                                              Icons.add,
                                              size: 18,
                                            ),
                                            label: const Text('Ajouter'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF009E60,
                                              ),
                                              disabledForegroundColor:
                                                  Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Liste des zones souhaitées
                                      if (_zonesSouhaitees.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                size: 20,
                                                color: Colors.grey[600],
                                              ),
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
                                        ..._zonesSouhaitees.asMap().entries.map(
                                          (entry) {
                                            final index = entry.key;
                                            final zone = entry.value;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF009E60,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF009E60,
                                                  ).withValues(alpha: 0.3),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    color: Color(0xFF009E60),
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      zone,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                      size: 20,
                                                    ),
                                                    color: Colors.red,
                                                    onPressed: () =>
                                                        _removeZoneSouhaitee(
                                                          index,
                                                        ),
                                                    tooltip: 'Supprimer',
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      const SizedBox(height: 20),

                                      // Champ Mot de passe
                                      TextFormField(
                                        controller: _passwordController,
                                        decoration: InputDecoration(
                                          labelText: 'Mot de passe',
                                          hintText: '••••••••',
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: Colors.grey[600],
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        obscureText: _obscurePassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez entrer un mot de passe';
                                          }
                                          if (value.length < 6) {
                                            return 'Le mot de passe doit contenir au moins 6 caractères';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Champ Confirmation mot de passe
                                      TextFormField(
                                        decoration: InputDecoration(
                                          labelText:
                                              'Confirmer le mot de passe',
                                          hintText: '••••••••',
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: Colors.grey[600],
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirmPassword =
                                                    !_obscureConfirmPassword;
                                              });
                                            },
                                          ),
                                        ),
                                        obscureText: _obscureConfirmPassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez confirmer votre mot de passe';
                                          }
                                          if (value !=
                                              _passwordController.text) {
                                            return 'Les mots de passe ne correspondent pas';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 32),

                                      // Bouton d'inscription
                                      ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleRegister,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFFF77F00,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                'S\'inscrire',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Lien vers connexion
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Déjà un compte ? ',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(0, 0),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Se connecter',
                                              style: TextStyle(
                                                color: Color(0xFFF77F00),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
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

// TextInputFormatter personnalisé pour convertir en majuscules
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
