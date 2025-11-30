import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String accountType = 'teacher_transfer',
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
      if (accountType == 'teacher_transfer' && matricule.isNotEmpty) {
        if (await _firestoreService.checkMatriculeExists(matricule)) {
          throw Exception('Ce numéro de matricule est déjà utilisé');
        }
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _firestoreService.createUser(
          UserModel(
            uid: userCredential.user!.uid,
            email: email,
            accountType: accountType,
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
            isVerified: false,
            freeQuotaUsed: 0,
          ),
        );
        await userCredential.user!.sendEmailVerification();
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue lors de l\'inscription');
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _firestoreService.updateUserOnlineStatus(
          userCredential.user!.uid,
          true,
        );
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue lors de la connexion');
    }
  }

  Future<UserCredential?> signInWithEmailPasswordAndMatricule({
    required String email,
    required String password,
    required String matricule,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = await _firestoreService.getUser(userCredential.user!.uid);

        if (user == null) {
          await _auth.signOut();
          throw Exception('Profil utilisateur introuvable');
        }

        if (user.matricule.toUpperCase() != matricule.toUpperCase()) {
          await _auth.signOut();
          throw Exception(
            'Le numéro de matricule ne correspond pas à ce compte',
          );
        }

        await _firestoreService.updateUserOnlineStatus(
          userCredential.user!.uid,
          true,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue lors de la connexion');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code, isPasswordReset: true));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue');
    }
  }

  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        await _firestoreService.updateUserOnlineStatus(currentUser!.uid, false);
      }
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur de déconnexion: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        await _firestoreService.deleteUser(currentUser!.uid);
        await currentUser!.delete();
      }
    } catch (e) {
      throw Exception('Erreur de suppression: $e');
    }
  }

  String _getAuthErrorMessage(String code, {bool isPasswordReset = false}) {
    final messages = {
      'weak-password': 'Le mot de passe est trop faible (minimum 6 caractères)',
      'email-already-in-use': 'Un compte existe déjà avec cette adresse email',
      'invalid-email': 'L\'adresse email est invalide',
      'operation-not-allowed': 'L\'inscription est temporairement désactivée',
      'user-not-found': 'Aucun compte n\'existe avec cette adresse email',
      'wrong-password': 'Mot de passe incorrect',
      'user-disabled': 'Ce compte a été désactivé',
      'too-many-requests': isPasswordReset
          ? 'Trop de demandes. Veuillez réessayer plus tard'
          : 'Trop de tentatives. Veuillez réessayer plus tard',
      'invalid-credential': 'Email ou mot de passe incorrect',
      'network-request-failed': 'Erreur de connexion. Vérifiez votre internet',
    };
    return messages[code] ??
        (isPasswordReset
            ? 'Impossible d\'envoyer l\'email de réinitialisation'
            : 'Impossible de se connecter. Vérifiez vos identifiants');
  }
}
