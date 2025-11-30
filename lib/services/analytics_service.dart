import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service centralisé pour Firebase Analytics
/// Tracks tous les événements utilisateur importants
class AnalyticsService {
  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalyticsObserver? _observer;

  /// NavigatorObserver pour tracking automatique des écrans
  FirebaseAnalyticsObserver get observer {
    _observer ??= FirebaseAnalyticsObserver(analytics: _analytics);
    return _observer!;
  }

  // ============================================
  // 1. AUTHENTIFICATION
  // ============================================

  /// Track une connexion utilisateur
  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('📊 Analytics: Login tracked (method: $method)');
    } catch (e) {
      debugPrint('⚠️ Analytics Error (login): $e');
    }
  }

  /// Définir l'ID utilisateur pour associer tous les événements
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      debugPrint('📊 Analytics: User ID set ($userId)');
    } catch (e) {
      debugPrint('⚠️ Analytics Error (setUserId): $e');
    }
  }

  /// Définir les propriétés utilisateur pour segmentation
  Future<void> setUserProperties({
    String? accountType,
    bool? isVerified,
    String? region,
  }) async {
    try {
      if (accountType != null) {
        await _analytics.setUserProperty(
          name: 'account_type',
          value: accountType,
        );
      }
      if (isVerified != null) {
        await _analytics.setUserProperty(
          name: 'is_verified',
          value: isVerified.toString(),
        );
      }
      if (region != null) {
        await _analytics.setUserProperty(name: 'region', value: region);
      }
      debugPrint('📊 Analytics: User properties set');
    } catch (e) {
      debugPrint('⚠️ Analytics Error (setUserProperties): $e');
    }
  }

  // ============================================
  // 2. RECHERCHE
  // ============================================

  /// Track une recherche utilisateur
  Future<void> logSearch(String searchTerm, {String? category}) async {
    try {
      await _analytics.logSearch(
        searchTerm: searchTerm,
        parameters: {if (category != null) 'search_category': category},
      );
      debugPrint(
        '📊 Analytics: Search tracked ("$searchTerm", category: $category)',
      );
    } catch (e) {
      debugPrint('⚠️ Analytics Error (search): $e');
    }
  }

  // ============================================
  // 3. CONSULTATION DE PROFILS
  // ============================================

  /// Track la consultation d'un profil
  Future<void> logViewProfile(String profileId, String profileType) async {
    try {
      await _analytics.logEvent(
        name: 'view_profile',
        parameters: {
          'profile_id': profileId,
          'profile_type': profileType,
          'content_type': 'profile',
        },
      );
      debugPrint('📊 Analytics: Profile view tracked (type: $profileType)');
    } catch (e) {
      debugPrint('⚠️ Analytics Error (viewProfile): $e');
    }
  }

  // ============================================
  // 4. MESSAGERIE
  // ============================================

  /// Track l'envoi d'un message
  Future<void> logSendMessage(String conversationType) async {
    try {
      await _analytics.logEvent(
        name: 'send_message',
        parameters: {'conversation_type': conversationType},
      );
      debugPrint(
        '📊 Analytics: Message sent tracked (type: $conversationType)',
      );
    } catch (e) {
      debugPrint('⚠️ Analytics Error (sendMessage): $e');
    }
  }

  // ============================================
  // 5. ABONNEMENTS & ACHATS
  // ============================================

  /// Track le début d'un abonnement
  Future<void> logSubscriptionStart(
    String subscriptionType,
    String duration,
  ) async {
    try {
      await _analytics.logEvent(
        name: 'subscription_start',
        parameters: {
          'subscription_type': subscriptionType,
          'duration': duration,
        },
      );
      debugPrint(
        '📊 Analytics: Subscription started (type: $subscriptionType, duration: $duration)',
      );
    } catch (e) {
      debugPrint('⚠️ Analytics Error (subscriptionStart): $e');
    }
  }

  /// Track un achat (pour métriques de revenus)
  Future<void> logPurchase({
    required String subscriptionType,
    required double value,
    required String currency,
  }) async {
    try {
      await _analytics.logPurchase(
        value: value,
        currency: currency,
        parameters: {'item_name': subscriptionType},
      );
      debugPrint('📊 Analytics: Purchase tracked ($value $currency)');
    } catch (e) {
      debugPrint('⚠️ Analytics Error (purchase): $e');
    }
  }

  // ============================================
  // 6. ÉVÉNEMENTS PERSONNALISÉS
  // ============================================

  /// Track un événement personnalisé avec paramètres
  Future<void> logCustomEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
      debugPrint('📊 Analytics: Custom event "$eventName" tracked');
    } catch (e) {
      debugPrint('⚠️ Analytics Error (customEvent): $e');
    }
  }

  // ============================================
  // 7. FAVORIS
  // ============================================

  /// Track l'ajout d'un favori
  Future<void> logAddFavorite(String profileId, String profileType) async {
    try {
      await _analytics.logEvent(
        name: 'add_to_favorites',
        parameters: {'profile_id': profileId, 'profile_type': profileType},
      );
      debugPrint('📊 Analytics: Favorite added (type: $profileType)');
    } catch (e) {
      debugPrint('⚠️ Analytics Error (addFavorite): $e');
    }
  }

  /// Track le retrait d'un favori
  Future<void> logRemoveFavorite(String profileId, String profileType) async {
    try {
      await _analytics.logEvent(
        name: 'remove_from_favorites',
        parameters: {'profile_id': profileId, 'profile_type': profileType},
      );
      debugPrint('📊 Analytics: Favorite removed (type: $profileType)');
    } catch (e) {
      debugPrint('⚠️ Analytics Error (removeFavorite): $e');
    }
  }

  // ============================================
  // 8. CANDIDATURES (pour teacher_candidate)
  // ============================================

  /// Track une candidature à une offre
  Future<void> logJobApplication(String offerId) async {
    try {
      await _analytics.logEvent(
        name: 'job_application',
        parameters: {'offer_id': offerId},
      );
      debugPrint('📊 Analytics: Job application tracked');
    } catch (e) {
      debugPrint('⚠️ Analytics Error (jobApplication): $e');
    }
  }

  // ============================================
  // 9. CONFIGURATION
  // ============================================

  /// Activer/désactiver la collecte Analytics
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
      debugPrint(
        '📊 Analytics: Collection ${enabled ? "enabled" : "disabled"}',
      );
    } catch (e) {
      debugPrint('⚠️ Analytics Error (setEnabled): $e');
    }
  }
}
