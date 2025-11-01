import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modèle pour une annonce
class AnnouncementModel {
  final String id;
  final String title;              // Titre de l'annonce
  final String message;            // Contenu du message
  final String type;               // Type: 'info', 'warning', 'success', 'error'
  final List<String> targetAccounts; // Types de comptes ciblés: 'teacher_transfer', 'teacher_candidate', 'school', 'all'
  final DateTime createdAt;
  final DateTime? expiresAt;       // Date d'expiration (optionnel)
  final bool isActive;             // Actif ou non
  final String? actionUrl;         // URL d'action (optionnel)
  final String? actionLabel;       // Libellé du bouton d'action (optionnel)
  final String createdBy;          // ID de l'admin qui a créé l'annonce
  final int priority;              // Priorité d'affichage (0 = faible, 1 = normal, 2 = élevé, 3 = urgent)

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'info',
    required this.targetAccounts,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.actionUrl,
    this.actionLabel,
    required this.createdBy,
    this.priority = 1,
  });

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'targetAccounts': targetAccounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'actionUrl': actionUrl,
      'actionLabel': actionLabel,
      'createdBy': createdBy,
      'priority': priority,
    };
  }

  /// Créer depuis un document Firestore
  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'info',
      targetAccounts: List<String>.from(data['targetAccounts'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      actionUrl: data['actionUrl'],
      actionLabel: data['actionLabel'],
      createdBy: data['createdBy'] ?? '',
      priority: data['priority'] ?? 1,
    );
  }

  /// Copier avec modifications
  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    List<String>? targetAccounts,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    String? actionUrl,
    String? actionLabel,
    String? createdBy,
    int? priority,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      targetAccounts: targetAccounts ?? this.targetAccounts,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      createdBy: createdBy ?? this.createdBy,
      priority: priority ?? this.priority,
    );
  }

  /// Vérifier si l'annonce est expirée
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Vérifier si l'annonce est visible
  bool get isVisible => isActive && !isExpired;

  /// Obtenir la couleur selon le type
  static int getColorForType(String type) {
    switch (type) {
      case 'info':
        return 0xFF2196F3; // Bleu
      case 'warning':
        return 0xFFFFA726; // Orange
      case 'success':
        return 0xFF66BB6A; // Vert
      case 'error':
        return 0xFFEF5350; // Rouge
      default:
        return 0xFF2196F3;
    }
  }

  /// Obtenir l'icône selon le type
  static IconData getIconDataForType(String type) {
    switch (type) {
      case 'info':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  /// Obtenir le libellé de priorité
  String get priorityLabel {
    switch (priority) {
      case 0:
        return 'Faible';
      case 1:
        return 'Normal';
      case 2:
        return 'Élevé';
      case 3:
        return 'Urgent';
      default:
        return 'Normal';
    }
  }
}
