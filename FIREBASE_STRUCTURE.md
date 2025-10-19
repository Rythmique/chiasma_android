# Structure Firebase & Firestore - CHIASMA

## Configuration Firebase

### Package Android
- **Application ID**: `chiasma.android`
- **Project ID**: `chiasma-android`
- **Fichier de configuration**: `android/app/google-services.json`

### Dépendances installées
- `firebase_core: ^3.8.1`
- `firebase_auth: ^5.3.4`
- `cloud_firestore: ^5.5.2`

---

## Structure des Collections Firestore

### 1. Collection `users`
Stocke les profils des utilisateurs fonctionnaires

**Document ID**: UID de l'utilisateur (Firebase Auth)

**Champs**:
```json
{
  "uid": "string",
  "email": "string",
  "matricule": "string (format: 123456A)",
  "nom": "string",
  "telephones": ["string", "string", "string"],  // Max 3
  "fonction": "string",
  "zoneActuelle": "string",
  "dren": "string | null (optionnel)",
  "infosZoneActuelle": "string (min 50 caractères)",
  "zonesSouhaitees": ["string", "string", ...],  // Max 5
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  "isOnline": "boolean",
  "isVerified": "boolean",
  "isAdmin": "boolean (défaut: false, accès panneau admin)"
}
```

**Index recommandés**:
- `matricule` (unique)
- `zoneActuelle` (pour recherche)
- `fonction` (pour recherche)
- `dren` (pour recherche)
- `zonesSouhaitees` (array-contains pour recherche)
- `isOnline`

---

### 2. Collection `favorites`
Gère les favoris entre utilisateurs

**Document ID**: `{userId}_{favoriteUserId}` (format composite)

**Champs**:
```json
{
  "userId": "string (UID de l'utilisateur qui ajoute)",
  "favoriteUserId": "string (UID de l'utilisateur favori)",
  "createdAt": "Timestamp"
}
```

**Index recommandés**:
- `userId` (pour récupérer tous les favoris d'un utilisateur)
- `favoriteUserId`

---

### 3. Collection `messages`
Gère les conversations entre utilisateurs

**Document ID**: `{user1Id}_{user2Id}` (IDs triés alphabétiquement pour unicité)

**Champs**:
```json
{
  "participants": ["userId1", "userId2"],
  "createdAt": "Timestamp",
  "lastMessage": "string | null",
  "lastMessageTime": "Timestamp | null"
}
```

**Sous-collection `messages`**:
Chaque conversation contient une sous-collection de messages

**Champs d'un message**:
```json
{
  "senderId": "string",
  "message": "string",
  "timestamp": "Timestamp",
  "read": "boolean"
}
```

**Index recommandés**:
- `participants` (array-contains)
- `lastMessageTime` (pour trier les conversations)
- Pour la sous-collection: `timestamp` (pour trier les messages)

---

## Règles de Sécurité Firestore Recommandées

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function pour vérifier si l'utilisateur est authentifié
    function isSignedIn() {
      return request.auth != null;
    }

    // Helper function pour vérifier si c'est le propriétaire
    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // Collection users
    match /users/{userId} {
      // Lecture: tout utilisateur authentifié peut lire les profils
      allow read: if isSignedIn();

      // Création: uniquement lors de l'inscription
      allow create: if isSignedIn()
                    && isOwner(userId)
                    && request.resource.data.matricule is string
                    && request.resource.data.matricule.matches('^[0-9]{6}[A-Z]$');

      // Mise à jour: uniquement son propre profil
      allow update: if isSignedIn()
                    && isOwner(userId)
                    && request.resource.data.matricule == resource.data.matricule; // Le matricule ne peut pas changer

      // Suppression: uniquement son propre profil
      allow delete: if isSignedIn() && isOwner(userId);
    }

    // Collection favorites
    match /favorites/{favoriteId} {
      // Lecture: l'utilisateur peut lire ses propres favoris
      allow read: if isSignedIn()
                  && request.auth.uid == resource.data.userId;

      // Création: l'utilisateur peut ajouter des favoris
      allow create: if isSignedIn()
                    && request.auth.uid == request.resource.data.userId;

      // Suppression: l'utilisateur peut retirer ses favoris
      allow delete: if isSignedIn()
                    && request.auth.uid == resource.data.userId;
    }

    // Collection messages
    match /messages/{conversationId} {
      // Lecture: uniquement les participants
      allow read: if isSignedIn()
                  && request.auth.uid in resource.data.participants;

      // Création: uniquement si l'utilisateur fait partie de la conversation
      allow create: if isSignedIn()
                    && request.auth.uid in request.resource.data.participants;

      // Mise à jour: uniquement les participants
      allow update: if isSignedIn()
                    && request.auth.uid in resource.data.participants;

      // Sous-collection messages
      match /messages/{messageId} {
        // Lecture: uniquement les participants de la conversation
        allow read: if isSignedIn()
                    && request.auth.uid in get(/databases/$(database)/documents/messages/$(conversationId)).data.participants;

        // Création: uniquement les participants
        allow create: if isSignedIn()
                      && request.auth.uid in get(/databases/$(database)/documents/messages/$(conversationId)).data.participants
                      && request.auth.uid == request.resource.data.senderId;
      }
    }
  }
}
```

---

## Fonctionnalités Implémentées

### Authentification
✅ Inscription avec email + mot de passe + matricule
✅ Connexion avec email + mot de passe + matricule (triple vérification)
✅ Vérification de l'unicité du matricule
✅ Email de vérification automatique
✅ Réinitialisation de mot de passe
✅ Déconnexion avec mise à jour du statut
✅ Suppression de compte

### Gestion des Utilisateurs
✅ Création de profil complet dans Firestore
✅ Mise à jour du statut en ligne/hors ligne
✅ Stockage de toutes les données du formulaire d'inscription

### Recherche
✅ Recherche par zone actuelle
✅ Recherche par zone souhaitée
✅ Recherche par fonction
✅ Recherche par DREN
✅ Recherche de match mutuel (correspondance bidirectionnelle)
✅ Récupération de tous les utilisateurs

### Favoris
✅ Ajouter aux favoris
✅ Retirer des favoris
✅ Récupérer la liste des favoris
✅ Vérifier si un profil est en favori

### Messagerie
✅ Créer une conversation
✅ Envoyer des messages
✅ Récupérer les messages d'une conversation
✅ Lister toutes les conversations d'un utilisateur

---

## Prochaines Étapes Recommandées

### 1. Configuration Firebase Console
- [ ] Activer l'authentification Email/Password dans Firebase Console
- [ ] Créer les index Firestore composites nécessaires
- [ ] Configurer les règles de sécurité Firestore
- [ ] Activer la vérification d'email
- [ ] Configurer le domaine autorisé pour la vérification d'email

### 2. Fonctionnalités Additionnelles
- [ ] Gestion des notifications push
- [ ] Upload de photos de profil (Firebase Storage)
- [ ] Système de notation/avis
- [ ] Historique des permutations
- [ ] Filtres avancés de recherche
- [ ] Export des données utilisateur (RGPD)

### 3. Optimisations
- [ ] Mise en cache locale (offline persistence)
- [ ] Pagination des résultats de recherche
- [ ] Indexation Algolia pour recherche full-text
- [ ] Analytics Firebase pour suivi d'utilisation
- [ ] Performance monitoring
- [ ] Crashlytics pour suivi des erreurs

### 4. Tests
- [ ] Tests unitaires des services Firebase
- [ ] Tests d'intégration de l'authentification
- [ ] Tests de sécurité Firestore
- [ ] Tests de performance

---

## Notes Importantes

### Sécurité
- Le matricule est utilisé comme identifiant secondaire unique
- Vérification triple lors de la connexion (email + mot de passe + matricule)
- Les données sensibles ne sont pas exposées publiquement
- Le matricule ne peut pas être modifié après l'inscription

### Performance
- Les requêtes utilisent des index pour optimiser les performances
- La recherche de match mutuel peut être optimisée avec Cloud Functions
- Considérer l'utilisation de Cloud Functions pour les opérations complexes

### Coûts
- Firestore facture par lecture/écriture/suppression
- Optimiser les requêtes pour réduire les coûts
- Utiliser la mise en cache côté client
- Limiter le nombre de documents récupérés avec pagination

---

## Support

Pour toute question sur la configuration Firebase ou Firestore, consultez:
- [Documentation Firebase](https://firebase.google.com/docs)
- [Documentation Firestore](https://firebase.google.com/docs/firestore)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
