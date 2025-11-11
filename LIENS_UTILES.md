# 🔗 Liens Utiles - Chiasma

## 🔥 Firebase Console

### Dashboard Principal
**Console Firebase** : https://console.firebase.google.com/project/chiasma-android/overview

### Cloud Functions
**Functions Dashboard** : https://console.firebase.google.com/project/chiasma-android/functions

**URLs des fonctions** :
- `helloWorld` : https://us-central1-chiasma-android.cloudfunctions.net/helloWorld
- `reindexAllUsers` : https://us-central1-chiasma-android.cloudfunctions.net/reindexAllUsers
- `reindexAllJobOffers` : https://us-central1-chiasma-android.cloudfunctions.net/reindexAllJobOffers

### Firestore Database
**Firestore Console** : https://console.firebase.google.com/project/chiasma-android/firestore

**Collections importantes** :
- `users` - Profils utilisateurs (écoles, candidats, enseignants)
- `job_offers` - Offres d'emploi
- `notifications` - Historique notifications (avec métadonnées push)
- `privacy_settings` - Paramètres de confidentialité

### Cloud Messaging
**FCM Console** : https://console.firebase.google.com/project/chiasma-android/notification

### Logs
**Functions Logs** : https://console.firebase.google.com/project/chiasma-android/functions/logs

---

## 🔍 Algolia Dashboard

**Application** : EHXDOBMUY9

### Dashboard Principal
**Console Algolia** : https://www.algolia.com/apps/EHXDOBMUY9/dashboard

### Indices
**Index Users** : https://www.algolia.com/apps/EHXDOBMUY9/explorer/browse/users
**Index Job Offers** : https://www.algolia.com/apps/EHXDOBMUY9/explorer/browse/job_offers

### API Keys
**Settings → API Keys** : https://www.algolia.com/apps/EHXDOBMUY9/api-keys/all

**Clés configurées** :
- Application ID : `EHXDOBMUY9`
- Search-Only API Key : `bedf7946040c42b76b24c6e2d2eaee87` (dans le code Flutter)
- Admin API Key : `6d40...7546` (dans functions/.env, backend seulement)

---

## 📱 Commandes Utiles

### Déploiement

```bash
# Déployer toutes les fonctions
firebase deploy --only functions

# Déployer une fonction spécifique
firebase deploy --only functions:sendPushNotification

# Voir les logs en temps réel
firebase functions:log --only sendPushNotification

# Voir tous les logs
firebase functions:log
```

### Build Flutter

```bash
# Build APK release
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

# Build et run en debug
flutter run
```

### Tests Notifications

```bash
# Appeler la fonction de test (depuis Firebase Console ou avec curl)
# Option 1 : Firebase Console → Functions → sendTestNotification → Test

# Option 2 : Depuis Flutter
FirebaseFunctions.instance
  .httpsCallable('sendTestNotification')
  .call({'title': 'Test', 'message': 'Notification test'});
```

### Réindexation Algolia

```bash
# Réindexer tous les utilisateurs (HTTP GET/POST)
curl https://us-central1-chiasma-android.cloudfunctions.net/reindexAllUsers

# Réindexer toutes les offres
curl https://us-central1-chiasma-android.cloudfunctions.net/reindexAllJobOffers
```

---

## 🔧 Maintenance

### Nettoyer le cache local

```bash
flutter clean
flutter pub get
```

### Mettre à jour les dépendances

```bash
flutter pub upgrade
```

### Vérifier l'état Firebase

```bash
firebase projects:list
firebase use chiasma-android
firebase functions:list
```

### Voir les tokens FCM invalides nettoyés

Firestore Console → Collection `users` → Filtrer où `fcmToken` est null

---

## 📊 Monitoring

### Métriques Firebase Functions

**Usage Dashboard** : https://console.firebase.google.com/project/chiasma-android/usage

**Métriques à surveiller** :
- Invocations : < 2M/mois (gratuit)
- Durée d'exécution
- Erreurs (taux < 1%)

### Algolia Monitoring

**Analytics** : https://www.algolia.com/apps/EHXDOBMUY9/analytics/overview

**Métriques à surveiller** :
- Recherches : < 10k/mois (gratuit)
- Records : < 10k (gratuit)
- Latence des recherches

---

## 🆘 Support

### Documentation Firebase
- Functions : https://firebase.google.com/docs/functions
- FCM : https://firebase.google.com/docs/cloud-messaging
- Firestore : https://firebase.google.com/docs/firestore

### Documentation Algolia
- Getting Started : https://www.algolia.com/doc/
- Flutter Integration : https://www.algolia.com/doc/guides/building-search-ui/what-is-instantsearch/flutter/

### Documentation Flutter
- Main Docs : https://flutter.dev/docs
- Packages : https://pub.dev/

---

## 🔐 Informations Sensibles

⚠️ **NE JAMAIS PARTAGER** :
- Admin API Key Algolia (6d40...7546)
- Firebase Service Account Keys
- Fichier `functions/.env`

✅ **OK à partager publiquement** :
- Application ID Algolia (EHXDOBMUY9)
- Search-Only API Key (bedf7946...)
- URLs des Cloud Functions

---

## 📁 Structure Projet

```
myapp/
├── lib/                                  # Code Flutter
│   ├── models/                          # Modèles de données
│   │   ├── user_model.dart             # UserModel avec fcmToken
│   │   └── notification_model.dart     # NotificationModel
│   ├── services/                        # Services
│   │   ├── notification_service.dart   # Notifications (délègue à Cloud Functions)
│   │   └── privacy_settings_service.dart
│   ├── school/
│   │   ├── create_job_offer_page.dart  # Niveaux/Matières étendus
│   │   └── school_home_screen.dart     # Cache fonctionnel
│   ├── teacher_candidate/
│   │   └── candidate_home_screen.dart  # Cache fonctionnel
│   └── config/
│       └── algolia_config.dart         # Config Algolia (App ID + Search Key)
├── functions/                           # Cloud Functions
│   ├── src/
│   │   ├── index.ts                    # Point d'entrée
│   │   ├── notifications.ts            # 3 fonctions notifications
│   │   └── algoliaSync.ts              # 4 fonctions Algolia
│   ├── .env                            # Variables backend (GIT IGNORED)
│   └── package.json
└── Documentation/
    ├── TOUT_EST_PRET.txt               # Résumé rapide
    ├── DEPLOIEMENT_FINAL.md            # Guide complet
    ├── LIENS_UTILES.md                 # Ce fichier
    └── README_NOTIFICATIONS.md         # Doc notifications
```

---

**Dernière mise à jour** : 11 Novembre 2025
