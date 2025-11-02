import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service pour vérifier les mises à jour depuis le serveur Chiasma
/// Fonctionne pour les installations hors Play Store
class UpdateCheckerService {
  // URL du fichier de version sur votre serveur
  static const String _versionUrl = 'https://chiasma.pro/version.json';
  static const String _downloadUrl = 'https://chiasma.pro/telecharger.html';

  /// Vérifier s'il y a une nouvelle version disponible
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      // Récupérer la version actuelle de l'app
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      debugPrint('Version actuelle: $currentVersion ($currentBuildNumber)');

      // Récupérer les infos de version depuis le serveur
      final response = await http.get(
        Uri.parse(_versionUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('Erreur serveur: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final latestVersion = data['version'] as String;
      final latestBuildNumber = data['buildNumber'] as int;
      final updateMessage = data['message'] as String?;
      final isForced = data['forceUpdate'] as bool? ?? false;

      debugPrint('Dernière version: $latestVersion ($latestBuildNumber)');

      // Comparer les versions
      if (latestBuildNumber > currentBuildNumber) {
        return {
          'hasUpdate': true,
          'currentVersion': currentVersion,
          'latestVersion': latestVersion,
          'currentBuild': currentBuildNumber,
          'latestBuild': latestBuildNumber,
          'message': updateMessage ?? 'Une nouvelle version est disponible',
          'isForced': isForced,
          'downloadUrl': _downloadUrl,
        };
      }

      return {'hasUpdate': false};
    } catch (e) {
      debugPrint('Erreur lors de la vérification de mise à jour: $e');
      return null;
    }
  }

  /// Afficher une boîte de dialogue pour proposer la mise à jour
  static Future<void> showUpdateDialog(
    BuildContext context,
    Map<String, dynamic> updateInfo,
  ) async {
    final isForced = updateInfo['isForced'] as bool;

    return showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (BuildContext context) {
        return PopScope(
          canPop: !isForced,
          child: AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.system_update,
                  color: Color(0xFFF77F00),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isForced
                        ? 'Mise à jour requise'
                        : 'Mise à jour disponible',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  updateInfo['message'] as String,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Version actuelle :',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            updateInfo['currentVersion'] as String,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nouvelle version :',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            updateInfo['latestVersion'] as String,
                            style: const TextStyle(
                              color: Color(0xFFF77F00),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isForced) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      border: Border.all(color: Colors.orange, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cette mise à jour est obligatoire pour continuer à utiliser l\'application.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isForced)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Plus tard',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _openDownloadPage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF77F00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.download),
                label: const Text(
                  'Télécharger',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Ouvrir la page de téléchargement
  static Future<void> _openDownloadPage() async {
    final uri = Uri.parse(_downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Impossible d\'ouvrir l\'URL: $_downloadUrl');
    }
  }

  /// Vérifier et afficher la mise à jour si disponible
  static Future<void> checkAndShowUpdate(BuildContext context) async {
    final updateInfo = await checkForUpdate();

    if (updateInfo == null) {
      // Erreur de connexion ou pas de réponse
      return;
    }

    if (updateInfo['hasUpdate'] == true && context.mounted) {
      await showUpdateDialog(context, updateInfo);
    }
  }

  /// Vérification manuelle avec feedback utilisateur
  static Future<void> checkManually(BuildContext context) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF77F00),
        ),
      ),
    );

    final updateInfo = await checkForUpdate();

    // Fermer le loader
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (updateInfo == null) {
      // Erreur de connexion
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de vérifier les mises à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (updateInfo['hasUpdate'] == true) {
      if (context.mounted) {
        await showUpdateDialog(context, updateInfo);
      }
    } else {
      // Pas de mise à jour
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Vous avez la dernière version'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
