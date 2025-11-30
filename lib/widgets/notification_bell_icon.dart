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
  static const _updateInterval = Duration(milliseconds: 500);
  static const _maxDisplayCount = 99;
  static const _badgeSize = 18.0;

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

    return StreamBuilder<int>(
      stream: _getCombinedUnreadCount(currentUser.uid),
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
            if (unreadCount > 0) _buildBadge(unreadCount),
          ],
        );
      },
    );
  }

  Widget _buildBadge(int count) {
    return Positioned(
      right: 8,
      top: 8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: _badgeSize,
          minHeight: _badgeSize,
        ),
        child: Text(
          count > _maxDisplayCount ? '$_maxDisplayCount+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Combine le comptage des notifications non lues et des messages non lus
  Stream<int> _getCombinedUnreadCount(String userId) {
    final firestoreService = FirestoreService();
    final notificationService = NotificationService();

    return Stream.periodic(_updateInterval).asyncMap((_) async {
      final results = await Future.wait([
        notificationService.streamUnreadCount(userId).first,
        firestoreService.getTotalUnreadMessagesCount(userId).first,
      ]);
      return results[0] + results[1];
    });
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsPage()),
    );
  }
}
