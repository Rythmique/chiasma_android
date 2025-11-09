import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service pour gérer le cache local avec Hive
///
/// Ce service permet de stocker des données localement pour:
/// - Chargement instantané de l'app (< 100ms)
/// - Fonctionnement hors-ligne
/// - Réduction des lectures Firestore
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;

  CacheService._internal();

  // Boxes Hive pour différents types de données
  Box? _usersBox;
  Box? _candidatesBox;
  Box? _jobOffersBox;
  Box? _favoritesBox;
  Box? _metadataBox;

  /// Initialiser Hive (à appeler au démarrage de l'app)
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      debugPrint('✅ Hive initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Hive: $e');
      rethrow;
    }
  }

  /// Ouvrir toutes les boxes nécessaires
  Future<void> openBoxes() async {
    try {
      _usersBox = await Hive.openBox('users_cache');
      _candidatesBox = await Hive.openBox('candidates_cache');
      _jobOffersBox = await Hive.openBox('job_offers_cache');
      _favoritesBox = await Hive.openBox('favorites_cache');
      _metadataBox = await Hive.openBox('cache_metadata');

      debugPrint('✅ All Hive boxes opened successfully');
    } catch (e) {
      debugPrint('❌ Error opening Hive boxes: $e');
      rethrow;
    }
  }

  /// Sauvegarder des utilisateurs dans le cache
  ///
  /// [cacheKey] Clé unique (ex: 'search_page_1', 'admin_panel_users')
  /// [users] Liste des données utilisateurs (Map JSON)
  Future<void> saveUsersToCache(String cacheKey, List<Map<String, dynamic>> users) async {
    try {
      if (_usersBox == null) await openBoxes();

      final cacheData = {
        'data': users,
        'cachedAt': DateTime.now().toIso8601String(),
        'count': users.length,
      };

      await _usersBox!.put(cacheKey, cacheData);
      debugPrint('💾 Saved ${users.length} users to cache: $cacheKey');
    } catch (e) {
      debugPrint('❌ Error saving users to cache: $e');
    }
  }

  /// Récupérer des utilisateurs depuis le cache
  ///
  /// [cacheKey] Clé unique
  /// [maxAge] Durée maximale de validité du cache (défaut: 1 heure)
  /// Retourne null si le cache n'existe pas ou est expiré
  Future<List<Map<String, dynamic>>?> getUsersFromCache(
    String cacheKey, {
    Duration maxAge = const Duration(hours: 1),
  }) async {
    try {
      if (_usersBox == null) await openBoxes();

      final cacheData = _usersBox!.get(cacheKey) as Map?;
      if (cacheData == null) {
        debugPrint('📭 No cache found for: $cacheKey');
        return null;
      }

      // Vérifier l'expiration du cache
      final cachedAt = DateTime.parse(cacheData['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age > maxAge) {
        debugPrint('⏰ Cache expired for: $cacheKey (age: ${age.inMinutes}min)');
        return null;
      }

      final data = (cacheData['data'] as List).cast<Map<String, dynamic>>();
      debugPrint('✅ Loaded ${data.length} users from cache: $cacheKey (age: ${age.inMinutes}min)');
      return data;
    } catch (e) {
      debugPrint('❌ Error loading users from cache: $e');
      return null;
    }
  }

  /// Sauvegarder des candidats dans le cache
  Future<void> saveCandidatesToCache(String cacheKey, List<Map<String, dynamic>> candidates) async {
    try {
      if (_candidatesBox == null) await openBoxes();

      final cacheData = {
        'data': candidates,
        'cachedAt': DateTime.now().toIso8601String(),
        'count': candidates.length,
      };

      await _candidatesBox!.put(cacheKey, cacheData);
      debugPrint('💾 Saved ${candidates.length} candidates to cache: $cacheKey');
    } catch (e) {
      debugPrint('❌ Error saving candidates to cache: $e');
    }
  }

  /// Récupérer des candidats depuis le cache
  Future<List<Map<String, dynamic>>?> getCandidatesFromCache(
    String cacheKey, {
    Duration maxAge = const Duration(hours: 1),
  }) async {
    try {
      if (_candidatesBox == null) await openBoxes();

      final cacheData = _candidatesBox!.get(cacheKey) as Map?;
      if (cacheData == null) return null;

      final cachedAt = DateTime.parse(cacheData['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age > maxAge) {
        debugPrint('⏰ Cache expired for: $cacheKey');
        return null;
      }

      final data = (cacheData['data'] as List).cast<Map<String, dynamic>>();
      debugPrint('✅ Loaded ${data.length} candidates from cache: $cacheKey');
      return data;
    } catch (e) {
      debugPrint('❌ Error loading candidates from cache: $e');
      return null;
    }
  }

  /// Sauvegarder des offres d'emploi dans le cache
  Future<void> saveJobOffersToCache(String cacheKey, List<Map<String, dynamic>> jobOffers) async {
    try {
      if (_jobOffersBox == null) await openBoxes();

      final cacheData = {
        'data': jobOffers,
        'cachedAt': DateTime.now().toIso8601String(),
        'count': jobOffers.length,
      };

      await _jobOffersBox!.put(cacheKey, cacheData);
      debugPrint('💾 Saved ${jobOffers.length} job offers to cache: $cacheKey');
    } catch (e) {
      debugPrint('❌ Error saving job offers to cache: $e');
    }
  }

  /// Récupérer des offres d'emploi depuis le cache
  Future<List<Map<String, dynamic>>?> getJobOffersFromCache(
    String cacheKey, {
    Duration maxAge = const Duration(hours: 1),
  }) async {
    try {
      if (_jobOffersBox == null) await openBoxes();

      final cacheData = _jobOffersBox!.get(cacheKey) as Map?;
      if (cacheData == null) return null;

      final cachedAt = DateTime.parse(cacheData['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age > maxAge) {
        debugPrint('⏰ Cache expired for: $cacheKey');
        return null;
      }

      final data = (cacheData['data'] as List).cast<Map<String, dynamic>>();
      debugPrint('✅ Loaded ${data.length} job offers from cache: $cacheKey');
      return data;
    } catch (e) {
      debugPrint('❌ Error loading job offers from cache: $e');
      return null;
    }
  }

  /// Sauvegarder les favoris dans le cache
  Future<void> saveFavoritesToCache(String userId, List<Map<String, dynamic>> favorites) async {
    try {
      if (_favoritesBox == null) await openBoxes();

      final cacheData = {
        'data': favorites,
        'cachedAt': DateTime.now().toIso8601String(),
        'count': favorites.length,
      };

      await _favoritesBox!.put('favorites_$userId', cacheData);
      debugPrint('💾 Saved ${favorites.length} favorites to cache for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving favorites to cache: $e');
    }
  }

  /// Récupérer les favoris depuis le cache
  Future<List<Map<String, dynamic>>?> getFavoritesFromCache(
    String userId, {
    Duration maxAge = const Duration(minutes: 30),
  }) async {
    try {
      if (_favoritesBox == null) await openBoxes();

      final cacheData = _favoritesBox!.get('favorites_$userId') as Map?;
      if (cacheData == null) return null;

      final cachedAt = DateTime.parse(cacheData['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age > maxAge) {
        debugPrint('⏰ Favorites cache expired for user: $userId');
        return null;
      }

      final data = (cacheData['data'] as List).cast<Map<String, dynamic>>();
      debugPrint('✅ Loaded ${data.length} favorites from cache for user: $userId');
      return data;
    } catch (e) {
      debugPrint('❌ Error loading favorites from cache: $e');
      return null;
    }
  }

  /// Invalider un cache spécifique
  Future<void> invalidateCache(String boxName, String cacheKey) async {
    try {
      Box? box;
      switch (boxName) {
        case 'users':
          box = _usersBox;
          break;
        case 'candidates':
          box = _candidatesBox;
          break;
        case 'job_offers':
          box = _jobOffersBox;
          break;
        case 'favorites':
          box = _favoritesBox;
          break;
      }

      if (box != null) {
        await box.delete(cacheKey);
        debugPrint('🗑️ Cache invalidated: $boxName/$cacheKey');
      }
    } catch (e) {
      debugPrint('❌ Error invalidating cache: $e');
    }
  }

  /// Invalider tout le cache d'une box
  Future<void> clearBox(String boxName) async {
    try {
      Box? box;
      switch (boxName) {
        case 'users':
          box = _usersBox;
          break;
        case 'candidates':
          box = _candidatesBox;
          break;
        case 'job_offers':
          box = _jobOffersBox;
          break;
        case 'favorites':
          box = _favoritesBox;
          break;
      }

      if (box != null) {
        await box.clear();
        debugPrint('🗑️ Box cleared: $boxName');
      }
    } catch (e) {
      debugPrint('❌ Error clearing box: $e');
    }
  }

  /// Nettoyer tout le cache ancien (> 24 heures)
  Future<void> cleanOldCache() async {
    try {
      if (_usersBox == null) await openBoxes();

      int deletedCount = 0;
      final boxes = [_usersBox, _candidatesBox, _jobOffersBox, _favoritesBox];

      for (final box in boxes) {
        if (box == null) continue;

        final keysToDelete = <String>[];

        for (final key in box.keys) {
          final cacheData = box.get(key) as Map?;
          if (cacheData == null) continue;

          try {
            final cachedAt = DateTime.parse(cacheData['cachedAt'] as String);
            final age = DateTime.now().difference(cachedAt);

            if (age.inDays > 1) {
              keysToDelete.add(key as String);
            }
          } catch (e) {
            // Cache corrompu, le supprimer
            keysToDelete.add(key as String);
          }
        }

        for (final key in keysToDelete) {
          await box.delete(key);
          deletedCount++;
        }
      }

      debugPrint('🧹 Cleaned $deletedCount old cache entries');
    } catch (e) {
      debugPrint('❌ Error cleaning old cache: $e');
    }
  }

  /// Obtenir la taille totale du cache (en Ko)
  Future<Map<String, int>> getCacheSize() async {
    try {
      final sizes = <String, int>{};
      final boxes = {
        'users': _usersBox,
        'candidates': _candidatesBox,
        'job_offers': _jobOffersBox,
        'favorites': _favoritesBox,
      };

      for (final entry in boxes.entries) {
        if (entry.value == null) continue;

        int itemCount = entry.value!.length;
        sizes[entry.key] = itemCount;
      }

      debugPrint('📊 Cache sizes: $sizes items');
      return sizes;
    } catch (e) {
      debugPrint('❌ Error getting cache size: $e');
      return {};
    }
  }

  /// Fermer toutes les boxes
  Future<void> closeBoxes() async {
    try {
      await _usersBox?.close();
      await _candidatesBox?.close();
      await _jobOffersBox?.close();
      await _favoritesBox?.close();
      await _metadataBox?.close();

      debugPrint('🔒 All Hive boxes closed');
    } catch (e) {
      debugPrint('❌ Error closing boxes: $e');
    }
  }
}
