/// Configuration Algolia pour Chiasma
///
/// IMPORTANT: Ces clés sont configurées pour votre compte Algolia.
///
/// SÉCURITÉ:
/// - Utilise UNIQUEMENT la Search-Only API Key (jamais l'Admin Key)
/// - Cette clé peut être exposée côté client sans risque
/// - L'Admin Key est utilisée uniquement dans les Cloud Functions
class AlgoliaConfig {
  /// Application ID Algolia
  static const String applicationId = 'EHXDOBMUY9';

  /// Search-Only API Key
  ///
  /// Cette clé permet uniquement de faire des recherches (lecture seule)
  /// Sécurisé pour une utilisation côté client
  static const String searchApiKey = 'bedf7946040c42b76b24c6e2d2eaee87';

  /// Vérifier si Algolia est configuré
  static bool get isConfigured {
    return applicationId != 'YOUR_APPLICATION_ID_HERE' &&
        searchApiKey != 'YOUR_SEARCH_API_KEY_HERE' &&
        applicationId.isNotEmpty &&
        searchApiKey.isNotEmpty;
  }
}
