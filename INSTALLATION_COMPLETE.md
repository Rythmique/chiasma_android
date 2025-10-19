# 🎉 Installation MoneyFusion Complète !

## ✅ Ce qui a été installé

### 1. Architecture Sécurisée
```
Flutter App (Client)
     ↓
Firebase Cloud Functions (Serveur)
     ↓
Google Cloud Secret Manager (Coffre-fort sécurisé)
     ↓
MoneyFusion API
```

### 2. Fichiers Créés

#### Backend (Cloud Functions)
- ✅ `functions/package.json` - Configuration du projet Node.js
- ✅ `functions/tsconfig.json` - Configuration TypeScript
- ✅ `functions/.eslintrc.js` - Configuration linting
- ✅ `functions/.gitignore` - Protection Git
- ✅ `functions/src/index.ts` - **3 Cloud Functions:**
  1. `initializePayment` - Initialise un paiement sécurisé
  2. `moneyFusionWebhook` - Reçoit les notifications de paiement
  3. `checkPaymentStatus` - Vérifie le statut d'un paiement

#### Frontend (Flutter)
- ✅ `lib/services/payment_service.dart` - **Service complet avec:**
  - `processPayment()` - Initialise et ouvre le paiement
  - `initializePayment()` - Initialise uniquement
  - `checkPaymentStatus()` - Vérifie le statut
  - `openPaymentUrl()` - Ouvre l'URL de paiement
  - `formatPrice()` - Formate les prix en EUR
  - `calculateYearlySavings()` - Calcule les économies

#### Documentation
- ✅ `MONEYFUSION_SETUP.md` - Guide de configuration technique détaillé
- ✅ `MONEYFUSION_INTEGRATION_GUIDE.md` - Guide d'utilisation pour développeurs
- ✅ `MONEYFUSION_QUICKSTART.md` - Guide de démarrage rapide
- ✅ `INSTALLATION_COMPLETE.md` - Ce fichier

#### Configuration
- ✅ `pubspec.yaml` - Dépendances ajoutées:
  - `cloud_functions: ^5.2.2`
  - `url_launcher: ^6.3.1`
- ✅ `firebase.json` - Configuration Cloud Functions ajoutée
- ✅ Dépendances Flutter installées (`flutter pub get` ✅)

---

## 🚀 Prochaines Étapes (À FAIRE)

### Étape 1: Configurer Google Cloud Secret Manager

**⚠️ IMPORTANT:** Ne partagez JAMAIS votre clé API ici ou dans Git !

```bash
# 1. Se connecter à Google Cloud
gcloud auth login

# 2. Définir le projet
gcloud config set project chiasma-android

# 3. Activer Secret Manager
gcloud services enable secretmanager.googleapis.com

# 4. Créer le secret (remplacez YOUR_API_KEY par votre vraie clé)
echo -n "YOUR_MONEYFUSION_API_KEY" | gcloud secrets create moneyfusion-api-key \
    --data-file=- \
    --replication-policy="automatic"

# 5. Donner l'accès à Cloud Functions
gcloud secrets add-iam-policy-binding moneyfusion-api-key \
    --member="serviceAccount:chiasma-android@appspot.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

### Étape 2: Installer et Déployer Cloud Functions

```bash
# 1. Aller dans le dossier functions
cd functions

# 2. Installer les dépendances Node.js
npm install

# 3. Compiler et déployer sur Firebase
npm run deploy

# 4. Retourner à la racine
cd ..
```

**Temps estimé:** 5-10 minutes (première fois)

### Étape 3: Configurer le Webhook MoneyFusion

Après le déploiement (étape 2), vous recevrez une URL comme:
```
https://europe-west1-chiasma-android.cloudfunctions.net/moneyFusionWebhook
```

**Actions:**
1. Copiez cette URL
2. Connectez-vous à votre tableau de bord MoneyFusion
3. Allez dans **Paramètres → Webhooks** (ou équivalent)
4. Ajoutez l'URL du webhook
5. Sélectionnez les événements à écouter:
   - ✅ `payment.completed` (ou `payment.success`)
   - ✅ `payment.failed`
   - ✅ `payment.pending` (optionnel)

### Étape 4: Tester l'Intégration

**Code de test minimal:**

```dart
import 'package:myapp/services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Dans un bouton ou une fonction
Future<void> testPayment() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('Utilisateur non connecté');
    return;
  }

  final result = await PaymentService.processPayment(
    userId: user.uid,
    subscriptionType: PaymentService.subscriptionMonthly,
  );

  if (result['success'] == true) {
    print('✅ Paiement initié!');
    print('Payment ID: ${result['paymentId']}');
    print('URL: ${result['paymentUrl']}');
  } else {
    print('❌ Erreur: ${result['error']}');
  }
}
```

### Étape 5: Configurer les Règles Firestore Sécurisées

**Dans Firebase Console → Firestore Database → Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users - lecture seule par l'utilisateur
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Seulement via Cloud Functions
    }

    // Transactions de paiement - lecture seule par l'utilisateur
    match /payment_transactions/{transactionId} {
      allow read: if request.auth != null
                  && resource.data.userId == request.auth.uid;
      allow write: if false; // Seulement via Cloud Functions
    }

    // Vos autres règles...
  }
}
```

---

## 📋 Checklist de Validation

- [ ] **Étape 1:** Secret créé dans Secret Manager
- [ ] **Étape 1:** Permissions IAM configurées
- [ ] **Étape 2:** `npm install` exécuté dans `functions/`
- [ ] **Étape 2:** Cloud Functions déployées
- [ ] **Étape 3:** Webhook configuré dans MoneyFusion
- [ ] **Étape 4:** Test de paiement effectué
- [ ] **Étape 5:** Règles Firestore sécurisées

---

## 🔍 Commandes de Vérification

### Vérifier que le secret existe
```bash
gcloud secrets list | grep moneyfusion-api-key
```

### Vérifier les permissions du secret
```bash
gcloud secrets get-iam-policy moneyfusion-api-key
```

### Lister les Cloud Functions déployées
```bash
firebase functions:list
```

### Voir les logs des Cloud Functions
```bash
# Tous les logs
firebase functions:log

# Logs d'une fonction spécifique
firebase functions:log --only initializePayment
firebase functions:log --only moneyFusionWebhook
firebase functions:log --only checkPaymentStatus
```

### Tester l'accès au secret
```bash
gcloud secrets versions access latest --secret="moneyfusion-api-key"
```

---

## 💰 Tarifs Configurés

**Abonnements actuellement configurés:**
- **Mensuel:** 9,99 € / mois
- **Annuel:** 99,99 € / an
  - **Économie:** 19,89 € (17%)

**Modifier les tarifs:**

Éditez `lib/services/payment_service.dart`:

```dart
static const Map<String, double> subscriptionPrices = {
  subscriptionMonthly: 9.99,  // ← Changez ici
  subscriptionYearly: 99.99,  // ← Changez ici
};
```

---

## 🔐 Sécurité

### ✅ Points Forts de Cette Architecture

1. **Clé API jamais exposée** - Stockée dans Secret Manager, jamais dans l'app
2. **Chiffrement automatique** - Secret Manager chiffre automatiquement
3. **Authentification vérifiée** - Seuls les utilisateurs connectés peuvent payer
4. **Vérification d'identité** - Un utilisateur ne peut payer que pour lui-même
5. **Logs sécurisés** - Pas de données sensibles dans les logs
6. **Conformité RGPD** - Déployé en region `europe-west1`
7. **Audit complet** - Tous les accès au secret sont loggés
8. **Gestion des versions** - Possibilité de rotate la clé API sans downtime

### ⚠️ Règles de Sécurité à Respecter

1. ❌ **NE JAMAIS** commiter la clé API dans Git
2. ❌ **NE JAMAIS** hardcoder la clé dans le code Flutter
3. ❌ **NE JAMAIS** appeler MoneyFusion API directement depuis Flutter
4. ❌ **NE JAMAIS** partager la clé API dans des chats/emails/forums
5. ✅ **TOUJOURS** passer par les Cloud Functions
6. ✅ **TOUJOURS** vérifier l'authentification côté serveur
7. ✅ **TOUJOURS** logger les erreurs (sans données sensibles)

---

## 💡 Exemples d'Utilisation

### Exemple 1: Bouton Simple de Paiement

```dart
ElevatedButton(
  onPressed: () async {
    final user = FirebaseAuth.instance.currentUser!;

    final result = await PaymentService.processPayment(
      userId: user.uid,
      subscriptionType: PaymentService.subscriptionMonthly,
    );

    if (result['success'] == true) {
      // Paiement initié, l'URL s'est ouverte automatiquement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Page de paiement ouverte!')),
      );
    }
  },
  child: Text('Souscrire - 9,99 €/mois'),
)
```

### Exemple 2: Page Complète de Choix d'Abonnement

Voir le code complet dans [MONEYFUSION_INTEGRATION_GUIDE.md](MONEYFUSION_INTEGRATION_GUIDE.md#widget-complet-page-de-choix-dabonnement)

### Exemple 3: Vérifier le Statut d'un Paiement

```dart
final result = await PaymentService.checkPaymentStatus(
  paymentId: 'payment_123456',
);

if (result['success'] == true) {
  switch (result['status']) {
    case 'pending':
      print('Paiement en attente');
      break;
    case 'completed':
      print('Paiement complété!');
      break;
    case 'failed':
      print('Paiement échoué');
      break;
  }
}
```

---

## 📊 Structure des Données Firestore

### Collection: `payment_transactions`

Créée automatiquement lors du premier paiement:

```javascript
{
  userId: "abc123",
  amount: 9.99,
  currency: "EUR",
  subscriptionType: "monthly",
  status: "pending", // puis "completed" ou "failed"
  paymentId: "pay_xyz789",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Collection: `users`

Mise à jour automatiquement après paiement réussi:

```javascript
{
  // ... vos champs existants
  subscriptionType: "monthly", // ou "yearly"
  subscriptionStatus: "active",
  subscriptionExpiresAt: Timestamp, // +1 mois ou +1 an
  updatedAt: Timestamp
}
```

---

## 🛠️ Dépannage

### Problème: "Failed to access secret"

**Cause:** Permissions IAM manquantes

**Solution:**
```bash
gcloud secrets add-iam-policy-binding moneyfusion-api-key \
    --member="serviceAccount:chiasma-android@appspot.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

### Problème: "Function not found"

**Cause:** Cloud Functions pas déployées

**Solution:**
```bash
cd functions
npm run deploy
```

### Problème: Le webhook ne reçoit rien

**Causes possibles:**
1. URL webhook incorrecte dans MoneyFusion
2. Événements non sélectionnés dans MoneyFusion
3. Firewall bloquant les requêtes

**Solutions:**
1. Vérifiez l'URL dans MoneyFusion dashboard
2. Vérifiez les logs: `firebase functions:log --only moneyFusionWebhook`
3. Testez manuellement:
```bash
curl -X POST https://YOUR_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{"paymentId":"test","status":"completed","userId":"testuser"}'
```

### Problème: L'URL de paiement ne s'ouvre pas

**Causes possibles:**
1. Permissions manquantes sur Android
2. URL malformée

**Solutions Android:**

Ajoutez dans `android/app/src/main/AndroidManifest.xml`:

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
    </intent>
</queries>
```

---

## 💵 Coûts Estimés

### Google Cloud (pour ~1000 paiements/mois)

| Service | Coût mensuel |
|---------|--------------|
| Secret Manager | ~0,06 € |
| Cloud Functions (3 fonctions) | ~0-1 € (niveau gratuit) |
| Firestore (lectures/écritures) | ~0-2 € |
| **TOTAL** | **~0-3 €** |

### MoneyFusion

Consultez la grille tarifaire MoneyFusion (généralement un % par transaction + frais fixes).

---

## 📚 Documentation

- **[MONEYFUSION_QUICKSTART.md](MONEYFUSION_QUICKSTART.md)** - Guide rapide (recommandé pour commencer)
- **[MONEYFUSION_SETUP.md](MONEYFUSION_SETUP.md)** - Configuration technique détaillée
- **[MONEYFUSION_INTEGRATION_GUIDE.md](MONEYFUSION_INTEGRATION_GUIDE.md)** - Guide d'utilisation complet
- **Code source commenté:** `lib/services/payment_service.dart`
- **Cloud Functions commentées:** `functions/src/index.ts`

---

## 🎯 Architecture Recommandée pour Production

```
1. Utilisateur clique "Souscrire" dans l'app
2. Flutter appelle PaymentService.processPayment()
3. Cloud Function récupère la clé API (Secret Manager)
4. Cloud Function appelle MoneyFusion API
5. MoneyFusion retourne une URL de paiement
6. Flutter ouvre cette URL dans le navigateur
7. Utilisateur complète le paiement
8. MoneyFusion envoie un webhook
9. Cloud Function met à jour Firestore
10. Flutter écoute Firestore et affiche l'abonnement actif
```

---

## 🚀 Prêt pour la Production

Avant de mettre en production:

- [ ] Testez avec les cartes de test MoneyFusion
- [ ] Vérifiez les logs Cloud Functions
- [ ] Testez le webhook avec un paiement réel (petit montant)
- [ ] Configurez les règles Firestore sécurisées
- [ ] Configurez les alertes de monitoring
- [ ] Documentez votre processus de support client
- [ ] Testez les cas d'erreur (paiement échoué, timeout, etc.)
- [ ] Vérifiez la conformité légale (CGV, mentions légales)

---

## 📞 Support

**En cas de problème:**

1. **Consultez les logs:** `firebase functions:log`
2. **Vérifiez Firestore:** Collections `users` et `payment_transactions`
3. **Testez le secret:** `gcloud secrets versions access latest --secret="moneyfusion-api-key"`
4. **Consultez la documentation:** Fichiers MD dans le projet

**Ressources externes:**
- Firebase Functions: https://firebase.google.com/docs/functions
- Secret Manager: https://cloud.google.com/secret-manager/docs
- MoneyFusion: [Documentation de votre fournisseur]

---

## ✅ Félicitations !

Votre intégration MoneyFusion est **installée et prête** !

**Prochaine action:** Suivez les **5 étapes** ci-dessus pour activer le système.

**Questions?** Consultez [MONEYFUSION_QUICKSTART.md](MONEYFUSION_QUICKSTART.md) ou [MONEYFUSION_INTEGRATION_GUIDE.md](MONEYFUSION_INTEGRATION_GUIDE.md).

---

**Bonne chance avec votre application CHIASMA ! 🎉**
