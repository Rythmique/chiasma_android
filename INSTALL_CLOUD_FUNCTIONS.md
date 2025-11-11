# Installation des Cloud Functions pour les Notifications Push

## 🎯 Pourquoi Cloud Functions?

L'API Cloud Messaging Legacy est **désactivée/dépréciée** par Firebase. La solution moderne et sécurisée est d'utiliser **Cloud Functions** qui:

✅ **Plus sécurisé** - Pas de clé serveur dans le code client
✅ **Automatique** - Trigger Firestore déclenche les notifications
✅ **Son + Vibration** - Configurés automatiquement côté serveur
✅ **Gratuit** - 2 millions d'invocations/mois dans le plan gratuit Firebase

---

## 📋 Prérequis

1. Node.js installé (version 18 ou supérieure)
2. npm installé
3. Firebase CLI installé

---

## 🚀 Installation étape par étape

### Étape 1: Installer Firebase CLI

```bash
npm install -g firebase-tools
```

Vérifiez l'installation:
```bash
firebase --version
```

### Étape 2: Se connecter à Firebase

```bash
firebase login
```

Cela ouvrira votre navigateur pour vous connecter avec votre compte Google.

### Étape 3: Initialiser Firebase Functions dans votre projet

```bash
cd /home/user/myapp
firebase init functions
```

**Répondez aux questions:**

1. **Select a default Firebase project**: Choisissez votre projet **Chiasma**
2. **What language would you like to use?**: Choisissez **JavaScript**
3. **Do you want to use ESLint?**: Tapez **n** (non)
4. **Do you want to install dependencies with npm now?**: Tapez **y** (oui)

Cela va créer:
- `functions/` - Dossier contenant le code des fonctions
- `functions/package.json` - Dépendances npm
- `functions/index.js` - Votre code de fonctions (déjà créé!)

### Étape 4: Installer les dépendances

```bash
cd functions
npm install
```

### Étape 5: Vérifier le code des fonctions

Le fichier `functions/index.js` est déjà créé avec 3 fonctions:

1. **sendPushNotification** - Envoie automatiquement une notification push avec son + vibration quand une notification est créée dans Firestore
2. **cleanInvalidTokens** - Nettoie automatiquement les tokens FCM invalides
3. **sendTestNotification** - Fonction de test appelable via HTTP

### Étape 6: Déployer les Cloud Functions

```bash
firebase deploy --only functions
```

**Sortie attendue:**
```
✔ functions: Finished running predeploy script.
i functions: preparing functions directory for uploading...
i functions: packaged functions (X KB) for uploading
✔ functions: functions folder uploaded successfully
i functions: creating Node.js 18 function sendPushNotification...
i functions: creating Node.js 18 function cleanInvalidTokens...
i functions: creating Node.js 18 function sendTestNotification...
✔ functions[sendPushNotification]: Successful create operation.
✔ functions[cleanInvalidTokens]: Successful create operation.
✔ functions[sendTestNotification]: Successful create operation.

✔ Deploy complete!
```

---

## ✅ Vérification de l'installation

### 1. Vérifier les fonctions déployées

Dans Firebase Console:
1. Allez dans **Functions** (menu gauche)
2. Vous devriez voir:
   - ✅ `sendPushNotification` (Firestore trigger)
   - ✅ `cleanInvalidTokens` (Firestore trigger)
   - ✅ `sendTestNotification` (Callable)

### 2. Vérifier les logs

```bash
firebase functions:log
```

Ou dans Firebase Console → **Functions** → cliquez sur une fonction → **Logs**

---

## 🧪 Tester les notifications

### Test 1: Via l'application

1. Lancez l'app sur 2 appareils:
   - Appareil 1: Compte **École**
   - Appareil 2: Compte **Candidat**

2. **École** accepte une candidature

3. **Candidat** doit recevoir:
   - ✅ Notification visuelle
   - ✅ **Son** 🔔
   - ✅ **Vibration** 📳

### Test 2: Vérifier les logs Cloud Functions

```bash
firebase functions:log --only sendPushNotification
```

**Logs attendus:**
```
📬 Nouvelle notification créée: { id: 'xxx', title: 'Candidature acceptée', userId: 'yyy' }
✅ Notification push envoyée avec succès: { userId: 'yyy', title: 'Candidature acceptée', messageId: 'zzz' }
```

### Test 3: Vérifier dans Firestore

Firebase Console → **Firestore Database** → collection `notifications`

Chaque notification devrait avoir:
- ✅ `pushSentAt` - Timestamp de l'envoi
- ✅ `pushMessageId` - ID du message FCM

Si erreur:
- ❌ `pushError` - Message d'erreur
- ❌ `pushErrorCode` - Code d'erreur

---

## 🔧 Configuration du son et de la vibration

Les paramètres sont déjà configurés dans `functions/index.js` lignes 40-65:

```javascript
android: {
  priority: 'high',
  notification: {
    channelId: 'high_importance_channel',
    sound: 'default',              // ✅ Son activé
    priority: 'high',
    defaultSound: true,
    defaultVibrateTimings: false,
    defaultLightSettings: true,
    color: '#F77F00',              // Couleur orange Chiasma
    icon: '@mipmap/ic_launcher',
    // Pattern: 500ms pause, 1000ms vibration, 500ms pause
    vibrateTimingsMillis: [500, 1000, 500],  // ✅ Vibration activée
  },
}
```

---

## 🚨 Dépannage

### Problème: "Permission denied" lors du déploiement

**Solution:**
```bash
firebase login --reauth
firebase use --add
# Sélectionnez votre projet Chiasma
firebase deploy --only functions
```

### Problème: Les notifications ne sont pas envoyées

**Vérifiez:**

1. **Les tokens FCM sont enregistrés?**
   - Firestore → `users` → vérifiez que `fcmToken` existe

2. **Les Cloud Functions sont déployées?**
   - Firebase Console → Functions → Vérifiez le statut

3. **Les logs des fonctions:**
   ```bash
   firebase functions:log
   ```

4. **Les utilisateurs doivent se reconnecter** pour que leur token FCM soit enregistré

### Problème: "messaging/invalid-registration-token"

**Solution:** C'est normal! La fonction `cleanInvalidTokens` va automatiquement supprimer ce token. L'utilisateur doit se reconnecter pour obtenir un nouveau token.

### Problème: Pas de son ou vibration

**Vérifiez sur le téléphone:**
- Mode Ne Pas Déranger désactivé
- Notifications activées pour l'app
- Son des notifications activé dans Android
- Canal "high_importance_channel" existe

---

## 💰 Coûts

**Plan gratuit Firebase:**
- ✅ 2 millions d'invocations de fonctions/mois
- ✅ 400 000 GB-secondes/mois
- ✅ 200 000 CPU-secondes/mois

**Pour une app comme Chiasma:**
- Si 1000 notifications/jour → ~30 000/mois
- **Largement dans le plan gratuit!** ✅

---

## 📊 Monitoring

### Voir les statistiques

Firebase Console → **Functions** → cliquez sur une fonction

Vous verrez:
- Nombre d'invocations
- Temps d'exécution moyen
- Taux d'erreur
- Graphiques en temps réel

### Alertes

Vous pouvez configurer des alertes:
1. Firebase Console → **Functions**
2. Cliquez sur ⚙️ → **Metrics**
3. Cliquez sur **Create Alert**

---

## 🔄 Mise à jour du code

Si vous modifiez `functions/index.js`:

```bash
cd functions
firebase deploy --only functions
```

Seules les fonctions modifiées seront redéployées.

---

## 📝 Résumé des commandes

```bash
# Installation initiale
npm install -g firebase-tools
firebase login
cd /home/user/myapp
firebase init functions
cd functions
npm install

# Déploiement
firebase deploy --only functions

# Logs
firebase functions:log
firebase functions:log --only sendPushNotification

# Test
firebase functions:shell
```

---

## ✅ Checklist finale

- [ ] Firebase CLI installé
- [ ] Connecté avec `firebase login`
- [ ] Functions initialisées avec `firebase init functions`
- [ ] Dépendances installées avec `npm install`
- [ ] Functions déployées avec `firebase deploy --only functions`
- [ ] Vérifié dans Firebase Console → Functions
- [ ] Testé une notification (accepter candidature)
- [ ] Vérifié les logs avec `firebase functions:log`
- [ ] Candidat a reçu notification avec son + vibration ✅

---

**🎉 Une fois déployé, toutes les notifications de l'app auront automatiquement du son et de la vibration!**

Aucune configuration supplémentaire nécessaire dans le code Flutter.
