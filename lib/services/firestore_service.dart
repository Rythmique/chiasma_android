import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _messagesCollection => _firestore.collection('messages');
  CollectionReference get _favoritesCollection => _firestore.collection('favorites');

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

  // ========== MESSAGES ==========

  // Créer une conversation
  Future<String> createConversation(String user1Id, String user2Id) async {
    try {
      // Créer un ID de conversation unique (toujours le même ordre)
      List<String> userIds = [user1Id, user2Id]..sort();
      String conversationId = '${userIds[0]}_${userIds[1]}';

      // Vérifier si la conversation existe déjà
      DocumentSnapshot doc = await _messagesCollection
          .doc(conversationId)
          .get();

      if (!doc.exists) {
        await _messagesCollection.doc(conversationId).set({
          'participants': userIds,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageTime': null,
        });
      }

      return conversationId;
    } catch (e) {
      throw Exception('Erreur lors de la création de la conversation: $e');
    }
  }

  // Envoyer un message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String message,
  }) async {
    try {
      await _messagesCollection
          .doc(conversationId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Mettre à jour la dernière activité de la conversation
      await _messagesCollection.doc(conversationId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
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
      return _messagesCollection
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des conversations: $e');
    }
  }
}
