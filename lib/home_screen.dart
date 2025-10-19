import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/profile_detail_page.dart';
import 'package:myapp/chat_page.dart';
import 'package:myapp/settings_page.dart';
import 'package:myapp/subscription_page.dart';
import 'package:myapp/notifications_page.dart';
import 'package:myapp/user_info_page.dart';
import 'package:myapp/privacy_settings_page.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/widgets/announcements_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final Set<int> _favoriteProfiles = {}; // Shared favorites state

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SearchPage(
        favoriteProfiles: _favoriteProfiles,
        onFavoriteToggle: () => setState(() {}),
      ),
      FavoritesPage(
        favoriteProfiles: _favoriteProfiles,
        onFavoriteToggle: () => setState(() {}),
      ),
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
  final Set<int> favoriteProfiles;
  final VoidCallback onFavoriteToggle;

  const SearchPage({
    super.key,
    required this.favoriteProfiles,
    required this.onFavoriteToggle,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _selectedSearchMode = 'zone_actuelle'; // Par défaut: Par Zone Actuelle
  final int _freeViewsRemaining = 5; // Compteur de consultations gratuites
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Données de l'utilisateur connecté (pour le match mutuel)
  final Map<String, dynamic> _currentUser = {
    'zoneActuelle': 'Abidjan, Cocody',
    'zoneSouhaitee': 'Yamoussoukro',
    'fonction': 'Professeur de Mathématiques',
    'dren': 'Abidjan 1',
  };

  // Liste de profils fictifs avec données de recherche
  final List<Map<String, dynamic>> _allProfiles = [
    {
      'userId': 'mock_user_1',
      'name': 'Jean Kouassi',
      'fonction': 'Professeur de Mathématiques',
      'zoneActuelle': 'Abidjan, Cocody',
      'zoneSouhaitee': 'Yamoussoukro',
      'dren': 'Abidjan 1',
      'isOnline': true,
    },
    {
      'userId': 'mock_user_2',
      'name': 'Marie Koné',
      'fonction': 'Professeur de Français',
      'zoneActuelle': 'Bouaké, Centre',
      'zoneSouhaitee': 'Abidjan, Plateau',
      'dren': 'Bouaké',
      'isOnline': false,
    },
    {
      'userId': 'mock_user_3',
      'name': 'Paul Diabaté',
      'fonction': 'Professeur d\'Anglais',
      'zoneActuelle': 'Daloa, Ouest',
      'zoneSouhaitee': 'San-Pedro',
      'dren': 'Daloa',
      'isOnline': true,
    },
    {
      'userId': 'mock_user_4',
      'name': 'Aminata Traoré',
      'fonction': 'Directeur d\'école',
      'zoneActuelle': 'Yamoussoukro',
      'zoneSouhaitee': 'Abidjan, Cocody',
      'dren': 'Yamoussoukro',
      'isOnline': false,
    },
    {
      'userId': 'mock_user_5',
      'name': 'Koffi Yao',
      'fonction': 'Censeur',
      'zoneActuelle': 'Man, Montagnes',
      'zoneSouhaitee': 'Bouaké',
      'dren': 'Man',
      'isOnline': true,
    },
    {
      'userId': 'mock_user_6',
      'name': 'Adjoua Bamba',
      'fonction': 'Professeur de Mathématiques',
      'zoneActuelle': 'Korhogo, Nord',
      'zoneSouhaitee': 'Abidjan, Yopougon',
      'dren': 'Korhogo',
      'isOnline': false,
    },
    {
      'userId': 'mock_user_7',
      'name': 'Ibrahim Sangaré',
      'fonction': 'Professeur de Physique',
      'zoneActuelle': 'Abidjan, Abobo',
      'zoneSouhaitee': 'Daloa',
      'dren': 'Abidjan 2',
      'isOnline': true,
    },
    {
      'userId': 'mock_user_8',
      'name': 'Aya N\'Guessan',
      'fonction': 'Professeur d\'Histoire',
      'zoneActuelle': 'San-Pedro',
      'zoneSouhaitee': 'Abidjan, Cocody',
      'dren': 'San-Pedro',
      'isOnline': false,
    },
    {
      'userId': 'mock_user_9',
      'name': 'Serge Ouattara',
      'fonction': 'Professeur de SVT',
      'zoneActuelle': 'Gagnoa, Centre-Ouest',
      'zoneSouhaitee': 'Yamoussoukro',
      'dren': 'Gagnoa',
      'isOnline': true,
    },
    {
      'userId': 'mock_user_10',
      'name': 'Fatou Diallo',
      'fonction': 'Professeur d\'Espagnol',
      'zoneActuelle': 'Abidjan, Marcory',
      'zoneSouhaitee': 'Bouaké',
      'dren': 'Abidjan 3',
      'isOnline': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Map<String, dynamic>> get _filteredProfiles {
    // Mode Match Mutuel : recherche automatique
    if (_selectedSearchMode == 'match_mutuel') {
      return _allProfiles.where((profile) {
        // Match mutuel = la zone souhaitée de l'utilisateur correspond à la zone actuelle du profil
        // ET la zone actuelle de l'utilisateur correspond à la zone souhaitée du profil
        return profile['zoneActuelle'] == _currentUser['zoneSouhaitee'] &&
               profile['zoneSouhaitee'] == _currentUser['zoneActuelle'];
      }).toList();
    }

    // Si pas de recherche, retourner tous les profils
    if (_searchQuery.isEmpty) {
      return _allProfiles;
    }

    final query = _searchQuery.toLowerCase();

    // Filtrer selon le mode de recherche sélectionné
    switch (_selectedSearchMode) {
      case 'zone_actuelle':
        return _allProfiles.where((profile) {
          return profile['zoneActuelle'].toString().toLowerCase().contains(query);
        }).toList();

      case 'zone_souhaitee':
        return _allProfiles.where((profile) {
          return profile['zoneSouhaitee'].toString().toLowerCase().contains(query);
        }).toList();

      case 'fonction':
        return _allProfiles.where((profile) {
          return profile['fonction'].toString().toLowerCase().contains(query);
        }).toList();

      case 'dren':
        return _allProfiles.where((profile) {
          return profile['dren'].toString().toLowerCase().contains(query);
        }).toList();

      default:
        return _allProfiles;
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
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'CHIASMA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
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
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Consultations gratuites : $_freeViewsRemaining/5',
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

          // Bannière d'annonces système
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF009E60).withValues(alpha: 0.1),
                    const Color(0xFFF77F00).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF77F00).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF77F00).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.campaign,
                      color: Color(0xFFF77F00),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouveauté',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Messagerie instantanée maintenant disponible !',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
          _filteredProfiles.isEmpty
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

  Widget _buildProfileCard(Map<String, dynamic> profile, int index) {
    final userId = profile['userId'] as String;
    final isOnline = profile['isOnline'] as bool;
    final name = profile['name'] as String;
    final fonction = profile['fonction'] as String;
    final zoneActuelle = profile['zoneActuelle'] as String;
    final zoneSouhaitee = profile['zoneSouhaitee'] as String;

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
                  widget.favoriteProfiles.contains(index) ? Icons.favorite : Icons.favorite_border,
                  color: widget.favoriteProfiles.contains(index) ? Colors.red : Colors.grey[400],
                ),
                onPressed: () {
                  setState(() {
                    if (widget.favoriteProfiles.contains(index)) {
                      widget.favoriteProfiles.remove(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retiré des favoris'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } else {
                      widget.favoriteProfiles.add(index);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ajouté aux favoris'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Color(0xFF009E60),
                        ),
                      );
                    }
                  });
                  widget.onFavoriteToggle();
                },
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileDetailPage(
                          userId: userId,
                          name: name,
                          fonction: fonction,
                          zoneActuelle: zoneActuelle,
                          zoneSouhaitee: zoneSouhaitee,
                          isOnline: isOnline,
                        ),
                      ),
                    );
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          contactName: name,
                          contactFunction: fonction,
                          isOnline: isOnline,
                        ),
                      ),
                    );
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
  final Set<int> favoriteProfiles;
  final VoidCallback onFavoriteToggle;

  const FavoritesPage({
    super.key,
    required this.favoriteProfiles,
    required this.onFavoriteToggle,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: widget.favoriteProfiles.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.favoriteProfiles.length,
              itemBuilder: (context, index) {
                final profileIndex = widget.favoriteProfiles.elementAt(index);
                return _buildFavoriteProfileCard(context, profileIndex);
              },
            ),
    );
  }

  Widget _buildFavoriteProfileCard(BuildContext context, int index) {
    final isOnline = index % 3 == 0;
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
                      'AB',
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
                        Text(
                          'Enseignant ${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Professeur de Mathématiques',
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
                onPressed: () {
                  setState(() {
                    widget.favoriteProfiles.remove(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Retiré des favoris'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  });
                  widget.onFavoriteToggle();
                },
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
                          const Text(
                            'Abidjan, Cocody',
                            style: TextStyle(
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
                          const Text(
                            'Yamoussoukro',
                            style: TextStyle(
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileDetailPage(
                          userId: 'mock_match_user_${index + 1}',
                          name: 'Enseignant ${index + 1}',
                          fonction: 'Professeur de Mathématiques',
                          zoneActuelle: 'Abidjan, Cocody',
                          zoneSouhaitee: 'Yamoussoukro',
                          isOnline: isOnline,
                        ),
                      ),
                    );
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          contactName: 'Enseignant ${index + 1}',
                          contactFunction: 'Professeur de Mathématiques',
                          isOnline: isOnline,
                        ),
                      ),
                    );
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
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        itemCount: 3,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final hasUnread = index == 0;
          return ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFF77F00).withValues(alpha: 0.2),
                  child: Text(
                    'E${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFF77F00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (index == 0)
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
                Text(
                  'Enseignant ${index + 1}',
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
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
                    child: const Text(
                      '2',
                      style: TextStyle(
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
              'Bonjour, je suis intéressé par une permutation...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            trailing: Text(
              index == 0 ? 'Il y a 5 min' : 'Il y a ${index}h',
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
                    contactName: 'Enseignant ${index + 1}',
                    contactFunction: 'Professeur',
                    isOnline: index == 0,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Nouveau message
        },
        backgroundColor: const Color(0xFFF77F00),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

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
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
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
                      _buildActionCard(
                        context,
                        'Abonnement',
                        'Compte Gratuit',
                        'Passez au premium pour des fonctionnalités illimitées',
                        Icons.workspace_premium,
                        const Color(0xFF009E60),
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

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    String description,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SubscriptionPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
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
