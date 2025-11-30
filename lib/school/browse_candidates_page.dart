import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/subscription_service.dart';
import '../models/user_model.dart';
import '../profile_detail_page.dart';
import '../chat_page.dart';
import '../widgets/zone_search_field.dart';
import '../widgets/subscription_required_dialog.dart';

/// Page pour consulter les candidats enseignants
class BrowseCandidatesPage extends StatefulWidget {
  const BrowseCandidatesPage({super.key});

  @override
  State<BrowseCandidatesPage> createState() => _BrowseCandidatesPageState();
}

class _BrowseCandidatesPageState extends State<BrowseCandidatesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedZone = '';
  String _selectedFonction = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtrer les candidats selon les critères
  List<UserModel> _filterCandidates(List<UserModel> candidates) {
    return candidates.where((candidate) {
      // Filtre par recherche (nom)
      final matchesSearch =
          _searchQuery.isEmpty ||
          candidate.nom.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filtre par zone
      final matchesZone =
          _selectedZone.isEmpty ||
          candidate.zoneActuelle.toLowerCase().contains(
            _selectedZone.toLowerCase(),
          ) ||
          candidate.zonesSouhaitees.any(
            (zone) => zone.toLowerCase().contains(_selectedZone.toLowerCase()),
          );

      // Filtre par fonction
      final matchesFonction =
          _selectedFonction.isEmpty ||
          candidate.fonction.toLowerCase().contains(
            _selectedFonction.toLowerCase(),
          );

      return matchesSearch && matchesZone && matchesFonction;
    }).toList();
  }

  // Afficher les options de filtre
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fonction',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tous'),
                    selected: _selectedFonction.isEmpty,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFonction = '';
                      });
                      Navigator.pop(context);
                    },
                  ),
                  FilterChip(
                    label: const Text('Enseignant'),
                    selected: _selectedFonction == 'enseignant',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFonction = selected ? 'enseignant' : '';
                      });
                      Navigator.pop(context);
                    },
                  ),
                  FilterChip(
                    label: const Text('Directeur'),
                    selected: _selectedFonction == 'directeur',
                    onSelected: (selected) {
                      setState(() {
                        _selectedFonction = selected ? 'directeur' : '';
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Zone géographique',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ZoneSearchField(
                labelText: 'Zone géographique',
                hintText: 'Rechercher une zone...',
                icon: Icons.location_on,
                onZoneSelected: (zone) {
                  setState(() {
                    _selectedZone = zone;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedZone = '';
                _selectedFonction = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Réinitialiser'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Candidats enseignants'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Veuillez vous connecter')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidats enseignants'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtres',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF77F00),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un candidat...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Chips de filtres actifs
          if (_selectedZone.isNotEmpty || _selectedFonction.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedZone.isNotEmpty)
                    Chip(
                      label: Text('Zone: $_selectedZone'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedZone = '';
                        });
                      },
                    ),
                  if (_selectedFonction.isNotEmpty)
                    Chip(
                      label: Text('Fonction: $_selectedFonction'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedFonction = '';
                        });
                      },
                    ),
                ],
              ),
            ),

          // Liste des candidats
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: _firestoreService.getUserStream(currentUser.uid),
              builder: (context, schoolSnapshot) {
                if (schoolSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final schoolUser = schoolSnapshot.data;

                return StreamBuilder<List<UserModel>>(
                  stream: _firestoreService.getUsersByAccountType(
                    'teacher_candidate',
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    }

                    final allCandidates = snapshot.data ?? [];
                    final filteredCandidates = _filterCandidates(allCandidates);

                    if (filteredCandidates.isEmpty) {
                      return _buildEmptyView();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredCandidates.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final candidate = filteredCandidates[index];
                        return _buildCandidateCard(candidate, schoolUser);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun candidat trouvé',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ||
                    _selectedZone.isNotEmpty ||
                    _selectedFonction.isNotEmpty
                ? 'Essayez de modifier vos filtres'
                : 'Aucun candidat disponible pour le moment',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(UserModel candidate, UserModel? schoolUser) {
    final bool canSendMessage =
        schoolUser != null &&
        schoolUser.isVerified &&
        !schoolUser.isVerificationExpired;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildCandidateAvatar(candidate),
        title: Text(
          candidate.nom,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: _buildCandidateInfo(candidate),
        trailing: _buildCandidateActions(candidate, canSendMessage),
        onTap: () => _handleCandidateTap(candidate),
      ),
    );
  }

  Widget _buildCandidateAvatar(UserModel candidate) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.2),
          child: Text(
            candidate.nom
                .split(' ')
                .map((word) => word.isNotEmpty ? word[0] : '')
                .take(2)
                .join()
                .toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFF77F00),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        if (candidate.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCandidateInfo(UserModel candidate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        _buildInfoRow(
          Icons.work_outline,
          candidate.fonction,
          const Color(0xFF009E60),
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          Icons.location_on_outlined,
          candidate.zoneActuelle,
          Colors.grey,
        ),
        if (candidate.zonesSouhaitees.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.place_outlined,
            'Souhaite: ${candidate.zonesSouhaitees.take(2).join(', ')}${candidate.zonesSouhaitees.length > 2 ? '...' : ''}',
            Colors.grey,
            isItalic: true,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    Color? iconColor, {
    bool isItalic = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isItalic ? 12 : 13,
              color: iconColor is Color
                  ? (iconColor == Colors.grey ? Colors.grey[700] : iconColor)
                  : Colors.grey[700],
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCandidateActions(UserModel candidate, bool canSendMessage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.message_outlined,
            color: canSendMessage ? const Color(0xFFF77F00) : Colors.grey,
          ),
          onPressed: canSendMessage
              ? () => _navigateToChat(candidate)
              : () => SubscriptionRequiredDialog.show(context, 'school'),
          tooltip: canSendMessage ? 'Envoyer un message' : 'Abonnement requis',
        ),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ],
    );
  }

  void _navigateToChat(UserModel candidate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          contactName: candidate.nom,
          contactFunction: candidate.fonction,
          isOnline: candidate.isOnline,
          contactUserId: candidate.uid,
        ),
      ),
    );
  }

  Future<void> _handleCandidateTap(UserModel candidate) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await SubscriptionService().consumeCandidateViewQuota(
      currentUserId,
    );

    if (!context.mounted) return;

    if (result.needsSubscription) {
      // ignore: use_build_context_synchronously
      SubscriptionRequiredDialog.show(context, result.accountType ?? 'school');
    } else if (result.success) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ProfileDetailPage(userId: candidate.uid),
        ),
      );

      if (result.quotaRemaining >= 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Vues de candidats restantes: ${result.quotaRemaining}',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF009E60),
          ),
        );
      }
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }
}
