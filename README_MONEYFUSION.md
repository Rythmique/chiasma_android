# 🔐 Intégration Sécurisée MoneyFusion - CHIASMA

## 📌 Vue d'Ensemble

Ce projet intègre **MoneyFusion** avec une architecture sécurisée utilisant:
- **Google Cloud Secret Manager** pour protéger votre clé API
- **Firebase Cloud Functions** pour gérer les paiements côté serveur
- **Flutter** pour l'interface utilisateur

**Votre clé API n'est JAMAIS exposée dans l'application.**

---

## 📁 Fichiers Créés

### Documentation (LIRE EN PREMIER)
1. **[INSTALLATION_COMPLETE.md](INSTALLATION_COMPLETE.md)** 👈 **COMMENCEZ ICI**
   - Vue d'ensemble complète
   - Checklist de validation
   - Exemples de code
   
2. **[MONEYFUSION_QUICKSTART.md](MONEYFUSION_QUICKSTART.md)** 👈 **GUIDE RAPIDE**
   - Installation en 5 étapes
   - Exemples minimaux
   
3. **[MONEYFUSION_SETUP.md](MONEYFUSION_SETUP.md)** 👈 **CONFIGURATION TECHNIQUE**
   - Configuration détaillée de Secret Manager
   - Déploiement Cloud Functions
   - Configuration webhook
   
4. **[MONEYFUSION_INTEGRATION_GUIDE.md](MONEYFUSION_INTEGRATION_GUIDE.md)** 👈 **GUIDE DÉVELOPPEUR**
   - Utilisation du PaymentService
   - Widgets complets
   - Gestion des erreurs

### Code

#### Backend (Cloud Functions)
- `functions/src/index.ts` - 3 Cloud Functions
- `functions/package.json` - Configuration npm
- `functions/tsconfig.json` - Configuration TypeScript

#### Frontend (Flutter)
- `lib/services/payment_service.dart` - Service de paiement complet

---

## 🚀 Démarrage Rapide

### Étape 1: Lire la Documentation

Lisez **[INSTALLATION_COMPLETE.md](INSTALLATION_COMPLETE.md)** en entier.

### Étape 2: Configurer Secret Manager

```bash
gcloud auth login
gcloud config set project chiasma-android
gcloud services enable secretmanager.googleapis.com

echo -n "VOTRE_CLE_API" | gcloud secrets create moneyfusion-api-key \
    --data-file=- \
    --replication-policy="automatic"

gcloud secrets add-iam-policy-binding moneyfusion-api-key \
    --member="serviceAccount:chiasma-android@appspot.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

### Étape 3: Déployer Cloud Functions

```bash
cd functions
npm install
npm run deploy
cd ..
```

### Étape 4: Configurer le Webhook

Copiez l'URL du webhook affichée après le déploiement et configurez-la dans MoneyFusion.

### Étape 5: Tester

```dart
import 'package:myapp/services/payment_service.dart';

final result = await PaymentService.processPayment(
  userId: currentUser.uid,
  subscriptionType: PaymentService.subscriptionMonthly,
);
```

---

## 📊 Architecture

```
┌──────────────────┐
│  Flutter App     │ (Utilisateur clique "Souscrire")
└────────┬─────────┘
         │ PaymentService.processPayment()
         ▼
┌──────────────────────────────┐
│  Firebase Cloud Functions    │ (Récupère clé API)
└────────┬─────────────────────┘
         │
         ├──► Google Cloud Secret Manager (Clé sécurisée)
         │
         └──► MoneyFusion API (Appel avec clé)
                  │
                  ▼
         ┌──────────────────┐
         │  Page Paiement   │ (Ouverte dans navigateur)
         └──────────────────┘
                  │
                  ▼ (Paiement complété)
         ┌──────────────────┐
         │  Webhook         │ (Notification à Cloud Function)
         └──────────────────┘
                  │
                  ▼
         ┌──────────────────┐
         │  Firestore       │ (Mise à jour abonnement)
         └──────────────────┘
```

---

## 🔐 Sécurité

### ✅ Ce qui EST sécurisé
- Clé API stockée dans Secret Manager (chiffrée)
- Jamais exposée côté client
- Authentification vérifiée côté serveur
- Logs sans données sensibles
- Conformité RGPD (région europe-west1)

### ⚠️ À NE JAMAIS FAIRE
- ❌ Commiter la clé API dans Git
- ❌ Hardcoder la clé dans Flutter
- ❌ Appeler MoneyFusion directement depuis Flutter
- ❌ Partager la clé API publiquement

---

## 💰 Tarifs Configurés

- **Mensuel:** 9,99 €/mois
- **Annuel:** 99,99 €/an (économie de 17%)

Modifiez dans `lib/services/payment_service.dart`.

---

## 📞 Support

**Problème?**
1. Consultez les logs: `firebase functions:log`
2. Vérifiez Secret Manager: `gcloud secrets list`
3. Lisez [INSTALLATION_COMPLETE.md](INSTALLATION_COMPLETE.md)

---

## ✅ Checklist

- [ ] Documentation lue
- [ ] Secret Manager configuré
- [ ] Cloud Functions déployées
- [ ] Webhook configuré
- [ ] Test de paiement effectué

---

**Suivant:** Lisez [INSTALLATION_COMPLETE.md](INSTALLATION_COMPLETE.md) pour commencer ! 🚀
