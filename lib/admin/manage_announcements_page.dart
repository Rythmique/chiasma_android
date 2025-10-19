import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

/// Page de gestion des annonces (admin)
class ManageAnnouncementsPage extends StatefulWidget {
  const ManageAnnouncementsPage({super.key});

  @override
  State<ManageAnnouncementsPage> createState() => _ManageAnnouncementsPageState();
}

class _ManageAnnouncementsPageState extends State<ManageAnnouncementsPage> {
  final AnnouncementService _announcementService = AnnouncementService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des annonces'),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Nettoyer les annonces expirées',
            onPressed: _cleanExpiredAnnouncements,
          ),
        ],
      ),
      body: StreamBuilder<List<AnnouncementModel>>(
        stream: _announcementService.streamAllAnnouncements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          final announcements = snapshot.data ?? [];

          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune annonce',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre première annonce',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              return _buildAnnouncementCard(announcements[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAnnouncementDialog(),
        backgroundColor: const Color(0xFFF77F00),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle annonce'),
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    final color = Color(AnnouncementModel.getColorForType(announcement.type));
    final isExpired = announcement.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconData(
                    AnnouncementModel.getIconForType(announcement.type),
                    fontFamily: 'MaterialIcons',
                  ),
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        announcement.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badges de statut
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: announcement.isActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        announcement.isActive ? 'ACTIF' : 'INACTIF',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isExpired) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'EXPIRÉ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.message,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Ciblage
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: announcement.targetAccounts.map((account) {
                    return Chip(
                      label: Text(_getAccountLabel(account)),
                      backgroundColor: const Color(0xFF009E60).withValues(alpha: 0.1),
                      side: const BorderSide(color: Color(0xFF009E60)),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF009E60),
                        fontWeight: FontWeight.w600,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Métadonnées
                Row(
                  children: [
                    Icon(Icons.priority_high, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Priorité: ${announcement.priorityLabel}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    if (announcement.expiresAt != null) ...[
                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Expire: ${_formatDate(announcement.expiresAt!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _toggleStatus(announcement),
                icon: Icon(
                  announcement.isActive ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                ),
                label: Text(announcement.isActive ? 'Désactiver' : 'Activer'),
              ),
              TextButton.icon(
                onPressed: () => _showEditAnnouncementDialog(announcement),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Modifier'),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(announcement),
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateAnnouncementDialog() {
    _showAnnouncementDialog(null);
  }

  void _showEditAnnouncementDialog(AnnouncementModel announcement) {
    _showAnnouncementDialog(announcement);
  }

  void _showAnnouncementDialog(AnnouncementModel? announcement) {
    final isEdit = announcement != null;
    final titleController = TextEditingController(text: announcement?.title ?? '');
    final messageController = TextEditingController(text: announcement?.message ?? '');
    final actionUrlController = TextEditingController(text: announcement?.actionUrl ?? '');
    final actionLabelController = TextEditingController(text: announcement?.actionLabel ?? '');

    String selectedType = announcement?.type ?? 'info';
    List<String> selectedAccounts = List.from(announcement?.targetAccounts ?? ['all']);
    int selectedPriority = announcement?.priority ?? 1;
    DateTime? expiresAt = announcement?.expiresAt;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Modifier l\'annonce' : 'Nouvelle annonce'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),

                // Type
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'info', child: Text('Information')),
                    DropdownMenuItem(value: 'warning', child: Text('Avertissement')),
                    DropdownMenuItem(value: 'success', child: Text('Succès')),
                    DropdownMenuItem(value: 'error', child: Text('Erreur')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedType = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Priorité
                DropdownButtonFormField<int>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priorité',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Faible')),
                    DropdownMenuItem(value: 1, child: Text('Normal')),
                    DropdownMenuItem(value: 2, child: Text('Élevé')),
                    DropdownMenuItem(value: 3, child: Text('Urgent')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedPriority = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Ciblage
                const Text('Diffuser vers:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Tous les comptes'),
                  value: selectedAccounts.contains('all'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedAccounts = ['all'];
                      } else {
                        selectedAccounts.remove('all');
                      }
                    });
                  },
                ),
                if (!selectedAccounts.contains('all')) ...[
                  CheckboxListTile(
                    title: const Text('Enseignants (Permutation)'),
                    value: selectedAccounts.contains('teacher_transfer'),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedAccounts.add('teacher_transfer');
                        } else {
                          selectedAccounts.remove('teacher_transfer');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Candidats enseignants'),
                    value: selectedAccounts.contains('teacher_candidate'),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedAccounts.add('teacher_candidate');
                        } else {
                          selectedAccounts.remove('teacher_candidate');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Établissements scolaires'),
                    value: selectedAccounts.contains('school'),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedAccounts.add('school');
                        } else {
                          selectedAccounts.remove('school');
                        }
                      });
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Date d'expiration
                ListTile(
                  title: const Text('Date d\'expiration'),
                  subtitle: Text(
                    expiresAt != null ? _formatDate(expiresAt!) : 'Aucune',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: expiresAt ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() => expiresAt = date);
                          }
                        },
                      ),
                      if (expiresAt != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => expiresAt = null);
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action (optionnel)
                TextField(
                  controller: actionLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Libellé du bouton (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: actionUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL d\'action (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || messageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le titre et le message sont obligatoires'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedAccounts.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner au moins un type de compte'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) return;

                  if (isEdit) {
                    await _announcementService.updateAnnouncement(
                      announcement.id,
                      {
                        'title': titleController.text,
                        'message': messageController.text,
                        'type': selectedType,
                        'targetAccounts': selectedAccounts,
                        'priority': selectedPriority,
                        'expiresAt': expiresAt != null
                            ? Timestamp.fromDate(expiresAt!)
                            : null,
                        'actionUrl': actionUrlController.text.isNotEmpty
                            ? actionUrlController.text
                            : null,
                        'actionLabel': actionLabelController.text.isNotEmpty
                            ? actionLabelController.text
                            : null,
                      },
                    );
                  } else {
                    final newAnnouncement = AnnouncementModel(
                      id: '',
                      title: titleController.text,
                      message: messageController.text,
                      type: selectedType,
                      targetAccounts: selectedAccounts,
                      createdAt: DateTime.now(),
                      expiresAt: expiresAt,
                      actionUrl: actionUrlController.text.isNotEmpty
                          ? actionUrlController.text
                          : null,
                      actionLabel: actionLabelController.text.isNotEmpty
                          ? actionLabelController.text
                          : null,
                      createdBy: currentUser.uid,
                      priority: selectedPriority,
                    );

                    await _announcementService.createAnnouncement(newAnnouncement);
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Annonce modifiée avec succès'
                              : 'Annonce créée avec succès',
                        ),
                        backgroundColor: Colors.green,
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF77F00),
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Modifier' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(AnnouncementModel announcement) async {
    try {
      await _announcementService.toggleAnnouncementStatus(
        announcement.id,
        !announcement.isActive,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              announcement.isActive
                  ? 'Annonce désactivée'
                  : 'Annonce activée',
            ),
            backgroundColor: Colors.green,
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

  Future<void> _confirmDelete(AnnouncementModel announcement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer l\'annonce "${announcement.title}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _announcementService.deleteAnnouncement(announcement.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Annonce supprimée'),
              backgroundColor: Colors.green,
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
  }

  Future<void> _cleanExpiredAnnouncements() async {
    try {
      final count = await _announcementService.cleanExpiredAnnouncements();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count annonce(s) expirée(s) nettoyée(s)'),
            backgroundColor: Colors.green,
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

  String _getAccountLabel(String account) {
    switch (account) {
      case 'all':
        return 'Tous';
      case 'teacher_transfer':
        return 'Enseignants';
      case 'teacher_candidate':
        return 'Candidats';
      case 'school':
        return 'Établissements';
      default:
        return account;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
