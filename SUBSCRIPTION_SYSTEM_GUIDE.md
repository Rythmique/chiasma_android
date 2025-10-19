# Guide du Système d'Abonnement CHIASMA

## Vue d'ensemble

Le système d'abonnement CHIASMA permet de gérer l'accès aux consultations de profils via un modèle freemium avec paiement MoneyFusion (Orange Money, MTN Money, Moov Money).

## Fonctionnalités principales

### 1. Modèle Freemium
- **5 consultations gratuites** pour chaque nouvel utilisateur inscrit
- Après épuisement, l'utilisateur doit souscrire à un abonnement
- Les administrateurs peuvent activer/désactiver le système globalement

### 2. Tarifs d'abonnement

| Durée | Prix | Avantage |
|-------|------|----------|
| 1 mois | 500 FCFA | Essai à petit prix |
| 3 mois | 1 500 FCFA | 500 FCFA/mois (économie vs mensuel) |
| 12 mois | 5 000 FCFA | **Meilleure offre** - 2 mois GRATUITS (équivaut à 10 mois au prix de 500 FCFA/mois) |

### 3. Modes de fonctionnement

#### Mode Gratuit Illimité (système désactivé)
- **Activation** : Via le toggle admin dans Paramètres
- **Comportement** : Tous les utilisateurs ont un accès illimité aux consultations
- **Notification** : Bannière indiquant "Mode gratuit et illimité"

#### Mode Abonnement (système activé)
- **Activation** : Via le toggle admin dans Paramètres
- **Comportement** :
  - Nouveaux utilisateurs : 5 consultations gratuites
  - Utilisateurs premium : Consultations illimitées jusqu'à expiration
  - Utilisateurs expirés : Bloqués, doivent souscrire

## Architecture Technique

### Modèles de données

#### 1. UserModel (mis à jour)
```dart
class UserModel {
  final int profileViewsCount;           // Compteur total de consultations
  final int freeViewsRemaining;          // Consultations gratuites restantes (0-5)
  final bool hasActiveSubscription;      // Possède un abonnement actif
  final DateTime? subscriptionEndDate;   // Date de fin de l'abonnement
  // ... autres champs
}
```

#### 2. SubscriptionModel
```dart
enum SubscriptionType {
  monthly,   // 1 mois - 500 FCFA
  quarterly, // 3 mois - 1500 FCFA
  yearly,    // 12 mois - 5000 FCFA
}

enum SubscriptionStatus {
  active,    // Abonnement actif
  expired,   // Abonnement expiré
  cancelled, // Abonnement annulé
}
```

#### 3. AppConfigModel
```dart
class AppConfigModel {
  final bool subscriptionSystemEnabled;  // Toggle global du système
  final int freeConsultationsLimit;      // Nombre de consultations gratuites (5)
  final DateTime updatedAt;
  final String? updatedBy;               // UID de l'admin qui a modifié
}
```

### Services

#### 1. MoneyFusionService
**Fichier** : `lib/services/moneyfusion_service.dart`

**Responsabilité** : Intégration de l'API MoneyFusion pour les paiements Mobile Money

**Méthodes principales** :
- `initiatePayment()` - Initier un paiement
- `checkPaymentStatus()` - Vérifier le statut d'une transaction
- `cancelPayment()` - Annuler un paiement en attente
- `formatPhoneNumber()` - Formater les numéros ivoiriens (+225)

**Configuration requise** :
```dart
// Dans moneyfusion_service.dart, remplacer par vos vraies clés :
static const String _apiKey = 'YOUR_MONEYFUSION_API_KEY';
static const String _merchantId = 'YOUR_MERCHANT_ID';
```

#### 2. SubscriptionService
**Fichier** : `lib/services/subscription_service.dart`

**Responsabilité** : Gestion complète des abonnements et consultations

**Méthodes principales** :
- `getAppConfig()` - Récupérer la configuration globale
- `updateAppConfig()` - Mettre à jour le toggle admin (admins seulement)
- `createSubscription()` - Créer un abonnement après paiement
- `getActiveSubscription()` - Obtenir l'abonnement actif d'un utilisateur
- `canUserViewProfile()` - Vérifier si un utilisateur peut consulter un profil
- `incrementProfileViewCount()` - Décrémenter les consultations gratuites
- `checkExpiredSubscriptions()` - Tâche de maintenance (à exécuter périodiquement)

## Flux Utilisateur

### 1. Inscription
```
Nouvel utilisateur
    ↓
Créer compte (Firebase Auth)
    ↓
Créer profil Firestore
    ↓
Initialiser : freeViewsRemaining = 5
```

### 2. Consultation de profil (système activé)

```
Utilisateur clique sur un profil
    ↓
Vérifier : canUserViewProfile()
    ↓
┌─────────────────────────────────┐
│ A un abonnement actif ?         │
│   OUI → Autoriser (illimité)    │
└─────────────────────────────────┘
    ↓ NON
┌─────────────────────────────────┐
│ freeViewsRemaining > 0 ?        │
│   OUI → Autoriser + décrémenter │
└─────────────────────────────────┘
    ↓ NON
┌─────────────────────────────────┐
│ Bloquer + Rediriger vers        │
│ page d'abonnement               │
└─────────────────────────────────┘
```

### 3. Souscription d'abonnement

```
Utilisateur choisit un plan
    ↓
Sélectionne mode de paiement
(Orange/MTN/Moov Money)
    ↓
Entre son numéro de téléphone
    ↓
Initier paiement via MoneyFusion
    ↓
Utilisateur compose #144# et valide
    ↓
Vérifier statut du paiement
    ↓
┌─────────────────────────────────┐
│ Paiement réussi ?               │
│   OUI → Créer abonnement        │
│   NON → Afficher erreur         │
└─────────────────────────────────┘
    ↓ OUI
Mettre à jour UserModel :
  - hasActiveSubscription = true
  - subscriptionEndDate = now + durée
    ↓
Accès illimité jusqu'à expiration
```

## Interface Administrateur

### Panel Admin - Onglet "Paramètres"

#### Toggle Principal
**Localisation** : Panel Admin > Paramètres

**Fonctionnalité** :
- **Activé** : Système d'abonnement opérationnel
  - Nouveaux utilisateurs : 5 consultations gratuites
  - Nécessite abonnement après épuisement

- **Désactivé** : Mode gratuit illimité
  - Tous les utilisateurs ont accès illimité
  - Aucune restriction de consultation
  - Message affiché : "Mode gratuit et illimité activé"

#### Statistiques affichées
- **Total abonnements** : Nombre total d'abonnements créés
- **Abonnements actifs** : Nombre d'abonnements en cours
- **Abonnements expirés** : Nombre d'abonnements terminés
- **Revenus totaux** : Somme des paiements en FCFA

#### Tarifs affichés
- 1 mois : 500 FCFA
- 3 mois : 1 500 FCFA
- 12 mois : 5 000 FCFA (meilleure offre)

## Structure Firebase

### Collections Firestore

#### 1. `users` (mise à jour)
```json
{
  "uid": "user123",
  "email": "user@example.com",
  "profileViewsCount": 12,
  "freeViewsRemaining": 0,
  "hasActiveSubscription": true,
  "subscriptionEndDate": "2025-12-31T23:59:59Z",
  // ... autres champs
}
```

#### 2. `subscriptions` (nouvelle collection)
```json
{
  "id": "sub123",
  "userId": "user123",
  "type": "yearly",
  "status": "active",
  "amountPaid": 5000,
  "startDate": "2025-01-15T10:00:00Z",
  "endDate": "2026-01-15T10:00:00Z",
  "transactionId": "mf_txn_abc123",
  "paymentMethod": "orange_money",
  "createdAt": "2025-01-15T10:00:00Z"
}
```

#### 3. `app_config` (nouvelle collection)
Document unique : `global_config`
```json
{
  "subscriptionSystemEnabled": true,
  "freeConsultationsLimit": 5,
  "updatedAt": "2025-01-15T10:00:00Z",
  "updatedBy": "admin_uid"
}
```

## Notifications Utilisateur

### Bannières de statut

#### Mode gratuit illimité (système désactivé)
```
┌─────────────────────────────────────────┐
│ 🎉 Mode gratuit et illimité activé      │
│ Consultez autant de profils que vous    │
│ voulez sans restriction                 │
└─────────────────────────────────────────┘
```

#### Consultations limitées (système activé, pas d'abonnement)
```
┌─────────────────────────────────────────┐
│ ⚠️ 3 consultations gratuites restantes │
│ [Voir les offres d'abonnement]         │
└─────────────────────────────────────────┘
```

#### Abonnement premium actif
```
┌─────────────────────────────────────────┐
│ ⭐ Premium - Consultations illimitées   │
│ Votre abonnement expire dans 45 jours  │
└─────────────────────────────────────────┘
```

#### Consultations épuisées
```
┌─────────────────────────────────────────┐
│ 🔒 Consultations gratuites épuisées     │
│ Souscrivez pour continuer               │
│ [Voir les offres]                       │
└─────────────────────────────────────────┘
```

## Configuration MoneyFusion

### 1. Obtenir vos clés API
1. Créer un compte marchand sur [MoneyFusion](https://moneyfusion.net)
2. Accéder au tableau de bord
3. Générer vos clés API (API Key & Merchant ID)

### 2. Configurer dans le code
Éditer `lib/services/moneyfusion_service.dart` :

```dart
static const String _apiKey = 'votre_cle_api_moneyfusion';
static const String _merchantId = 'votre_merchant_id';
```

### 3. URL de callback (optionnel)
Pour les notifications de paiement en temps réel, configurer :
```dart
'callback_url': 'https://votreapp.com/payment-callback'
```

## Tests et Validation

### Scénarios de test

#### Test 1 : Nouvel utilisateur
1. Créer un nouveau compte
2. Vérifier : `freeViewsRemaining = 5`
3. Consulter 5 profils
4. Vérifier : `freeViewsRemaining = 0`
5. Tenter 6ème consultation → Redirection vers abonnement

#### Test 2 : Souscription abonnement
1. Utilisateur avec 0 consultations
2. Choisir plan "1 mois - 500 FCFA"
3. Sélectionner Orange Money
4. Entrer numéro : 0123456789
5. Vérifier transaction MoneyFusion
6. Confirmer paiement
7. Vérifier : `hasActiveSubscription = true`
8. Vérifier : Consultations illimitées possibles

#### Test 3 : Toggle admin
1. Se connecter en tant qu'admin
2. Panel Admin > Paramètres
3. Désactiver le système
4. Vérifier : Tous utilisateurs ont accès illimité
5. Vérifier : Message "Mode gratuit illimité"
6. Réactiver le système
7. Vérifier : Restrictions appliquées à nouveau

## Maintenance et Tâches Périodiques

### Vérification des abonnements expirés
À exécuter quotidiennement (via Cloud Functions ou cron) :

```dart
await subscriptionService.checkExpiredSubscriptions();
```

Cette fonction :
- Trouve tous les abonnements avec `status = active` et `endDate < now`
- Marque les abonnements comme `expired`
- Met à jour `hasActiveSubscription = false` pour les utilisateurs concernés

### Exemple Cloud Function (Firebase)
```javascript
exports.checkExpiredSubscriptions = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    // Appeler la logique de vérification
  });
```

## Sécurité

### Règles Firestore recommandées

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Configuration globale - Lecture pour tous, écriture admin seulement
    match /app_config/{docId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }

    // Abonnements - Lecture par propriétaire, création via backend
    match /subscriptions/{subId} {
      allow read: if request.auth != null &&
                     resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
      allow update, delete: if false; // Via backend seulement
    }

    // Utilisateurs - Voir profil, modifier le sien seulement
    match /users/{userId} {
      allow read: if request.auth != null;
      allow update: if request.auth != null &&
                       request.auth.uid == userId;
    }
  }
}
```

## Dépannage

### Problème : Paiement non validé
**Symptômes** : Transaction initiée mais abonnement non créé

**Solutions** :
1. Vérifier le statut via `checkPaymentStatus(transactionId)`
2. Confirmer que l'utilisateur a bien validé via #144#
3. Vérifier les logs MoneyFusion
4. Contacter support MoneyFusion si nécessaire

### Problème : Toggle admin ne fonctionne pas
**Symptômes** : Changement non pris en compte

**Solutions** :
1. Vérifier que l'utilisateur est bien admin (`isAdmin = true`)
2. Vérifier les permissions Firestore
3. Forcer un rechargement de l'application
4. Vérifier les logs de la console

### Problème : Consultations non décrémentées
**Symptômes** : `freeViewsRemaining` ne diminue pas

**Solutions** :
1. Vérifier que `incrementProfileViewCount()` est bien appelé
2. Vérifier les permissions d'écriture Firestore
3. Vérifier que le système est activé
4. Consulter les logs Firebase

## Fichiers du système

### Modèles
- `lib/models/subscription_model.dart` - Modèles Subscription et AppConfig
- `lib/models/user_model.dart` - Modèle User (mis à jour)

### Services
- `lib/services/moneyfusion_service.dart` - Intégration MoneyFusion API
- `lib/services/subscription_service.dart` - Gestion des abonnements

### Pages
- `lib/subscription_page.dart` - Page de souscription utilisateur (mise à jour)
- `lib/admin_panel_page.dart` - Panel admin avec onglet Paramètres (mis à jour)

## Support et Contact

Pour toute question ou problème :
1. Consulter la documentation MoneyFusion : https://docs.moneyfusion.net
2. Vérifier les logs Firebase Console
3. Contacter le support technique CHIASMA

---

**Version** : 1.0.0
**Dernière mise à jour** : Janvier 2025
**Auteur** : Équipe CHIASMA
