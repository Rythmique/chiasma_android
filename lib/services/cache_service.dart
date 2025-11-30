import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Box? _usersBox;
  Box? _candidatesBox;
  Box? _jobOffersBox;
  Box? _favoritesBox;
  Box? _metadataBox;

  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      debugPrint('✅ Hive initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Hive: $e');
      rethrow;
    }
  }

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

  Future<void> _saveToCache(
    Box? box,
    String cacheKey,
    List<Map<String, dynamic>> data,
    String boxName,
  ) async {
    try {
      if (box == null) await openBoxes();

      final cacheData = {
        'data': data,
        'cachedAt': DateTime.now().toIso8601String(),
        'count': data.length,
      };

      await box!.put(cacheKey, cacheData);
      debugPrint('💾 Saved ${data.length} items to cache: $boxName/$cacheKey');
    } catch (e) {
      debugPrint('❌ Error saving to cache: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> _getFromCache(
    Box? box,
    String cacheKey,
    String boxName, {
    Duration maxAge = const Duration(hours: 1),
  }) async {
    try {
      if (box == null) await openBoxes();

      final cacheData = box!.get(cacheKey) as Map?;
      if (cacheData == null) {
        debugPrint('📭 No cache found for: $boxName/$cacheKey');
        return null;
      }

      final cachedAt = DateTime.parse(cacheData['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      if (age > maxAge) {
        debugPrint(
          '⏰ Cache expired for: $boxName/$cacheKey (age: ${age.inMinutes}min)',
        );
        return null;
      }

      final data = (cacheData['data'] as List).cast<Map<String, dynamic>>();
      debugPrint(
        '✅ Loaded ${data.length} items from cache: $boxName/$cacheKey (age: ${age.inMinutes}min)',
      );
      return data;
    } catch (e) {
      debugPrint('❌ Error loading from cache: $e');
      return null;
    }
  }

  Future<void> saveUsersToCache(
    String cacheKey,
    List<Map<String, dynamic>> users,
  ) => _saveToCache(_usersBox, cacheKey, users, 'users');

  Future<List<Map<String, dynamic>>?> getUsersFromCache(
    String cacheKey, {
    Duration maxAge = const Duration(hours: 1),
  }) => _getFromCache(_usersBox, cacheKey, 'users', maxAge: maxAge);

  Future<void> saveCandidatesToCache(
    String cacheKey,
    List<Map<String, dynamic>> candidates,
  ) => _saveToCache(_candidatesBox, cacheKey, candidates, 'candidates');

  Future<List<Map<String, dynamic>>?> getCandidatesFromCache(
    String cacheKey, {
    Duration maxAge = const Duration(hours: 1),
  }) => _getFromCache(_candidatesBox, cacheKey, 'candidates', maxAge: maxAge);

  Future<void> saveJobOffersToCache(
    String cacheKey,
    List<Map<String, dynamic>> jobOffers,
  ) => _saveToCache(_jobOffersBox, cacheKey, jobOffers, 'job_offers');

  Future<List<Map<String, dynamic>>?> getJobOffersFromCache(
    String cacheKey, {
    Duration maxAge = const Duration(hours: 1),
  }) => _getFromCache(_jobOffersBox, cacheKey, 'job_offers', maxAge: maxAge);

  Future<void> saveFavoritesToCache(
    String userId,
    List<Map<String, dynamic>> favorites,
  ) => _saveToCache(_favoritesBox, 'favorites_$userId', favorites, 'favorites');

  Future<List<Map<String, dynamic>>?> getFavoritesFromCache(
    String userId, {
    Duration maxAge = const Duration(minutes: 30),
  }) => _getFromCache(
    _favoritesBox,
    'favorites_$userId',
    'favorites',
    maxAge: maxAge,
  );

  Future<void> invalidateCache(String boxName, String cacheKey) async {
    try {
      final box = _getBoxByName(boxName);

      if (box != null) {
        await box.delete(cacheKey);
        debugPrint('🗑️ Cache invalidated: $boxName/$cacheKey');
      }
    } catch (e) {
      debugPrint('❌ Error invalidating cache: $e');
    }
  }

  Future<void> clearBox(String boxName) async {
    try {
      final box = _getBoxByName(boxName);

      if (box != null) {
        await box.clear();
        debugPrint('🗑️ Box cleared: $boxName');
      }
    } catch (e) {
      debugPrint('❌ Error clearing box: $e');
    }
  }

  Box? _getBoxByName(String boxName) {
    switch (boxName) {
      case 'users':
        return _usersBox;
      case 'candidates':
        return _candidatesBox;
      case 'job_offers':
        return _jobOffersBox;
      case 'favorites':
        return _favoritesBox;
      default:
        return null;
    }
  }

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
        sizes[entry.key] = entry.value!.length;
      }

      debugPrint('📊 Cache sizes: $sizes items');
      return sizes;
    } catch (e) {
      debugPrint('❌ Error getting cache size: $e');
      return {};
    }
  }

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
