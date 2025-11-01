import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/job_offer_model.dart';
import 'package:myapp/models/offer_application_model.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/jobs_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/widgets/subscription_required_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Page de détail d'une offre d'emploi avec possibilité de candidater
class JobOfferDetailPage extends StatefulWidget {
  final JobOfferModel offer;

  const JobOfferDetailPage({super.key, required this.offer});

  @override
  State<JobOfferDetailPage> createState() => _JobOfferDetailPageState();
}

class _JobOfferDetailPageState extends State<JobOfferDetailPage> {
  final JobsService _jobsService = JobsService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _coverLetterController = TextEditingController();

  bool _isLoading = false;
  bool _hasApplied = false;
  UserModel? _schoolInfo;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _checkIfAlreadyApplied();
    _incrementViewCount();
    _loadSchoolInfo();
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAlreadyApplied() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final application = await _jobsService.getOfferApplicationByUserAndOffer(
        userId,
        widget.offer.id,
      );

      if (mounted) {
        setState(() {
          _hasApplied = application != null;
        });
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }

  Future<void> _incrementViewCount() async {
    try {
      await _jobsService.incrementOfferViewCount(widget.offer.id);
    } catch (e) {
      // Erreur silencieuse
    }
  }

  Future<void> _loadSchoolInfo() async {
    try {
      final schoolDoc = await _firestoreService.getUser(widget.offer.schoolId);
      if (mounted && schoolDoc != null) {
        setState(() {
          _schoolInfo = schoolDoc;
        });
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }

  Future<void> _submitApplication() async {
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

    // Consommer un quota pour postuler
    final result = await SubscriptionService().consumeApplicationQuota(userId);

    if (!mounted) return;

    if (result.needsSubscription) {
      // Fermer le modal d'abord
      Navigator.pop(context);
      // Afficher le dialogue d'abonnement
      SubscriptionRequiredDialog.show(context, result.accountType ?? 'teacher_candidate');
      return;
    } else if (!result.success) {
      // Erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Afficher le quota restant si pas illimité
    if (result.quotaRemaining >= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Candidatures gratuites restantes: ${result.quotaRemaining}'),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF009E60),
        ),
      );
    }

    // Récupérer les infos du candidat
    final user = await _firestoreService.getUser(userId);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Profil utilisateur introuvable'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final application = OfferApplicationModel(
        id: '',
        offerId: widget.offer.id,
        userId: userId,
        candidateName: user.nom,
        candidateEmail: user.email,
        candidatePhones: user.telephones,
        coverLetter: _coverLetterController.text.trim().isNotEmpty
            ? _coverLetterController.text.trim()
            : null,
        createdAt: DateTime.now(),
        jobTitle: widget.offer.poste,
        schoolName: widget.offer.nomEtablissement,
        schoolId: widget.offer.schoolId,
      );

      await _jobsService.createOfferApplication(application);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidature envoyée avec succès!'),
            backgroundColor: Color(0xFF009E60),
          ),
        );

        setState(() {
          _hasApplied = true;
        });

        // Fermer le modal
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
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

  void _showApplicationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.send, color: Color(0xFF009E60)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Postuler à cette offre',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Votre profil sera partagé avec ${widget.offer.nomEtablissement}.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _coverLetterController,
                decoration: const InputDecoration(
                  labelText: 'Lettre de motivation (optionnel)',
                  hintText: 'Expliquez pourquoi vous êtes le candidat idéal...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
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
                        'Envoyer ma candidature',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'offre'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête avec établissement
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF77F00).withValues(alpha: 0.1),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 48,
                      color: Color(0xFFF77F00),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.offer.nomEtablissement,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.offer.localisationComplete,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009E60).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.offer.typeContrat,
                      style: const TextStyle(
                        color: Color(0xFF009E60),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre du poste
                  Text(
                    widget.offer.poste,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Publié ${timeago.format(widget.offer.createdAt, locale: 'fr')}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Matières
                  if (widget.offer.matieres.isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.book,
                      title: 'Matières',
                      content: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.offer.matieres.map((matiere) {
                          return Chip(
                            label: Text(matiere),
                            backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Niveaux
                  if (widget.offer.niveaux.isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.school,
                      title: 'Niveaux',
                      content: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.offer.niveaux.map((niveau) {
                          return Chip(
                            label: Text(niveau),
                            backgroundColor: const Color(0xFF009E60).withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Description
                  _buildSection(
                    icon: Icons.description,
                    title: 'Description du poste',
                    content: Text(
                      widget.offer.description,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),

                  // Exigences
                  if (widget.offer.exigences.isNotEmpty) ...[
                    _buildSection(
                      icon: Icons.checklist,
                      title: 'Exigences',
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.offer.exigences.map((exigence) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Color(0xFF009E60),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    exigence,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Salaire
                  if (widget.offer.salaire != null) ...[
                    _buildSection(
                      icon: Icons.payments,
                      title: 'Rémunération',
                      content: Text(
                        widget.offer.salaire!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF009E60),
                        ),
                      ),
                    ),
                  ],

                  // Statistiques
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                          icon: Icons.visibility,
                          value: widget.offer.viewsCount.toString(),
                          label: 'Vues',
                        ),
                        Container(width: 1, height: 40, color: Colors.grey[300]),
                        _buildStat(
                          icon: Icons.people,
                          value: widget.offer.applicantsCount.toString(),
                          label: 'Candidatures',
                        ),
                      ],
                    ),
                  ),

                  // Contact de l'établissement (conditionnel)
                  if (_schoolInfo != null) ...[
                    const SizedBox(height: 24),
                    if (_schoolInfo!.showContactInfo)
                      _buildSection(
                        icon: Icons.contact_mail,
                        title: 'Contact de l\'établissement',
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.email,
                                  size: 20,
                                  color: Color(0xFF009E60),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _schoolInfo!.email,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            if (_schoolInfo!.telephones.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ..._schoolInfo!.telephones.map((phone) =>
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 20,
                                        color: Color(0xFF009E60),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          phone,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF77F00).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, color: Colors.orange[700], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Cet établissement a choisi de ne pas afficher ses coordonnées. Utilisez le bouton "Postuler" pour entrer en contact.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange[800],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _hasApplied
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF009E60).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF009E60), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF009E60)),
                      const SizedBox(width: 8),
                      Text(
                        'Candidature envoyée',
                        style: const TextStyle(
                          color: Color(0xFF009E60),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ElevatedButton(
                  onPressed: _showApplicationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009E60),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send),
                      SizedBox(width: 8),
                      Text(
                        'Postuler à cette offre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: const Color(0xFFF77F00)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFF77F00)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
