import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Stream de l'utilisateur connecté
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Inscription avec email, mot de passe et données utilisateur
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String accountType = 'teacher_transfer', // Type de compte
    required String matricule,
    required String nom,
    required List<String> telephones,
    required String fonction,
    required String zoneActuelle,
    String? dren,
    required String infosZoneActuelle,
    required List<String> zonesSouhaitees,
  }) async {
    try {
      // Vérifier si le matricule existe déjà (uniquement pour teacher_transfer)
      // Les candidats et écoles n'ont pas de matricule
      if (accountType == 'teacher_transfer' && matricule.isNotEmpty) {
        bool matriculeExists = await _firestoreService.checkMatriculeExists(matricule);
        if (matriculeExists) {
          throw Exception('Ce numéro de matricule est déjà utilisé');
        }
      }

      // Créer le compte Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Créer le profil utilisateur dans Firestore
      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          accountType: accountType, // Ajouter le type de compte
          matricule: matricule,
          nom: nom,
          telephones: telephones,
          fonction: fonction,
          zoneActuelle: zoneActuelle,
          dren: dren,
          infosZoneActuelle: infosZoneActuelle,
          zonesSouhaitees: zonesSouhaitees,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isOnline: true,
          isVerified: true, // Vérifié automatiquement à l'inscription
          freeQuotaUsed: 0, // Commence à 0
          // freeQuotaLimit est calculé automatiquement selon accountType
        );

        await _firestoreService.createUser(newUser);

        // Envoyer email de vérification
        await userCredential.user!.sendEmailVerification();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('Le mot de passe est trop faible');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('Cet email est déjà utilisé');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email invalide');
      } else {
        throw Exception('Erreur d\'inscription: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Connexion avec email et mot de passe
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Mettre à jour le statut en ligne
      if (userCredential.user != null) {
        await _firestoreService.updateUserOnlineStatus(
          userCredential.user!.uid,
          true,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Aucun utilisateur trouvé avec cet email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Mot de passe incorrect');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email invalide');
      } else {
        throw Exception('Erreur de connexion: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Connexion avec email, mot de passe ET matricule (validation supplémentaire)
  Future<UserCredential?> signInWithEmailPasswordAndMatricule({
    required String email,
    required String password,
    required String matricule,
  }) async {
    try {
      // D'abord, se connecter avec email et mot de passe
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Vérifier que le matricule correspond
      if (userCredential.user != null) {
        UserModel? user = await _firestoreService.getUser(userCredential.user!.uid);

        if (user == null) {
          await _auth.signOut();
          throw Exception('Profil utilisateur introuvable');
        }

        if (user.matricule.toUpperCase() != matricule.toUpperCase()) {
          await _auth.signOut();
          throw Exception('Le numéro de matricule ne correspond pas');
        }

        // Mettre à jour le statut en ligne
        await _firestoreService.updateUserOnlineStatus(
          userCredential.user!.uid,
          true,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Aucun utilisateur trouvé avec cet email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Mot de passe incorrect');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email invalide');
      } else {
        throw Exception('Erreur de connexion: ${e.message}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Réinitialisation du mot de passe
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Aucun utilisateur trouvé avec cet email');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email invalide');
      } else {
        throw Exception('Erreur: ${e.message}');
      }
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      // Mettre à jour le statut hors ligne avant de se déconnecter
      if (currentUser != null) {
        await _firestoreService.updateUserOnlineStatus(
          currentUser!.uid,
          false,
        );
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur de déconnexion: $e');
    }
  }

  // Supprimer le compte
  Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        // Supprimer les données Firestore
        await _firestoreService.deleteUser(currentUser!.uid);
        // Supprimer le compte Auth
        await currentUser!.delete();
      }
    } catch (e) {
      throw Exception('Erreur de suppression: $e');
    }
  }
}
