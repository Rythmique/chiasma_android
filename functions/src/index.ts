
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialiser l'SDK Admin Firebase
admin.initializeApp();
const db = admin.firestore();

/**
 * Exemple de fonction Cloud Function
 * Toutes les fonctions de paiement ont été retirées
 */
export const helloWorld = functions.https.onRequest((request, response) => {
  response.send("Hello from Firebase!");
});

// Exporter les fonctions de synchronisation Algolia
export {
  syncUserToAlgolia,
  syncJobOfferToAlgolia,
  reindexAllUsers,
  reindexAllJobOffers,
} from "./algoliaSync";

// Exporter les fonctions de notifications push
export {
  sendPushNotification,
  cleanInvalidTokens,
  sendTestNotification,
} from "./notifications";

// Exporter les fonctions de vérification de version
export {
  getAppVersion,
  checkAppVersion,
} from "./versionCheck";
