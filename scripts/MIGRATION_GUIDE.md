# Guide de Migration des Utilisateurs Firebase

Ce guide explique comment migrer environ 50-60 utilisateurs d'un projet Firebase source vers le projet **chiasma-android**.

## 📋 Vue d'ensemble

Le script de migration copie :
- ✅ Les comptes Firebase Authentication (email/password)
- ✅ Les documents utilisateurs dans Firestore (collection `users/`)
- ✅ Tous les métadonnées et quotas
- ⚠️ Les mots de passe sont réinitialisés (les utilisateurs recevront un mot de passe temporaire)

Tous les utilisateurs migrés auront :
- `accountType: 'teacher_transfer'`
- `isVerified: true`
- `freeQuotaLimit: 5` (5 consultations gratuites)
- Mot de passe temporaire : `Chiasma2025!`

## 🔧 Prérequis

### 1. Node.js
Assurez-vous que Node.js est installé (version 14+) :
```bash
node --version
```

### 2. Service Accounts
Vous devez obtenir les fichiers JSON de service account pour les deux projets Firebase :

#### A. Projet SOURCE (ancien projet)
1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet source
3. Allez dans **Paramètres du projet** (roue dentée) > **Comptes de service**
4. Cliquez sur **Générer une nouvelle clé privée**
5. Téléchargez le fichier JSON
6. Renommez-le : `source-project-service-account.json`

#### B. Projet DESTINATION (chiasma-android)
1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez le projet **chiasma-android**
3. Allez dans **Paramètres du projet** > **Comptes de service**
4. Cliquez sur **Générer une nouvelle clé privée**
5. Téléchargez le fichier JSON
6. Renommez-le : `chiasma-android-service-account.json`

⚠️ **IMPORTANT** : Ces fichiers contiennent des secrets. Ne les commitez JAMAIS dans Git !

## 📁 Structure du dossier

Créez cette structure dans `/home/user/myapp/scripts/` :

```
scripts/
├── package.json
├── migrate_users.js
├── migration_config.example.json
├── migration_config.json           # ← À créer (voir étape 3)
├── service-accounts/                # ← À créer
│   ├── source-project-service-account.json
│   └── chiasma-android-service-account.json
├── MIGRATION_GUIDE.md (ce fichier)
└── .gitignore
```

## 🚀 Instructions d'installation

### Étape 1 : Créer le dossier des service accounts
```bash
cd /home/user/myapp/scripts
mkdir -p service-accounts
```

### Étape 2 : Copier les service accounts
Placez vos deux fichiers JSON téléchargés dans le dossier `service-accounts/` :
```bash
# Exemple (adaptez les chemins selon votre situation)
cp ~/Downloads/mon-projet-source-*.json service-accounts/source-project-service-account.json
cp ~/Downloads/chiasma-android-*.json service-accounts/chiasma-android-service-account.json
```

### Étape 3 : Configurer la migration
```bash
# Copier le fichier de configuration exemple
cp migration_config.example.json migration_config.json

# Éditer la configuration
nano migration_config.json  # ou utilisez votre éditeur préféré
```

Remplissez les valeurs dans `migration_config.json` :
```json
{
  "sourceProjectId": "mon-ancien-projet",  // ← ID de votre projet source
  "sourceServiceAccountPath": "./service-accounts/source-project-service-account.json",

  "destProjectId": "chiasma-android",
  "destServiceAccountPath": "./service-accounts/chiasma-android-service-account.json",

  "skipDuplicates": true,
  "defaultPassword": "Chiasma2025!"
}
```

### Étape 4 : Installer les dépendances
```bash
npm install
```

## 🎯 Exécution de la migration

### Test préliminaire (DRY-RUN)
Toujours commencer par un test pour vérifier que tout fonctionne :
```bash
npm run migrate:dry-run
# OU
node migrate_users.js --dry-run
```

Le mode dry-run affichera :
- Combien d'utilisateurs seront migrés
- Lesquels seront ignorés (doublons)
- Les erreurs potentielles
- **SANS EFFECTUER de modifications réelles**

### Migration réelle
Une fois le test validé, lancez la vraie migration :
```bash
npm run migrate
# OU
node migrate_users.js
```

## 📊 Comprendre les résultats

### Pendant l'exécution
Le script affiche pour chaque utilisateur :
```
[1/60] 👤 jean.dupont@example.com
   ✓ Compte Auth créé (UID: abc123xyz)
   ✓ Document Firestore créé

[2/60] 👤 marie.martin@example.com
   ⏭️  Ignoré: email_exists_in_auth
```

### Résumé final
```
═══════════════════════════════════════════════════════
📊 RÉSUMÉ DE LA MIGRATION
═══════════════════════════════════════════════════════
Total utilisateurs:     60
✅ Migrés avec succès:  55
⏭️  Ignorés (doublons):  3
❌ Erreurs:             2
⏱️  Durée:               45.2s
═══════════════════════════════════════════════════════
```

### Rapport JSON
Un rapport détaillé est généré automatiquement :
- **Nom** : `migration_report_2025-11-03T14-30-00-000Z.json`
- **Contenu** : Détails de chaque utilisateur (succès/échec/ignoré)

## ⚠️ Gestion des erreurs courantes

### Erreur : "invalid_matricule"
**Cause** : Le matricule ne respecte pas le format `123456A` (6 chiffres + 1 lettre)
**Solution** : Corrigez le matricule dans le projet source avant la migration

### Erreur : "email_exists_in_auth"
**Cause** : L'email existe déjà dans chiasma-android
**Action** : Automatiquement ignoré si `skipDuplicates: true`

### Erreur : "matricule_exists_in_firestore"
**Cause** : Le matricule existe déjà dans chiasma-android
**Action** : Automatiquement ignoré si `skipDuplicates: true`

### Erreur : "source_auth_not_found"
**Cause** : L'utilisateur existe dans Firestore source mais pas dans Auth source
**Solution** : Vérifiez l'intégrité des données du projet source

## 🔐 Sécurité et mots de passe

### Mot de passe temporaire
Tous les utilisateurs migrés auront le mot de passe : **`Chiasma2025!`**

⚠️ **Les utilisateurs DOIVENT réinitialiser leur mot de passe** après la migration.

### Informer les utilisateurs
Envoyez un email à tous les utilisateurs migrés :

```
Objet : Votre compte Chiasma a été migré

Bonjour,

Votre compte a été migré vers la nouvelle plateforme Chiasma.

Pour vous connecter :
1. Email : [votre email]
2. Mot de passe temporaire : Chiasma2025!

⚠️ IMPORTANT : Changez votre mot de passe dès la première connexion
pour sécuriser votre compte.

L'équipe Chiasma
```

### Firebase Authentication
Pour envoyer un email de réinitialisation à un utilisateur spécifique :
```bash
# Utiliser la console Firebase ou le SDK
# Les utilisateurs peuvent aussi utiliser "Mot de passe oublié"
```

## 🧹 Nettoyage après migration

### Vérifier les données
1. Connectez-vous à [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez **chiasma-android**
3. Allez dans **Authentication** : vérifiez le nombre d'utilisateurs
4. Allez dans **Firestore** > collection `users` : vérifiez les documents

### Supprimer les fichiers sensibles (optionnel)
Une fois la migration terminée avec succès :
```bash
# ATTENTION : Cette action est irréversible !
rm -f service-accounts/*.json
rm -f migration_config.json

# Gardez uniquement les rapports et le code
ls scripts/
# Devrait afficher : migrate_users.js, package.json, migration_report_*.json
```

## 📝 Validation des données

### Champs requis
Vérifiez que chaque utilisateur migré a :
- ✅ `uid` (nouveau, différent de la source)
- ✅ `email`
- ✅ `accountType: 'teacher_transfer'`
- ✅ `matricule` (format : 6 chiffres + 1 lettre)
- ✅ `nom`
- ✅ `isVerified: true`
- ✅ `freeQuotaLimit: 5`

### Comptage
```bash
# Dans Firebase Console > Firestore
# Collection users : devrait avoir +50-60 documents
# Filtrer par accountType == 'teacher_transfer'
```

## 🆘 Besoin d'aide ?

### Logs détaillés
Les logs de la console montrent toutes les étapes. Copiez-les pour débogage.

### Rapport JSON
Le fichier `migration_report_*.json` contient tous les détails de chaque utilisateur.

### Rollback
Si vous devez annuler la migration :
1. Supprimez manuellement les utilisateurs dans Firebase Console
2. Ou utilisez un script de suppression (à créer si nécessaire)

## 📚 Ressources

- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Authentication](https://firebase.google.com/docs/auth)

---

**Créé le** : 2025-11-03
**Pour le projet** : Chiasma Android
**Contact** : Voir la documentation principale du projet
