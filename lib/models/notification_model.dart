import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String userId; // Destinataire
  final String type; // 'message', 'match', 'favorite', 'application', 'offer', 'system'
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data; // Données supplémentaires (ex: profileId, offerId, etc.)

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
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
      data: data ?? this.data,
    );
  }

  // Obtenir l'icône selon le type
  static IconData getIconDataForType(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'match':
        return Icons.people;
      case 'favorite':
        return Icons.favorite;
      case 'application':
        return Icons.work;
      case 'offer':
        return Icons.business_center;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  // Obtenir la couleur selon le type
  static int getColorForType(String type) {
    switch (type) {
      case 'message':
        return 0xFF2196F3; // Bleu
      case 'match':
        return 0xFFE91E63; // Rose
      case 'favorite':
        return 0xFFFF5252; // Rouge
      case 'application':
        return 0xFF009E60; // Vert
      case 'offer':
        return 0xFFF77F00; // Orange
      case 'system':
        return 0xFF9C27B0; // Violet
      default:
        return 0xFF757575; // Gris
    }
  }
}
