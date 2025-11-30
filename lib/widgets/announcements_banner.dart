import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

/// Widget pour afficher les annonces sous forme de bannière
class AnnouncementsBanner extends StatelessWidget {
  static const _borderRadius = 12.0;
  static const _maxAnnouncementsToShow = 3;

  final String accountType;

  const AnnouncementsBanner({super.key, required this.accountType});

  @override
  Widget build(BuildContext context) {
    final announcementService = AnnouncementService();

    return StreamBuilder<List<AnnouncementModel>>(
      stream: announcementService.streamActiveAnnouncementsForAccount(
        accountType,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final announcements = snapshot.data!;

        return Column(
          children: announcements
              .take(_maxAnnouncementsToShow)
              .map(
                (announcement) => _buildAnnouncementCard(context, announcement),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    AnnouncementModel announcement,
  ) {
    final color = Color(AnnouncementModel.getColorForType(announcement.type));
    final iconData = AnnouncementModel.getIconDataForType(announcement.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(color, iconData, announcement),
          _buildContent(color, announcement),
        ],
      ),
    );
  }

  Widget _buildHeader(
    Color color,
    IconData iconData,
    AnnouncementModel announcement,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_borderRadius),
          topRight: Radius.circular(_borderRadius),
        ),
      ),
      child: Row(
        children: [
          Icon(iconData, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              announcement.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          if (announcement.priority >= 2)
            _buildPriorityBadge(color, announcement.priority),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(Color color, int priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: Text(
        priority == 3 ? 'URGENT' : 'IMPORTANT',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildContent(Color color, AnnouncementModel announcement) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            announcement.message,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          if (announcement.actionUrl != null &&
              announcement.actionLabel != null) ...[
            const SizedBox(height: 12),
            _buildActionButton(color, announcement),
          ],
          if (announcement.expiresAt != null) ...[
            const SizedBox(height: 8),
            _buildExpirationInfo(announcement.expiresAt!),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(Color color, AnnouncementModel announcement) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _launchUrl(announcement.actionUrl!),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(announcement.actionLabel!),
      ),
    );
  }

  Widget _buildExpirationInfo(DateTime expiresAt) {
    return Row(
      children: [
        Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          'Expire le ${_formatDate(expiresAt)}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Widget compact pour afficher les annonces dans un carrousel
class AnnouncementsCarousel extends StatelessWidget {
  static const _borderRadius = 12.0;
  static const _carouselHeight = 100.0;
  static const _cardWidth = 280.0;

  final String accountType;

  const AnnouncementsCarousel({super.key, required this.accountType});

  @override
  Widget build(BuildContext context) {
    final announcementService = AnnouncementService();

    return StreamBuilder<List<AnnouncementModel>>(
      stream: announcementService.streamActiveAnnouncementsForAccount(
        accountType,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final announcements = snapshot.data!;

        return SizedBox(
          height: _carouselHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: announcements.length,
            itemBuilder: (context, index) =>
                _buildCarouselCard(announcements[index]),
          ),
        );
      },
    );
  }

  Widget _buildCarouselCard(AnnouncementModel announcement) {
    final color = Color(AnnouncementModel.getColorForType(announcement.type));
    final iconData = AnnouncementModel.getIconDataForType(announcement.type);

    return Container(
      width: _cardWidth,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(iconData, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  announcement.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              announcement.message,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
