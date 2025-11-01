import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/profile_detail_page.dart';
import 'package:myapp/chat_page.dart';
import 'package:myapp/settings_page.dart';
import 'package:myapp/notifications_page.dart';
import 'package:myapp/user_info_page.dart';
import 'package:myapp/privacy_settings_page.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/widgets/announcements_banner.dart';
import 'package:myapp/widgets/subscription_status_banner.dart';
import 'package:myapp/widgets/quota_status_widget.dart';
import 'package:myapp/widgets/welcome_quota_dialog.dart';
import 'package:myapp/widgets/subscription_required_dialog.dart';
import 'package:myapp/widgets/verified_badge.dart';
import 'package:myapp/services/subscription_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const SearchPage(),
      const FavoritesPage(),
      const MessagesPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFF77F00),
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Recherche',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favoris',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

// Page de recherche
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _selectedSearchMode = 'zone_actuelle'; // Par défaut: Par Zone Actuelle
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FirestoreService _firestoreService = FirestoreService();
  Set<String> _favoriteUserIds = {}; // IDs des profils favoris (vrais userId)
  List<UserModel> _allUsers = []; // Liste de tous les utilisateurs réels depuis Firestore
  bool _isLoadingUsers = true;

  // Données de l'utilisateur connecté (pour le match mutuel)
  Map<String, dynamic> _currentUser = {
    'zoneActuelle': 'Abidjan, Cocody',
    'zoneSouhaitee': 'Yamoussoukro',
    'fonction': 'Professeur de Mathématiques',
    'dren': 'Abidjan 1',
  };

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadUsers();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Charger les données de l'utilisateur connecté
  Future<void> _loadCurrentUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final userData = await _firestoreService.getUser(currentUser.uid);
      if (userData != null && mounted) {
        setState(() {
          _currentUser = {
            'zoneActuelle': userData.zoneActuelle,
            'zoneSouhaitee': userData.zonesSouhaitees.isNotEmpty
                ? userData.zonesSouhaitees.first
                : '',
            'fonction': userData.fonction,
            'dren': userData.dren ?? '',
          };
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données utilisateur: $e');
    }
  }

  // Charger tous les utilisateurs depuis Firestore (filtrés par type de compte)
  Future<void> _loadUsers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Charger uniquement les utilisateurs de type "teacher_transfer" (permutation)
      _firestoreService.getUsersByAccountType('teacher_transfer').listen((users) {
        if (mounted) {
          setState(() {
            // Exclure l'utilisateur connecté de la liste
            _allUsers = users.where((user) => user.uid != currentUser.uid).toList();
            _isLoadingUsers = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Erreur chargement utilisateurs: $e');
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  // Charger les favoris de l'utilisateur depuis Firestore
  Future<void> _loadFavorites() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Écouter les changements dans la collection favorites
      FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: currentUser.uid)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _favoriteUserIds = snapshot.docs
                .map((doc) => doc.data()['favoriteUserId'] as String)
                .toSet();
          });
        }
      });
    } catch (e) {
      // Erreur lors du chargement des favoris
      debugPrint('Erreur chargement favoris: $e');
    }
  }

  // Basculer un profil en favori
  Future<void> _toggleFavorite(String profileUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      if (_favoriteUserIds.contains(profileUserId)) {
        await _firestoreService.removeFavorite(currentUser.uid, profileUserId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retiré des favoris'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _firestoreService.addFavorite(currentUser.uid, profileUserId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ajouté aux favoris'),
              duration: Duration(seconds: 1),
              backgroundColor: Color(0xFF009E60),
            ),
          );
        }
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
    }
  }



  // Obtenir le placeholder du champ de recherche selon le filtre actif
  String get _searchHint {
    switch (_selectedSearchMode) {
      case 'zone_actuelle':
        return 'Rechercher par zone actuelle (ex: Abidjan, Cocody)...';
      case 'zone_souhaitee':
        return 'Rechercher par zone souhaitée (ex: Yamoussoukro)...';
      case 'fonction':
        return 'Rechercher par fonction (ex: Professeur, Directeur)...';
      case 'dren':
        return 'Rechercher par DREN (ex: Abidjan 1, Bouaké)...';
      case 'match_mutuel':
        return 'Match automatique activé - Aucune recherche nécessaire';
      default:
        return 'Rechercher...';
    }
  }

  // Obtenir la couleur de bordure du filtre sélectionné
  Color _getFilterBorderColor() {
    switch (_selectedSearchMode) {
      case 'zone_actuelle':
        return const Color(0xFFF77F00); // Orange
      case 'zone_souhaitee':
        return const Color(0xFF009E60); // Vert
      case 'fonction':
        return const Color(0xFF2196F3); // Bleu
      case 'dren':
        return const Color(0xFF9C27B0); // Violet
      case 'match_mutuel':
        return const Color(0xFFE91E63); // Rose
      default:
        return Colors.grey.shade300;
    }
  }

  // Obtenir la couleur de fond du filtre sélectionné
  Color _getFilterBackgroundColor() {
    switch (_selectedSearchMode) {
      case 'zone_actuelle':
        return const Color(0xFFF77F00).withValues(alpha: 0.05);
      case 'zone_souhaitee':
        return const Color(0xFF009E60).withValues(alpha: 0.05);
      case 'fonction':
        return const Color(0xFF2196F3).withValues(alpha: 0.05);
      case 'dren':
        return const Color(0xFF9C27B0).withValues(alpha: 0.05);
      case 'match_mutuel':
        return const Color(0xFFE91E63).withValues(alpha: 0.05);
      default:
        return Colors.white;
    }
  }

  List<UserModel> get _filteredProfiles {
    // Mode Match Mutuel : recherche automatique
    if (_selectedSearchMode == 'match_mutuel') {
      return _allUsers.where((user) {
        // Match mutuel = la zone souhaitée de l'utilisateur correspond à la zone actuelle du profil
        // ET la zone actuelle de l'utilisateur correspond à la zone souhaitée du profil
        final zoneSouhaitee = user.zonesSouhaitees.isNotEmpty ? user.zonesSouhaitees.first : '';
        return user.zoneActuelle == _currentUser['zoneSouhaitee'] &&
               zoneSouhaitee == _currentUser['zoneActuelle'];
      }).toList();
    }

    // Si pas de recherche, retourner tous les utilisateurs
    if (_searchQuery.isEmpty) {
      return _allUsers;
    }

    final query = _searchQuery.toLowerCase();

    // Filtrer selon le mode de recherche sélectionné
    switch (_selectedSearchMode) {
      case 'zone_actuelle':
        return _allUsers.where((user) {
          return user.zoneActuelle.toLowerCase().contains(query);
        }).toList();

      case 'zone_souhaitee':
        return _allUsers.where((user) {
          return user.zonesSouhaitees.any((zone) => zone.toLowerCase().contains(query));
        }).toList();

      case 'fonction':
        return _allUsers.where((user) {
          return user.fonction.toLowerCase().contains(query);
        }).toList();

      case 'dren':
        return _allUsers.where((user) {
          return (user.dren ?? '').toLowerCase().contains(query);
        }).toList();

      default:
        return _allUsers;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // AppBar avec dégradé
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              title: const Text(
                'CHIASMA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 16,
                ),
              ),
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
              ),
            ),
            actions: [
              // Notification bell with badge
              StreamBuilder<int>(
                stream: NotificationService().streamUnreadCount(
                  FirebaseAuth.instance.currentUser?.uid ?? '',
                ),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsPage(),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),

          // Barre de recherche
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                enabled: _selectedSearchMode != 'match_mutuel', // Désactivé en mode match mutuel
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: _searchHint,
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(
                    _selectedSearchMode == 'match_mutuel' ? Icons.auto_awesome : Icons.search,
                    color: const Color(0xFFF77F00),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: _selectedSearchMode == 'match_mutuel'
                      ? Colors.grey[100]
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFF77F00), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Menu déroulant pour les modes de recherche
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode de recherche',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getFilterBackgroundColor(),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getFilterBorderColor(),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getFilterBorderColor().withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSearchMode,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFF77F00)),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'zone_actuelle',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF77F00).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Color(0xFFF77F00),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Par Zone Actuelle'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'zone_souhaitee',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF009E60).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_searching,
                                    color: Color(0xFF009E60),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Par Zone Souhaitée'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'fonction',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.work,
                                    color: Color(0xFF2196F3),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Par Fonction'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'dren',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.apartment,
                                    color: Color(0xFF9C27B0),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Par DREN'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'match_mutuel',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.sync_alt,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Match Mutuel'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSearchMode = value!;
                            // Réinitialiser la recherche lors du changement de filtre
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Annonces
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AnnouncementsBanner(accountType: 'teacher_transfer'),
            ),
          ),

          // Statut de vérification et quota
          SliverToBoxAdapter(
            child: StreamBuilder<UserModel?>(
              stream: _firestoreService.getUserStream(
                FirebaseAuth.instance.currentUser?.uid ?? '',
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final user = snapshot.data!;

                // Afficher le dialogue de bienvenue si première connexion
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  WelcomeQuotaDialog.showIfFirstTime(context, user);

                  // Vérifier si le quota est épuisé et afficher le dialogue
                  if (user.isFreeQuotaExhausted && !user.hasAccess) {
                    SubscriptionRequiredDialog.show(context, user.accountType);
                  }
                });

                return Column(
                  children: [
                    SubscriptionStatusBanner(user: user),
                    QuotaStatusWidget(user: user),
                  ],
                );
              },
            ),
          ),

          // Liste des résultats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _searchQuery.isNotEmpty ? 'Résultats de recherche' : 'Profils disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    '${_filteredProfiles.length} profil${_filteredProfiles.length > 1 ? 's' : ''} trouvé${_filteredProfiles.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Cartes de profils
          _isLoadingUsers
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(
                        color: Color(0xFFF77F00),
                      ),
                    ),
                  ),
                )
              : _filteredProfiles.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun profil trouvé',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Essayez une autre recherche',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProfileCard(_filteredProfiles[index], index),
                      childCount: _filteredProfiles.length,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel user, int index) {
    final userId = user.uid;
    final isOnline = user.isOnline;
    final name = user.nom;
    final fonction = user.fonction;
    final zoneActuelle = user.zoneActuelle;
    final zoneSouhaitee = user.zonesSouhaitees.isNotEmpty ? user.zonesSouhaitees.first : 'Non spécifiée';

    // Get initials from name
    final initials = name.split(' ').map((word) => word[0]).take(2).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.2),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: const Color(0xFFF77F00),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOnline) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'En ligne',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        VerifiedBadge(
                          isVerified: user.isVerified,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fonction,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _favoriteUserIds.contains(userId) ? Icons.favorite : Icons.favorite_border,
                  color: _favoriteUserIds.contains(userId) ? Colors.red : Colors.grey[400],
                ),
                onPressed: () => _toggleFavorite(userId),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: const Color(0xFFF77F00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zone actuelle',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            zoneActuelle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_searching,
                      size: 18,
                      color: const Color(0xFF009E60),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zone souhaitée',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            zoneSouhaitee,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    if (currentUserId == null) return;

                    // Consommer un quota pour voir le profil
                    final result = await SubscriptionService().consumeProfileViewQuota(currentUserId);

                    if (!context.mounted) return;

                    if (result.needsSubscription) {
                      // Afficher le dialogue d'abonnement
                      SubscriptionRequiredDialog.show(context, result.accountType ?? 'teacher_transfer');
                    } else if (result.success) {
                      // Naviguer vers le profil
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileDetailPage(
                            userId: userId,
                          ),
                        ),
                      );

                      // Afficher le quota restant si pas illimité
                      if (result.quotaRemaining >= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Consultations restantes: ${result.quotaRemaining}'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF009E60),
                          ),
                        );
                      }
                    } else {
                      // Erreur
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF77F00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Voir profil'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    if (currentUserId == null) return;

                    // Consommer un quota pour envoyer un message
                    final result = await SubscriptionService().consumeMessageQuota(currentUserId);

                    if (!context.mounted) return;

                    if (result.needsSubscription) {
                      // Afficher le dialogue d'abonnement
                      SubscriptionRequiredDialog.show(context, result.accountType ?? 'teacher_transfer');
                    } else if (result.success) {
                      // Naviguer vers la page de chat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            contactName: name,
                            contactFunction: fonction,
                            isOnline: isOnline,
                            contactUserId: userId,
                          ),
                        ),
                      );

                      // Afficher le quota restant si pas illimité
                      if (result.quotaRemaining >= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Consultations restantes: ${result.quotaRemaining}'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF009E60),
                          ),
                        );
                      }
                    } else {
                      // Erreur
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF009E60),
                    side: const BorderSide(color: Color(0xFF009E60)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Page des favoris
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirestoreService _firestoreService = FirestoreService();



  Future<void> _removeFavorite(String favoriteUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _firestoreService.removeFavorite(currentUser.uid, favoriteUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retiré des favoris'),
            duration: Duration(seconds: 1),
          ),
        );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Veuillez vous connecter')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _firestoreService.getFavorites(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun favori pour le moment',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Ajoutez des profils à vos favoris pour les retrouver facilement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final user = favorites[index];
              return _buildFavoriteProfileCard(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteProfileCard(UserModel user) {
    // Get initials from name
    final initials = user.nom.split(' ').map((word) => word[0]).take(2).join().toUpperCase();
    final zoneSouhaitee = user.zonesSouhaitees.isNotEmpty ? user.zonesSouhaitees.first : 'Non spécifiée';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.2),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: const Color(0xFFF77F00),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.nom,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isOnline) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'En ligne',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.fonction,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                onPressed: () => _removeFavorite(user.uid),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: const Color(0xFFF77F00),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zone actuelle',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            user.zoneActuelle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_searching,
                      size: 18,
                      color: const Color(0xFF009E60),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zone souhaitée',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            zoneSouhaitee,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    if (currentUserId == null) return;

                    // Consommer un quota pour voir le profil
                    final result = await SubscriptionService().consumeProfileViewQuota(currentUserId);

                    if (!context.mounted) return;

                    if (result.needsSubscription) {
                      // Afficher le dialogue d'abonnement
                      SubscriptionRequiredDialog.show(context, result.accountType ?? 'teacher_transfer');
                    } else if (result.success) {
                      // Naviguer vers le profil
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileDetailPage(
                            userId: user.uid,
                          ),
                        ),
                      );

                      // Afficher le quota restant si pas illimité
                      if (result.quotaRemaining >= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Consultations restantes: ${result.quotaRemaining}'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF009E60),
                          ),
                        );
                      }
                    } else {
                      // Erreur
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF77F00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Voir profil'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    if (currentUserId == null) return;

                    // Consommer un quota pour envoyer un message
                    final result = await SubscriptionService().consumeMessageQuota(currentUserId);

                    if (!context.mounted) return;

                    if (result.needsSubscription) {
                      // Afficher le dialogue d'abonnement
                      SubscriptionRequiredDialog.show(context, result.accountType ?? 'teacher_transfer');
                    } else if (result.success) {
                      // Naviguer vers la page de chat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            contactName: user.nom,
                            contactFunction: user.fonction,
                            isOnline: user.isOnline,
                            contactUserId: user.uid,
                          ),
                        ),
                      );

                      // Afficher le quota restant si pas illimité
                      if (result.quotaRemaining >= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Consultations restantes: ${result.quotaRemaining}'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF009E60),
                          ),
                        );
                      }
                    } else {
                      // Erreur
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF009E60),
                    side: const BorderSide(color: Color(0xFF009E60)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Page des messages
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FirestoreService _firestoreService = FirestoreService();

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Veuillez vous connecter'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getConversations(currentUser.uid),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final allConversations = snapshot.data?.docs ?? [];

          // Filtrer les conversations avec lastMessageTime null pour éviter l'erreur Firestore
          final conversations = allConversations.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['lastMessageTime'] != null;
          }).toList();

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Commencez une conversation en envoyant un message depuis un profil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Récupérer tous les IDs des autres participants en une fois
          final otherUserIds = conversations.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final participants = data['participants'] as List<dynamic>;
            return participants.firstWhere(
              (id) => id != currentUser.uid,
              orElse: () => null,
            ) as String?;
          }).where((id) => id != null).cast<String>().toSet().toList();

          // Charger tous les utilisateurs en une seule fois
          return FutureBuilder<Map<String, UserModel>>(
            future: _loadUsersMap(otherUserIds),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFF77F00),
                  ),
                );
              }

              final usersMap = usersSnapshot.data ?? {};

              return ListView.separated(
                itemCount: conversations.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conversationDoc = conversations[index];
                  final conversationData = conversationDoc.data() as Map<String, dynamic>;
                  final participants = conversationData['participants'] as List<dynamic>;
                  final lastMessage = conversationData['lastMessage'] as String? ?? '';
                  final lastMessageTime = conversationData['lastMessageTime'] as Timestamp?;
                  final unreadCount = conversationData['unreadCount'] as Map<String, dynamic>? ?? {};

                  // Trouver l'ID de l'autre participant
                  final otherUserId = participants.firstWhere(
                    (id) => id != currentUser.uid,
                    orElse: () => null,
                  ) as String?;

                  if (otherUserId == null || !usersMap.containsKey(otherUserId)) {
                    return const SizedBox.shrink();
                  }

                  final otherUser = usersMap[otherUserId]!;
                  final initials = otherUser.nom.split(' ')
                      .map((word) => word[0])
                      .take(2)
                      .join()
                      .toUpperCase();
                  final hasUnread = (unreadCount[currentUser.uid] ?? 0) > 0;

                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.2),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Color(0xFFF77F00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (otherUser.isOnline)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            otherUser.nom,
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF77F00),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount[currentUser.uid].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      lastMessage.isEmpty ? 'Aucun message' : lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    trailing: Text(
                      lastMessageTime != null
                          ? _formatTime(lastMessageTime.toDate())
                          : '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            contactName: otherUser.nom,
                            contactFunction: otherUser.fonction,
                            isOnline: otherUser.isOnline,
                            conversationId: conversationDoc.id,
                            contactUserId: otherUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Charger tous les utilisateurs en une seule fois et retourner une map
  Future<Map<String, UserModel>> _loadUsersMap(List<String> userIds) async {
    final Map<String, UserModel> usersMap = {};

    // Charger tous les utilisateurs en parallèle
    await Future.wait(
      userIds.map((userId) async {
        try {
          final user = await _firestoreService.getUser(userId);
          if (user != null) {
            usersMap[userId] = user;
          }
        } catch (e) {
          debugPrint('Erreur chargement utilisateur $userId: $e');
        }
      }),
    );

    return usersMap;
  }
}

// Page de profil
// Page de profil
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Clé pour forcer le rafraîchissement du FutureBuilder
  int _refreshKey = 0;

  void _refreshProfile() {
    if (mounted) {
      setState(() {
        _refreshKey++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mon Profil'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Aucun utilisateur connecté'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              ).then((_) => _refreshProfile()); // Rafraîchir après retour des paramètres
            },
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        key: ValueKey(_refreshKey), // Utiliser la clé pour forcer le rafraîchissement
        future: FirestoreService().getUser(currentUser.uid),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final userData = snapshot.data;

          if (userData == null) {
            return const Center(
              child: Text('Aucune donnée utilisateur trouvée'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFF77F00),
                        const Color(0xFFF77F00).withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          _getInitials(userData.nom),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF77F00),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData.nom,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData.fonction,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              userData.isVerified
                                  ? Icons.verified_user
                                  : Icons.pending,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              userData.isVerified
                                  ? 'Profil vérifié'
                                  : 'En attente de vérification',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        'Informations personnelles',
                        [
                          // Matricule uniquement pour les admins
                          if (userData.isAdmin)
                            _buildInfoRow(Icons.badge, 'Matricule', userData.matricule),
                          _buildInfoRow(Icons.email, 'Email', userData.email),
                          if (userData.telephones.isNotEmpty)
                            _buildInfoRow(Icons.phone, 'Téléphone', userData.telephones.first),
                          if (userData.dren != null)
                            _buildInfoRow(Icons.location_city, 'DREN', userData.dren!),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        'Zones',
                        [
                          _buildInfoRow(Icons.location_on, 'Zone actuelle', userData.zoneActuelle),
                          if (userData.zonesSouhaitees.isNotEmpty)
                            _buildInfoRow(
                              Icons.location_searching,
                              'Zones souhaitées',
                              userData.zonesSouhaitees.join(', '),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMenuList(context),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.isEmpty) return '??';
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFF77F00)),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMenuList(BuildContext context) {
    return Container(
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
        children: [
          _buildMenuItem(
            Icons.account_circle_outlined,
            'Mes informations complètes',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserInfoPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            Icons.privacy_tip_outlined,
            'Confidentialité',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacySettingsPage(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            Icons.logout,
            'Déconnexion',
            () async {
              // Afficher un dialogue de confirmation
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Déconnexion'),
                    ],
                  ),
                  content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              }
            },
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    dynamic onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFFF77F00)),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}
