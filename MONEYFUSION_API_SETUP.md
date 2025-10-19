# Configuration de l'API MoneyFusion - CHIASMA

## ✅ Code mis à jour avec la vraie API MoneyFusion

Le service MoneyFusion a été complètement réécrit pour correspondre à la **documentation officielle**.

---

## 🔑 Étape CRITIQUE : Obtenir votre API URL

### 1. Connectez-vous à votre tableau de bord MoneyFusion

Allez sur : **https://moneyfusion.net** (ou votre URL de dashboard)

### 2. Récupérez votre API URL unique

Selon la documentation MoneyFusion, chaque marchand a une **API URL unique** à récupérer depuis le tableau de bord.

Cette URL ressemble probablement à :
```
https://api.moneyfusion.net/merchant/[VOTRE_ID]/payment
```
ou similaire.

### 3. Configurez l'URL dans le code

Ouvrez le fichier : `lib/services/moneyfusion_service.dart`

**Ligne 10**, remplacez :
```dart
static const String _apiUrl = 'YOUR_API_URL';
```

Par votre vraie URL, par exemple :
```dart
static const String _apiUrl = 'https://api.moneyfusion.net/merchant/68aee21447de6b2608cdac7a/payment';
```

---

## 📋 Format de l'API implémenté

### Requête de paiement

**Endpoint :** Votre API URL (depuis le dashboard)

**Méthode :** POST

**Headers :**
```json
{
  "Content-Type": "application/json"
}
```

**Body :**
```json
{
  "totalPrice": 500,
  "article": [
    {
      "Abonnement CHIASMA - Mensuel": 500
    }
  ],
  "personal_Info": [
    {
      "userId": "user123",
      "orderId": "sub_1234567890"
    }
  ],
  "numeroSend": "0123456789",
  "nomclient": "John Doe",
  "return_url": "https://your-app.com/callback",
  "webhook_url": "https://your-app.com/webhook"
}
```

### Réponse attendue

```json
{
  "statut": true,
  "token": "5d58823b084564",
  "message": "paiement en cours",
  "url": "https://www.pay.moneyfusion.net/pay/6596aded36bd58823b084564"
}
```

---

## 🔍 Vérification du statut

**Endpoint :** `https://www.pay.moneyfusion.net/paiementNotif/{token}`

**Méthode :** GET

**Réponse :**
```json
{
  "statut": true,
  "data": {
    "tokenPay": "0d1d8bc9b6d2819c",
    "statut": "paid",
    "Montant": 500,
    "frais": 5,
    "moyen": "orange",
    "numeroTransaction": "0708889205"
  }
}
```

---

## 🎯 Statuts de paiement

| Statut | Description |
|--------|-------------|
| `pending` | Paiement en cours |
| `paid` | ✅ Paiement réussi |
| `failure` | ❌ Paiement échoué |
| `no paid` | ❌ Paiement non effectué |

---

## 🧪 Test du paiement

### Option 1 : Via l'application Flutter

1. Lancez l'app : `flutter run`
2. Connectez-vous avec un compte
3. Allez dans "Abonnement"
4. Sélectionnez un plan (Mensuel 500 FCFA)
5. Choisissez Orange Money
6. Entrez votre numéro : `0123456789`
7. Vérifiez les logs :

```bash
flutter logs | grep MoneyFusion
```

### Option 2 : Test direct avec curl

```bash
curl -X POST [VOTRE_API_URL] \
  -H "Content-Type: application/json" \
  -d '{
    "totalPrice": 500,
    "article": [{"Test": 500}],
    "personal_Info": [{"userId": "test123"}],
    "numeroSend": "0123456789",
    "nomclient": "Test User"
  }'
```

---

## 📱 Format des numéros de téléphone

MoneyFusion attend le format : **`0123456789`** (commence par 0)

Le service convertit automatiquement :
- `+2250123456789` → `0123456789`
- `2250123456789` → `0123456789`
- `0123456789` → `0123456789` ✅

---

## 🔧 Modifications apportées

### 1. `lib/services/moneyfusion_service.dart`
- ✅ Réécrit selon la documentation officielle MoneyFusion
- ✅ Utilise le format `totalPrice`, `article`, `numeroSend`, `nomclient`
- ✅ Retourne `token` comme ID de transaction
- ✅ URL de vérification : `https://www.pay.moneyfusion.net/paiementNotif/{token}`
- ✅ Statuts corrects : `pending`, `paid`, `failure`, `no paid`

### 2. `lib/services/subscription_service.dart`
- ✅ Récupère le nom du client depuis Firestore
- ✅ Formate correctement le numéro de téléphone
- ✅ Passe tous les paramètres requis par MoneyFusion
- ✅ Utilise le statut `paid` au lieu de `SUCCESS`

---

## ⚠️ Important

### Ce qui DOIT être configuré :

1. **API URL** dans `moneyfusion_service.dart:10` ← **CRITIQUE**
2. Optionnel : `return_url` et `webhook_url` si vous voulez des callbacks

### Ce qui est déjà configuré :

- ✅ Format de requête MoneyFusion
- ✅ Gestion des réponses
- ✅ Vérification de statut
- ✅ Formatage des numéros
- ✅ Intégration avec le système d'abonnement

---

## 🚀 Prochaines étapes

1. **Récupérez votre API URL** depuis le dashboard MoneyFusion
2. **Configurez-la** dans `lib/services/moneyfusion_service.dart:10`
3. **Testez** un paiement dans l'app
4. **Vérifiez les logs** pour voir la réponse MoneyFusion

---

## 📞 Support

Si vous ne trouvez pas votre API URL :
1. Contactez le support MoneyFusion
2. Vérifiez votre tableau de bord dans la section "API" ou "Intégration"
3. La documentation mentionne : "Obtenez ceci depuis votre tableau de bord"

---

## 🎉 Une fois configuré

Votre système de paiement fonctionnera comme ceci :

1. **Utilisateur clique "Souscrire"** → Sélectionne un plan
2. **Entre son numéro** → Orange Money / MTN / Moov
3. **API MoneyFusion appelée** → Retourne une URL de paiement
4. **Utilisateur redirigé** → Page de paiement MoneyFusion
5. **Paiement validé** → Statut `paid` retourné
6. **Abonnement activé** → L'utilisateur est Premium !

---

**Question ?** Lisez les logs détaillés avec `flutter logs` pour diagnostiquer tout problème.
