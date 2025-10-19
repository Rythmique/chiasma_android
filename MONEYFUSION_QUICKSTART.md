# MoneyFusion - Guide de Démarrage Rapide

## Architecture Sécurisée Installée ✅

Votre projet est maintenant configuré avec une architecture sécurisée pour MoneyFusion:

```
Flutter App → Firebase Cloud Functions → Secret Manager → MoneyFusion API
```

**Votre clé API est protégée et ne sera JAMAIS exposée dans l'application.**

---

## Fichiers Créés

### Cloud Functions (Backend)
- `functions/package.json` - Configuration npm
- `functions/tsconfig.json` - Configuration TypeScript
- `functions/src/index.ts` - 3 Cloud Functions:
  - `initializePayment` - Initialise un paiement
  - `moneyFusionWebhook` - Reçoit les notifications de paiement
  - `checkPaymentStatus` - Vérifie le statut d'un paiement

### Flutter App (Frontend)
- `lib/services/payment_service.dart` - Service de paiement complet avec:
  - `processPayment()` - Méthode tout-en-un
  - `initializePayment()` - Initialise un paiement
  - `checkPaymentStatus()` - Vérifie le statut
  - `formatPrice()` - Formate les prix
  - `calculateYearlySavings()` - Calcule les économies

### Documentation
- `MONEYFUSION_SETUP.md` - Guide de configuration détaillé
- `MONEYFUSION_INTEGRATION_GUIDE.md` - Guide d'utilisation pour développeurs
- `MONEYFUSION_QUICKSTART.md` - Ce fichier

### Configuration
- `firebase.json` - Mis à jour avec la config Cloud Functions
- `pubspec.yaml` - Dépendances ajoutées:
  - `cloud_functions: ^5.2.2`
  - `url_launcher: ^6.3.1`

---

## Installation en 5 Étapes

### 1️⃣ Installer les Dépendances Flutter

```bash
flutter pub get
```

### 2️⃣ Configurer Google Cloud Secret Manager

```bash
# Se connecter à Google Cloud
gcloud auth login
gcloud config set project chiasma-android

# Activer Secret Manager
gcloud services enable secretmanager.googleapis.com

# Créer le secret avec VOTRE clé API (remplacez YOUR_API_KEY)
echo -n "YOUR_MONEYFUSION_API_KEY" | gcloud secrets create moneyfusion-api-key \
    --data-file=- \
    --replication-policy="automatic"

# Donner l'accès à Cloud Functions
gcloud secrets add-iam-policy-binding moneyfusion-api-key \
    --member="serviceAccount:chiasma-android@appspot.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

### 3️⃣ Installer et Déployer Cloud Functions

```bash
# Installer les dépendances Node.js
cd functions
npm install

# Compiler et déployer
npm run deploy

# Retourner à la racine
cd ..
```

### 4️⃣ Configurer le Webhook MoneyFusion

Après le déploiement, vous recevrez une URL comme:
```
https://europe-west1-chiasma-android.cloudfunctions.net/moneyFusionWebhook
```

1. Connectez-vous à votre dashboard MoneyFusion
2. Allez dans **Paramètres → Webhooks**
3. Ajoutez cette URL
4. Sélectionnez les événements: `payment.completed`, `payment.failed`, `payment.pending`

### 5️⃣ Tester l'Intégration

```dart
// Dans votre app Flutter
import 'package:myapp/services/payment_service.dart';

// Tester un paiement
final result = await PaymentService.processPayment(
  userId: FirebaseAuth.instance.currentUser!.uid,
  subscriptionType: 'monthly',
);

if (result['success']) {
  print('Paiement initié! URL: ${result['paymentUrl']}');
}
```

---

## Utilisation Rapide

### Exemple Minimal

```dart
import 'package:flutter/material.dart';
import 'package:myapp/services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuickPaymentButton extends StatelessWidget {
  const QuickPaymentButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final result = await PaymentService.processPayment(
          userId: user.uid,
          subscriptionType: PaymentService.subscriptionMonthly,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['success'] == true
                    ? 'Paiement initié!'
                    : 'Erreur: ${result['error']}',
              ),
            ),
          );
        }
      },
      child: const Text('Souscrire (9,99 €/mois)'),
    );
  }
}
```

---

## Tarifs Configurés

- **Mensuel:** 9,99 € / mois
- **Annuel:** 99,99 € / an (économie de 17%)

Modifiez ces valeurs dans `lib/services/payment_service.dart`:

```dart
static const Map<String, double> subscriptionPrices = {
  subscriptionMonthly: 9.99,  // ← Modifiez ici
  subscriptionYearly: 99.99,   // ← Modifiez ici
};
```

---

## Flux de Paiement

1. **Utilisateur clique sur "Souscrire"**
2. `PaymentService.processPayment()` est appelé
3. Cloud Function récupère la clé API depuis Secret Manager
4. Cloud Function appelle MoneyFusion API
5. L'app ouvre l'URL de paiement dans le navigateur
6. L'utilisateur complète le paiement
7. MoneyFusion envoie un webhook
8. Cloud Function met à jour l'abonnement dans Firestore
9. L'app affiche l'abonnement actif

---

## Structure Firestore

### Collection: `payment_transactions`

```
payment_transactions/{transactionId}
├── userId: string
├── amount: number
├── currency: string
├── subscriptionType: 'monthly' | 'yearly'
├── status: 'pending' | 'completed' | 'failed'
├── paymentId: string
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

### Collection: `users` (mis à jour automatiquement)

```
users/{userId}
├── ... autres champs
├── subscriptionType: 'monthly' | 'yearly' | 'free'
├── subscriptionStatus: 'active' | 'inactive' | 'expired'
├── subscriptionExpiresAt: Timestamp
└── updatedAt: Timestamp
```

---

## Vérification de l'Installation

### ✅ Checklist

- [ ] `flutter pub get` exécuté
- [ ] Secret créé dans Secret Manager
- [ ] Permissions IAM configurées
- [ ] Cloud Functions déployées (`npm run deploy`)
- [ ] Webhook configuré dans MoneyFusion
- [ ] Test de paiement effectué
- [ ] Règles Firestore sécurisées

### Commandes de Vérification

```bash
# Vérifier que le secret existe
gcloud secrets list | grep moneyfusion-api-key

# Vérifier les permissions
gcloud secrets get-iam-policy moneyfusion-api-key

# Lister les Cloud Functions déployées
firebase functions:list

# Voir les logs
firebase functions:log --only initializePayment
```

---

## Dépannage Rapide

### Erreur: "Failed to access secret"
```bash
gcloud secrets add-iam-policy-binding moneyfusion-api-key \
    --member="serviceAccount:chiasma-android@appspot.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

### Erreur: "Function not found"
```bash
cd functions
npm run deploy
```

### Le webhook ne fonctionne pas
1. Vérifiez l'URL dans MoneyFusion dashboard
2. Consultez les logs: `firebase functions:log --only moneyFusionWebhook`

---

## Sécurité

### ✅ Points de Sécurité

- Clé API stockée dans Secret Manager (chiffrée)
- Jamais exposée côté client
- Vérification de l'authentification dans Cloud Functions
- Vérification de l'identité (userId)
- Logs sans données sensibles
- Region europe-west1 (conformité RGPD)

### ⚠️ Ne JAMAIS Faire

- ❌ Commiter la clé API dans Git
- ❌ Hardcoder la clé dans l'app Flutter
- ❌ Appeler MoneyFusion API directement depuis Flutter
- ❌ Partager la clé API dans des chats/forums

---

## Coûts Estimés

### Google Cloud (pour ~1000 utilisateurs/mois)

- **Secret Manager:** ~0,06 € / mois
- **Cloud Functions:** ~0-1 € / mois (niveau gratuit)
- **Firestore:** ~0-2 € / mois (selon l'usage)

**Total:** ~0-3 € / mois

### MoneyFusion

Consultez leur grille tarifaire (généralement % par transaction).

---

## Documentation Complète

- **Configuration:** [MONEYFUSION_SETUP.md](MONEYFUSION_SETUP.md)
- **Intégration:** [MONEYFUSION_INTEGRATION_GUIDE.md](MONEYFUSION_INTEGRATION_GUIDE.md)
- **API Reference:** Code commenté dans `lib/services/payment_service.dart`

---

## Support

Pour toute question:

1. **Logs Cloud Functions:** `firebase functions:log`
2. **Firestore Console:** https://console.firebase.google.com
3. **Secret Manager Console:** https://console.cloud.google.com/security/secret-manager
4. **MoneyFusion Dashboard:** [Votre lien MoneyFusion]

---

## Prochaines Étapes Recommandées

1. ✅ Complétez l'installation (étapes 1-5 ci-dessus)
2. Testez avec une carte de test MoneyFusion
3. Implémentez la page de choix d'abonnement (voir [MONEYFUSION_INTEGRATION_GUIDE.md](MONEYFUSION_INTEGRATION_GUIDE.md))
4. Configurez les règles Firestore sécurisées
5. Testez le flux complet end-to-end
6. Activez les logs et monitoring
7. Déployez en production

---

**🎉 Votre intégration MoneyFusion est prête! Suivez les 5 étapes d'installation et vous serez opérationnel.**
