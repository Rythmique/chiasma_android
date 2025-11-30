import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../profile_detail_page.dart';
import '../chat_page.dart';
import '../widgets/subscription_required_dialog.dart';

/// Page des candidats favoris de l'école
class SchoolFavoritesPage extends StatefulWidget {
  const SchoolFavoritesPage({super.key});

  @override
  State<SchoolFavoritesPage> createState() => _SchoolFavoritesPageState();
}

class _SchoolFavoritesPageState extends State<SchoolFavoritesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mes favoris'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Erreur: utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes favoris'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.getFavorites(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return _buildEmptyView();
          }

          return StreamBuilder<UserModel?>(
            stream: _firestoreService.getUserStream(_currentUserId),
            builder: (context, schoolSnapshot) {
              final schoolUser = schoolSnapshot.data;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return _buildCandidateCard(favorites[index], schoolUser);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Vue vide
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Aucun favori',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Les candidats que vous ajoutez en favoris apparaîtront ici',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte d'un candidat favori
  Widget _buildCandidateCard(UserModel candidate, UserModel? schoolUser) {
    final canSendMessage =
        schoolUser != null &&
        schoolUser.isVerified &&
        !schoolUser.isVerificationExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCandidateHeader(candidate),
            const SizedBox(height: 12),
            if (candidate.zonesSouhaitees.isNotEmpty) ...[
              _buildZonesRow(candidate),
              const SizedBox(height: 8),
            ],
            _buildActionButtons(candidate, canSendMessage),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateHeader(UserModel candidate) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFF77F00),
          child: Text(
            candidate.nom
                .split(' ')
                .map((word) => word.isNotEmpty ? word[0] : '')
                .take(2)
                .join()
                .toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.nom,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.subject, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      candidate.fonction,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite, color: Colors.red, size: 20),
        ),
      ],
    );
  }

  Widget _buildZonesRow(UserModel candidate) {
    return Row(
      children: [
        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            candidate.zonesSouhaitees.take(3).join(' • '),
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(UserModel candidate, bool canSendMessage) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _viewProfile(candidate),
            icon: const Icon(Icons.person, size: 18),
            label: const Text('Profil'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canSendMessage
                ? () => _contactCandidate(candidate)
                : () => SubscriptionRequiredDialog.show(context, 'school'),
            icon: const Icon(Icons.message, size: 18),
            label: const Text('Contacter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: canSendMessage
                  ? const Color(0xFF009E60)
                  : Colors.grey,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _removeFavorite(candidate),
          tooltip: 'Retirer des favoris',
        ),
      ],
    );
  }

  /// Voir le profil du candidat
  void _viewProfile(UserModel candidate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailPage(userId: candidate.uid),
      ),
    );
  }

  /// Contacter le candidat
  Future<void> _contactCandidate(UserModel candidate) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          contactUserId: candidate.uid,
          contactName: candidate.nom,
          contactFunction: candidate.fonction,
          isOnline: candidate.isOnline,
        ),
      ),
    );
  }

  /// Retirer des favoris
  Future<void> _removeFavorite(UserModel candidate) async {
    if (_currentUserId == null) return;

    try {
      await _firestoreService.removeFavorite(_currentUserId, candidate.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${candidate.nom} retiré des favoris'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Annuler',
              onPressed: () async {
                // Rajouter aux favoris
                await _firestoreService.addFavorite(
                  _currentUserId,
                  candidate.uid,
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
