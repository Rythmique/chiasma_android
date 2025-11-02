import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../notifications_page.dart';

/// Widget de cloche de notifications avec badge de comptage
///
/// Affiche une icône de cloche avec un badge indiquant:
/// - Le nombre de notifications non lues
/// - Le nombre de messages non lus
/// Le total est affiché sur le badge
class NotificationBellIcon extends StatelessWidget {
  const NotificationBellIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => _navigateToNotifications(context),
      );
    }

    final firestoreService = FirestoreService();
    final notificationService = NotificationService();

    return StreamBuilder<int>(
      stream: _getCombinedUnreadCount(
        currentUser.uid,
        firestoreService,
        notificationService,
      ),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                unreadCount > 0
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
              ),
              onPressed: () => _navigateToNotifications(context),
              tooltip: 'Notifications',
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
                    unreadCount > 99 ? '99+' : '$unreadCount',
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
    );
  }

  /// Combine le comptage des notifications non lues et des messages non lus
  Stream<int> _getCombinedUnreadCount(
    String userId,
    FirestoreService firestoreService,
    NotificationService notificationService,
  ) {
    return Stream.periodic(const Duration(milliseconds: 500)).asyncMap((_) async {
      // Compter les notifications non lues
      final notificationsCount = await notificationService
          .streamUnreadCount(userId)
          .first;

      // Compter les messages non lus
      final messagesCount = await firestoreService
          .getTotalUnreadMessagesCount(userId)
          .first;

      return notificationsCount + messagesCount;
    });
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );
  }
}
