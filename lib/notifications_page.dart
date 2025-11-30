import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/models/notification_model.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/profile_detail_page.dart';
import 'package:myapp/teacher_candidate/job_offers_list_page.dart';
import 'package:myapp/school/my_job_offers_page.dart';
import 'package:myapp/chat_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter =
      'all'; // all, unread, message, application, offer, favorite, system
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Configurer timeago en français
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filtrer les notifications selon le filtre sélectionné et la recherche
  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
  ) {
    var filtered = notifications;

    // Filtrer par type
    if (_selectedFilter != 'all') {
      if (_selectedFilter == 'unread') {
        filtered = filtered.where((n) => !n.isRead).toList();
      } else {
        filtered = filtered.where((n) => n.type == _selectedFilter).toList();
      }
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((n) {
        return n.title.toLowerCase().contains(query) ||
            n.message.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: const Color(0xFFF77F00),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Vous devez être connecté pour voir les notifications'),
        ),
      );
    }

    // Variable locale non-nullable pour éviter les avertissements
    final currentUser = _currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Marquer tout comme lu
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Tout marquer comme lu',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await _notificationService.markAllAsRead(currentUser.uid);
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Toutes les notifications sont marquées comme lues',
                    ),
                    backgroundColor: Color(0xFF009E60),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          // Menu options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'delete_all') {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer toutes les notifications'),
                    content: const Text(
                      'Êtes-vous sûr de vouloir supprimer toutes vos notifications ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    await _notificationService.deleteAllNotifications(
                      currentUser.uid,
                    );
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Toutes les notifications ont été supprimées',
                        ),
                        backgroundColor: Color(0xFF009E60),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Tout supprimer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher dans les notifications...',
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filtres par onglets
          Container(
            height: 50,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildFilterChip('Tout', 'all', Icons.inbox),
                _buildFilterChip(
                  'Non lus',
                  'unread',
                  Icons.circle_notifications,
                ),
                _buildFilterChip('Messages', 'message', Icons.message),
                _buildFilterChip('Candidatures', 'application', Icons.work),
                _buildFilterChip('Offres', 'offer', Icons.business_center),
                _buildFilterChip('Favoris', 'favorite', Icons.favorite),
                _buildFilterChip('Système', 'system', Icons.info),
              ],
            ),
          ),

          const Divider(height: 1),

          // Liste des notifications
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.streamUserNotifications(
                currentUser.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF77F00)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final allNotifications = snapshot.data ?? [];

                // Appliquer les filtres
                final notifications = _filterNotifications(allNotifications);

                if (allNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune notification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vous serez notifié ici des nouvelles activités',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun résultat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune notification ne correspond à vos critères',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construire un chip de filtre
  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFFF77F00),
            ),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: const Color(0xFFF77F00),
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFFF77F00) : Colors.transparent,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final color = Color(NotificationModel.getColorForType(notification.type));
    final icon = NotificationModel.getIconDataForType(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        try {
          await _notificationService.deleteNotification(notification.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification supprimée'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: notification.isRead ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.isRead
                ? Colors.grey.shade200
                : color.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await _notificationService.markAsRead(notification.id);
            }

            // Navigation selon le type de notification
            if (!mounted) return;

            switch (notification.type) {
              case 'application':
                // Navigation vers les offres d'emploi pour les écoles
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyJobOffersPage(),
                  ),
                );
                break;

              case 'offer':
                // Navigation vers la liste des offres pour les candidats
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JobOffersListPage(),
                  ),
                );
                break;

              case 'match':
              case 'favorite':
                // Navigation vers le profil si toutes les données sont fournies
                final profileId = notification.data?['profileId'] as String?;
                final name = notification.data?['name'] as String?;
                final fonction = notification.data?['fonction'] as String?;
                final zoneActuelle =
                    notification.data?['zoneActuelle'] as String?;
                final zoneSouhaitee =
                    notification.data?['zoneSouhaitee'] as String?;
                final isOnline = notification.data?['isOnline'] as bool?;

                if (profileId != null &&
                    name != null &&
                    fonction != null &&
                    zoneActuelle != null &&
                    zoneSouhaitee != null &&
                    isOnline != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileDetailPage(userId: profileId),
                    ),
                  );
                } else {
                  // Si les données ne sont pas complètes, afficher un message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informations du profil incomplètes'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                break;

              case 'message':
                // Navigation vers la page de chat si les données du contact sont fournies
                final contactId = notification.data?['contactId'] as String?;
                final contactName =
                    notification.data?['contactName'] as String?;
                final contactFunction =
                    notification.data?['contactFunction'] as String?;
                final isOnline =
                    notification.data?['isOnline'] as bool? ?? false;

                if (contactId != null &&
                    contactName != null &&
                    contactFunction != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        contactName: contactName,
                        contactFunction: contactFunction,
                        isOnline: isOnline,
                        contactUserId: contactId,
                      ),
                    ),
                  );
                } else {
                  // Si les données ne sont pas complètes, naviguer vers la liste des messages
                  // La MessagesPage est dans home_screen.dart, on ne peut pas y naviguer directement
                  // On affiche un message pour aller dans l'onglet Messages
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Veuillez consulter l\'onglet Messages pour voir vos conversations',
                      ),
                      backgroundColor: Color(0xFF2196F3),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
                break;

              case 'system':
                // Les notifications système n'ont généralement pas d'action
                break;

              default:
                break;
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.white
                  : color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeago.format(notification.createdAt, locale: 'fr'),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
