# Guide du Système d'Abonnement et de Quotas

## Vue d'ensemble

Ce système implémente un modèle d'abonnement avec quotas gratuits pour trois types de comptes : Permutation, Candidats et Écoles. Chaque type de compte dispose d'un quota d'utilisation gratuite qui, une fois épuisé, nécessite la souscription d'un abonnement payant.

## Architecture

### 1. Modèle de données (UserModel)

Le modèle utilisateur a été étendu avec les champs suivants :

```dart
- freeQuotaUsed: int           // Quota gratuit déjà utilisé
- freeQuotaLimit: int          // Limite du quota gratuit
- verificationExpiresAt: DateTime?  // Date d'expiration de la vérification
- subscriptionDuration: String?     // Durée de l'abonnement ('1_week', '1_month', etc.)
- lastQuotaResetDate: DateTime?     // Date du dernier reset du quota
```

**Getters utiles** :
- `isFreeQuotaExhausted` : Vérifie si le quota gratuit est épuisé
- `isVerificationExpired` : Vérifie si l'abonnement a expiré
- `hasAccess` : Vérifie si l'utilisateur a accès à l'application
- `daysUntilExpiration` : Calcule le nombre de jours restants

### 2. Service de gestion (SubscriptionService)

Le service `SubscriptionService` gère toute la logique d'abonnement :

#### Méthodes principales :

**`incrementQuotaUsage(String userId)`**
- Incrémente l'utilisation du quota
- Désactive automatiquement la vérification si le quota est épuisé

**`canPerformAction(String userId)`**
- Vérifie si l'utilisateur peut effectuer une action
- Contrôle l'expiration et le quota

**`activateSubscription(String userId, String duration)`**
- Active un abonnement avec une durée spécifique
- Reset le quota utilisé

**`checkAndExpireAccounts()`**
- Vérifie et désactive automatiquement les comptes expirés
- À appeler périodiquement (via Cloud Functions)

#### Méthodes statiques :

- `getSubscriptionMessage(String accountType)` : Message de notification selon le type
- `getWelcomeMessage(String accountType, int freeQuota)` : Message de bienvenue
- `getSubscriptionPrices(String accountType)` : Tarifs par type de compte
- `getDurationLabel(String duration)` : Libellé de durée en français

## Quotas gratuits par type de compte

| Type de compte | Quota gratuit | Description |
|----------------|---------------|-------------|
| **teacher_transfer** (Permutation) | 5 consultations | Consulter des profils pour permutation |
| **teacher_candidate** (Candidat) | 2 candidatures | Postuler à des offres d'emploi |
| **school** (École) | 1 offre | Publier une offre d'emploi |

## Tarifs d'abonnement

### Permutation (teacher_transfer)
- **1 mois** : 500 F CFA
- **3 mois** : 1 500 F CFA
- **12 mois** : 2 500 F CFA

### Candidats (teacher_candidate)
- **1 semaine** : 500 F CFA
- **1 mois** : 1 500 F CFA (au lieu de 2 000 F)
- **12 mois** : 20 000 F CFA (au lieu de 24 000 F)

### Écoles (school)
- **1 semaine** : 2 000 F CFA
- **1 mois** : 5 000 F CFA (au lieu de 8 000 F)
- **12 mois** : 90 000 F CFA (au lieu de 96 000 F)

## Widgets UI

### 1. SubscriptionStatusBanner

Affiche le statut de vérification et le temps restant avant expiration.

**Couleurs selon l'état** :
- 🔴 Rouge : Expiré
- 🟠 Orange : Expire dans ≤ 3 jours
- 🟡 Jaune : Expire dans ≤ 7 jours
- 🟢 Vert : Actif (> 7 jours)

### 2. QuotaStatusWidget

Affiche le quota gratuit restant avec une barre de progression.

**Caractéristiques** :
- Affichage du quota utilisé / total
- Barre de progression colorée
- Message informatif

### 3. WelcomeQuotaDialog

Dialogue de bienvenue affiché à la première connexion.

**Contenu** :
- Message de bienvenue personnalisé
- Présentation du quota gratuit
- Explication du système

### 4. SubscriptionRequiredDialog

Dialogue affiché lorsque le quota est épuisé.

**Contenu** :
- Message d'abonnement requis
- Tarifs disponibles
- Numéro de paiement (+225 0758747888)
- Bouton WhatsApp direct
- Non dismissible (ne se ferme que par le bouton)

## Panneau d'administration

### Calendrier de vérification

L'administrateur peut maintenant sélectionner une durée de vérification lors de l'approbation d'un utilisateur :

**Options disponibles** :
- 1 semaine
- 1 mois
- 3 mois
- 6 mois
- 12 mois

**Fonctionnement** :
1. Clic sur "Approuver" pour un utilisateur non vérifié
2. Sélection de la durée dans le dialogue
3. Activation automatique avec date d'expiration

## Flux utilisateur

### 1. Inscription

1. L'utilisateur crée un compte
2. Le compte est **automatiquement vérifié**
3. Le quota gratuit est initialisé selon le type de compte
4. `freeQuotaUsed = 0`
5. `freeQuotaLimit` = calculé automatiquement

### 2. Première connexion

1. Affichage du dialogue de bienvenue
2. Présentation du quota gratuit
3. Explication du système

### 3. Utilisation normale

1. À chaque action consommant du quota :
   - Appel de `incrementQuotaUsage()`
   - Vérification automatique du quota
   - Désactivation si quota épuisé

2. Affichage permanent :
   - Bannière de statut (si abonnement)
   - Widget de quota (si pas d'abonnement actif)

### 4. Quota épuisé

1. Désactivation automatique du compte
2. Affichage du dialogue d'abonnement
3. Blocage de l'accès aux fonctionnalités

### 5. Renouvellement

**Côté utilisateur** :
1. Paiement via WAVE ou MTN Money
2. Envoi de la preuve au +225 0758747888 via WhatsApp

**Côté administrateur** :
1. Réception de la preuve de paiement
2. Accès au panneau admin
3. Onglet "Vérifications"
4. Sélection de l'utilisateur
5. Clic sur "Approuver"
6. Choix de la durée
7. Activation automatique

### 6. Expiration

1. La date d'expiration est atteinte
2. Un job périodique (à implémenter) appelle `checkAndExpireAccounts()`
3. Le compte est désactivé automatiquement
4. L'utilisateur retourne dans la liste "non vérifiés"
5. Affichage du dialogue d'abonnement

## Intégration dans les écrans

Les widgets ont été intégrés dans les écrans principaux :

### HomeScreen (Permutation)
- `SearchPage` : Bannière de statut + Widget de quota

### CandidateHomeScreen
- `JobOffersListPage` : Bannière de statut + Widget de quota

### SchoolHomeScreen
- `MyJobOffersPage` : Bannière de statut + Widget de quota

## Paiement

**Mode de paiement accepté** :
- WAVE Money
- MTN Money (Mobile Money)

**Numéro de paiement** : +225 0758747888

**Processus** :
1. Utilisateur effectue le paiement
2. Envoie la capture d'écran via WhatsApp au même numéro
3. Administrateur vérifie et active l'abonnement

## Points d'attention

### Sécurité
- ✅ Les quotas sont gérés côté serveur (Firestore)
- ✅ Transactions atomiques pour l'incrémentation
- ✅ Vérifications multiples avant actions

### Performance
- ✅ Utilisation de `StreamBuilder` pour mises à jour temps réel
- ✅ Mise en cache automatique par Firebase
- ✅ Batch updates pour les expirations

### UX
- ✅ Messages clairs et personnalisés
- ✅ Couleurs informatives
- ✅ Bouton WhatsApp direct
- ✅ Copie du numéro en un clic

## Améliorations futures

1. **Automatisation des expirations**
   - Cloud Function déclenchée quotidiennement
   - Appel de `checkAndExpireAccounts()`

2. **Notifications push**
   - Alerte 3 jours avant expiration
   - Alerte le jour de l'expiration
   - Confirmation d'activation d'abonnement

3. **Intégration paiement automatique**
   - API MoneyFusion (déjà en place)
   - Validation automatique des paiements
   - Activation instantanée

4. **Historique des abonnements**
   - Collection `subscriptions` dans Firestore
   - Suivi des paiements
   - Factures automatiques

5. **Analytics**
   - Taux de conversion quota → abonnement
   - Durées d'abonnement préférées
   - Revenus par type de compte

## Fichiers modifiés

### Modèles
- ✅ `lib/models/user_model.dart`

### Services
- ✅ `lib/services/auth_service.dart`
- ✅ `lib/services/firestore_service.dart`
- ✨ **NOUVEAU** `lib/services/subscription_service.dart`

### Widgets
- ✨ **NOUVEAU** `lib/widgets/subscription_status_banner.dart`
- ✨ **NOUVEAU** `lib/widgets/quota_status_widget.dart`
- ✨ **NOUVEAU** `lib/widgets/welcome_quota_dialog.dart`
- ✨ **NOUVEAU** `lib/widgets/subscription_required_dialog.dart`

### Écrans
- ✅ `lib/admin_panel_page.dart`
- ✅ `lib/home_screen.dart`
- ✅ `lib/teacher_candidate/job_offers_list_page.dart`
- ✅ `lib/school/my_job_offers_page.dart`

### Documentation
- ✨ **NOUVEAU** `SUBSCRIPTION_SYSTEM_GUIDE.md`

## Support

Pour toute question ou problème :
- WhatsApp : +225 0758747888
- Le système affiche des messages clairs pour guider les utilisateurs

---

**Date de création** : 2025-01-01
**Version** : 1.0
**Statut** : ✅ Implémenté et testé
