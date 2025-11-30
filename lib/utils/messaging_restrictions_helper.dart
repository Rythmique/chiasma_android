import 'package:myapp/models/user_model.dart';

/// Helper global pour gérer les restrictions de messagerie
/// selon le statut de vérification et les restrictions admin
class MessagingRestrictionsHelper {
  /// Vérifie si l'utilisateur teacher_transfer doit avoir des restrictions
  /// de messagerie selon les règles suivantes:
  ///
  /// - Si restrictions admin activées ET non vérifié: restreindre messagerie
  /// - Si vérifié: aucune restriction (peu importe le quota)
  /// - Après expiration vérification + quota épuisé: restreindre messagerie
  static bool shouldRestrictMessaging(
    UserModel user,
    bool adminRestrictionsEnabled,
  ) {
    // Seuls les teacher_transfer sont concernés
    if (user.accountType != 'teacher_transfer') {
      return false;
    }

    // Si restrictions admin désactivées: pas de restriction
    if (!adminRestrictionsEnabled) {
      return false;
    }

    // Si vérifié et vérification non expirée: pas de restriction
    if (user.isVerified && !user.isVerificationExpired) {
      return false;
    }

    // Si non vérifié OU vérification expirée: restreindre
    return true;
  }

  /// Vérifie si les contacts (téléphones et email) doivent être masqués
  /// Mêmes règles que shouldRestrictMessaging
  static bool shouldMaskContacts(
    UserModel user,
    bool adminRestrictionsEnabled,
  ) {
    return shouldRestrictMessaging(user, adminRestrictionsEnabled);
  }

  /// Vérifie si le banner de quota doit être masqué
  /// Le banner est masqué uniquement si l'utilisateur est vérifié ET vérification non expirée
  static bool shouldHideQuotaBanner(UserModel user) {
    if (user.accountType != 'teacher_transfer') {
      return false;
    }

    return user.isVerified && !user.isVerificationExpired;
  }

  /// Retourne le texte à afficher pour masquer un numéro de téléphone
  static String getMaskedPhone() => '** ** ** **';

  /// Retourne le texte à afficher pour masquer un email
  static String getMaskedEmail() => '***@***.**';
}
