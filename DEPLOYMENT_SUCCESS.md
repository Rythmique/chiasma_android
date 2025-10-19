# ✅ Déploiement Réussi !

## 🎉 Les Cloud Functions sont Déployées !

Les 3 Cloud Functions MoneyFusion sont **ACTIVES et DÉPLOYÉES** :

### 1. initializePayment
- **URL:** `https://europe-west1-chiasma-android.cloudfunctions.net/initializePayment`
- **Type:** Callable Function (appelée depuis Flutter)
- **Statut:** ✅ ACTIVE

### 2. moneyFusionWebhook
- **URL:** `https://europe-west1-chiasma-android.cloudfunctions.net/moneyFusionWebhook`
- **Type:** HTTP Function (webhook pour MoneyFusion)
- **Statut:** ✅ ACTIVE

### 3. checkPaymentStatus
- **URL:** `https://europe-west1-chiasma-android.cloudfunctions.net/checkPaymentStatus`
- **Type:** Callable Function (appelée depuis Flutter)
- **Statut:** ✅ ACTIVE

---

## 🔧 Prochaines Étapes pour Activer les Paiements

### Étape 1: Configurer le Secret MoneyFusion ⚠️ **OBLIGATOIRE**

```bash
# Se connecter à Google Cloud
gcloud auth login

# Définir le projet
gcloud config set project chiasma-android

# Créer le secret avec votre clé API MoneyFusion
echo -n "VOTRE_CLE_MONEYFUSION_ICI" | gcloud secrets create moneyfusion-api-key \
    --data-file=- \
    --replication-policy="automatic"

# Donner l'accès à Cloud Functions
gcloud secrets add-iam-policy-binding moneyfusion-api-key \
    --member="serviceAccount:chiasma-android@appspot.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

**SANS CETTE ÉTAPE, les paiements NE FONCTIONNERONT PAS !**

---

### Étape 2: Configurer le Webhook MoneyFusion

1. Connectez-vous à votre dashboard MoneyFusion
2. Allez dans **Paramètres** → **Webhooks**
3. Ajoutez cette URL :
   ```
   https://europe-west1-chiasma-android.cloudfunctions.net/moneyFusionWebhook
   ```
4. Sélectionnez les événements :
   - ✅ `payment.completed` (ou `payment.success`)
   - ✅ `payment.failed`
   - ✅ `payment.pending` (optionnel)

---

### Étape 3: Tester l'Intégration dans Flutter

Votre app Flutter est déjà configurée ! Le service `PaymentService` est prêt à utiliser.

**Code de test simple :**

```dart
import 'package:myapp/services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> testPayment() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('❌ Utilisateur non connecté');
    return;
  }

  print('🔄 Initialisation du paiement...');

  final result = await PaymentService.processPayment(
    userId: user.uid,
    subscriptionType: PaymentService.subscriptionMonthly,
  );

  if (result['success'] == true) {
    print('✅ Paiement initié!');
    print('   Payment ID: ${result['paymentId']}');
    print('   URL: ${result['paymentUrl']}');
  } else {
    print('❌ Erreur: ${result['error']}');
  }
}
```

---

## 🔍 Diagnostic et Débogage

### Vérifier que les Functions sont actives

```bash
# Via Firebase
firebase functions:list

# Via gcloud
gcloud functions list --project=chiasma-android
```

### Voir les logs en temps réel

```bash
# Logs de la fonction de paiement
firebase functions:log --only initializePayment

# Logs du webhook
firebase functions:log --only moneyFusionWebhook

# Tous les logs
firebase functions:log
```

### Tester avec l'outil de diagnostic

Ajoutez cette page à votre app (fichier déjà créé) :

```dart
import 'package:myapp/test_payment_debug.dart';

// Dans votre navigation
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => PaymentDebugPage()),
);
```

Cette page va vous montrer exactement où est le problème avec des messages clairs.

---

## ❌ Problèmes Courants et Solutions

### Problème 1: "Failed to access secret"

**Cause:** Le secret `moneyfusion-api-key` n'existe pas ou n'a pas les bonnes permissions.

**Solution:**
```bash
# Créer le secret
echo -n "VOTRE_CLE_API" | gcloud secrets create moneyfusion-api-key \
    --data-file=- \
    --replication-policy="automatic"

# Ajouter les permissions
gcloud secrets add-iam-policy-binding moneyfusion-api-key \
    --member="serviceAccount:chiasma-android@appspot.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

### Problème 2: "Erreur lors de l'initialisation du paiement"

**Causes possibles:**
1. Le secret n'est pas configuré (voir Problème 1)
2. L'URL de l'API MoneyFusion est incorrecte
3. La clé API MoneyFusion est invalide

**Solution:**
```bash
# Vérifier les logs
firebase functions:log --only initializePayment

# Le log vous dira exactement quelle est l'erreur
```

### Problème 3: Le webhook ne reçoit pas les notifications

**Causes possibles:**
1. L'URL webhook n'est pas configurée dans MoneyFusion
2. Les événements ne sont pas sélectionnés

**Solution:**
1. Vérifiez l'URL dans MoneyFusion dashboard
2. Testez manuellement :
```bash
curl -X POST https://europe-west1-chiasma-android.cloudfunctions.net/moneyFusionWebhook \
  -H "Content-Type: application/json" \
  -d '{"paymentId":"test","status":"completed","userId":"testuser","subscriptionType":"monthly"}'
```

### Problème 4: "Function not found"

**Cause:** Les Cloud Functions ne sont pas déployées.

**Solution:** Elles SONT déployées ! Si vous avez cette erreur, c'est que l'app n'appelle pas la bonne région.

Vérifiez dans `lib/services/payment_service.dart` :
```dart
final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
```

---

## 📊 URLs des Cloud Functions

Copiez ces URLs pour votre référence :

| Fonction | URL | Usage |
|----------|-----|-------|
| **initializePayment** | `https://europe-west1-chiasma-android.cloudfunctions.net/initializePayment` | Appelée par Flutter via `PaymentService` |
| **moneyFusionWebhook** | `https://europe-west1-chiasma-android.cloudfunctions.net/moneyFusionWebhook` | Configurée dans MoneyFusion dashboard |
| **checkPaymentStatus** | `https://europe-west1-chiasma-android.cloudfunctions.net/checkPaymentStatus` | Appelée par Flutter via `PaymentService` |

---

## ✅ Checklist Finale

- [  ] Secret `moneyfusion-api-key` créé dans Google Cloud Secret Manager
- [ ] Permissions IAM configurées pour le secret
- [ ] Webhook configuré dans MoneyFusion dashboard
- [ ] Test de paiement effectué depuis l'app Flutter
- [ ] Logs vérifiés (aucune erreur)

---

## 🎯 Test Complet End-to-End

1. **Lancez l'app Flutter**
2. **Connectez-vous** avec un utilisateur Firebase
3. **Appelez** `PaymentService.processPayment()`
4. **Vérifiez** que l'URL de paiement s'ouvre
5. **Complétez** le paiement (carte de test)
6. **Vérifiez** dans Firestore que l'abonnement est activé

---

## 📞 Support

**Problème persistant ?**

1. Vérifiez les logs : `firebase functions:log`
2. Testez avec l'outil de diagnostic : `PaymentDebugPage`
3. Vérifiez Firestore : Collections `users` et `payment_transactions`
4. Consultez [MONEYFUSION_INTEGRATION_GUIDE.md](MONEYFUSION_INTEGRATION_GUIDE.md)

---

## 🎉 Félicitations !

Vos Cloud Functions sont déployées et prêtes !

**Prochaine action :** Créez le secret MoneyFusion (Étape 1 ci-dessus) et testez ! 🚀
