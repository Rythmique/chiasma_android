# Migration : Quota enseignants 3 → 5 consultations

**Date** : 10 novembre 2025
**Type de migration** : Mise à jour du quota gratuit pour les enseignants (permutation)
**Statut** : ✅ **TERMINÉE AVEC SUCCÈS**

---

## 📊 Résumé de la migration

### Avant la migration
- **31 enseignants** dans la base de données
- **2 utilisateurs** avec quota = 3 (ancien quota)
- **29 utilisateurs** avec quota = 5 (déjà à jour)

### Après la migration
- **31 enseignants** dans la base de données
- **0 utilisateurs** avec quota = 3 ✅
- **31 utilisateurs** avec quota = 5 ✅

---

## ✅ Résultat

**Migration réussie !** Tous les enseignants ont maintenant **5 consultations gratuites**.

### Utilisateurs mis à jour
1. **Enseignant1** (enseignant1@gmail.com) : 3 → 5
2. **Emmanuel N'da** (ndandriemmanuel@gmail.com) : 3 → 5

---

## 🛠️ Modifications effectuées

### 1. Code (déjà configuré)

**Fichier** : [lib/models/user_model.dart](lib/models/user_model.dart:57-68)

```dart
static int _getDefaultQuotaLimit(String accountType) {
  switch (accountType) {
    case 'teacher_transfer':
      return 5;  // 5 consultations gratuites ✅
    case 'teacher_candidate':
      return 2;  // 2 candidatures gratuites
    case 'school':
      return 1;  // 1 offre d'emploi gratuite
    default:
      return 0;
  }
}
```

**Effet** : Les **nouveaux utilisateurs** créés auront automatiquement **5 consultations gratuites**.

### 2. Base de données (mise à jour)

**Script** : [scripts/update_teacher_quota_to_5.js](scripts/update_teacher_quota_to_5.js)

**Commande exécutée** :
```bash
cd /home/user/myapp/scripts
node update_teacher_quota_to_5.js
```

**Effet** : Les **utilisateurs existants** ont été mis à jour de 3 à 5 consultations.

---

## 📱 Impact utilisateur

### Avant
Les enseignants voyaient dans leur app :
```
Quota gratuit
3 / 3  (ou 2 / 3, 1 / 3, 0 / 3)
```

### Après
Les enseignants voient maintenant dans leur app :
```
Quota gratuit
5 / 5  (ou 4 / 5, 3 / 5, etc.)
```

**Note** : Si un enseignant avait déjà utilisé 3 consultations sur 3, il aura maintenant 3 utilisées sur 5, donc **2 consultations supplémentaires disponibles** ! ✅

---

## 🎯 Cas d'usage

### Cas 1 : Enseignant qui avait épuisé son quota (3/3)
**Avant** :
- `freeQuotaUsed: 3`
- `freeQuotaLimit: 3`
- Quota épuisé → Message "Prenez un abonnement"

**Après** :
- `freeQuotaUsed: 3` (inchangé)
- `freeQuotaLimit: 5` ✅
- **2 consultations disponibles** → Peut continuer à consulter des profils ! ✅

### Cas 2 : Enseignant qui avait utilisé 1 consultation (1/3)
**Avant** :
- `freeQuotaUsed: 1`
- `freeQuotaLimit: 3`
- 2 consultations restantes

**Après** :
- `freeQuotaUsed: 1` (inchangé)
- `freeQuotaLimit: 5` ✅
- **4 consultations restantes** → Bonus de +2 consultations ! ✅

### Cas 3 : Nouvel enseignant (inscription après migration)
**Avant** : N/A

**Après** :
- `freeQuotaUsed: 0`
- `freeQuotaLimit: 5` ✅
- **5 consultations gratuites** dès l'inscription ! ✅

---

## 🔍 Vérification

### Comment vérifier que la migration a fonctionné ?

#### Option 1 : Via l'app mobile
1. Se connecter avec un compte enseignant
2. Regarder la barre de quota sur l'écran d'accueil
3. Vérifier que le quota affiche `X / 5` (au lieu de `X / 3`)

#### Option 2 : Via Firebase Console
1. Aller sur Firebase Console → Firestore
2. Collection `users`
3. Filtrer par `accountType == teacher_transfer`
4. Vérifier que tous ont `freeQuotaLimit: 5`

#### Option 3 : Réexécuter le script
```bash
cd /home/user/myapp/scripts
node update_teacher_quota_to_5.js
```

Si tout est correct, le script devrait afficher :
```
✅ Tous les enseignants ont déjà le quota de 5.
✅ Aucune mise à jour nécessaire.
```

---

## 📝 Logs de la migration

```
🚀 Démarrage de la migration : Quota enseignants 3 → 5
================================================

📊 Récupération des enseignants...
✅ 31 enseignant(s) trouvé(s)

📈 Analyse des quotas actuels :
   - Quota = 3 : 2 utilisateur(s) → À METTRE À JOUR
   - Quota = 5 : 29 utilisateur(s) → Déjà correct
   - Autre     : 0 utilisateur(s) → À vérifier

🔄 Mise à jour en cours...

   ✓ Enseignant1 (enseignant1@gmail.com) : 3 → 5
   ✓ Emmanuel N'da (ndandriemmanuel@gmail.com) : 3 → 5

✅ Batch commit réussi : 2 utilisateur(s) mis à jour

================================================
📊 RÉSUMÉ DE LA MIGRATION
================================================
Total d'enseignants      : 31
Mis à jour (3 → 5)       : 2
Déjà à jour (quota = 5)  : 29
Non modifiés (autre)     : 0
================================================

🔍 Vérification post-migration...
   - Quota = 3 : 0 utilisateur(s)
   - Quota = 5 : 31 utilisateur(s)

✅ Migration réussie ! Tous les enseignants ont maintenant 5 consultations gratuites.

✅ Script terminé avec succès
```

---

## ⚠️ Points d'attention

### Quota utilisé non réinitialisé
Le champ `freeQuotaUsed` **n'a PAS été réinitialisé** par cette migration. C'est intentionnel.

**Exemple** :
- Enseignant avec 3 consultations utilisées sur 3
- Après migration : 3 consultations utilisées sur 5
- **Résultat** : L'enseignant a 2 nouvelles consultations disponibles

### Futurs enseignants
Les nouveaux enseignants qui s'inscrivent après cette migration auront automatiquement **5 consultations gratuites** grâce au code dans [user_model.dart](lib/models/user_model.dart:60).

Aucune action supplémentaire n'est nécessaire.

---

## 🎉 Conclusion

✅ **Migration terminée avec succès**
✅ **31 enseignants** ont maintenant **5 consultations gratuites**
✅ **2 utilisateurs** ont été mis à jour (3 → 5)
✅ **Nouveaux utilisateurs** auront automatiquement 5 consultations
✅ **Aucun impact négatif** sur les utilisateurs existants

**Date de migration** : 10 novembre 2025
**Par** : Claude Code
**Statut** : ✅ Production ready
