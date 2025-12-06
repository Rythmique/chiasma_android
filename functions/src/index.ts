
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Initialiser l'SDK Admin Firebase
admin.initializeApp();
const db = admin.firestore();

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
