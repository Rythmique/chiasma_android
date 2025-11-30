import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String userId; // Destinataire
  final String
  type; // 'message', 'match', 'favorite', 'application', 'offer', 'system'
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String createdBy; // Créateur de la notification (pour sécurité)
  final String?
  relatedId; // ID de l'entité liée (offre, candidature, message, etc.)
  final Map<String, dynamic>?
  data; // Données supplémentaires (ex: profileId, offerId, etc.)

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.createdBy,
    this.isRead = false,
    this.relatedId,
    this.data,
  });

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'createdBy': createdBy,
      'relatedId': relatedId,
      'data': data,
    };
  }

  // Créer depuis Firestore
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'system',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      createdBy: data['createdBy'] ?? '',
      relatedId: data['relatedId'],
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  // Copier avec modifications
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? createdBy,
    String? relatedId,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      createdBy: createdBy ?? this.createdBy,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
    );
  }

  // Helper pour obtenir config selon le type (icône et couleur)
  static (IconData, int) _getTypeConfig(String type) {
    switch (type) {
      case 'message':
        return (Icons.message, 0xFF2196F3); // Bleu
      case 'match':
        return (Icons.people, 0xFFE91E63); // Rose
      case 'favorite':
        return (Icons.favorite, 0xFFFF5252); // Rouge
      case 'application':
        return (Icons.work, 0xFF009E60); // Vert
      case 'offer':
        return (Icons.business_center, 0xFFF77F00); // Orange
      case 'system':
        return (Icons.notifications, 0xFF9C27B0); // Violet
      default:
        return (Icons.notifications, 0xFF757575); // Gris
    }
  }

  // Obtenir l'icône selon le type
  static IconData getIconDataForType(String type) => _getTypeConfig(type).$1;

  // Obtenir la couleur selon le type
  static int getColorForType(String type) => _getTypeConfig(type).$2;
}
