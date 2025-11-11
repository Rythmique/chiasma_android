const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Cloud Function qui envoie automatiquement une notification push
 * quand une notification est créée dans Firestore.
 *
 * Déclenché automatiquement par: notifications/{notificationId}
 * Son et vibration configurés automatiquement
 */
exports.sendPushNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const notificationId = context.params.notificationId;

    console.log('📬 Nouvelle notification créée:', {
      id: notificationId,
      title: notification.title,
      userId: notification.userId,
      type: notification.type,
    });

    try {
      // Récupérer les données de l'utilisateur
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(notification.userId)
        .get();

      if (!userDoc.exists) {
        console.log('❌ Utilisateur introuvable:', notification.userId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log('⚠️ Pas de token FCM pour l\'utilisateur:', notification.userId);
        return null;
      }

      // Préparer le message avec son et vibration
      const message = {
        token: fcmToken,
        notification: {
          title: notification.title,
          body: notification.message,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'high_importance_channel',
            sound: 'default',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: false,
            defaultLightSettings: true,
            color: '#F77F00',
            icon: '@mipmap/ic_launcher',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            // Pattern de vibration: 500ms pause, 1000ms vibration, 500ms pause
            vibrateTimingsMillis: [500, 1000, 500],
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        data: {
          notificationId: notificationId,
          type: notification.type || 'general',
          ...(notification.data || {}),
        },
      };

      // Envoyer la notification push
      const response = await admin.messaging().send(message);

      console.log('✅ Notification push envoyée avec succès:', {
        userId: notification.userId,
        title: notification.title,
        messageId: response,
      });

      // Mettre à jour le document pour indiquer que la notification push a été envoyée
      await snap.ref.update({
        pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
        pushMessageId: response,
      });

      return response;

    } catch (error) {
      console.error('❌ Erreur lors de l\'envoi de la notification push:', {
        userId: notification.userId,
        error: error.message,
        code: error.code,
      });

      // Enregistrer l'erreur dans le document notification
      await snap.ref.update({
        pushError: error.message,
        pushErrorCode: error.code || 'unknown',
        pushErrorAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Ne pas lancer d'erreur pour ne pas bloquer le trigger
      return null;
    }
  });

/**
 * Cloud Function pour nettoyer les tokens FCM invalides
 * Déclenché quand une notification échoue
 */
exports.cleanInvalidTokens = functions.firestore
  .document('notifications/{notificationId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();

    // Si une erreur de token invalide est détectée
    if (newData.pushErrorCode === 'messaging/invalid-registration-token' ||
        newData.pushErrorCode === 'messaging/registration-token-not-registered') {

      console.log('🧹 Nettoyage du token FCM invalide pour:', newData.userId);

      try {
        // Supprimer le token invalide
        await admin.firestore()
          .collection('users')
          .doc(newData.userId)
          .update({
            fcmToken: admin.firestore.FieldValue.delete(),
          });

        console.log('✅ Token FCM invalide supprimé');
      } catch (error) {
        console.error('❌ Erreur lors du nettoyage du token:', error);
      }
    }

    return null;
  });

/**
 * Cloud Function pour envoyer des notifications de test
 * Utilisable via HTTP pour tester
 */
exports.sendTestNotification = functions.https.onCall(async (data, context) => {
  // Vérifier que l'utilisateur est authentifié
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'L\'utilisateur doit être authentifié'
    );
  }

  const userId = context.auth.uid;
  const title = data.title || 'Notification de test';
  const message = data.message || 'Ceci est une notification de test avec son et vibration!';

  try {
    // Créer une notification de test dans Firestore
    const notificationRef = await admin.firestore().collection('notifications').add({
      userId: userId,
      type: 'test',
      title: title,
      message: message,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      data: { isTest: true },
    });

    return {
      success: true,
      message: 'Notification de test envoyée',
      notificationId: notificationRef.id,
    };
  } catch (error) {
    console.error('❌ Erreur lors de l\'envoi de la notification de test:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
