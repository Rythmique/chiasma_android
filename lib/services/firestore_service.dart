import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/notification_service.dart';
import 'package:myapp/services/firestore_error_handler.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _messagesCollection =>
      _firestore.collection('messages');
  CollectionReference get _favoritesCollection =>
      _firestore.collection('favorites');
  CollectionReference get _profileViewsCollection =>
      _firestore.collection('profile_views');

  // ========== USERS ==========

  // Créer un utilisateur
  Future<void> createUser(UserModel user) async {
    return FirestoreErrorHandler.handleOperation(() async {
      await _usersCollection.doc(user.uid).set(user.toMap());
    });
  }

  // Récupérer un utilisateur par UID
  Future<UserModel?> getUser(String uid) async {
    return FirestoreErrorHandler.handleOperation(() async {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Stream d'un utilisateur spécifique (temps réel)
  Stream<UserModel?> getUserStream(String uid) {
    return FirestoreErrorHandler.handleStream(
      _usersCollection.doc(uid).snapshots().map((doc) {
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        }
        return null;
      }),
    );
  }

  // Vérifier si un matricule existe déjà
  Future<bool> checkMatriculeExists(String matricule) async {
    return FirestoreErrorHandler.handleOperation(() async {
      QuerySnapshot query = await _usersCollection
          .where('matricule', isEqualTo: matricule.toUpperCase())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    });
  }

  // Mettre à jour le statut en ligne
  Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    return FirestoreErrorHandler.handleOperation(() async {
      await _usersCollection.doc(uid).update({
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    return FirestoreErrorHandler.handleOperation(() async {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _usersCollection.doc(uid).update(data);
    });
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(String uid) async {
    return FirestoreErrorHandler.handleOperation(() async {
      await _usersCollection.doc(uid).delete();
    });
  }

  // ========== RECHERCHE ==========

  // Rechercher par zone actuelle
  Stream<List<UserModel>> searchByZoneActuelle(String zone) {
    return FirestoreErrorHandler.handleStream(
      _usersCollection
          .where('zoneActuelle', isGreaterThanOrEqualTo: zone)
          .where('zoneActuelle', isLessThanOrEqualTo: '$zone\uf8ff')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          ),
    );
  }

  // Rechercher par zone souhaitée
  Stream<List<UserModel>> searchByZoneSouhaitee(String zone) {
    return FirestoreErrorHandler.handleStream(
      _usersCollection
          .where('zonesSouhaitees', arrayContains: zone)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          ),
    );
  }

  // Rechercher par fonction
  Stream<List<UserModel>> searchByFonction(String fonction) {
    return FirestoreErrorHandler.handleStream(
      _usersCollection
          .where('fonction', isGreaterThanOrEqualTo: fonction)
          .where('fonction', isLessThanOrEqualTo: '$fonction\uf8ff')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          ),
    );
  }

  // Rechercher par DREN
  Stream<List<UserModel>> searchByDREN(String dren) {
    return FirestoreErrorHandler.handleStream(
      _usersCollection
          .where('dren', isGreaterThanOrEqualTo: dren)
          .where('dren', isLessThanOrEqualTo: '$dren\uf8ff')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          ),
    );
  }

  // Obtenir tous les utilisateurs (pour l'affichage initial)
  Stream<List<UserModel>> getAllUsers() {
    return FirestoreErrorHandler.handleStream(
      _usersCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList(),
          ),
    );
  }

  // Obtenir les utilisateurs filtrés par type de compte
  Stream<List<UserModel>> getUsersByAccountType(String accountType) {
    return FirestoreErrorHandler.handleStream(
      _usersCollection
          .where('accountType', isEqualTo: accountType)
          // Note: orderBy nécessite un index composite, temporairement désactivé
          // .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            // Trier en mémoire au lieu d'utiliser orderBy Firestore
            var users = snapshot.docs
                .map((doc) => UserModel.fromFirestore(doc))
                .toList();
            // Trier par date de création décroissante
            users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return users;
          }),
    );
  }

  // Obtenir les utilisateurs par type de compte avec pagination
  Future<Map<String, dynamic>> getUsersByAccountTypePaginated(
    String accountType, {
    required int limit,
    DocumentSnapshot? startAfterDocument,
  }) async {
    return FirestoreErrorHandler.handleOperation(() async {
      Query query = _usersCollection.where(
        'accountType',
        isEqualTo: accountType,
      );

      // Si on a un document de départ (pagination), commencer après
      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      // Limiter le nombre de résultats
      final snapshot = await query.limit(limit).get();

      // Convertir en UserModel
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // Trier en mémoire par date de création
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Retourner les utilisateurs et le dernier document pour la pagination
      return {
        'users': users,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      };
    });
  }

  // Obtenir tous les utilisateurs en stream (pour panneau admin)
  Stream<List<UserModel>> getAllUsersStream() {
    return getAllUsers();
  }

  // Obtenir tous les utilisateurs avec pagination
  Future<Map<String, dynamic>> getAllUsersPaginated({
    required int limit,
    DocumentSnapshot? startAfterDocument,
  }) async {
    return FirestoreErrorHandler.handleOperation(() async {
      Query query = _usersCollection;

      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      final snapshot = await query.limit(limit).get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return {
        'users': users,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      };
    });
  }

  // Mettre à jour le statut de vérification
  Future<void> updateUserVerificationStatus(String uid, bool isVerified) async {
    return FirestoreErrorHandler.handleOperation(() async {
      final updateData = <String, dynamic>{
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Si on retire la vérification, réinitialiser le quota au niveau initial
      if (!isVerified) {
        // Récupérer l'utilisateur pour connaître son type de compte
        final userDoc = await _usersCollection.doc(uid).get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          final accountType = data['accountType'] as String?;

          // Réinitialiser le quota selon le type de compte
          int initialQuota = 0;
          switch (accountType) {
            case 'school':
              initialQuota = 1; // 1 offre gratuite
              break;
            case 'teacher_transfer':
              initialQuota = 5; // 5 consultations gratuites
              break;
            case 'teacher_candidate':
              initialQuota = 2; // 2 candidatures gratuites
              break;
          }

          updateData['freeQuotaUsed'] = 0;
          updateData['freeQuotaLimit'] = initialQuota;
        }
      }

      await _usersCollection.doc(uid).update(updateData);
    });
  }

  // Mettre à jour le statut admin
  Future<void> updateUserAdminStatus(String uid, bool isAdmin) async {
    return FirestoreErrorHandler.handleOperation(() async {
      await _usersCollection.doc(uid).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // Recherche de match mutuel
  Future<List<UserModel>> searchMutualMatch({
    required String currentUserZoneActuelle,
    required List<String> currentUserZonesSouhaitees,
  }) async {
    return FirestoreErrorHandler.handleOperation(() async {
      List<UserModel> matches = [];

      for (String zoneSouhaitee in currentUserZonesSouhaitees) {
        QuerySnapshot query = await _usersCollection
            .where('zoneActuelle', isEqualTo: zoneSouhaitee)
            .where('zonesSouhaitees', arrayContains: currentUserZoneActuelle)
            .get();

        for (var doc in query.docs) {
          matches.add(UserModel.fromFirestore(doc));
        }
      }

      return matches;
    });
  }

  // ========== FAVORIS ==========

  // Ajouter un favori
  Future<void> addFavorite(String userId, String favoriteUserId) async {
    return FirestoreErrorHandler.handleOperation(() async {
      final favoriteId = '${userId}_$favoriteUserId';
      await _favoritesCollection.doc(favoriteId).set({
        'userId': userId,
        'favoriteUserId': favoriteUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Envoyer une notification au profil ajouté aux favoris
      try {
        // Récupérer le nom de l'utilisateur qui ajoute aux favoris
        final userDoc = await _usersCollection.doc(userId).get();
        final userData = userDoc.data() as Map<String, dynamic>?;
        final userName = userData?['nom'] ?? 'Un utilisateur';
        final userType = userData?['accountType'] ?? '';

        String notificationMessage;
        if (userType == 'school') {
          notificationMessage =
              'Un établissement scolaire a ajouté votre profil à ses favoris';
        } else {
          notificationMessage = '$userName a ajouté votre profil à ses favoris';
        }

        await _notificationService.sendNotification(
          userId: favoriteUserId,
          createdBy: userId,
          type: 'new_favorite',
          title: 'Nouveau favori',
          message: notificationMessage,
          relatedId: favoriteId,
          data: {'userId': userId, 'userName': userName, 'userType': userType},
        );
      } catch (e) {
        debugPrint('Erreur lors de l\'envoi de la notification de favori: $e');
      }
    });
  }

  // Retirer un favori
  Future<void> removeFavorite(String userId, String favoriteUserId) async {
    return FirestoreErrorHandler.handleOperation(() async {
      await _favoritesCollection.doc('${userId}_$favoriteUserId').delete();
    });
  }

  // Obtenir les favoris d'un utilisateur
  Stream<List<UserModel>> getFavorites(String userId) {
    return FirestoreErrorHandler.handleStream(
      _favoritesCollection
          .where('userId', isEqualTo: userId)
          .snapshots()
          .asyncMap((snapshot) async {
            List<UserModel> favorites = [];
            for (var doc in snapshot.docs) {
              String favoriteUserId = doc['favoriteUserId'];
              UserModel? user = await getUser(favoriteUserId);
              if (user != null) {
                favorites.add(user);
              }
            }
            return favorites;
          }),
    );
  }

  // Vérifier si un utilisateur est en favori
  Future<bool> isFavorite(String userId, String targetUserId) async {
    return FirestoreErrorHandler.handleOperation(() async {
      DocumentSnapshot doc = await _favoritesCollection
          .doc('${userId}_$targetUserId')
          .get();
      return doc.exists;
    });
  }

  // ========== VUES DE PROFIL ==========

  // Enregistrer une vue de profil
  Future<void> recordProfileView({
    required String viewerId,
    required String profileUserId,
  }) async {
    return FirestoreErrorHandler.handleOperation(() async {
      // Ne pas enregistrer si c'est le même utilisateur qui consulte son propre profil
      if (viewerId == profileUserId) return;

      // Récupérer les informations du viewer et du profil consulté
      final viewerUser = await getUser(viewerId);
      final profileUser = await getUser(profileUserId);

      if (viewerUser == null || profileUser == null) return;

      // Ne compter que les vues des écoles sur les profils de candidats
      if (viewerUser.accountType != 'school' ||
          profileUser.accountType != 'teacher_candidate') {
        return;
      }

      // Créer un identifiant unique pour cette vue
      final viewId = '${viewerId}_$profileUserId';
      final now = Timestamp.now();

      // Vérifier si une vue existe déjà aujourd'hui (pour éviter les doublons)
      final existingView = await _profileViewsCollection.doc(viewId).get();

      if (existingView.exists) {
        final data = existingView.data() as Map<String, dynamic>;
        final lastViewTime = data['lastViewedAt'] as Timestamp;
        final lastViewDate = lastViewTime.toDate();
        final today = DateTime.now();

        // Si la dernière vue date du même jour, on met seulement à jour le timestamp
        if (lastViewDate.year == today.year &&
            lastViewDate.month == today.month &&
            lastViewDate.day == today.day) {
          await _profileViewsCollection.doc(viewId).update({
            'lastViewedAt': now,
          });
          return;
        }
      }

      // Enregistrer ou mettre à jour la vue
      await _profileViewsCollection.doc(viewId).set({
        'viewerId': viewerId,
        'viewerName': viewerUser.nom,
        'viewerAccountType': viewerUser.accountType,
        'profileUserId': profileUserId,
        'profileName': profileUser.nom,
        'profileAccountType': profileUser.accountType,
        'lastViewedAt': now,
        'createdAt': existingView.exists
            ? (existingView.data() as Map<String, dynamic>)['createdAt']
            : now,
      }, SetOptions(merge: true));

      // Incrémenter le compteur de vues sur le profil du candidat
      await _usersCollection.doc(profileUserId).update({
        'profileViewsCount': FieldValue.increment(1),
      });
    });
  }

  // Obtenir les vues d'un profil
  Stream<List<Map<String, dynamic>>> getProfileViews(String profileUserId) {
    return FirestoreErrorHandler.handleStream(
      _profileViewsCollection
          .where('profileUserId', isEqualTo: profileUserId)
          .orderBy('lastViewedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList(),
          ),
    );
  }

  // Obtenir le nombre total de vues d'un profil
  Future<int> getProfileViewsCount(String profileUserId) async {
    return FirestoreErrorHandler.handleOperation(() async {
      final userDoc = await _usersCollection.doc(profileUserId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['profileViewsCount'] ?? 0;
      }
      return 0;
    });
  }

  // ========== MESSAGES ==========

  // Créer une conversation
  Future<String> createConversation(String user1Id, String user2Id) async {
    // Créer un ID de conversation unique (toujours le même ordre)
    List<String> userIds = [user1Id, user2Id]..sort();
    String conversationId = '${userIds[0]}_${userIds[1]}';

    return FirestoreErrorHandler.handleOperation(() async {
      // Vérifier si la conversation existe déjà
      DocumentSnapshot doc = await _messagesCollection
          .doc(conversationId)
          .get();

      if (!doc.exists) {
        // Créer la conversation seulement si elle n'existe pas
        await _messagesCollection.doc(conversationId).set({
          'participants': userIds,
          'createdAt': Timestamp.now(),
          'lastMessage': '',
          'lastMessageTime': Timestamp.now(),
          'unreadCount': {userIds[0]: 0, userIds[1]: 0},
        });
      }

      return conversationId;
    });
  }

  // Envoyer un message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String message,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    String? storagePath,
  }) async {
    return FirestoreErrorHandler.handleOperation(() async {
      // S'assurer que la conversation existe avant d'envoyer le message
      final conversationDoc = await _messagesCollection
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        // Extraire les IDs des participants depuis le conversationId
        final participantIds = conversationId.split('_');

        // Créer la conversation si elle n'existe pas
        await _messagesCollection.doc(conversationId).set({
          'participants': participantIds,
          'createdAt': Timestamp.now(),
          'lastMessage': '',
          'lastMessageTime': Timestamp.now(),
          'unreadCount': {participantIds[0]: 0, participantIds[1]: 0},
        });
      }

      final messageData = {
        'senderId': senderId,
        'message': message,
        'timestamp': Timestamp.now(),
        'read': false,
      };

      // Ajouter les informations du fichier si présent
      if (fileUrl != null) {
        messageData['hasFile'] = true;
        messageData['fileUrl'] = fileUrl;
        messageData['fileName'] = fileName ?? 'fichier';
        messageData['fileSize'] = fileSize ?? 0;
        messageData['fileType'] = fileType ?? 'file';
        messageData['storagePath'] = storagePath ?? '';
      } else {
        messageData['hasFile'] = false;
      }

      // Ajouter le message à la sous-collection
      await _messagesCollection
          .doc(conversationId)
          .collection('messages')
          .add(messageData);

      // Mettre à jour la dernière activité de la conversation
      final lastMessage = fileUrl != null
          ? 'Fichier joint: ${fileName ?? "fichier"}'
          : message;

      // Déterminer l'ID du destinataire (l'autre participant)
      final conversationData = conversationDoc.data() as Map<String, dynamic>?;
      final participants =
          conversationData?['participants'] as List<dynamic>? ?? [];
      final receiverId = participants.firstWhere(
        (id) => id != senderId,
        orElse: () => '',
      );

      // Mettre à jour le document de conversation et incrémenter le compteur de non-lus pour le destinataire
      final updates = {
        'lastMessage': lastMessage,
        'lastMessageTime': Timestamp.now(),
      };

      // Incrémenter le compteur de messages non lus pour le destinataire
      if (receiverId.isNotEmpty) {
        updates['unreadCount.$receiverId'] = FieldValue.increment(1);
      }

      await _messagesCollection.doc(conversationId).update(updates);

      // Envoyer une notification au destinataire
      if (receiverId.isNotEmpty) {
        try {
          // Récupérer le nom de l'expéditeur
          final senderDoc = await _usersCollection.doc(senderId).get();
          final senderData = senderDoc.data() as Map<String, dynamic>?;
          final senderName = senderData?['nom'] ?? 'Un utilisateur';

          // Préparer le message de notification
          String notificationMessage;
          if (fileUrl != null) {
            notificationMessage =
                'Vous a envoyé un fichier: ${fileName ?? "fichier"}';
          } else {
            // Limiter le message à 100 caractères pour la notification
            notificationMessage = message.length > 100
                ? '${message.substring(0, 100)}...'
                : message;
          }

          await _notificationService.sendNotification(
            userId: receiverId,
            createdBy: senderId,
            type: 'message',
            title: 'Nouveau message de $senderName',
            message: notificationMessage,
            relatedId: conversationId,
            data: {
              'conversationId': conversationId,
              'senderId': senderId,
              'senderName': senderName,
            },
          );
        } catch (e) {
          debugPrint(
            'Erreur lors de l\'envoi de la notification de message: $e',
          );
        }
      }
    });
  }

  // Réinitialiser le compteur de messages non lus pour un utilisateur
  Future<void> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    return FirestoreErrorHandler.handleOperation(() async {
      debugPrint(
        '[CHAT] Marquage de la conversation $conversationId comme lue pour l\'utilisateur $userId',
      );
      await _messagesCollection.doc(conversationId).update({
        'unreadCount.$userId': 0,
      });
      debugPrint('[CHAT] Conversation marquée comme lue avec succès');
    });
  }

  // Obtenir le nombre total de messages non lus pour un utilisateur
  Stream<int> getTotalUnreadMessagesCount(String userId) {
    return FirestoreErrorHandler.handleStream(
      _messagesCollection
          .where('participants', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
            int total = 0;
            debugPrint(
              '[CHAT] Calcul des messages non lus pour userId: $userId',
            );
            debugPrint(
              '[CHAT] Nombre de conversations: ${snapshot.docs.length}',
            );
            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final unreadCount = data['unreadCount'] as Map<String, dynamic>?;
              if (unreadCount != null && unreadCount.containsKey(userId)) {
                final count = (unreadCount[userId] as int?) ?? 0;
                debugPrint(
                  '[CHAT] Conversation ${doc.id}: $count message(s) non lu(s)',
                );
                total += count;
              }
            }
            debugPrint('[CHAT] Total messages non lus: $total');
            return total;
          }),
    );
  }

  // Obtenir les messages d'une conversation
  Stream<QuerySnapshot> getMessages(String conversationId) {
    return FirestoreErrorHandler.handleStream(
      _messagesCollection
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
    );
  }

  // Obtenir toutes les conversations d'un utilisateur
  Stream<QuerySnapshot> getConversations(String userId) {
    return FirestoreErrorHandler.handleStream(
      _messagesCollection
          .where('participants', arrayContains: userId)
          .snapshots()
          .distinct((prev, next) {
            // Vérifier si les deux snapshots sont vraiment différents
            if (prev.docs.length != next.docs.length) return false;

            // Comparer les IDs des documents
            for (int i = 0; i < prev.docs.length; i++) {
              if (prev.docs[i].id != next.docs[i].id) return false;

              // Comparer lastMessageTime pour détecter les changements
              final prevData = prev.docs[i].data() as Map<String, dynamic>;
              final nextData = next.docs[i].data() as Map<String, dynamic>;
              final prevTime = prevData['lastMessageTime'] as Timestamp?;
              final nextTime = nextData['lastMessageTime'] as Timestamp?;

              if (prevTime != nextTime) return false;
            }

            return true;
          }),
    );
  }

  // ==================== PROBLEM REPORTS ====================

  /// Soumettre un signalement de problème
  Future<void> submitProblemReport({
    required String userId,
    required String userName,
    required String userEmail,
    required String accountType,
    required String problemDescription,
  }) async {
    return FirestoreErrorHandler.handleOperation(() async {
      await _firestore.collection('problem_reports').add({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'accountType': accountType,
        'problemDescription': problemDescription,
        'status': 'new', // new, read, resolved
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Signalement de problème soumis avec succès');
    });
  }

  /// Obtenir tous les signalements de problèmes pour l'admin
  Stream<List<Map<String, dynamic>>> getProblemReports() {
    return FirestoreErrorHandler.handleStream(
      _firestore
          .collection('problem_reports')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
          }),
    );
  }

  /// Mettre à jour le statut d'un signalement
  Future<void> updateProblemReportStatus({
    required String reportId,
    required String status,
  }) async {
    return FirestoreErrorHandler.handleOperation(() async {
      await _firestore.collection('problem_reports').doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Statut du signalement mis à jour: $status');
    });
  }

  /// Supprimer un signalement
  Future<void> deleteProblemReport(String reportId) async {
    return FirestoreErrorHandler.handleOperation(() async {
      await _firestore.collection('problem_reports').doc(reportId).delete();
      debugPrint('Signalement supprimé avec succès');
    });
  }
}
