/**
 * Cloud Functions pour synchroniser Firestore avec Algolia
 *
 * Ces fonctions se déclenchent automatiquement quand des documents
 * sont créés/modifiés/supprimés dans Firestore et mettent à jour
 * les index Algolia correspondants.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import algoliasearch from 'algoliasearch';

// Récupérer les identifiants Algolia depuis les variables d'environnement (.env)
// Solution moderne et durable - Compatible au-delà de Mars 2026
const algoliaAppId = process.env.ALGOLIA_APP_ID || '';
const algoliaAdminKey = process.env.ALGOLIA_ADMIN_KEY || '';

// Initialiser Algolia avec les identifiants configurés
const algoliaClient = algoliasearch(algoliaAppId, algoliaAdminKey);

const usersIndex = algoliaClient.initIndex('users');
const jobOffersIndex = algoliaClient.initIndex('job_offers');

/**
 * Synchroniser les utilisateurs vers Algolia
 *
 * Se déclenche quand un document users/{userId} est créé, modifié ou supprimé
 */
export const syncUserToAlgolia = functions.firestore
  .document('users/{userId}')
  .onWrite(async (change, context) => {
    const userId = context.params.userId;

    try {
      // Si le document est supprimé
      if (!change.after.exists) {
        console.log(`Suppression de l'utilisateur ${userId} d'Algolia`);
        await usersIndex.deleteObject(userId);
        return null;
      }

      // Document créé ou modifié
      const userData = change.after.data();
      if (!userData) return null;

      // Préparer l'objet pour Algolia
      const algoliaObject = {
        objectID: userId,
        uid: userId,
        nom: userData.nom || '',
        prenom: userData.prenom || '',
        fonction: userData.fonction || '',
        zoneActuelle: userData.zoneActuelle || '',
        zonesSouhaitees: userData.zonesSouhaitees || [],
        dren: userData.dren || '',
        accountType: userData.accountType || '',
        isVerified: userData.isVerified || false,
        photoURL: userData.photoURL || '',
        bio: userData.bio || '',
        experience: userData.experience || '',
        // Timestamp pour tri
        createdAt: userData.createdAt?.toMillis() || Date.now(),
        // Champs pour recherche
        _tags: [
          userData.accountType,
          userData.fonction,
          userData.zoneActuelle,
          ...(userData.zonesSouhaitees || []),
        ].filter(Boolean),
      };

      console.log(`Indexation de l'utilisateur ${userId} dans Algolia`);
      await usersIndex.saveObject(algoliaObject);

      return null;
    } catch (error) {
      console.error(`Erreur lors de la synchronisation de l'utilisateur ${userId}:`, error);
      // Ne pas faire échouer la fonction, juste logger l'erreur
      return null;
    }
  });

/**
 * Synchroniser les offres d'emploi vers Algolia
 *
 * Se déclenche quand un document job_offers/{offerId} est créé, modifié ou supprimé
 */
export const syncJobOfferToAlgolia = functions.firestore
  .document('job_offers/{offerId}')
  .onWrite(async (change, context) => {
    const offerId = context.params.offerId;

    try {
      // Si le document est supprimé
      if (!change.after.exists) {
        console.log(`Suppression de l'offre ${offerId} d'Algolia`);
        await jobOffersIndex.deleteObject(offerId);
        return null;
      }

      // Document créé ou modifié
      const offerData = change.after.data();
      if (!offerData) return null;

      // Ne synchroniser que les offres ouvertes
      if (offerData.status !== 'open') {
        // Supprimer de l'index si l'offre n'est plus ouverte
        console.log(`Suppression de l'offre fermée ${offerId} d'Algolia`);
        await jobOffersIndex.deleteObject(offerId);
        return null;
      }

      // Préparer l'objet pour Algolia
      const algoliaObject = {
        objectID: offerId,
        id: offerId,
        title: offerData.title || '',
        description: offerData.description || '',
        discipline: offerData.discipline || '',
        ville: offerData.ville || '',
        typeContrat: offerData.typeContrat || '',
        schoolId: offerData.schoolId || '',
        schoolName: offerData.schoolName || '',
        status: offerData.status,
        // Timestamp pour tri
        createdAt: offerData.createdAt?.toMillis() || Date.now(),
        // Champs pour recherche
        _tags: [
          offerData.typeContrat,
          offerData.discipline,
          offerData.ville,
          'open',
        ].filter(Boolean),
      };

      console.log(`Indexation de l'offre ${offerId} dans Algolia`);
      await jobOffersIndex.saveObject(algoliaObject);

      return null;
    } catch (error) {
      console.error(`Erreur lors de la synchronisation de l'offre ${offerId}:`, error);
      return null;
    }
  });

/**
 * Fonction HTTP pour réindexer tous les utilisateurs
 *
 * Utiliser avec précaution, seulement pour la configuration initiale
 * ou après un problème de synchronisation.
 *
 * Appel: POST https://region-project.cloudfunctions.net/reindexAllUsers
 */
export const reindexAllUsers = functions.https.onRequest(async (req, res) => {
  try {
    // TODO: Ajouter authentification en production si nécessaire
    // Utiliser Firebase Auth ou un token Bearer personnalisé

    console.log('Début de la réindexation de tous les utilisateurs');

    const usersSnapshot = await admin.firestore().collection('users').get();
    const algoliaObjects: any[] = [];

    usersSnapshot.forEach((doc) => {
      const userData = doc.data();
      algoliaObjects.push({
        objectID: doc.id,
        uid: doc.id,
        nom: userData.nom || '',
        prenom: userData.prenom || '',
        fonction: userData.fonction || '',
        zoneActuelle: userData.zoneActuelle || '',
        zonesSouhaitees: userData.zonesSouhaitees || [],
        dren: userData.dren || '',
        accountType: userData.accountType || '',
        isVerified: userData.isVerified || false,
        photoURL: userData.photoURL || '',
        bio: userData.bio || '',
        experience: userData.experience || '',
        createdAt: userData.createdAt?.toMillis() || Date.now(),
        _tags: [
          userData.accountType,
          userData.fonction,
          userData.zoneActuelle,
          ...(userData.zonesSouhaitees || []),
        ].filter(Boolean),
      });
    });

    // Indexer par lots de 1000
    const batchSize = 1000;
    for (let i = 0; i < algoliaObjects.length; i += batchSize) {
      const batch = algoliaObjects.slice(i, i + batchSize);
      await usersIndex.saveObjects(batch);
      console.log(`Indexé ${i + batch.length}/${algoliaObjects.length} utilisateurs`);
    }

    console.log(`Réindexation terminée: ${algoliaObjects.length} utilisateurs`);
    res.status(200).send({
      success: true,
      count: algoliaObjects.length,
      message: `${algoliaObjects.length} utilisateurs réindexés avec succès`,
    });
  } catch (error) {
    console.error('Erreur lors de la réindexation:', error);
    res.status(500).send({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

/**
 * Fonction HTTP pour réindexer toutes les offres d'emploi
 */
export const reindexAllJobOffers = functions.https.onRequest(async (req, res) => {
  try {
    // TODO: Ajouter authentification en production si nécessaire
    // Utiliser Firebase Auth ou un token Bearer personnalisé

    console.log('Début de la réindexation de toutes les offres d\'emploi');

    const offersSnapshot = await admin.firestore()
      .collection('job_offers')
      .where('status', '==', 'open')
      .get();

    const algoliaObjects: any[] = [];

    offersSnapshot.forEach((doc) => {
      const offerData = doc.data();
      algoliaObjects.push({
        objectID: doc.id,
        id: doc.id,
        title: offerData.title || '',
        description: offerData.description || '',
        discipline: offerData.discipline || '',
        ville: offerData.ville || '',
        typeContrat: offerData.typeContrat || '',
        schoolId: offerData.schoolId || '',
        schoolName: offerData.schoolName || '',
        status: offerData.status,
        createdAt: offerData.createdAt?.toMillis() || Date.now(),
        _tags: [
          offerData.typeContrat,
          offerData.discipline,
          offerData.ville,
          'open',
        ].filter(Boolean),
      });
    });

    // Indexer par lots
    const batchSize = 1000;
    for (let i = 0; i < algoliaObjects.length; i += batchSize) {
      const batch = algoliaObjects.slice(i, i + batchSize);
      await jobOffersIndex.saveObjects(batch);
      console.log(`Indexé ${i + batch.length}/${algoliaObjects.length} offres`);
    }

    console.log(`Réindexation terminée: ${algoliaObjects.length} offres`);
    res.status(200).send({
      success: true,
      count: algoliaObjects.length,
      message: `${algoliaObjects.length} offres réindexées avec succès`,
    });
  } catch (error) {
    console.error('Erreur lors de la réindexation:', error);
    res.status(500).send({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});
