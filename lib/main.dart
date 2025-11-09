import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/login_screen.dart';
import 'package:myapp/services/app_update_service.dart';
import 'package:myapp/services/update_checker_service.dart';
import 'package:myapp/services/cache_service.dart';
import 'package:myapp/services/algolia_service.dart';
import 'package:myapp/config/algolia_config.dart';
import 'firebase_options.dart';

// Handler pour les messages en arrière-plan
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Message reçu en arrière-plan: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gestionnaire d'erreurs simplifié
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('Error: ${details.exception}');
    }
  };

  // Configurer le handler de notifications en arrière-plan (avant Firebase.initializeApp)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Initialiser Firebase - c'est la SEULE initialisation bloquante nécessaire
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    // Firebase est critique, mais on laisse l'app se lancer pour afficher l'erreur
  }

  // Lancer l'app immédiatement - les autres initialisations se feront en arrière-plan
  runApp(const MyApp());
}

// Widget d'initialisation qui gère Firebase en arrière-plan
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  bool _error = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Vérifier que Firebase est bien initialisé
      try {
        Firebase.app();
      } catch (e) {
        throw Exception('Firebase non initialisé: $e');
      }

      // Configuration Firestore
      try {
        if (kIsWeb) {
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: false,
          );
        } else {
          FirebaseFirestore.instance.settings = const Settings(
            persistenceEnabled: true,
            cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
          );
        }
        debugPrint('✅ Firestore configured');
      } catch (e) {
        debugPrint('⚠️ Erreur configuration Firestore: $e');
        // Non critique, on continue
      }

      // Marquer comme initialisé immédiatement (l'app peut démarrer)
      if (mounted) {
        setState(() => _initialized = true);
      }

      // Initialisations en arrière-plan (non bloquantes) - avec gestion d'erreurs
      if (AlgoliaConfig.isConfigured) {
        // ignore: unawaited_futures
        _initializeAlgolia();
      }

      if (!kIsWeb) {
        // ignore: unawaited_futures
        _initializeCache();
      }

      // Vérifier les mises à jour après un délai
      if (!kIsWeb && mounted) {
        // ignore: unawaited_futures
        Future.delayed(const Duration(seconds: 3), () async {
          if (mounted) {
            try {
              await AppUpdateService.checkForUpdate(context);
            } catch (e) {
              debugPrint('⚠️ Update check error: $e');
            }

            // ignore: unawaited_futures
            Future.delayed(const Duration(seconds: 1), () async {
              if (mounted) {
                try {
                  await UpdateCheckerService.checkAndShowUpdate(context);
                } catch (e) {
                  debugPrint('⚠️ Update checker error: $e');
                }
              }
            });
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur critique d\'initialisation: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Initialisation Algolia en arrière-plan
  Future<void> _initializeAlgolia() async {
    try {
      await AlgoliaService().initialize(
        applicationId: AlgoliaConfig.applicationId,
        apiKey: AlgoliaConfig.searchApiKey,
      );
      debugPrint('✅ Algolia initialized');
    } catch (e) {
      debugPrint('⚠️ Algolia initialization failed: $e');
    }
  }

  // Initialisation du cache en arrière-plan
  Future<void> _initializeCache() async {
    try {
      await CacheService.initialize();
      final cacheService = CacheService();
      await cacheService.openBoxes();
      await cacheService.cleanOldCache();
      debugPrint('✅ Cache service initialized');
    } catch (e) {
      debugPrint('⚠️ Cache service initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher erreur si échec
    if (_error) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur d\'initialisation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage.isNotEmpty ? _errorMessage : 'Erreur inconnue',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Veuillez redémarrer l\'application',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Afficher LoginScreen si initialisé
    if (_initialized) {
      return const LoginScreen();
    }

    // Splash screen minimaliste pour un chargement rapide
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo simplifié (pas de BoxDecoration complexe)
            Icon(
              Icons.swap_horiz_rounded,
              size: 80,
              color: Color(0xFFF77F00),
            ),
            SizedBox(height: 24),
            Text(
              'CHIASMA',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF77F00),
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF77F00)),
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CHIASMA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF77F00), // Orange ivoirien
          primary: const Color(0xFFF77F00), // Orange
          secondary: const Color(0xFF009E60), // Vert
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF2C2C2C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Police avec support étendu des caractères Unicode
        textTheme: GoogleFonts.robotoTextTheme(),
        fontFamily: GoogleFonts.roboto().fontFamily,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF77F00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF77F00), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const AppInitializer(),
    );
  }
}
