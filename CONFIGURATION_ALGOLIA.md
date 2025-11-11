# 🔍 Configuration Algolia - Guide Complet

## ✅ Migration effectuée vers l'API moderne

Le code a été migré de `functions.config()` (déprécié) vers `defineString()` (moderne et durable).

---

## 🚀 Configuration en 3 étapes

### Étape 1: Récupérer vos identifiants Algolia

1. Allez sur [Algolia Dashboard](https://www.algolia.com/dashboard)
2. Connectez-vous à votre compte
3. Cliquez sur **Settings** → **API Keys**
4. Notez:
   - **Application ID** (ex: `ABC123XYZ`)
   - **Admin API Key** (ex: `abc123...`)

⚠️ **Important:** L'Admin API Key est sensible, ne la partagez jamais!

---

### Étape 2: Choisir votre méthode de configuration

#### 🥇 **Option A: Firebase Secrets (Recommandé - Plus sécurisé)**

```bash
cd /home/user/myapp

# Configurer l'App ID
firebase functions:secrets:set ALGOLIA_APP_ID
# Collez votre Application ID quand demandé

# Configurer l'Admin Key
firebase functions:secrets:set ALGOLIA_ADMIN_KEY
# Collez votre Admin API Key quand demandé
```

**Avantages:**
- ✅ Clés chiffrées dans Google Cloud Secret Manager
- ✅ Jamais exposées dans le code
- ✅ Rotation facile des clés
- ✅ Gratuit dans le plan Blaze de Firebase

---

#### 🥈 **Option B: Variables d'environnement Firebase (Simple)**

```bash
cd /home/user/myapp

firebase functions:config:set \
  algolia.app_id="VOTRE_APP_ID" \
  algolia.admin_key="VOTRE_ADMIN_KEY"
```

**Avantages:**
- ✅ Simple à configurer
- ✅ Compatible avec l'ancien et le nouveau code

---

#### 🥉 **Option C: Fichier .env (Développement local uniquement)**

```bash
cd /home/user/myapp/functions

# Créer le fichier .env
cat > .env << EOF
ALGOLIA_APP_ID=VOTRE_APP_ID
ALGOLIA_ADMIN_KEY=VOTRE_ADMIN_KEY
EOF
```

⚠️ **Attention:** Le fichier `.env` est déjà dans `.gitignore` pour éviter de le commiter!

---

### Étape 3: Déployer les fonctions

```bash
cd /home/user/myapp

# Build
cd functions
npm run build

# Deploy
cd ..
firebase deploy --only functions
```

---

## 🧪 Vérifier que ça fonctionne

### Test 1: Vérifier les logs

```bash
firebase functions:log --only syncUserToAlgolia
```

**Sortie attendue (pas d'erreur Algolia):**
```
✅ Utilisateur synchronisé avec Algolia
```

### Test 2: Créer un utilisateur

1. Inscrivez un nouvel utilisateur dans l'app
2. Vérifiez dans [Algolia Dashboard](https://www.algolia.com/dashboard) → **Indices** → `users`
3. Vous devriez voir le nouvel utilisateur

### Test 3: Créer une offre d'emploi

1. École crée une nouvelle offre
2. Vérifiez dans Algolia → **Indices** → `job_offers`
3. L'offre devrait apparaître

---

## 📊 Indices Algolia utilisés

Votre app utilise 2 indices:

1. **`users`** - Index des utilisateurs (enseignants/candidats)
   - Synchronisé automatiquement via `syncUserToAlgolia`

2. **`job_offers`** - Index des offres d'emploi
   - Synchronisé automatiquement via `syncJobOfferToAlgolia`

---

## 🔧 Fonctions Algolia disponibles

### Fonctions de synchronisation automatique

✅ **`syncUserToAlgolia`**
- Déclenché quand un utilisateur est créé/modifié/supprimé
- Synchronise automatiquement avec l'index Algolia `users`

✅ **`syncJobOfferToAlgolia`**
- Déclenché quand une offre est créée/modifiée/supprimée
- Synchronise automatiquement avec l'index Algolia `job_offers`

### Fonctions de réindexation manuelle

✅ **`reindexAllUsers`** (Callable)
- Réindexe tous les utilisateurs existants
- Utile après une migration ou corruption d'index

✅ **`reindexAllJobOffers`** (Callable)
- Réindexe toutes les offres d'emploi
- Utile après une migration ou corruption d'index

---

## 🔄 Migration depuis functions.config()

### Si vous aviez l'ancienne configuration

```bash
# Récupérer les anciennes valeurs
firebase functions:config:get

# Exemple de sortie:
# {
#   "algolia": {
#     "app_id": "ABC123XYZ",
#     "admin_key": "abc123..."
#   }
# }
```

**Migrer vers Firebase Secrets:**

```bash
# Utiliser les valeurs récupérées ci-dessus
firebase functions:secrets:set ALGOLIA_APP_ID
# Coller: ABC123XYZ

firebase functions:secrets:set ALGOLIA_ADMIN_KEY
# Coller: abc123...
```

**Optionnel: Supprimer l'ancienne config**

```bash
firebase functions:config:unset algolia
```

---

## 🚨 Dépannage

### Problème: "Algolia credentials are required"

**Solution:** Les variables ne sont pas configurées.

```bash
# Vérifier la configuration actuelle
firebase functions:config:get

# Si vide, configurez avec l'Option A ou B ci-dessus
```

### Problème: Index vide dans Algolia

**Solution:** Réindexer manuellement

```bash
# Via Firebase Console → Functions → Tester la fonction
# Ou via Cloud Shell
firebase functions:call reindexAllUsers
firebase functions:call reindexAllJobOffers
```

### Problème: "Invalid credentials"

**Solution:** Vérifiez que vous avez utilisé la bonne clé

- ✅ Utilisez **Admin API Key** (pas Search-Only Key)
- ✅ Vérifiez qu'il n'y a pas d'espace avant/après la clé

---

## 💰 Coûts Algolia

**Plan gratuit Algolia:**
- ✅ 10,000 recherches/mois
- ✅ 10,000 enregistrements

**Pour Chiasma:**
- ~1000 utilisateurs
- ~500 offres d'emploi
- = **Largement dans le plan gratuit!** ✅

---

## 📝 Commandes utiles

```bash
# Voir la config actuelle
firebase functions:config:get

# Lister les secrets
firebase functions:secrets:list

# Voir les logs Algolia
firebase functions:log --only syncUserToAlgolia,syncJobOfferToAlgolia

# Réindexer (si besoin)
firebase functions:call reindexAllUsers
firebase functions:call reindexAllJobOffers
```

---

## ✅ Checklist de configuration

- [ ] Identifiants Algolia récupérés (App ID + Admin Key)
- [ ] Variables configurées (Option A, B ou C)
- [ ] Functions compilées (`npm run build`)
- [ ] Functions déployées (`firebase deploy --only functions`)
- [ ] Logs vérifiés (pas d'erreur Algolia)
- [ ] Test création utilisateur → visible dans Algolia
- [ ] Test création offre → visible dans Algolia

---

## 🎉 Une fois configuré

✅ Recherche instantanée dans l'app
✅ Synchronisation automatique Firestore → Algolia
✅ Pas de warning de dépréciation
✅ Code compatible 2026+

**C'est prêt!** 🚀
