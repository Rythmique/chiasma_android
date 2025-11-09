import 'package:algolia_client_search/algolia_client_search.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer les recherches Algolia
///
/// Ce service permet de faire des recherches ultra-rapides dans la base de données
/// avec filtres, facettes et tolérance aux fautes de frappe.
class AlgoliaService {
  SearchClient? _client;
  bool _isInitialized = false;

  static final AlgoliaService _instance = AlgoliaService._internal();
  factory AlgoliaService() => _instance;

  AlgoliaService._internal();

  /// Vérifie si Algolia est initialisé
  bool get isInitialized => _isInitialized;

  /// Initialiser Algolia avec les credentials
  ///
  /// IMPORTANT: Ces clés doivent être configurées dans les variables d'environnement
  /// ou dans un fichier de configuration sécurisé (jamais hardcodées ici)
  Future<void> initialize({
    required String applicationId,
    required String apiKey,
  }) async {
    // Éviter la double initialisation
    if (_isInitialized && _client != null) {
      debugPrint('⚠️ AlgoliaService already initialized, skipping...');
      return;
    }

    try {
      _client = SearchClient(
        appId: applicationId,
        apiKey: apiKey,
      );
      _isInitialized = true;

      debugPrint('✅ AlgoliaService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing AlgoliaService: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Rechercher des utilisateurs avec filtres
  ///
  /// [query] Texte de recherche (nom, prénom, fonction, etc.)
  /// [searchMode] Mode de recherche: 'zone_actuelle', 'zone_souhaitee', 'fonction', 'dren'
  /// [filterValue] Valeur du filtre (ex: "Abidjan" pour zone)
  /// [accountType] Type de compte: 'teacher_transfer', 'teacher_candidate', 'school'
  /// [limit] Nombre de résultats max (default: 50)
  Future<Map<String, dynamic>> searchUsers({
    String query = '',
    String? searchMode,
    String? filterValue,
    String? accountType,
    int limit = 50,
  }) async {
    // Vérifier que le client est initialisé
    if (_client == null || !_isInitialized) {
      debugPrint('⚠️ AlgoliaService not initialized');
      return {
        'hits': [],
        'nbHits': 0,
        'query': query,
        'error': 'Service not initialized',
      };
    }

    try {
      // Construire les filtres Algolia
      List<String> filters = [];

      if (accountType != null) {
        filters.add('accountType:"$accountType"');
      }

      // Ajouter filtre selon le mode de recherche
      if (searchMode != null && filterValue != null && filterValue.isNotEmpty) {
        switch (searchMode) {
          case 'zone_actuelle':
            filters.add('zoneActuelle:"$filterValue"');
            break;
          case 'zone_souhaitee':
            filters.add('zonesSouhaitees:"$filterValue"');
            break;
          case 'fonction':
            filters.add('fonction:"$filterValue"');
            break;
          case 'dren':
            filters.add('dren:"$filterValue"');
            break;
        }
      }

      debugPrint('🔍 Algolia search users: query="$query", filters=${filters.join(' AND ')}');

      final response = await _client!.searchSingleIndex(
        indexName: 'users',
        searchParams: SearchParamsObject(
          query: query.isEmpty ? null : query,
          filters: filters.isNotEmpty ? filters.join(' AND ') : null,
          hitsPerPage: limit,
          attributesToRetrieve: [
            'objectID',
            'uid',
            'nom',
            'prenom',
            'fonction',
            'zoneActuelle',
            'zonesSouhaitees',
            'dren',
            'accountType',
            'isVerified',
            'photoURL',
            'bio',
            'experience',
          ],
        ),
      );

      debugPrint('✅ Algolia found ${response.hits.length} users');

      return {
        'hits': response.hits.map((hit) => hit.toJson()).toList(),
        'nbHits': response.nbHits ?? 0,
        'query': query,
      };
    } catch (e) {
      debugPrint('❌ Error searching users in Algolia: $e');
      return {
        'hits': [],
        'nbHits': 0,
        'query': query,
        'error': e.toString(),
      };
    }
  }

  /// Rechercher des utilisateurs pour match mutuel
  ///
  /// Trouve les utilisateurs dont:
  /// - Leur zone actuelle = ma zone souhaitée
  /// - Leur zone souhaitée = ma zone actuelle
  Future<Map<String, dynamic>> searchMutualMatches({
    required String myZoneActuelle,
    required String myZoneSouhaitee,
    String? accountType,
    int limit = 50,
  }) async {
    // Vérifier que le client est initialisé
    if (_client == null || !_isInitialized) {
      debugPrint('⚠️ AlgoliaService not initialized');
      return {
        'hits': [],
        'nbHits': 0,
        'error': 'Service not initialized',
      };
    }

    try {
      // Utiliser des filtres pour le match mutuel
      final filters = [
        if (accountType != null) 'accountType:"$accountType"',
        'zoneActuelle:"$myZoneSouhaitee"',
        'zonesSouhaitees:"$myZoneActuelle"',
      ].join(' AND ');

      debugPrint('🔍 Algolia mutual match: $myZoneActuelle ↔ $myZoneSouhaitee');

      final response = await _client!.searchSingleIndex(
        indexName: 'users',
        searchParams: SearchParamsObject(
          filters: filters,
          hitsPerPage: limit,
        ),
      );

      debugPrint('✅ Algolia found ${response.hits.length} mutual matches');

      return {
        'hits': response.hits.map((hit) => hit.toJson()).toList(),
        'nbHits': response.nbHits ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error searching mutual matches in Algolia: $e');
      return {
        'hits': [],
        'nbHits': 0,
        'error': e.toString(),
      };
    }
  }

  /// Rechercher des offres d'emploi avec filtres
  ///
  /// [query] Texte de recherche (titre, description, discipline, établissement)
  /// [ville] Ville de l'offre
  /// [typeContrat] Type de contrat (CDI, CDD, Vacataire, etc.)
  /// [limit] Nombre de résultats max (default: 50)
  Future<Map<String, dynamic>> searchJobOffers({
    String query = '',
    String? ville,
    String? typeContrat,
    int limit = 50,
  }) async {
    // Vérifier que le client est initialisé
    if (_client == null || !_isInitialized) {
      debugPrint('⚠️ AlgoliaService not initialized');
      return {
        'hits': [],
        'nbHits': 0,
        'query': query,
        'error': 'Service not initialized',
      };
    }

    try {
      // Construire les filtres
      List<String> filters = [
        'status:"open"', // Seulement les offres ouvertes
      ];

      if (ville != null && ville.isNotEmpty) {
        filters.add('ville:"$ville"');
      }

      if (typeContrat != null && typeContrat.isNotEmpty) {
        filters.add('typeContrat:"$typeContrat"');
      }

      debugPrint('🔍 Algolia search jobs: query="$query", filters=${filters.join(' AND ')}');

      final response = await _client!.searchSingleIndex(
        indexName: 'job_offers',
        searchParams: SearchParamsObject(
          query: query.isEmpty ? null : query,
          filters: filters.join(' AND '),
          hitsPerPage: limit,
          attributesToRetrieve: [
            'objectID',
            'id',
            'title',
            'description',
            'discipline',
            'ville',
            'typeContrat',
            'schoolId',
            'schoolName',
            'status',
            'createdAt',
          ],
        ),
      );

      debugPrint('✅ Algolia found ${response.hits.length} job offers');

      return {
        'hits': response.hits.map((hit) => hit.toJson()).toList(),
        'nbHits': response.nbHits ?? 0,
        'query': query,
      };
    } catch (e) {
      debugPrint('❌ Error searching job offers in Algolia: $e');
      return {
        'hits': [],
        'nbHits': 0,
        'query': query,
        'error': e.toString(),
      };
    }
  }

  /// Obtenir des suggestions de recherche
  ///
  /// Retourne les suggestions de noms/prénoms qui correspondent à la query
  Future<List<String>> getSuggestions({
    required String query,
    String? accountType,
    int limit = 10,
  }) async {
    // Vérifier que le client est initialisé
    if (_client == null || !_isInitialized) {
      debugPrint('⚠️ AlgoliaService not initialized');
      return [];
    }

    try {
      final filters = accountType != null ? 'accountType:"$accountType"' : null;

      final response = await _client!.searchSingleIndex(
        indexName: 'users',
        searchParams: SearchParamsObject(
          query: query,
          filters: filters,
          hitsPerPage: limit,
          attributesToRetrieve: ['nom', 'prenom'],
        ),
      );

      // Extraire les noms et prénoms uniques
      final suggestions = <String>{};
      for (final hit in response.hits) {
        final data = hit.toJson();
        final nom = data['nom'] as String?;
        final prenom = data['prenom'] as String?;

        if (nom != null && nom.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(nom);
        }
        if (prenom != null && prenom.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(prenom);
        }
      }

      return suggestions.take(limit).toList();
    } catch (e) {
      debugPrint('❌ Error getting suggestions from Algolia: $e');
      return [];
    }
  }

  /// Fermer le client Algolia
  void dispose() {
    // Le client Algolia moderne n'a pas de méthode dispose
    debugPrint('🔒 AlgoliaService disposed');
  }
}
