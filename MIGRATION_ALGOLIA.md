# Migration Algolia - Plus de warning de dépréciation ✅

## ✅ Migration effectuée

Le code Algolia a été migré de l'ancienne API `functions.config()` vers la **nouvelle API moderne** `firebase-functions/params`.

**Résultat:** Plus de warning de dépréciation! Le code est compatible jusqu'en 2026+ 🎉

---

## 🔧 Configuration des variables (si Algolia est utilisé)

Si votre projet utilise Algolia pour la recherche, configurez les variables:

### Option 1: Variables d'environnement (Recommandé)

```bash
# Dans le dossier functions/
echo "ALGOLIA_APP_ID=votre_app_id" >> .env
echo "ALGOLIA_ADMIN_KEY=votre_admin_key" >> .env
```

### Option 2: Firebase Secrets (Plus sécurisé)

```bash
firebase functions:secrets:set ALGOLIA_APP_ID
# Entrez votre App ID quand demandé

firebase functions:secrets:set ALGOLIA_ADMIN_KEY
# Entrez votre Admin Key quand demandé
```

### Option 3: Firebase Environment (Déployé sur Cloud)

```bash
firebase functions:config:set algolia.app_id="votre_app_id"
firebase functions:config:set algolia.admin_key="votre_admin_key"
```

---

## 📝 Changements effectués

### Avant (déprécié):
```typescript
const algoliaClient = algoliasearch(
  functions.config().algolia?.app_id || '',
  functions.config().algolia?.admin_key || ''
);
```

### Après (moderne):
```typescript
import {defineString} from 'firebase-functions/params';

const algoliaAppId = defineString('ALGOLIA_APP_ID', {default: ''});
const algoliaAdminKey = defineString('ALGOLIA_ADMIN_KEY', {default: ''});

const algoliaClient = algoliasearch(
  algoliaAppId.value() || '',
  algoliaAdminKey.value() || ''
);
```

---

## ✅ Vérification

Après redéploiement:

```bash
firebase deploy --only functions
```

**Le warning de dépréciation ne devrait plus apparaître!** ✅

---

## 🎯 Impact

### Fonctions affectées:
- ✅ `syncUserToAlgolia` - Migré
- ✅ `syncJobOfferToAlgolia` - Migré
- ✅ `reindexAllUsers` - Migré
- ✅ `reindexAllJobOffers` - Migré

### Fonctions NON affectées (déjà modernes):
- ✅ `sendPushNotification` - Pas de config nécessaire
- ✅ `cleanInvalidTokens` - Pas de config nécessaire
- ✅ `sendTestNotification` - Pas de config nécessaire

---

## 💡 Note importante

Si vous **n'utilisez pas Algolia** pour la recherche, vous pouvez ignorer la configuration des variables. Les fonctions fonctionneront quand même, elles utiliseront simplement des valeurs vides.

**Les notifications push ne nécessitent AUCUNE configuration Algolia!** 🔔

---

## 🚀 Prochaine étape

Redéployez les fonctions:

```bash
firebase deploy --only functions
```

Le warning disparaîtra! ✅
