import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static const _orangeColor = Color(0xFFF77F00);
  static const _greenColor = Color(0xFF009E60);

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        final shouldForceUpdate =
            updateInfo.immediateUpdateAllowed &&
            (updateInfo.availableVersionCode ?? 0) >
                (updateInfo.clientVersionStalenessDays ?? 0) + 2;

        if (shouldForceUpdate) {
          await _performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed && context.mounted) {
          await _performFlexibleUpdate(context);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de mise à jour: $e');
    }
  }

  static Future<void> _performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour immédiate: $e');
    }
  }

  static Future<void> _performFlexibleUpdate(BuildContext context) async {
    try {
      final result = await InAppUpdate.startFlexibleUpdate();

      if (result == AppUpdateResult.success && context.mounted) {
        _showUpdateDialog(context);
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour flexible: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: _orangeColor),
            SizedBox(width: 12),
            Text('Mise à jour disponible'),
          ],
        ),
        content: const Text(
          'Une nouvelle version de CHIASMA a été téléchargée.\n\n'
          'Voulez-vous installer la mise à jour maintenant ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              InAppUpdate.completeFlexibleUpdate();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _greenColor),
            child: const Text('Installer'),
          ),
        ],
      ),
    );
  }

  static Future<void> checkForUpdateManually(BuildContext context) async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (!context.mounted) return;

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        _showManualUpdateDialog(context, updateInfo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous utilisez déjà la dernière version'),
            backgroundColor: _greenColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static void _showManualUpdateDialog(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: _orangeColor),
            SizedBox(width: 12),
            Text('Nouvelle version'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Une nouvelle version de CHIASMA est disponible !',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (updateInfo.availableVersionCode != null)
              Text('Version: ${updateInfo.availableVersionCode}'),
            const SizedBox(height: 8),
            const Text(
              'Nous recommandons de mettre à jour pour bénéficier '
              'des dernières améliorations et corrections.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (updateInfo.immediateUpdateAllowed) {
                _performImmediateUpdate();
              } else if (updateInfo.flexibleUpdateAllowed) {
                _performFlexibleUpdate(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _greenColor),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}
