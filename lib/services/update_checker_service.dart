import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckerService {
  static const String _cloudFunctionUrl =
      'https://us-central1-chiasma-android.cloudfunctions.net/getAppVersion';
  static const String _versionJsonUrl = 'https://chiasma.pro/version.json';
  static const String _downloadUrl = 'https://chiasma.pro/telecharger.html';
  static const _orangeColor = Color(0xFFF77F00);

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      debugPrint('Version actuelle: $currentVersion ($currentBuildNumber)');

      // Essayer d'abord la Cloud Function
      Map<String, dynamic>? data = await _fetchFromCloudFunction();

      // Si la Cloud Function échoue, essayer version.json
      if (data == null) {
        debugPrint('Cloud Function indisponible, essai avec version.json...');
        data = await _fetchFromVersionJson();
      }

      if (data == null) {
        debugPrint('Impossible de récupérer les informations de version');
        return null;
      }

      final latestBuildNumber = data['buildNumber'] as int;

      debugPrint('Dernière version: ${data['version']} ($latestBuildNumber)');

      if (latestBuildNumber > currentBuildNumber) {
        return {
          'hasUpdate': true,
          'currentVersion': currentVersion,
          'latestVersion': data['version'],
          'currentBuild': currentBuildNumber,
          'latestBuild': latestBuildNumber,
          'message': data['message'] ?? 'Une nouvelle version est disponible',
          'isForced': data['forceUpdate'] ?? false,
          'downloadUrl': _downloadUrl,
        };
      }

      return {'hasUpdate': false};
    } catch (e) {
      debugPrint('Erreur lors de la vérification de mise à jour: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _fetchFromCloudFunction() async {
    try {
      final response = await http
          .get(Uri.parse(_cloudFunctionUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('✓ Version récupérée depuis Cloud Function');
        return json.decode(response.body) as Map<String, dynamic>;
      }

      debugPrint('Cloud Function erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Erreur Cloud Function: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _fetchFromVersionJson() async {
    try {
      final response = await http
          .get(Uri.parse(_versionJsonUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('✓ Version récupérée depuis version.json');
        return json.decode(response.body) as Map<String, dynamic>;
      }

      debugPrint('version.json erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Erreur version.json: $e');
      return null;
    }
  }

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
                const Icon(Icons.system_update, color: _orangeColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isForced ? 'Mise à jour requise' : 'Mise à jour disponible',
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
                _buildVersionInfo(updateInfo),
                if (isForced) ...[
                  const SizedBox(height: 16),
                  _buildForceUpdateWarning(),
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
                  backgroundColor: _orangeColor,
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

  static Widget _buildVersionInfo(Map<String, dynamic> updateInfo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildVersionRow(
            'Version actuelle :',
            updateInfo['currentVersion'],
            Colors.grey[700],
          ),
          const SizedBox(height: 8),
          _buildVersionRow(
            'Nouvelle version :',
            updateInfo['latestVersion'],
            _orangeColor,
          ),
        ],
      ),
    );
  }

  static Widget _buildVersionRow(
    String label,
    String version,
    Color? valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(
          version,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: valueColor == _orangeColor ? 16 : 14,
          ),
        ),
      ],
    );
  }

  static Widget _buildForceUpdateWarning() {
    return Container(
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
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openDownloadPage() async {
    final uri = Uri.parse(_downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Impossible d\'ouvrir l\'URL: $_downloadUrl');
    }
  }

  static Future<void> checkAndShowUpdate(BuildContext context) async {
    final updateInfo = await checkForUpdate();

    if (updateInfo == null) return;

    if (updateInfo['hasUpdate'] == true && context.mounted) {
      await showUpdateDialog(context, updateInfo);
    }
  }

  static Future<void> checkManually(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: _orangeColor)),
    );

    final updateInfo = await checkForUpdate();

    if (context.mounted) Navigator.of(context).pop();

    if (updateInfo == null) {
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
      if (context.mounted) await showUpdateDialog(context, updateInfo);
    } else {
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
