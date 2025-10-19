import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/chat_page.dart';
import 'package:myapp/services/subscription_service.dart';
import 'package:myapp/services/firestore_service.dart';

class ProfileDetailPage extends StatefulWidget {
  final String userId;          // ID de l'utilisateur dont on consulte le profil
  final String name;
  final String fonction;
  final String zoneActuelle;
  final String zoneSouhaitee;
  final bool isOnline;

  const ProfileDetailPage({
    super.key,
    required this.userId,
    required this.name,
    required this.fonction,
    required this.zoneActuelle,
    required this.zoneSouhaitee,
    required this.isOnline,
  });

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  final _subscriptionService = SubscriptionService();
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Incrémenter le compteur de vues quand le profil est ouvert
    _incrementProfileView();
    // Charger le statut favori
    _loadFavoriteStatus();
  }

  Future<void> _incrementProfileView() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid != widget.userId) {
        // Ne pas compter si c'est le propriétaire qui voit son propre profil
        await _subscriptionService.incrementProfileViewCount(currentUser.uid);
      }
    } catch (e) {
      // Erreur silencieuse - ne pas bloquer l'affichage du profil
      debugPrint('Erreur lors de l\'incrémentation du compteur de vues: $e');
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final isFav = await _firestoreService.isFavorite(
          currentUser.uid,
          widget.userId,
        );
        if (mounted) {
          setState(() {
            _isFavorite = isFav;
            _isLoadingFavorite = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du statut favori: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      if (_isFavorite) {
        await _firestoreService.removeFavorite(currentUser.uid, widget.userId);
      } else {
        await _firestoreService.addFavorite(currentUser.uid, widget.userId);
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite
                  ? 'Ajouté aux favoris ❤️'
                  : 'Retiré des favoris',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: _isFavorite ? Colors.red : const Color(0xFF009E60),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF77F00),
                      const Color(0xFFF77F00).withValues(alpha: 0.8),
                      const Color(0xFF009E60),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              widget.name.substring(0, 2).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF77F00),
                              ),
                            ),
                          ),
                          if (widget.isOnline)
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.fonction,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: _isLoadingFavorite
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                onPressed: _isLoadingFavorite ? null : _toggleFavorite,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zones
                  _buildSectionCard(
                    'Zones de permutation',
                    [
                      _buildInfoRow(
                        Icons.location_on,
                        'Zone actuelle',
                        widget.zoneActuelle,
                        const Color(0xFFF77F00),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.location_searching,
                        'Zone souhaitée',
                        widget.zoneSouhaitee,
                        const Color(0xFF009E60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Informations professionnelles
                  _buildSectionCard(
                    'Informations professionnelles',
                    [
                      _buildInfoRow(
                        Icons.work,
                        'Fonction',
                        widget.fonction,
                        const Color(0xFF2196F3),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.apartment,
                        'DREN',
                        'Abidjan 1',
                        const Color(0xFF9C27B0),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.school,
                        'Établissement',
                        'Lycée Moderne de Cocody',
                        Colors.orange[800]!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contact
                  _buildSectionCard(
                    'Contact',
                    [
                      _buildInfoRow(
                        Icons.email,
                        'Email',
                        'enseignant@education.ci',
                        const Color(0xFFF77F00),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.phone,
                        'Téléphone',
                        '+225 07 XX XX XX XX',
                        const Color(0xFF009E60),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Le numéro complet sera visible après connexion mutuelle',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // À propos
                  _buildSectionCard(
                    'À propos',
                    [
                      Text(
                        'Enseignant expérimenté recherchant une permutation pour raisons familiales. Ouvert à la discussion et aux échanges constructifs.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  contactName: widget.name,
                                  contactFunction: widget.fonction,
                                  isOnline: widget.isOnline,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF77F00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.message),
                          label: const Text(
                            'Envoyer un message',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showContactDialog(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF009E60),
                            side: const BorderSide(color: Color(0xFF009E60)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.phone),
                          label: const Text(
                            'Demander le contact',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF009E60).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.phone,
                color: Color(0xFF009E60),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Demande de contact'),
          ],
        ),
        content: const Text(
          'Souhaitez-vous envoyer une demande de contact à cet enseignant ? Votre numéro sera également partagé.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demande de contact envoyée'),
                  backgroundColor: Color(0xFF009E60),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009E60),
              foregroundColor: Colors.white,
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
