# Guide de Configuration MoneyFusion avec Google Cloud Secret Manager

Ce guide vous explique comment configurer l'intégration sécurisée de MoneyFusion avec Google Cloud Secret Manager et Firebase Cloud Functions.

## Architecture de Sécurité

```
Flutter App (Client)
    ↓
Firebase Cloud Functions
    ↓
Google Cloud Secret Manager (Clé API MoneyFusion)
    ↓
MoneyFusion API
```

**Avantages:**
- La clé API n'est JAMAIS exposée dans l'application Flutter
- La clé est chiffrée et stockée de manière sécurisée dans Google Cloud
- Gestion des versions et audit complet des accès
- Protection contre les attaques client-side

---

## Étape 1: Configuration de Google Cloud Secret Manager

### 1.1 Activer l'API Secret Manager

```bash
# Installer gcloud CLI si pas déjà fait
# Télécharger: https://cloud.google.com/sdk/docs/install

# Se connecter à Google Cloud
gcloud auth login

# Définir le projet
gcloud config set project chiasma-android

# Activer l'API Secret Manager
gcloud services enable secretmanager.googleapis.com
```

### 1.2 Créer le Secret pour la Clé MoneyFusion

**IMPORTANT:** Ne partagez JAMAIS votre clé API. Exécutez cette commande LOCALEMENT sur votre machine.

```bash
# Créer le secret (remplacez YOUR_MONEYFUSION_API_KEY par votre vraie clé)
echo -n "YOUR_MONEYFUSION_API_KEY" | gcloud secrets create moneyfusion-api-key \
    --data-file=- \
    --replication-policy="automatic"

# Vérifier que le secret a été créé
gcloud secrets list
```

### 1.3 Donner l'accès à Cloud Functions

```bash
# Récupérer l'email du service account Cloud Functions
# Format: PROJECT_ID@appspot.gserviceaccount.com
PROJECT_ID=$(gcloud config get-value project)
SERVICE_ACCOUNT="${PROJECT_ID}@appspot.gserviceaccount.com"

# Donner l'accès au secret
gcloud secrets add-iam-policy-binding moneyfusion-api-key \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/secretmanager.secretAccessor"
```

---

## Étape 2: Déploiement des Cloud Functions

### 2.1 Installer les dépendances

```bash
cd functions
npm install
```

### 2.2 Build et Test Local (Optionnel)

```bash
# Compiler TypeScript
npm run build

# Démarrer l'émulateur local
npm run serve
```

### 2.3 Déployer sur Firebase

```bash
# Déployer toutes les fonctions
npm run deploy

# OU déployer une fonction spécifique
firebase deploy --only functions:initializePayment
firebase deploy --only functions:moneyFusionWebhook
firebase deploy --only functions:checkPaymentStatus
```

**Note:** Les fonctions sont déployées dans la région `europe-west1` pour la conformité RGPD.

---

## Étape 3: Configuration du Webhook MoneyFusion

### 3.1 Récupérer l'URL du Webhook

Après le déploiement, vous recevrez une URL comme:
```
https://europe-west1-chiasma-android.cloudfunctions.net/moneyFusionWebhook
```

### 3.2 Configurer dans MoneyFusion Dashboard

1. Connectez-vous à votre tableau de bord MoneyFusion
2. Allez dans **Paramètres** → **Webhooks**
3. Ajoutez l'URL du webhook
4. Sélectionnez les événements à écouter:
   - `payment.completed`
   - `payment.failed`
   - `payment.pending`

---

## Étape 4: Intégration Flutter

### 4.1 Ajouter les dépendances

```bash
cd ..  # Retour à la racine du projet
flutter pub add cloud_functions
```

### 4.2 Le service est déjà créé

Le fichier `lib/services/payment_service.dart` contient toute la logique nécessaire.

### 4.3 Utilisation dans votre App

```dart
import 'package:myapp/services/payment_service.dart';

// Initialiser un paiement
final result = await PaymentService.initializePayment(
  userId: currentUser.uid,
  amount: 9.99,
  currency: 'EUR',
  subscriptionType: 'monthly',
);

if (result['success']) {
  final paymentUrl = result['paymentUrl'];
  // Ouvrir paymentUrl dans un navigateur/webview
}

// Vérifier le statut d'un paiement
final status = await PaymentService.checkPaymentStatus(paymentId);
```

---

## Étape 5: Sécurité et Vérification

### 5.1 Vérifier que le secret est accessible

```bash
# Tester l'accès au secret
gcloud secrets versions access latest --secret="moneyfusion-api-key"
```

### 5.2 Vérifier les logs des Cloud Functions

```bash
# Voir les logs en temps réel
firebase functions:log --only initializePayment

# Voir tous les logs
npm run logs
```

### 5.3 Tester l'intégration

```bash
# Dans votre app Flutter, appelez la fonction
# Vérifiez les logs Cloud Functions pour voir si le secret est bien récupéré
```

---

## Gestion des Secrets

### Mettre à jour la clé API

```bash
# Créer une nouvelle version du secret
echo -n "NEW_API_KEY" | gcloud secrets versions add moneyfusion-api-key \
    --data-file=-
```

**Les Cloud Functions utiliseront automatiquement la dernière version.**

### Lister toutes les versions

```bash
gcloud secrets versions list moneyfusion-api-key
```

### Révoquer une version compromise

```bash
gcloud secrets versions destroy VERSION_NUMBER --secret="moneyfusion-api-key"
```

---

## Structure des Données Firestore

### Collection: `payment_transactions`

```javascript
{
  userId: string,
  amount: number,
  currency: string,
  subscriptionType: 'monthly' | 'yearly',
  status: 'pending' | 'completed' | 'failed',
  paymentId: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Collection: `users` (mis à jour après paiement)

```javascript
{
  // ... autres champs
  subscriptionType: 'monthly' | 'yearly' | 'free',
  subscriptionStatus: 'active' | 'inactive' | 'expired',
  subscriptionExpiresAt: Timestamp,
  updatedAt: Timestamp
}
```

---

## Règles de Sécurité Firestore

Ajoutez ces règles dans Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Transactions de paiement - lecture seule pour l'utilisateur
    match /payment_transactions/{transactionId} {
      allow read: if request.auth != null
                  && resource.data.userId == request.auth.uid;
      allow write: if false; // Seulement via Cloud Functions
    }

    // Les autres règles restent inchangées
  }
}
```

---

## Tarification MoneyFusion (Exemple)

- **Mensuel:** 9.99 EUR
- **Annuel:** 99.99 EUR (économie de 17%)

Configurez ces valeurs dans votre app selon votre modèle commercial.

---

## Dépannage

### Erreur: "Failed to access secret"

**Solution:**
```bash
# Vérifier les permissions
gcloud secrets get-iam-policy moneyfusion-api-key

# Réappliquer les permissions
gcloud secrets add-iam-policy-binding moneyfusion-api-key \
    --member="serviceAccount:chiasma-android@appspot.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

### Erreur: "Function not found"

**Solution:**
```bash
# Redéployer les fonctions
cd functions
npm run deploy
```

### Le webhook ne reçoit pas les notifications

**Solution:**
1. Vérifiez l'URL du webhook dans MoneyFusion dashboard
2. Vérifiez les logs: `firebase functions:log --only moneyFusionWebhook`
3. Testez manuellement avec curl:
```bash
curl -X POST https://YOUR_FUNCTION_URL \
  -H "Content-Type: application/json" \
  -d '{"paymentId":"test","status":"completed","userId":"testuser"}'
```

---

## Coûts Google Cloud

### Secret Manager
- **Gratuit:** 6 accès/mois aux secrets
- **Après:** 0.03 USD pour 10 000 accès
- **Stockage:** 0.06 USD par secret actif/mois

### Cloud Functions
- **Niveau gratuit:** 2M invocations/mois
- **Après:** 0.40 USD par million d'invocations

**Pour une app moyenne, le coût est quasi nul (~0-2 USD/mois).**

---

## Conformité et Audit

### Voir qui a accédé au secret

```bash
gcloud logging read "resource.type=secretmanager_secret AND resource.labels.secret_id=moneyfusion-api-key" --limit 50 --format json
```

### Exporter les logs vers BigQuery (pour audit long terme)

```bash
gcloud logging sinks create moneyfusion-audit \
    bigquery.googleapis.com/projects/chiasma-android/datasets/audit_logs \
    --log-filter='resource.type="secretmanager_secret"'
```

---

## Checklist de Déploiement

- [ ] API Secret Manager activée
- [ ] Secret `moneyfusion-api-key` créé
- [ ] Permissions IAM configurées
- [ ] Cloud Functions déployées
- [ ] URL webhook configurée dans MoneyFusion
- [ ] Dépendance `cloud_functions` ajoutée à Flutter
- [ ] Tests de paiement effectués
- [ ] Règles Firestore sécurisées
- [ ] Monitoring et logs configurés

---

## Support et Documentation

- **MoneyFusion API:** [Documentation de votre fournisseur]
- **Google Cloud Secret Manager:** https://cloud.google.com/secret-manager/docs
- **Firebase Cloud Functions:** https://firebase.google.com/docs/functions
- **Flutter Cloud Functions:** https://firebase.google.com/docs/functions/callable

---

**RAPPEL DE SÉCURITÉ:** Ne commitez JAMAIS votre clé API dans Git. Le dossier `functions/` est configuré pour ignorer les fichiers sensibles.
