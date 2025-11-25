import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return _handlePermissionDenied(error);

        case 'failed-precondition':
          return _handleFailedPrecondition(error);

        case 'unauthenticated':
          return 'Vous devez être connecté pour effectuer cette action';

        case 'resource-exhausted':
          return 'Votre quota gratuit est épuisé. Veuillez souscrire à un abonnement pour continuer';

        case 'invalid-argument':
          return 'Les données fournies sont invalides. Veuillez vérifier vos informations';

        case 'not-found':
          return 'La ressource demandée est introuvable';

        case 'already-exists':
          return 'Cette ressource existe déjà';

        case 'aborted':
          return 'L\'opération a été annulée. Veuillez réessayer';

        case 'out-of-range':
          return 'La valeur fournie est hors limites';

        case 'unimplemented':
          return 'Cette fonctionnalité n\'est pas encore disponible';

        case 'internal':
          return 'Une erreur interne s\'est produite. Veuillez réessayer';

        case 'unavailable':
          return 'Le service est temporairement indisponible. Veuillez réessayer';

        case 'data-loss':
          return 'Des données ont été perdues. Veuillez contacter le support';

        case 'deadline-exceeded':
          return 'L\'opération a pris trop de temps. Veuillez réessayer';

        case 'cancelled':
          return 'L\'opération a été annulée';

        default:
          return _parseCustomMessage(error);
      }
    }

    if (error is Exception) {
      final message = error.toString();
      if (message.contains('quota')) {
        return 'Votre quota gratuit est épuisé. Veuillez souscrire à un abonnement pour continuer';
      }
      if (message.contains('permission') || message.contains('denied')) {
        return 'Vous n\'êtes pas autorisé à effectuer cette action';
      }
      if (message.contains('authenticated') || message.contains('auth')) {
        return 'Vous devez être connecté pour effectuer cette action';
      }
      return message.replaceAll('Exception: ', '');
    }

    return 'Une erreur inattendue s\'est produite. Veuillez réessayer';
  }

  static String _handlePermissionDenied(FirebaseException error) {
    final message = error.message?.toLowerCase() ?? '';

    if (message.contains('quota')) {
      return 'Votre quota gratuit est épuisé. Veuillez souscrire à un abonnement pour continuer';
    }

    if (message.contains('verified') || message.contains('vérif')) {
      return 'Votre compte doit être vérifié pour effectuer cette action';
    }

    if (message.contains('subscription') || message.contains('abonnement')) {
      return 'Cette action nécessite un abonnement actif';
    }

    if (message.contains('admin')) {
      return 'Seuls les administrateurs peuvent effectuer cette action';
    }

    if (message.contains('owner') || message.contains('propriétaire')) {
      return 'Vous ne pouvez modifier que vos propres données';
    }

    if (message.contains('participant')) {
      return 'Vous devez être participant à cette conversation';
    }

    if (message.contains('create') || message.contains('créer')) {
      return 'Vous n\'êtes pas autorisé à créer cette ressource';
    }

    if (message.contains('read') || message.contains('lire')) {
      return 'Vous n\'êtes pas autorisé à consulter cette ressource';
    }

    if (message.contains('update') || message.contains('modifier')) {
      return 'Vous n\'êtes pas autorisé à modifier cette ressource';
    }

    if (message.contains('delete') || message.contains('supprimer')) {
      return 'Vous n\'êtes pas autorisé à supprimer cette ressource';
    }

    return 'Vous n\'êtes pas autorisé à effectuer cette action';
  }

  static String _handleFailedPrecondition(FirebaseException error) {
    final message = error.message?.toLowerCase() ?? '';

    if (message.contains('quota')) {
      return 'Votre quota gratuit est épuisé. Veuillez souscrire à un abonnement pour continuer';
    }

    if (message.contains('verified') || message.contains('vérif')) {
      return 'Votre compte doit être vérifié pour continuer';
    }

    if (message.contains('email')) {
      return 'Votre adresse email doit être vérifiée';
    }

    if (message.contains('payment') || message.contains('paiement')) {
      return 'Un paiement est requis pour cette action';
    }

    if (message.contains('subscription') || message.contains('abonnement')) {
      return 'Vous devez avoir un abonnement actif';
    }

    if (message.contains('expired') || message.contains('expiré')) {
      return 'Votre abonnement a expiré. Veuillez le renouveler';
    }

    if (message.contains('limit')) {
      return 'Vous avez atteint la limite autorisée';
    }

    return 'Les conditions requises ne sont pas remplies pour cette action';
  }

  static String _parseCustomMessage(FirebaseException error) {
    final message = error.message ?? '';

    if (message.contains('quota gratuit épuisé') ||
        message.contains('Quota épuisé') ||
        message.contains('quota exhausted')) {
      return 'Votre quota gratuit est épuisé. Veuillez souscrire à un abonnement pour continuer';
    }

    if (message.contains('compte non vérifié') ||
        message.contains('not verified')) {
      return 'Votre compte doit être vérifié pour effectuer cette action';
    }

    if (message.contains('abonnement requis') ||
        message.contains('subscription required')) {
      return 'Cette action nécessite un abonnement actif';
    }

    if (message.contains('abonnement expiré') ||
        message.contains('subscription expired')) {
      return 'Votre abonnement a expiré. Veuillez le renouveler';
    }

    if (message.contains('administrateur uniquement') ||
        message.contains('admin only')) {
      return 'Seuls les administrateurs peuvent effectuer cette action';
    }

    if (message.contains('matricule invalide') ||
        message.contains('invalid matricule')) {
      return 'Le numéro de matricule est invalide';
    }

    if (message.contains('email invalide') ||
        message.contains('invalid email')) {
      return 'L\'adresse email est invalide';
    }

    if (message.contains('téléphone invalide') ||
        message.contains('invalid phone')) {
      return 'Le numéro de téléphone est invalide';
    }

    if (message.contains('champs obligatoires manquants') ||
        message.contains('missing required fields')) {
      return 'Certains champs obligatoires sont manquants';
    }

    if (message.contains('limite atteinte') ||
        message.contains('limit reached')) {
      return 'Vous avez atteint la limite autorisée';
    }

    if (message.contains('auto-promotion') ||
        message.contains('self-promote')) {
      return 'Vous ne pouvez pas vous auto-promouvoir administrateur';
    }

    if (message.contains('auto-vérification') ||
        message.contains('self-verify')) {
      return 'Vous ne pouvez pas vous auto-vérifier';
    }

    if (message.contains('champ immuable') ||
        message.contains('immutable field')) {
      return 'Ce champ ne peut pas être modifié';
    }

    if (message.isEmpty) {
      return 'Une erreur s\'est produite. Veuillez réessayer';
    }

    return message;
  }

  static void logError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🔥 Firestore Error: ${error.toString()}');
      if (error is FirebaseException) {
        debugPrint('   Code: ${error.code}');
        debugPrint('   Message: ${error.message}');
        debugPrint('   Plugin: ${error.plugin}');
      }
      if (stackTrace != null) {
        debugPrint('   Stack: ${stackTrace.toString()}');
      }
    }
  }

  static Future<T> handleOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e, stackTrace) {
      logError(e, stackTrace);
      throw Exception(getErrorMessage(e));
    } catch (e, stackTrace) {
      logError(e, stackTrace);
      throw Exception(getErrorMessage(e));
    }
  }

  static Stream<T> handleStream<T>(Stream<T> stream) {
    return stream.handleError((error, stackTrace) {
      logError(error, stackTrace);
      throw Exception(getErrorMessage(error));
    });
  }
}
