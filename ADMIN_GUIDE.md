# Guide Administrateur - CHIASMA

## Vue d'ensemble

Le système d'administration permet aux utilisateurs ayant le statut **admin** de gérer la plateforme CHIASMA, notamment :
- Vérifier les profils des nouveaux utilisateurs
- Gérer les utilisateurs (promouvoir/rétrograder les admins)
- Consulter les statistiques de la plateforme

---

## Accès au panneau d'administration

### Visibilité
Le panneau d'administration n'est visible **QUE** pour les utilisateurs dont le champ `isAdmin = true` dans Firestore.

### Comment y accéder ?
1. Ouvrir l'application
2. Aller dans **Profil** (onglet du bas)
3. Cliquer sur **Paramètres** (icône en haut à droite)
4. **Si vous êtes admin**, une nouvelle section **"Administration"** apparaît en haut de la page
5. Cliquer sur **"Panneau d'administration"**

---

## Création du premier administrateur

### Méthode 1 : Via Firebase Console (Recommandé)

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner votre projet **"chiasma-android"**
3. Aller dans **Firestore Database**
4. Naviguer vers **Collections** > **users**
5. Trouver votre document utilisateur (par UID)
6. Cliquer sur **Modifier**
7. Ajouter le champ :
   - **Nom du champ** : `isAdmin`
   - **Type** : boolean
   - **Valeur** : `true`
8. Enregistrer

### Méthode 2 : Via code (pour développement)

Modifier temporairement le fichier `lib/services/auth_service.dart` lors de la création de votre compte :

```dart
UserModel newUser = UserModel(
  // ... autres champs
  isAdmin: true,  // ⚠️ Changez ceci temporairement pour VOTRE compte uniquement
);
```

**IMPORTANT** : Remettez `isAdmin: false` après avoir créé votre compte admin !

---

## Fonctionnalités du panneau admin

### 1. Onglet "Vérifications"

**Objectif** : Approuver ou rejeter les nouveaux utilisateurs en attente de vérification.

**Fonctionnalités** :
- Liste de tous les utilisateurs avec `isVerified = false`
- Affichage des informations complètes (matricule, email, téléphone, zone, DREN)
- **Bouton "Approuver"** : Change `isVerified` à `true`
- **Bouton "Rejeter"** : Pour l'instant affiche juste un message (à personnaliser)

**Utilisation** :
1. Vérifier manuellement les informations de l'utilisateur
2. Vérifier la validité du matricule (format : 123456A)
3. Cliquer sur "Approuver" si tout est correct
4. L'utilisateur verra immédiatement son badge changer en "Profil vérifié"

### 2. Onglet "Utilisateurs"

**Objectif** : Gérer tous les utilisateurs de la plateforme.

**Fonctionnalités** :
- Liste complète de tous les utilisateurs
- Badges visuels : "Vérifié" (vert) et "Admin" (violet)
- Menu d'actions (⋮) pour chaque utilisateur :
  - **Vérifier / Retirer vérification** : Basculer le statut `isVerified`
  - **Promouvoir admin / Retirer admin** : Basculer le statut `isAdmin`

**Utilisation** :
1. Trouver l'utilisateur dans la liste
2. Cliquer sur les 3 points verticaux (⋮)
3. Choisir l'action appropriée

**⚠️ ATTENTION** :
- Ne vous retirez pas vous-même le statut admin par erreur
- Soyez prudent en promouvant d'autres admins

### 3. Onglet "Statistiques"

**Objectif** : Vue d'ensemble de la plateforme.

**Métriques affichées** :
- **Total utilisateurs** : Nombre total d'inscrits
- **Utilisateurs vérifiés** : Nombre de comptes validés
- **En attente de vérification** : Nombre de comptes à vérifier
- **Administrateurs** : Nombre total d'admins
- **Utilisateurs en ligne** : Nombre d'utilisateurs actuellement connectés

**Utilisation** :
- Consultation en lecture seule
- Mise à jour en temps réel (StreamBuilder)

---

## Structure Firestore

### Champ `isAdmin`

**Type** : `boolean`
**Valeur par défaut** : `false`
**Localisation** : Collection `users`, document `{uid}`

**Exemple de document** :
```json
{
  "uid": "abc123...",
  "email": "admin@education.ci",
  "matricule": "123456A",
  "nom": "Admin Principal",
  "isVerified": true,
  "isAdmin": true,  // ← Donne accès au panneau admin
  // ... autres champs
}
```

---

## Sécurité

### Règles Firestore recommandées

Pour protéger le champ `isAdmin`, ajoutez ces règles dans Firebase Console :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Lecture : tout le monde (pour voir les profils)
      allow read: if request.auth != null;

      // Création : uniquement lors de l'inscription
      allow create: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.data.isAdmin == false;  // ⚠️ Impossible de se créer admin

      // Mise à jour : utilisateur peut modifier son profil SAUF isAdmin
      allow update: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.data.isAdmin == resource.data.isAdmin;  // ⚠️ Ne peut pas changer isAdmin

      // Seuls les admins peuvent modifier isAdmin et isVerified d'autres utilisateurs
      // (Nécessite Cloud Functions pour être vraiment sécurisé)
    }
  }
}
```

**⚠️ NOTE IMPORTANTE** :
Pour une sécurité maximale, utilisez **Cloud Functions** pour gérer les changements de statut admin. Le code actuel permet techniquement à tout admin de modifier ces champs.

---

## Workflow de vérification

### Processus recommandé

1. **Nouvel utilisateur s'inscrit**
   - Son compte est créé avec `isVerified = false`
   - Il voit "En attente de vérification" sur son profil

2. **Admin reçoit notification** (à implémenter)
   - Le nombre d'utilisateurs en attente apparaît dans les statistiques
   - L'admin se rend dans l'onglet "Vérifications"

3. **Admin vérifie les informations**
   - Matricule au bon format
   - Email professionnel (@education.ci recommandé)
   - Informations cohérentes

4. **Admin approuve ou rejette**
   - **Si approuvé** : `isVerified = true`, l'utilisateur peut accéder à toutes les fonctionnalités
   - **Si rejeté** : Message à l'utilisateur (à personnaliser selon vos besoins)

5. **Utilisateur vérifié**
   - Badge "Profil vérifié" ✅
   - Accès complet à la messagerie, recherche, etc.

---

## Extensions futures possibles

### Notifications push
- Notifier les admins quand un nouvel utilisateur s'inscrit
- Notifier l'utilisateur quand son compte est vérifié

### Upload de documents
- Permettre aux utilisateurs d'uploader une carte professionnelle
- Admin peut consulter les documents avant d'approuver

### Logs d'actions admin
- Enregistrer qui a vérifié quel utilisateur et quand
- Historique des modifications de statut

### Dashboard avancé
- Graphiques d'évolution des inscriptions
- Statistiques par DREN, par zone, etc.
- Suivi des permutations réussies

### Système de modération
- Signalement d'utilisateurs
- Suspension/bannissement de comptes
- Messages de modération

---

## FAQ

### Q : Comment savoir qui est admin ?
**R** : Dans l'onglet "Utilisateurs" du panneau admin, les admins ont un badge violet "Admin".

### Q : Combien d'admins peut-il y avoir ?
**R** : Illimité. Vous pouvez promouvoir autant d'utilisateurs que nécessaire.

### Q : Peut-on retirer le statut admin à quelqu'un ?
**R** : Oui, via l'onglet "Utilisateurs", menu (⋮) > "Retirer admin".

### Q : Que se passe-t-il si je me retire le statut admin ?
**R** : Vous perdrez immédiatement l'accès au panneau admin. Assurez-vous qu'il y a au moins un autre admin avant de faire cela !

### Q : Les utilisateurs non vérifiés peuvent-ils utiliser l'app ?
**R** : Oui, mais vous pouvez restreindre certaines fonctionnalités (messagerie, etc.) selon vos besoins. Actuellement, ils ont accès à tout mais avec un badge "En attente".

### Q : Comment un utilisateur sait s'il est vérifié ?
**R** : Sur son profil, il voit soit "Profil vérifié ✅" soit "En attente de vérification ⏳".

---

## Support

Pour toute question sur le panneau admin, consultez :
- [FIREBASE_STRUCTURE.md](FIREBASE_STRUCTURE.md) - Structure complète de la base de données
- [CLAUDE.md](CLAUDE.md) - Guide de développement général
- Firebase Console - Pour gérer manuellement la base de données
