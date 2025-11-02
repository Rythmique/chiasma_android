import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service de gestion des mises à jour de l'application
///
/// Utilise le package in_app_update pour détecter et installer
/// automatiquement les mises à jour disponibles sur le Play Store
class AppUpdateService {
  /// Vérifier et afficher les mises à jour disponibles
  ///
  /// Cette méthode doit être appelée au démarrage de l'application
  /// Elle propose deux types de mise à jour :
  /// - Flexible : L'utilisateur peut continuer à utiliser l'app
  /// - Immédiate : L'utilisateur doit mettre à jour avant de continuer
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Vérifier la disponibilité d'une mise à jour
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Déterminer le type de mise à jour en fonction de la priorité
        // staleDays indique depuis combien de jours la mise à jour est disponible
        final shouldForceUpdate = updateInfo.immediateUpdateAllowed &&
            (updateInfo.availableVersionCode ?? 0) >
                (updateInfo.clientVersionStalenessDays ?? 0) + 2;

        if (shouldForceUpdate) {
          // Mise à jour immédiate obligatoire
          await _performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed && context.mounted) {
          // Mise à jour flexible (non bloquante)
          // ignore: use_build_context_synchronously
          await _performFlexibleUpdate(context);
        }
      }
    } catch (e) {
      // En cas d'erreur, on continue silencieusement
      // (par exemple, en mode debug ou si le Play Store n'est pas disponible)
      debugPrint('Erreur lors de la vérification de mise à jour: $e');
    }
  }

  /// Effectuer une mise à jour immédiate
  ///
  /// L'utilisateur est bloqué jusqu'à ce que la mise à jour soit installée
  static Future<void> _performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour immédiate: $e');
    }
  }

  /// Effectuer une mise à jour flexible
  ///
  /// L'utilisateur peut continuer à utiliser l'app pendant le téléchargement
  /// Un dialogue s'affichera pour installer la mise à jour une fois téléchargée
  static Future<void> _performFlexibleUpdate(BuildContext context) async {
    try {
      // Démarrer la mise à jour flexible
      final result = await InAppUpdate.startFlexibleUpdate();

      // Une fois le téléchargement terminé, afficher un dialogue
      // pour installer la mise à jour
      if (result == AppUpdateResult.success && context.mounted) {
        // ignore: use_build_context_synchronously
        _showUpdateDialog(context);
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour flexible: $e');
    }
  }

  /// Afficher un dialogue pour installer la mise à jour téléchargée
  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Color(0xFFF77F00)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009E60),
            ),
            child: const Text('Installer'),
          ),
        ],
      ),
    );
  }

  /// Vérifier manuellement les mises à jour
  ///
  /// Cette méthode peut être appelée depuis les paramètres de l'app
  /// pour permettre à l'utilisateur de vérifier manuellement
  static Future<void> checkForUpdateManually(BuildContext context) async {
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (!context.mounted) return;

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Afficher un dialogue pour proposer la mise à jour
        _showManualUpdateDialog(context, updateInfo);
      } else {
        // Aucune mise à jour disponible
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous utilisez déjà la dernière version'),
            backgroundColor: Color(0xFF009E60),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Afficher un dialogue pour la vérification manuelle
  static void _showManualUpdateDialog(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Color(0xFFF77F00)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009E60),
            ),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}
