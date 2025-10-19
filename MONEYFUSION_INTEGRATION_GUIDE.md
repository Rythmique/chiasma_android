# Guide d'Intégration MoneyFusion - CHIASMA

Ce guide explique comment utiliser l'intégration MoneyFusion dans votre application Flutter.

---

## Vue d'Ensemble de l'Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App (Client)                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         PaymentService.processPayment()              │   │
│  └─────────────────────┬───────────────────────────────┘   │
└────────────────────────┼─────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Firebase Cloud Functions                        │
│  ┌──────────────────────────────────────────────────┐       │
│  │  initializePayment()                              │       │
│  │    ↓                                              │       │
│  │  Google Cloud Secret Manager                      │       │
│  │    ↓                                              │       │
│  │  MoneyFusion API (avec clé sécurisée)            │       │
│  └──────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   MoneyFusion                                │
│  (Page de paiement ouverte dans le navigateur)              │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Webhook → Cloud Function                        │
│  (Mise à jour automatique de l'abonnement)                  │
└─────────────────────────────────────────────────────────────┘
```

---

## Utilisation du PaymentService

### Import

```dart
import 'package:myapp/services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
```

### Exemple 1: Initialiser un Paiement (Méthode Simple)

```dart
Future<void> buySubscription(String subscriptionType) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veuillez vous connecter')),
    );
    return;
  }

  // Afficher un indicateur de chargement
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  // Initialiser et ouvrir le paiement
  final result = await PaymentService.processPayment(
    userId: user.uid,
    subscriptionType: subscriptionType, // 'monthly' ou 'yearly'
  );

  // Fermer l'indicateur
  Navigator.of(context).pop();

  if (result['success'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paiement initié! ID: ${result['paymentId']}'),
        backgroundColor: Colors.green,
      ),
    );

    // La page de paiement s'est ouverte automatiquement
    // L'utilisateur va compléter le paiement dans son navigateur
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: ${result['error']}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Exemple 2: Initialiser sans Ouvrir l'URL (Contrôle Manuel)

```dart
Future<void> initPayment(String subscriptionType) async {
  final user = FirebaseAuth.instance.currentUser!;

  final result = await PaymentService.initializePayment(
    userId: user.uid,
    subscriptionType: subscriptionType,
  );

  if (result['success'] == true) {
    final paymentUrl = result['paymentUrl'] as String;
    final paymentId = result['paymentId'] as String;

    // Sauvegarder le paymentId pour référence
    await savePaymentId(paymentId);

    // Ouvrir manuellement plus tard
    await PaymentService.openPaymentUrl(paymentUrl);
  }
}
```

### Exemple 3: Vérifier le Statut d'un Paiement

```dart
Future<void> checkPayment(String paymentId) async {
  final result = await PaymentService.checkPaymentStatus(
    paymentId: paymentId,
  );

  if (result['success'] == true) {
    final status = result['status'] as String;

    switch (status) {
      case 'pending':
        print('Paiement en attente');
        break;
      case 'completed':
        print('Paiement complété!');
        // L'abonnement a été automatiquement activé par le webhook
        break;
      case 'failed':
        print('Paiement échoué');
        break;
    }
  }
}
```

---

## Widget Complet: Page de Choix d'Abonnement

```dart
import 'package:flutter/material.dart';
import 'package:myapp/services/payment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionChoicePage extends StatelessWidget {
  const SubscriptionChoicePage({Key? key}) : super(key: key);

  Future<void> _buySubscription(
    BuildContext context,
    String subscriptionType,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }

    // Afficher chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Initialiser le paiement
    final result = await PaymentService.processPayment(
      userId: user.uid,
      subscriptionType: subscriptionType,
    );

    // Fermer le chargement
    if (context.mounted) {
      Navigator.of(context).pop();

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Page de paiement ouverte. Complétez votre achat!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final savings = PaymentService.calculateYearlySavings();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir un abonnement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Abonnement Mensuel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Abonnement Mensuel',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      PaymentService.formatPrice(
                        PaymentService.getSubscriptionPrice(
                          PaymentService.subscriptionMonthly,
                        )!,
                      ),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Text('par mois'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _buySubscription(
                        context,
                        PaymentService.subscriptionMonthly,
                      ),
                      child: const Text('Souscrire'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Abonnement Annuel
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Abonnement Annuel',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            'Économisez ${savings['percentage']}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      PaymentService.formatPrice(
                        PaymentService.getSubscriptionPrice(
                          PaymentService.subscriptionYearly,
                        )!,
                      ),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Text('par an'),
                    const SizedBox(height: 8),
                    Text(
                      'Économie de ${PaymentService.formatPrice(savings['savings'])}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _buySubscription(
                        context,
                        PaymentService.subscriptionYearly,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Souscrire (Meilleure offre!)'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Configuration Android pour URL Launcher

Ajoutez dans `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest...>
    <application...>
        <!-- Vos activités existantes -->
    </application>

    <!-- Ajouter cette permission pour ouvrir les URLs -->
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
    </queries>
</manifest>
```

---

## Configuration Web pour URL Launcher

Pas de configuration spéciale nécessaire pour le web.

---

## Flux Utilisateur Complet

1. **L'utilisateur choisit un abonnement** dans l'app Flutter
2. **L'app appelle** `PaymentService.processPayment()`
3. **Cloud Function** récupère la clé API depuis Secret Manager
4. **Cloud Function** appelle l'API MoneyFusion
5. **MoneyFusion** retourne une URL de paiement
6. **L'app ouvre** cette URL dans le navigateur de l'utilisateur
7. **L'utilisateur complète** le paiement sur MoneyFusion
8. **MoneyFusion envoie** un webhook à votre Cloud Function
9. **Cloud Function** met à jour l'abonnement dans Firestore
10. **L'utilisateur revient** dans l'app et voit son abonnement actif

---

## Gestion de l'État de l'Abonnement

### Écouter les Changements d'Abonnement

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Stream<Map<String, dynamic>?> watchUserSubscription(String userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;

    final data = doc.data()!;
    return {
      'subscriptionType': data['subscriptionType'],
      'subscriptionStatus': data['subscriptionStatus'],
      'subscriptionExpiresAt': data['subscriptionExpiresAt'],
    };
  });
}

// Utilisation dans un widget
StreamBuilder<Map<String, dynamic>?>(
  stream: watchUserSubscription(currentUser.uid),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final sub = snapshot.data!;
      final isActive = sub['subscriptionStatus'] == 'active';

      return Text(isActive
          ? 'Abonnement actif: ${sub['subscriptionType']}'
          : 'Aucun abonnement actif');
    }
    return const CircularProgressIndicator();
  },
)
```

---

## Gestion des Erreurs

### Types d'Erreurs Possibles

1. **Utilisateur non authentifié**
   ```dart
   {'success': false, 'error': 'Utilisateur non authentifié'}
   ```

2. **Type d'abonnement invalide**
   ```dart
   {'success': false, 'error': 'Type d\'abonnement invalide'}
   ```

3. **Erreur Cloud Function**
   ```dart
   {'success': false, 'error': 'Erreur lors de l\'initialisation du paiement: ...'}
   ```

4. **URL de paiement ne peut pas s'ouvrir**
   ```dart
   {
     'success': false,
     'error': 'Impossible d\'ouvrir la page de paiement',
     'paymentId': '...',
     'paymentUrl': '...'
   }
   ```

### Gestion Recommandée

```dart
final result = await PaymentService.processPayment(...);

if (result['success'] == false) {
  final error = result['error'] as String;

  // Log pour debug
  developer.log('Payment failed: $error', name: 'MyApp');

  // Message utilisateur
  String userMessage;
  if (error.contains('authentifié')) {
    userMessage = 'Veuillez vous connecter pour continuer';
  } else if (error.contains('ouvrir la page')) {
    userMessage = 'Impossible d\'ouvrir la page de paiement. '
        'URL: ${result['paymentUrl']}';
  } else {
    userMessage = 'Une erreur est survenue. Veuillez réessayer.';
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(userMessage)),
  );
}
```

---

## Tests

### Test Local avec Émulateurs

```bash
# Terminal 1: Démarrer l'émulateur Firebase
cd functions
npm run serve

# Terminal 2: Configurer Flutter pour utiliser l'émulateur
# Dans votre main.dart, ajoutez:
```

```dart
import 'package:cloud_functions/cloud_functions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // UNIQUEMENT EN DÉVELOPPEMENT
  if (kDebugMode) {
    FirebaseFunctions.instanceFor(region: 'europe-west1')
        .useFunctionsEmulator('localhost', 5001);
  }

  runApp(MyApp());
}
```

### Test de Paiement en Production

1. Utilisez les cartes de test MoneyFusion (consultez leur documentation)
2. Vérifiez les logs Cloud Functions: `firebase functions:log`
3. Vérifiez Firestore pour voir si la transaction est créée
4. Testez le webhook avec un payload manuel

---

## Sécurité

### Points de Sécurité Importants

1. ✅ **La clé API n'est jamais exposée** côté client
2. ✅ **Vérification de l'authentification** dans Cloud Functions
3. ✅ **Vérification de l'identité** (l'utilisateur ne peut payer que pour lui-même)
4. ✅ **Logging sécurisé** (pas de données sensibles dans les logs)
5. ✅ **Region europe-west1** pour conformité RGPD

### Règles Firestore à Ajouter

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if false; // Seulement via Cloud Functions
    }

    match /payment_transactions/{transactionId} {
      allow read: if request.auth != null
                  && resource.data.userId == request.auth.uid;
      allow write: if false; // Seulement via Cloud Functions
    }
  }
}
```

---

## FAQ

### Q: L'utilisateur a payé, mais son abonnement n'est pas actif?

**R:** Vérifiez:
1. Le webhook est-il configuré dans MoneyFusion?
2. Les logs de `moneyFusionWebhook`: `firebase functions:log --only moneyFusionWebhook`
3. La collection `payment_transactions` dans Firestore

### Q: Comment tester sans payer réellement?

**R:** Utilisez les cartes de test MoneyFusion ou configurez un compte sandbox.

### Q: L'URL de paiement ne s'ouvre pas?

**R:** Vérifiez:
1. La configuration Android (queries dans AndroidManifest.xml)
2. Les permissions iOS (LSApplicationQueriesSchemes dans Info.plist)
3. Testez manuellement l'URL retournée

### Q: Comment gérer les remboursements?

**R:** Consultez la documentation MoneyFusion pour les webhooks de remboursement. Vous devrez ajouter une fonction pour gérer l'événement `refund`.

---

## Prochaines Étapes

1. ✅ Suivre [MONEYFUSION_SETUP.md](MONEYFUSION_SETUP.md) pour déployer
2. Tester l'intégration avec les cartes de test
3. Configurer le webhook dans MoneyFusion
4. Implémenter la page de choix d'abonnement
5. Tester le flux complet end-to-end
6. Déployer en production

---

## Support

Pour toute question sur l'intégration:
- Firebase Functions: Consultez les logs avec `firebase functions:log`
- MoneyFusion API: Consultez leur documentation
- Firestore: Vérifiez les collections `users` et `payment_transactions`
