# 🔔 Notifications Push - Chiasma

## ✅ CONFIGURATION TERMINÉE

Toutes les notifications push avec **son et vibration** sont prêtes à être déployées!

---

## 🚀 DÉPLOIEMENT (1 seule commande)

```bash
./deploy-notifications.sh
```

**OU manuellement:**

```bash
cd functions
npm install
npm run build
firebase deploy --only functions:sendPushNotification,functions:cleanInvalidTokens,functions:sendTestNotification
```

---

## 📁 Fichiers modifiés/créés

### Backend (Cloud Functions)
- ✅ `functions/src/notifications.ts` - Code des notifications push (NOUVEAU)
- ✅ `functions/src/index.ts` - Exports des fonctions (MODIFIÉ)

### Frontend (Flutter)
- ✅ `lib/services/notification_service.dart` - Simplifié, délègue aux Cloud Functions
- ✅ `lib/models/user_model.dart` - Ajout champ `fcmToken`

### Documentation
- ✅ `README_NOTIFICATIONS.md` - Ce fichier
- ✅ `DEMARRAGE_RAPIDE_FCM.md` - Guide 5 minutes
- ✅ `INSTALL_CLOUD_FUNCTIONS.md` - Guide détaillé
- ✅ `deploy-notifications.sh` - Script de déploiement

---

## 🎯 Comment ça marche

```
1. Utilisateur effectue une action (ex: accepter candidature)
   ↓
2. NotificationService crée notification dans Firestore
   ↓
3. Cloud Function "sendPushNotification" se déclenche automatiquement
   ↓
4. Notification push envoyée avec:
   ✅ Son activé
   ✅ Vibration (500ms-1000ms-500ms)
   ✅ Couleur orange #F77F00
   ✅ Priorité haute
   ↓
5. Destinataire reçoit notification 🔔📳
```

---

## 🔧 Paramètres son et vibration

Configurés dans `functions/src/notifications.ts`:

```typescript
android: {
  notification: {
    sound: "default",              // ✅ Son
    vibrateTimingsMillis: [500, 1000, 500],  // ✅ Vibration
    priority: "high",
    color: "#F77F00",              // Orange Chiasma
  }
}
```

---

## 🧪 Tester

1. Déployez: `./deploy-notifications.sh`
2. Lancez l'app sur 2 appareils
3. École accepte une candidature
4. Candidat reçoit notification avec son 🔔 + vibration 📳

**Voir les logs:**
```bash
firebase functions:log --only sendPushNotification
```

---

## 📊 Types de notifications avec son + vibration

### Côté École
- ✅ Nouvelles candidatures
- ✅ Messages
- ✅ Expiration des offres

### Côté Candidat
- ✅ Candidature acceptée/refusée
- ✅ Nouvelles offres
- ✅ Recommandations
- ✅ Messages

### Côté Enseignant Permutation
- ✅ Matchs mutuels
- ✅ Messages

---

## ⚙️ Vérifications Firebase Console

Après déploiement, vérifiez dans Firebase Console:

1. **Functions** → 3 fonctions déployées
   - `sendPushNotification`
   - `cleanInvalidTokens`
   - `sendTestNotification`

2. **Firestore** → collection `notifications`
   - Champs ajoutés automatiquement:
     - `pushSentAt` (timestamp)
     - `pushMessageId` (ID FCM)

3. **Cloud Messaging** → API activée
   - Pas besoin de clé serveur Legacy ✅

---

## 🔍 Dépannage

### Tokens FCM manquants?
→ Les utilisateurs doivent se **reconnecter** à l'app

### Erreur de déploiement?
```bash
firebase login --reauth
firebase use --add  # Sélectionner projet Chiasma
./deploy-notifications.sh
```

### Notifications sans son?
→ Vérifier:
- Mode Ne Pas Déranger désactivé
- Notifications activées pour l'app
- Canal "high_importance_channel" existe

---

## 💰 Coûts

**Plan gratuit Firebase:** 2M invocations/mois

**Usage estimé Chiasma:**
- 1000 notifications/jour = ~30,000/mois
- **Largement dans le plan gratuit!** ✅

---

## 📝 Commandes utiles

```bash
# Déployer
./deploy-notifications.sh

# Voir les logs
firebase functions:log

# Logs d'une fonction spécifique
firebase functions:log --only sendPushNotification

# Lister les fonctions déployées
firebase functions:list
```

---

## 🎉 C'EST PRÊT!

Exécutez simplement:

```bash
./deploy-notifications.sh
```

Et toutes les notifications de votre app auront automatiquement **son + vibration**!

**Aucune autre configuration nécessaire.** 🚀
