# Guide des Règles de Sécurité Firestore - CHIASMA

**Date de mise à jour:** 19 Octobre 2025
**Version:** 2.0.0
**Projet Firebase:** chiasma-android

---

## 📋 Vue d'Ensemble

Ce document détaille toutes les règles de sécurité Firestore de l'application CHIASMA, qui permet la gestion des permutations d'enseignants et le recrutement par les écoles.

### Types de Comptes

L'application supporte **3 types de comptes** définis par le champ `accountType` :

1. **`teacher_transfer`** - Enseignants cherchant une permutation
2. **`teacher_candidate`** - Enseignants candidats à un emploi
3. **`school`** - Établissements scolaires

### Rôles Spéciaux

- **`isAdmin: true`** - Administrateurs avec accès complet

---

## 🗂️ Collections Firestore

### 1. Collection `users`

**Description:** Profils de tous les utilisateurs (enseignants et écoles)

**Structure:**
```javascript
{
  uid: string,
  email: string,
  accountType: 'teacher_transfer' | 'teacher_candidate' | 'school',
  matricule: string,  // Format: 6 chiffres + 1 lettre (ex: 123456A)
  nom: string,
  telephones: string[],  // Max 3
  fonction: string,
  zoneActuelle: string,
  dren: string | null,
  infosZoneActuelle: string,
  zonesSouhaitees: string[],  // Max 5
  createdAt: Timestamp,
  updatedAt: Timestamp,
  isOnline: boolean,
  isVerified: boolean,
  isAdmin: boolean,
  profileViewsCount: number,
  freeViewsRemaining: number,
  hasActiveSubscription: boolean,
  subscriptionEndDate: Timestamp | null
}
```

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | Tous les utilisateurs authentifiés | Permet la recherche et consultation de profils |
| **Création** | L'utilisateur créant son propre profil | • UID doit correspondre<br>• Matricule valide (6 chiffres + 1 lettre)<br>• accountType valide<br>• Email correspond à l'auth |
| **Mise à jour** | Propriétaire ou Admin | • Propriétaire ne peut pas modifier : matricule, uid, email, accountType, isAdmin<br>• Admin peut tout modifier |
| **Suppression** | Admin uniquement | Protection contre suppression accidentelle |

---

### 2. Collection `subscriptions`

**Description:** Abonnements des enseignants (gérés par Cloud Functions après paiement)

**Structure:**
```javascript
{
  userId: string,
  type: 'monthly' | 'quarterly' | 'yearly',
  amount: number,
  status: 'pending' | 'active' | 'expired' | 'cancelled',
  startDate: Timestamp,
  endDate: Timestamp,
  paymentMethod: string,
  transactionId: string,
  createdAt: Timestamp
}
```

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | Propriétaire ou Admin | userId correspond à l'utilisateur |
| **Écriture** | Cloud Functions uniquement | Créé après vérification du paiement |

**Tarifs Enseignants:**
- Mensuel: 500 FCFA
- Trimestriel: 1,500 FCFA
- Annuel: 5,000 FCFA

---

### 3. Collection `school_subscriptions`

**Description:** Abonnements spécifiques des écoles

**Structure:**
```javascript
{
  userId: string,
  transactionId: string,
  duration: 'week' | 'month',
  amount: number,  // 5000 ou 15000 FCFA
  paymentMethod: string,
  status: 'pending' | 'active' | 'expired' | 'cancelled',
  createdAt: Timestamp,
  startDate: Timestamp | null,
  endDate: Timestamp
}
```

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | École propriétaire ou Admin | userId correspond |
| **Création** | Écoles uniquement | accountType == 'school' |
| **Mise à jour** | Cloud Functions uniquement | Confirmation de paiement |
| **Suppression** | Admin uniquement | - |

**Tarifs Écoles:**
- 1 semaine: 5,000 FCFA
- 1 mois: 15,000 FCFA

---

### 4. Collection `payment_transactions`

**Description:** Historique des transactions de paiement MoneyFusion

**Structure:**
```javascript
{
  userId: string,
  transactionId: string,
  amount: number,
  currency: 'XOF',
  paymentMethod: string,
  status: 'pending' | 'completed' | 'failed',
  createdAt: Timestamp,
  completedAt: Timestamp | null
}
```

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | Propriétaire ou Admin | - |
| **Écriture** | Cloud Functions uniquement | Sécurité des paiements |

---

### 5. Collection `app_config`

**Description:** Configuration globale de l'application (quotas, tarifs, paramètres)

**Documents:**
- `subscription_config` - Configuration des abonnements
- `payment_config` - Configuration MoneyFusion
- `free_views_quota` - Quota de consultations gratuites

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | Tous les utilisateurs authentifiés | - |
| **Écriture** | Admin uniquement | - |

---

### 6. Collection `favorites`

**Description:** Favoris entre utilisateurs (enseignants uniquement)

**Structure:**
```javascript
{
  userId: string,           // Celui qui ajoute
  favoriteUserId: string,   // Celui qui est favori
  createdAt: Timestamp
}
```

**ID du document:** `{userId}_{favoriteUserId}`

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | Propriétaire ou Admin | userId correspond |
| **Création** | Utilisateur authentifié | userId correspond |
| **Mise à jour/Suppression** | Propriétaire ou Admin | - |

---

### 7. Collection `messages` (+ sous-collection)

**Description:** Conversations 1-à-1 entre utilisateurs

**Structure principale:**
```javascript
{
  participants: [string, string],  // 2 UIDs
  createdAt: Timestamp,
  lastMessage: string | null,
  lastMessageTime: Timestamp | null
}
```

**ID du document:** `{user1Id}_{user2Id}` (IDs triés alphabétiquement)

**Sous-collection `messages`:**
```javascript
{
  senderId: string,
  message: string,
  timestamp: Timestamp,
  read: boolean
}
```

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture (conversation)** | Participants ou Admin | UID dans participants |
| **Création (conversation)** | Utilisateur authentifié | • Dans participants<br>• Exactement 2 participants |
| **Mise à jour (conversation)** | Participants | lastMessage, lastMessageTime |
| **Suppression (conversation)** | Admin uniquement | - |
| **Lecture (messages)** | Participants | - |
| **Création (messages)** | Participants | senderId == auth.uid |
| **Mise à jour (messages)** | Participants | Pour marquer comme lu |
| **Suppression (messages)** | Admin uniquement | - |

---

### 8. Collection `job_applications`

**Description:** Candidatures spontanées des enseignants (visibles aux écoles avec abonnement)

**Structure:**
```javascript
{
  userId: string,
  nom: string,
  email: string,
  telephones: string[],
  experience: string,
  matieres: string[],
  niveaux: string[],
  diplomes: string[],
  zones: string[],
  disponibilite: string,
  status: 'active' | 'inactive' | 'archived',
  viewsCount: number,       // Nombre de consultations par écoles
  contactsCount: number,    // Nombre de fois contacté
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | • Propriétaire<br>• Écoles (si active)<br>• Admin | Les écoles voient uniquement les candidatures actives |
| **Création** | Enseignants uniquement | • isTeacher()<br>• status == 'active' |
| **Mise à jour** | Propriétaire ou Admin | - |
| **Suppression** | Propriétaire ou Admin | - |

---

### 9. Collection `job_offers`

**Description:** Offres d'emploi publiées par les écoles

**Structure:**
```javascript
{
  schoolId: string,
  schoolName: string,
  position: string,
  matieres: string[],
  niveaux: string[],
  typeContrat: string,
  description: string,
  requirements: string[],
  salary: string | null,
  location: string,
  status: 'open' | 'active' | 'closed' | 'filled',
  viewsCount: number,
  applicationsCount: number,
  createdAt: Timestamp,
  updatedAt: Timestamp,
  expiresAt: Timestamp | null
}
```

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | • Enseignants (si open/active)<br>• École propriétaire<br>• Admin | Les enseignants voient uniquement offres ouvertes |
| **Création** | Écoles uniquement | isSchool() |
| **Mise à jour** | École propriétaire ou Admin | - |
| **Suppression** | École propriétaire ou Admin | - |

---

### 10. Collection `offer_applications`

**Description:** Candidatures aux offres d'emploi spécifiques

**Structure:**
```javascript
{
  offerId: string,
  userId: string,
  coverLetter: string,
  availability: string,
  status: 'pending' | 'reviewed' | 'accepted' | 'rejected',
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | • Candidat<br>• École de l'offre<br>• Admin | - |
| **Création** | Enseignants uniquement | isTeacher() |
| **Mise à jour** | • Candidat (sa candidature)<br>• École (statut)<br>• Admin | - |
| **Suppression** | Candidat ou Admin | - |

---

### 11. Collection `announcements`

**Description:** Annonces système affichées dans l'application

**Structure:**
```javascript
{
  title: string,
  message: string,
  type: 'info' | 'warning' | 'success' | 'error',
  targetAccounts: string[],  // ['teacher_transfer', 'teacher_candidate', 'school', 'all']
  priority: number,          // 1-5 (5 = haute priorité)
  isActive: boolean,
  startDate: Timestamp,
  endDate: Timestamp | null,
  createdBy: string,
  createdAt: Timestamp
}
```

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | Tous les utilisateurs authentifiés | - |
| **Création/Mise à jour/Suppression** | Admin uniquement | - |

---

### 12. Collection `notifications`

**Description:** Notifications personnelles des utilisateurs

**Structure:**
```javascript
{
  userId: string,
  type: 'message' | 'match' | 'favorite' | 'application' | 'offer' | 'system',
  title: string,
  message: string,
  createdAt: Timestamp,
  isRead: boolean,
  data: {  // Données supplémentaires selon le type
    profileId?: string,
    contactId?: string,
    contactName?: string,
    offerId?: string,
    // ...
  }
}
```

**Règles de sécurité:**
| Opération | Qui peut ? | Conditions |
|-----------|------------|------------|
| **Lecture** | Propriétaire ou Admin | userId correspond |
| **Création** | Tous les utilisateurs authentifiés | Pour notifier d'autres utilisateurs |
| **Mise à jour** | Propriétaire ou Admin | Marquer comme lu |
| **Suppression** | Propriétaire ou Admin | - |

---

## 🔐 Fonctions Helper

### `isSignedIn()`
Vérifie si l'utilisateur est authentifié via Firebase Auth.

### `isOwner(userId)`
Vérifie si l'utilisateur accède à ses propres données.

### `isAdmin()`
Vérifie si l'utilisateur a le flag `isAdmin: true` dans son document user.

### `getUserAccountType()`
Récupère le type de compte de l'utilisateur authentifié.

### `isTeacher()`
Vérifie si le compte est de type `teacher_transfer` ou `teacher_candidate`.

### `isSchool()`
Vérifie si le compte est de type `school`.

### `isValidMatricule(matricule)`
Valide le format du matricule : 6 chiffres + 1 lettre majuscule (ex: `123456A`).

---

## 📝 Règles d'Inscription

### Enseignants (teacher_transfer / teacher_candidate)

**Champs obligatoires:**
- ✅ Email (validé par Firebase Auth)
- ✅ Matricule (format: 6 chiffres + 1 lettre)
- ✅ Nom complet
- ✅ Téléphone(s) (1 à 3 numéros)
- ✅ Fonction
- ✅ Zone actuelle
- ✅ Informations zone actuelle (min 50 caractères)
- ✅ Zones souhaitées (1 à 5 zones)

**Champs optionnels:**
- DREN

**Validations:**
- Matricule unique dans la base de données
- Format matricule respecté
- Email unique (géré par Firebase Auth)

### Écoles (school)

**Champs obligatoires:**
- ✅ Email (validé par Firebase Auth)
- ✅ Matricule (format: 6 chiffres + 1 lettre)
- ✅ Nom de l'établissement
- ✅ Téléphone(s) (1 à 3 numéros)
- ✅ Zone/Localisation
- ✅ Type d'établissement

**Validations:**
- Matricule unique
- Email unique

---

## 🛡️ Sécurité et Bonnes Pratiques

### Protection des Données Personnelles

1. **Emails et téléphones masqués sans abonnement:**
   - Les écoles sans abonnement actif ne voient pas les contacts des candidats
   - Champ `hasActiveSubscription` vérifié côté client ET règles Firestore

2. **Matricule immuable:**
   - Le matricule ne peut jamais être modifié après la création du compte
   - Garantit l'intégrité des données

3. **Type de compte immuable:**
   - Le champ `accountType` ne peut pas être changé après l'inscription
   - Évite les escalades de privilèges

4. **Flag admin protégé:**
   - Seul un admin peut modifier le flag `isAdmin`
   - Les utilisateurs ne peuvent pas s'auto-promouvoir

### Validation des Paiements

- **Toutes les transactions passent par Cloud Functions**
- Les collections `subscriptions`, `school_subscriptions` et `payment_transactions` sont en lecture seule pour les clients
- Seules les Cloud Functions (avec droits admin) peuvent écrire

### Prévention des Abus

1. **Rate limiting via compteurs:**
   - `profileViewsCount` - Nombre de profils consultés
   - `freeViewsRemaining` - Consultations gratuites restantes
   - Incrémenté côté client, vérifié côté serveur

2. **Soft delete:**
   - Utilisation de status ('active', 'inactive', 'archived')
   - Permet la récupération et l'audit

3. **Règle par défaut:**
   ```javascript
   match /{document=**} {
     allow read, write: if false;
   }
   ```
   - Tout ce qui n'est pas explicitement autorisé est interdit

---

## 🚀 Déploiement des Règles

### Commande de déploiement:
```bash
firebase deploy --only firestore:rules --project chiasma-android
```

### Vérification avant déploiement:
```bash
# Valider la syntaxe
firebase deploy --only firestore:rules --dry-run

# Voir les différences
git diff firestore.rules
```

### Rollback en cas de problème:
```bash
# Restaurer la version précédente
git checkout HEAD~1 firestore.rules
firebase deploy --only firestore:rules --project chiasma-android
```

---

## ✅ Checklist de Validation

Avant de déployer en production, vérifiez:

- [ ] Tous les utilisateurs peuvent s'inscrire (teacher_transfer, teacher_candidate, school)
- [ ] Les matricules sont validés au format correct
- [ ] Les champs immuables (matricule, accountType, isAdmin) sont protégés
- [ ] Les enseignants peuvent créer des candidatures
- [ ] Les écoles peuvent créer des offres d'emploi
- [ ] Les écoles sans abonnement ne voient pas les contacts
- [ ] Les messages sont privés aux participants
- [ ] Les admins ont accès à tout
- [ ] Les paiements passent par Cloud Functions uniquement
- [ ] La règle par défaut refuse tout accès non explicite

---

## 📞 Support

Pour toute question sur les règles Firestore:
- Documentation: `FIREBASE_STRUCTURE.md`
- Guide Admin: `ADMIN_GUIDE.md`
- Règles: `firestore.rules`

**Note:** Les règles sont déployées mais les modifications nécessitent une authentification Firebase. En cas de problème, contactez l'administrateur du projet Firebase `chiasma-android`.
