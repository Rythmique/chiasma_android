import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Page affichant qui a consulté le profil du candidat
class ProfileViewsPage extends StatefulWidget {
  const ProfileViewsPage({super.key});

  @override
  State<ProfileViewsPage> createState() => _ProfileViewsPageState();
}

class _ProfileViewsPageState extends State<ProfileViewsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  int _profileViewsCount = 0;
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    _loadProfileViewsCount();
    // Configurer la locale française pour timeago
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }

  Future<void> _loadProfileViewsCount() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      final count = await _firestoreService.getProfileViewsCount(userId);
      if (mounted) {
        setState(() {
          _profileViewsCount = count;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du compteur de vues: $e');
      if (mounted) {
        setState(() {
          _isLoadingCount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _userId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Vues de profil'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Erreur: utilisateur non connecté'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vues de profil'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // En-tête avec statistiques
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF77F00),
                  const Color(0xFFF77F00).withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.visibility,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 12),
                _isLoadingCount
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _profileViewsCount.toString(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                const SizedBox(height: 4),
                Text(
                  _profileViewsCount <= 1 ? 'vue de profil' : 'vues de profil',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nombre de fois où des écoles ont consulté votre profil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          // Liste des vues
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getProfileViews(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF77F00),
                    ),
                  );
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

                final views = snapshot.data ?? [];

                if (views.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_off,
                            size: 100,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Aucune vue pour le moment',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Les écoles qui consultent votre profil apparaîtront ici.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: views.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final view = views[index];
                    return _buildViewCard(view);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewCard(Map<String, dynamic> view) {
    final viewerName = view['viewerName'] as String? ?? 'École';
    final lastViewedAt = view['lastViewedAt'] as Timestamp?;
    final createdAt = view['createdAt'] as Timestamp?;

    String timeAgoText = '';
    if (lastViewedAt != null) {
      try {
        timeAgoText = timeago.format(
          lastViewedAt.toDate(),
          locale: 'fr',
        );
      } catch (e) {
        timeAgoText = 'Récemment';
      }
    }

    String firstViewText = '';
    if (createdAt != null && lastViewedAt != null) {
      final firstView = createdAt.toDate();
      final lastView = lastViewedAt.toDate();

      if (firstView.year == lastView.year &&
          firstView.month == lastView.month &&
          firstView.day == lastView.day) {
        firstViewText = 'Première vue';
      } else {
        try {
          firstViewText = 'Première vue ${timeago.format(firstView, locale: 'fr')}';
        } catch (e) {
          firstViewText = 'Vue multiple';
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.2),
          child: const Icon(
            Icons.school,
            color: Color(0xFFF77F00),
            size: 28,
          ),
        ),
        title: Text(
          viewerName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 14,
                  color: Color(0xFF009E60),
                ),
                const SizedBox(width: 4),
                Text(
                  timeAgoText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF009E60),
                  ),
                ),
              ],
            ),
            if (firstViewText.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.history,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    firstViewText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF77F00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility,
                size: 16,
                color: Color(0xFFF77F00),
              ),
              SizedBox(width: 4),
              Text(
                'Vue',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF77F00),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
