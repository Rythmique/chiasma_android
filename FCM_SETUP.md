# Configuration des Notifications Push FCM pour Chiasma

## Vue d'ensemble

Les notifications push Firebase Cloud Messaging (FCM) avec **son et vibration** sont maintenant intégrées dans l'application Chiasma pour tous les types de comptes (École, Candidat, Enseignant permutation).

## Architecture des Notifications

### 1. Types de notifications avec son et vibration

#### Côté École:
- ✅ **Nouvelles candidatures** - Notification quand un candidat postule
- ✅ **Messages** - Nouveaux messages des candidats
- ✅ **Expiration des offres** - Rappels avant expiration

#### Côté Candidat:
- ✅ **Candidature acceptée** - Notification sonore et vibration quand accepté
- ✅ **Candidature refusée** - Notification quand refusé
- ✅ **Nouvelles offres** - Offres correspondant au profil
- ✅ **Recommandations** - Offres personnalisées
- ✅ **Messages** - Nouveaux messages des écoles

#### Côté Enseignant permutation:
- ✅ **Matchs mutuels** - Notification de match trouvé
- ✅ **Messages** - Nouveaux messages

### 2. Composants implémentés

#### FCMService (`lib/services/fcm_service.dart`)
- ✅ Gestion des notifications locales avec **son et vibration**
- ✅ Canal haute importance pour Android
- ✅ Permissions Android 13+
- ✅ Affichage automatique des notifications au premier plan

#### NotificationService (`lib/services/notification_service.dart`)
- ✅ **NOUVEAU**: Envoi de notifications push via API FCM
- ✅ Vérification des paramètres utilisateur
- ✅ Stockage dans Firestore
- ✅ Configuration son + vibration automatique

#### UserModel (`lib/models/user_model.dart`)
- ✅ **NOUVEAU**: Champ `fcmToken` ajouté pour stocker le token FCM

## Configuration requise

### Étape 1: Obtenir la clé serveur FCM

1. Allez dans [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet Chiasma
3. Cliquez sur l'icône ⚙️ (Paramètres) → **Project Settings**
4. Onglet **Cloud Messaging**
5. Copiez la **Server key** (Legacy)

### Étape 2: Configurer la clé dans l'application

Ouvrez `lib/services/notification_service.dart` et remplacez:

```dart
static const String _fcmServerKey = 'YOUR_FCM_SERVER_KEY_HERE';
```

Par:

```dart
static const String _fcmServerKey = 'VOTRE_CLE_SERVEUR_FCM_ICI';
```

⚠️ **IMPORTANT**: Ne committez JAMAIS cette clé dans un dépôt public!

### Étape 3 (Alternative recommandée): Utiliser Cloud Functions

Pour une meilleure sécurité, il est recommandé d'utiliser Firebase Cloud Functions au lieu d'une clé serveur côté client:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationOnNewNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();

    // Récupérer le token FCM de l'utilisateur
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(notification.userId)
      .get();

    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token for user:', notification.userId);
      return null;
    }

    // Envoyer la notification push avec son et vibration
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
          vibrationPattern: [500, 1000, 500],
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: false,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
      data: notification.data || {},
    };

    try {
      await admin.messaging().send(message);
      console.log('✅ Notification push envoyée:', notification.title);
    } catch (error) {
      console.error('❌ Erreur FCM:', error);
    }

    return null;
  });
```

## Fonctionnalités des notifications

### Son et Vibration configurés automatiquement

Les notifications incluent:
- ✅ **Son**: Son par défaut du système
- ✅ **Vibration**: Pattern 500ms-1000ms-500ms
- ✅ **LED**: Clignotement de notification
- ✅ **Priorité haute**: Affichage immédiat
- ✅ **Badge**: Compteur de notifications non lues
- ✅ **Couleur**: Orange Chiasma (#F77F00)

### Paramètres utilisateur respectés

Les notifications vérifient automatiquement les préférences utilisateur avant l'envoi:

```dart
// L'utilisateur peut désactiver certains types dans les paramètres
- Messages: settings.messages
- Candidatures: settings.newApplications
- Statut candidature: settings.applicationStatus
- Nouvelles offres: settings.newJobOffers
- Recommandations: settings.jobRecommendations
```

## Test des notifications

### Test manuel

1. **Accepter une candidature** (côté École):
   - Le candidat doit recevoir une notification avec son + vibration
   - Titre: "Candidature acceptée"
   - Message: "Votre candidature pour le poste de X chez Y a été acceptée !"

2. **Poster une candidature** (côté Candidat):
   - L'école doit recevoir une notification avec son + vibration
   - Titre: "Nouvelle candidature"
   - Message: "Un candidat a postulé à votre offre"

3. **Envoyer un message**:
   - Le destinataire reçoit une notification avec son + vibration

### Vérification des logs

Les logs de debug affichent:
- ✅ `✅ Notification push envoyée avec succès à {userId}`
- ❌ `❌ Erreur FCM: {code} - {message}`
- ⚠️ `⚠️ Pas de token FCM pour l'utilisateur {userId}`

## Dépannage

### Les notifications ne s'affichent pas

1. **Vérifier les permissions**:
   - Android 13+: Permission POST_NOTIFICATIONS
   - Paramètres app: Notifications activées

2. **Vérifier le token FCM**:
   ```dart
   final userData = await FirestoreService().getUser(userId);
   print('FCM Token: ${userData?.fcmToken}');
   ```

3. **Vérifier les paramètres utilisateur**:
   - Paramètres > Notifications > Type de notification activé

### Les notifications n'ont pas de son/vibration

1. **Vérifier le canal de notification**:
   - Android: Canal "high_importance_channel" doit être créé
   - Priorité: HIGH
   - Son: Activé

2. **Vérifier le mode Ne Pas Déranger**:
   - Le téléphone ne doit pas être en mode silencieux

### Erreur "Invalid FCM Server Key"

- La clé serveur FCM n'est pas configurée ou invalide
- Vérifiez dans Firebase Console > Cloud Messaging > Server key

## Sécurité

⚠️ **Recommandations de sécurité**:

1. **Ne PAS committer la clé serveur** dans le code
2. **Utiliser Cloud Functions** au lieu de l'API HTTP directe
3. **Valider les permissions** utilisateur avant d'envoyer
4. **Limiter le taux d'envoi** pour éviter le spam

## Code source modifié

### Fichiers créés/modifiés:

1. ✅ `lib/services/notification_service.dart` - Ajout envoi push FCM
2. ✅ `lib/models/user_model.dart` - Ajout champ fcmToken
3. ✅ `lib/services/fcm_service.dart` - Déjà configuré pour son/vibration
4. ✅ `lib/school/view_applications_page.dart` - Utilise sendNotification()
5. ✅ `FCM_SETUP.md` - Ce fichier de documentation

## Références

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Functions](https://firebase.google.com/docs/functions)
