import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _messagesCollection => _firestore.collection('messages');
  CollectionReference get _favoritesCollection => _firestore.collection('favorites');
  CollectionReference get _profileViewsCollection => _firestore.collection('profile_views');

  // ========== USERS ==========

  // Créer un utilisateur
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  // Récupérer un utilisateur par UID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  // Stream d'un utilisateur spécifique (temps réel)
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Vérifier si un matricule existe déjà
  Future<bool> checkMatriculeExists(String matricule) async {
    try {
      QuerySnapshot query = await _usersCollection
          .where('matricule', isEqualTo: matricule.toUpperCase())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du matricule: $e');
    }
  }

  // Mettre à jour le statut en ligne
  Future<void> updateUserOnlineStatus(String uid, bool isOnline) async {
    try {
      await _usersCollection.doc(uid).update({
        'isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'utilisateur: $e');
    }
  }

  // ========== RECHERCHE ==========

  // Rechercher par zone actuelle
  Stream<List<UserModel>> searchByZoneActuelle(String zone) {
    try {
      return _usersCollection
          .where('zoneActuelle', isGreaterThanOrEqualTo: zone)
          .where('zoneActuelle', isLessThanOrEqualTo: '$zone\uf8ff')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Rechercher par zone souhaitée
  Stream<List<UserModel>> searchByZoneSouhaitee(String zone) {
    try {
      return _usersCollection
          .where('zonesSouhaitees', arrayContains: zone)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Rechercher par fonction
  Stream<List<UserModel>> searchByFonction(String fonction) {
    try {
      return _usersCollection
          .where('fonction', isGreaterThanOrEqualTo: fonction)
          .where('fonction', isLessThanOrEqualTo: '$fonction\uf8ff')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Rechercher par DREN
  Stream<List<UserModel>> searchByDREN(String dren) {
    try {
      return _usersCollection
          .where('dren', isGreaterThanOrEqualTo: dren)
          .where('dren', isLessThanOrEqualTo: '$dren\uf8ff')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Obtenir tous les utilisateurs (pour l'affichage initial)
  Stream<List<UserModel>> getAllUsers() {
    try {
      return _usersCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  // Obtenir les utilisateurs filtrés par type de compte
  Stream<List<UserModel>> getUsersByAccountType(String accountType) {
    try {
      return _usersCollection
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
          });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs par type: $e');
    }
  }

  // Obtenir tous les utilisateurs en stream (pour panneau admin)
  Stream<List<UserModel>> getAllUsersStream() {
    return getAllUsers();
  }

  // Mettre à jour le statut de vérification
  Future<void> updateUserVerificationStatus(String uid, bool isVerified) async {
    try {
      await _usersCollection.doc(uid).update({
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut de vérification: $e');
    }
  }

  // Mettre à jour le statut admin
  Future<void> updateUserAdminStatus(String uid, bool isAdmin) async {
    try {
      await _usersCollection.doc(uid).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut admin: $e');
    }
  }

  // Recherche de match mutuel
  Future<List<UserModel>> searchMutualMatch({
    required String currentUserZoneActuelle,
    required List<String> currentUserZonesSouhaitees,
  }) async {
    try {
      // Chercher les utilisateurs dont la zone actuelle est dans nos zones souhaitées
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
    } catch (e) {
      throw Exception('Erreur lors de la recherche de match mutuel: $e');
    }
  }

  // ========== FAVORIS ==========

  // Ajouter un favori
  Future<void> addFavorite(String userId, String favoriteUserId) async {
    try {
      await _favoritesCollection.doc('${userId}_$favoriteUserId').set({
        'userId': userId,
        'favoriteUserId': favoriteUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout aux favoris: $e');
    }
  }

  // Retirer un favori
  Future<void> removeFavorite(String userId, String favoriteUserId) async {
    try {
      await _favoritesCollection.doc('${userId}_$favoriteUserId').delete();
    } catch (e) {
      throw Exception('Erreur lors du retrait des favoris: $e');
    }
  }

  // Obtenir les favoris d'un utilisateur
  Stream<List<UserModel>> getFavorites(String userId) {
    try {
      return _favoritesCollection
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
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des favoris: $e');
    }
  }

  // Vérifier si un utilisateur est en favori
  Future<bool> isFavorite(String userId, String targetUserId) async {
    try {
      DocumentSnapshot doc = await _favoritesCollection
          .doc('${userId}_$targetUserId')
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ========== VUES DE PROFIL ==========

  // Enregistrer une vue de profil
  Future<void> recordProfileView({
    required String viewerId,
    required String profileUserId,
  }) async {
    try {
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
        'createdAt': existingView.exists ? (existingView.data() as Map<String, dynamic>)['createdAt'] : now,
      }, SetOptions(merge: true));

      // Incrémenter le compteur de vues sur le profil du candidat
      await _usersCollection.doc(profileUserId).update({
        'profileViewsCount': FieldValue.increment(1),
      });

    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement de la vue de profil: $e');
      // Ne pas faire échouer l'opération si l'enregistrement de la vue échoue
    }
  }

  // Obtenir les vues d'un profil
  Stream<List<Map<String, dynamic>>> getProfileViews(String profileUserId) {
    try {
      return _profileViewsCollection
          .where('profileUserId', isEqualTo: profileUserId)
          .orderBy('lastViewedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList());
    } catch (e) {
      debugPrint('Erreur lors de la récupération des vues de profil: $e');
      return Stream.value([]);
    }
  }

  // Obtenir le nombre total de vues d'un profil
  Future<int> getProfileViewsCount(String profileUserId) async {
    try {
      final userDoc = await _usersCollection.doc(profileUserId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['profileViewsCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du compteur de vues: $e');
      return 0;
    }
  }

  // ========== MESSAGES ==========

  // Créer une conversation
  Future<String> createConversation(String user1Id, String user2Id) async {
    // Créer un ID de conversation unique (toujours le même ordre)
    List<String> userIds = [user1Id, user2Id]..sort();
    String conversationId = '${userIds[0]}_${userIds[1]}';

    try {
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
        });
      }

      return conversationId;
    } catch (e) {
      // Retourner l'ID même en cas d'erreur si c'est juste un problème de permissions
      // car la conversation existe peut-être déjà
      debugPrint('Erreur lors de la création de la conversation: $e');
      return conversationId;
    }
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
    try {
      // S'assurer que la conversation existe avant d'envoyer le message
      final conversationDoc = await _messagesCollection.doc(conversationId).get();

      if (!conversationDoc.exists) {
        // Extraire les IDs des participants depuis le conversationId
        final participantIds = conversationId.split('_');

        // Créer la conversation si elle n'existe pas
        await _messagesCollection.doc(conversationId).set({
          'participants': participantIds,
          'createdAt': Timestamp.now(),
          'lastMessage': '',
          'lastMessageTime': Timestamp.now(),
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

      // Mettre à jour le document de conversation
      await _messagesCollection.doc(conversationId).update({
        'lastMessage': lastMessage,
        'lastMessageTime': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message: $e');
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  // Obtenir les messages d'une conversation
  Stream<QuerySnapshot> getMessages(String conversationId) {
    try {
      return _messagesCollection
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des messages: $e');
    }
  }

  // Obtenir toutes les conversations d'un utilisateur
  Stream<QuerySnapshot> getConversations(String userId) {
    try {
      // Requête sans orderBy pour éviter l'erreur INTERNAL ASSERTION FAILED
      // Le tri sera fait côté client dans le widget
      return _messagesCollection
          .where('participants', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
            // Trier les conversations côté client par lastMessageTime
            final docs = snapshot.docs.toList();
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['lastMessageTime'] as Timestamp?;
              final bTime = bData['lastMessageTime'] as Timestamp?;

              // Les conversations sans messages vont à la fin
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              // Tri décroissant (les plus récentes en premier)
              return bTime.compareTo(aTime);
            });

            // Retourner un QuerySnapshot modifié avec les docs triés
            return _SortedQuerySnapshot(snapshot, docs);
          });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des conversations: $e');
    }
  }
}

// Classe helper pour retourner un QuerySnapshot avec des docs triés
class _SortedQuerySnapshot implements QuerySnapshot {
  final QuerySnapshot _original;
  final List<QueryDocumentSnapshot> _sortedDocs;

  _SortedQuerySnapshot(this._original, this._sortedDocs);

  @override
  List<QueryDocumentSnapshot> get docs => _sortedDocs;

  @override
  List<DocumentChange> get docChanges => _original.docChanges;

  @override
  SnapshotMetadata get metadata => _original.metadata;

  @override
  int get size => _sortedDocs.length;
}
