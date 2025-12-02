/**
 * Cloud Function pour vérifier la version de l'application
 *
 * Retourne les informations de version pour permettre aux clients
 * de vérifier s'ils ont la dernière version installée.
 */

import * as functions from "firebase-functions";

/**
 * Informations sur la dernière version disponible
 * À mettre à jour manuellement après chaque déploiement
 */
const LATEST_VERSION = {
  version: "1.0.3",
  buildNumber: 103,
  message: "Correction importante du téléchargement de fichiers dans la messagerie.",
  forceUpdate: false, // true = mise à jour obligatoire
  features: [
    "🔧 Téléchargement de fichiers corrigé (messagerie)",
    "📎 PDF, Word, Excel maintenant téléchargeables",
    "✅ Fix appliqué pour École, Candidat, Enseignant",
    "🔔 Notifications push avec son et vibration",
    "📚 Niveaux maternelle et primaire disponibles",
  ],
  releaseDate: "2025-12-02",
  downloadUrl: "https://chiasma.pro/telecharger.html",
};

/**
 * Endpoint HTTP pour récupérer les informations de version
 *
 * GET /getAppVersion
 *
 * Retourne:
 * {
 *   version: "1.0.2",
 *   buildNumber: 102,
 *   message: "...",
 *   forceUpdate: false,
 *   features: [...],
 *   releaseDate: "2025-11-11",
 *   downloadUrl: "..."
 * }
 */
export const getAppVersion = functions.https.onRequest((req, res) => {
  // Permettre CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  // Répondre aux requêtes OPTIONS (preflight)
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Seule méthode GET est autorisée
  if (req.method !== "GET") {
    res.status(405).json({error: "Méthode non autorisée"});
    return;
  }

  // Retourner les informations de version
  res.status(200).json(LATEST_VERSION);
});

/**
 * Fonction callable pour vérifier la version (alternative sécurisée)
 *
 * Peut être appelée depuis l'app avec :
 * FirebaseFunctions.instance.httpsCallable('checkAppVersion').call({
 *   'currentVersion': '1.0.1',
 *   'currentBuild': 101
 * });
 */
export const checkAppVersion = functions.https.onCall((data, context) => {
  const currentBuild = data.currentBuild as number || 0;
  const currentVersion = data.currentVersion as string || "0.0.0";

  const hasUpdate = LATEST_VERSION.buildNumber > currentBuild;

  return {
    hasUpdate,
    currentVersion,
    currentBuild,
    latestVersion: LATEST_VERSION.version,
    latestBuild: LATEST_VERSION.buildNumber,
    message: LATEST_VERSION.message,
    forceUpdate: LATEST_VERSION.forceUpdate,
    features: LATEST_VERSION.features,
    releaseDate: LATEST_VERSION.releaseDate,
    downloadUrl: LATEST_VERSION.downloadUrl,
  };
});
