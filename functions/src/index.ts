import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {SecretManagerServiceClient} from "@google-cloud/secret-manager";

// Initialiser Firebase Admin
admin.initializeApp();

// Client Secret Manager
const secretClient = new SecretManagerServiceClient();

/**
 * Récupère un secret depuis Google Cloud Secret Manager
 * @param {string} secretName - Le nom du secret
 * @return {Promise<string>} La valeur du secret
 */
async function getSecret(secretName: string): Promise<string> {
  const projectId = process.env.GCLOUD_PROJECT;
  const name = `projects/${projectId}/secrets/${secretName}/versions/latest`;

  try {
    const [version] = await secretClient.accessSecretVersion({name});
    const payload = version.payload?.data?.toString();

    if (!payload) {
      throw new Error(`Secret ${secretName} is empty`);
    }

    return payload;
  } catch (error) {
    console.error(`Error accessing secret ${secretName}:`, error);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to access secret: ${secretName}`
    );
  }
}

/**
 * Initialise un paiement MoneyFusion
 * @param {Object} data - Les données du paiement
 * @return {Promise<Object>} Le résultat de l'initialisation
 */
export const initializePayment = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    // Vérifier que l'utilisateur est authentifié
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "L'utilisateur doit être authentifié pour initier un paiement"
      );
    }

    const {amount, currency, subscriptionType, userId} = data;

    // Validation des données
    if (!amount || !currency || !subscriptionType || !userId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Données de paiement incomplètes"
      );
    }

    // Vérifier que l'utilisateur demande un paiement pour lui-même
    if (context.auth.uid !== userId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Vous ne pouvez initier un paiement que pour votre propre compte"
      );
    }

    try {
      // Récupérer la clé API depuis Secret Manager
      const apiKey = await getSecret("moneyfusion-api-key");

      // Appeler l'API MoneyFusion
      const response = await fetch("https://api.moneyfusion.com/v1/payments/initialize", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Authorization": `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          amount,
          currency,
          metadata: {
            userId,
            subscriptionType,
            timestamp: admin.firestore.Timestamp.now().toMillis(),
          },
        }),
      });

      if (!response.ok) {
        const errorData = await response.text();
        console.error("MoneyFusion API error:", errorData);
        throw new functions.https.HttpsError(
          "internal",
          "Erreur lors de l'initialisation du paiement"
        );
      }

      const paymentData = await response.json();

      // Enregistrer la transaction dans Firestore
      await admin.firestore().collection("payment_transactions").add({
        userId,
        amount,
        currency,
        subscriptionType,
        status: "pending",
        paymentId: paymentData.paymentId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        paymentId: paymentData.paymentId,
        paymentUrl: paymentData.paymentUrl,
      };
    } catch (error) {
      console.error("Error initializing payment:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Erreur lors de l'initialisation du paiement"
      );
    }
  });

/**
 * Webhook pour les notifications de paiement MoneyFusion
 * @param {Request} req - La requête HTTP
 * @param {Response} res - La réponse HTTP
 */
export const moneyFusionWebhook = functions
  .region("europe-west1")
  .https.onRequest(async (req, res) => {
    // Vérifier que c'est une requête POST
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    try {
      // Récupérer la clé API pour vérifier la signature
      // const apiKey = await getSecret("moneyfusion-api-key");

      // TODO: Vérifier la signature du webhook (selon la documentation MoneyFusion)
      // const signature = req.headers["x-moneyfusion-signature"];
      // Implémenter la vérification de signature ici

      const {paymentId, status, userId, subscriptionType} = req.body;

      // Mettre à jour la transaction dans Firestore
      const transactionQuery = await admin
        .firestore()
        .collection("payment_transactions")
        .where("paymentId", "==", paymentId)
        .limit(1)
        .get();

      if (transactionQuery.empty) {
        console.error(`Transaction not found for paymentId: ${paymentId}`);
        res.status(404).send("Transaction not found");
        return;
      }

      const transactionDoc = transactionQuery.docs[0];
      await transactionDoc.ref.update({
        status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Si le paiement est réussi, mettre à jour l'abonnement de l'utilisateur
      if (status === "completed" || status === "success") {
        const userRef = admin.firestore().collection("users").doc(userId);

        // Calculer la date d'expiration selon le type d'abonnement
        let expirationDate: Date;
        const now = new Date();

        switch (subscriptionType) {
        case "monthly":
          expirationDate = new Date(now.setMonth(now.getMonth() + 1));
          break;
        case "yearly":
          expirationDate = new Date(now.setFullYear(now.getFullYear() + 1));
          break;
        default:
          console.error(`Unknown subscription type: ${subscriptionType}`);
          res.status(400).send("Invalid subscription type");
          return;
        }

        await userRef.update({
          subscriptionType,
          subscriptionStatus: "active",
          subscriptionExpiresAt: admin.firestore.Timestamp.fromDate(expirationDate),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Subscription activated for user ${userId}: ${subscriptionType}`);
      }

      res.status(200).send("Webhook processed successfully");
    } catch (error) {
      console.error("Error processing webhook:", error);
      res.status(500).send("Internal Server Error");
    }
  });

/**
 * Vérifie le statut d'un paiement
 * @param {Object} data - Les données de vérification
 * @return {Promise<Object>} Le statut du paiement
 */
export const checkPaymentStatus = functions
  .region("europe-west1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "L'utilisateur doit être authentifié"
      );
    }

    const {paymentId} = data;

    if (!paymentId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "paymentId est requis"
      );
    }

    try {
      // Récupérer le statut depuis Firestore
      const transactionQuery = await admin
        .firestore()
        .collection("payment_transactions")
        .where("paymentId", "==", paymentId)
        .where("userId", "==", context.auth.uid)
        .limit(1)
        .get();

      if (transactionQuery.empty) {
        throw new functions.https.HttpsError(
          "not-found",
          "Transaction non trouvée"
        );
      }

      const transactionData = transactionQuery.docs[0].data();

      return {
        success: true,
        status: transactionData.status,
        amount: transactionData.amount,
        currency: transactionData.currency,
        subscriptionType: transactionData.subscriptionType,
      };
    } catch (error) {
      console.error("Error checking payment status:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Erreur lors de la vérification du statut"
      );
    }
  });
