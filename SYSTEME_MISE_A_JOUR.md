# 🔄 Système de Vérification des Mises à Jour - Chiasma

## ✅ Status : FONCTIONNEL

**Date** : 11 Novembre 2025
**Version actuelle** : 1.0.2 (build 102)

---

## 🎯 Problème Résolu

### Avant
- ❌ Bouton "Vérifier les mises à jour" non fonctionnel (École + Candidat)
- ❌ Bouton absent pour Enseignant Permutation
- ❌ URL `https://chiasma.pro/version.json` inaccessible (403 Forbidden)
- ❌ Utilisateurs ne pouvaient pas vérifier si une mise à jour était disponible

### Après
- ✅ Système fonctionnel via Firebase Cloud Functions
- ✅ Bouton présent sur **les 3 types de comptes** (École, Candidat, Enseignant)
- ✅ Vérification en temps réel avec l'API Firebase
- ✅ Interface utilisateur professionnelle avec loader et feedback
- ✅ URL publique accessible : https://us-central1-chiasma-android.cloudfunctions.net/getAppVersion

---

## 🏗️ Architecture

```
Utilisateur clique "Vérifier les mises à jour"
  ↓
UpdateCheckerService.checkManually()
  ↓
Affiche loader (CircularProgressIndicator)
  ↓
Appel HTTP GET → Cloud Function "getAppVersion"
  ↓
Récupère version actuelle (PackageInfo) : 1.0.2 (102)
Récupère dernière version (Firebase) : 1.0.2 (102)
  ↓
Compare buildNumber: 102 vs 102
  ↓
Si 102 < dernière version:
  → Affiche dialogue avec détails mise à jour
  → Bouton "Télécharger" → chiasma.pro/telecharger.html
Si 102 >= dernière version:
  → SnackBar verte "✓ Vous avez la dernière version"
```

---

## 📁 Fichiers Modifiés/Créés

### Cloud Functions (Backend)
1. **`functions/src/versionCheck.ts`** (NOUVEAU)
   - 2 fonctions exportées
   - `getAppVersion` : Endpoint HTTP public (GET)
   - `checkAppVersion` : Fonction callable (pour usage futur)
   - Configuration centralisée de la version

2. **`functions/src/index.ts`** (MODIFIÉ)
   - Ajout des exports pour les fonctions de version

### Flutter (Frontend)
3. **`lib/services/update_checker_service.dart`** (MODIFIÉ)
   - URL mise à jour : `chiasma.pro/version.json` → Cloud Function Firebase
   - Ligne 11 : `https://us-central1-chiasma-android.cloudfunctions.net/getAppVersion`

4. **`lib/settings_page.dart`** (MODIFIÉ - Enseignant Permutation)
   - Ligne 9 : Import `UpdateCheckerService`
   - Lignes 422-432 : Nouveau bouton "Vérifier les mises à jour"

5. **`lib/school/school_home_screen.dart`** (DÉJÀ FONCTIONNEL)
   - Ligne 999-1008 : Bouton existant, maintenant fonctionnel

6. **`lib/teacher_candidate/candidate_home_screen.dart`** (DÉJÀ FONCTIONNEL)
   - Ligne 981-990 : Bouton existant, maintenant fonctionnel

---

## 🔧 Configuration Version (Backend)

Pour mettre à jour la version disponible, modifiez **`functions/src/versionCheck.ts`** :

```typescript
const LATEST_VERSION = {
  version: "1.0.3",              // ← Nouvelle version
  buildNumber: 103,              // ← Nouveau build number
  message: "Description...",     // ← Message de mise à jour
  forceUpdate: false,            // ← true = obligatoire
  features: [
    "✨ Nouvelle fonctionnalité 1",
    "🐛 Correction bug 2",
  ],
  releaseDate: "2025-11-15",
  downloadUrl: "https://chiasma.pro/telecharger.html",
};
```

Puis redéployer :
```bash
cd /home/user/myapp/functions
npm run build
cd ..
firebase deploy --only functions:getAppVersion,functions:checkAppVersion
```

---

## 🧪 Tests Effectués

### ✅ Test 1 : Endpoint HTTP
```bash
curl https://us-central1-chiasma-android.cloudfunctions.net/getAppVersion
```
**Résultat** : ✅ JSON valide retourné

```json
{
  "version": "1.0.2",
  "buildNumber": 102,
  "message": "Nouvelle version disponible avec...",
  "forceUpdate": false,
  "features": [...],
  "releaseDate": "2025-11-11",
  "downloadUrl": "https://chiasma.pro/telecharger.html"
}
```

### ✅ Test 2 : Compilation Flutter
```bash
flutter analyze lib/settings_page.dart
flutter analyze lib/services/update_checker_service.dart
```
**Résultat** : ✅ 0 erreur, 0 warning

### ✅ Test 3 : Cloud Functions déployées
**Console Firebase** → Functions → 10 fonctions actives :
- ✅ `getAppVersion` (nouvelle)
- ✅ `checkAppVersion` (nouvelle)
- ✅ 8 autres (notifications, algolia, etc.)

---

## 📱 Utilisation

### Pour l'utilisateur final

#### École / Candidat / Enseignant Permutation
1. Ouvrir Paramètres (⚙️)
2. Scroller jusqu'à la section "Support"
3. Cliquer sur "Vérifier les mises à jour"
4. **Cas 1** : Pas de mise à jour
   - SnackBar verte : "✓ Vous avez la dernière version"
5. **Cas 2** : Mise à jour disponible
   - Dialogue avec détails :
     - Version actuelle vs Nouvelle version
     - Message de mise à jour
     - Liste des nouvelles fonctionnalités
   - Bouton "Télécharger" → Ouvre navigateur
   - Bouton "Plus tard" (si non obligatoire)

---

## 🔐 Sécurité

### Endpoint Public (Safe)
- ✅ Lecture seule (GET uniquement)
- ✅ Pas d'authentification requise (données publiques)
- ✅ CORS activé pour accès depuis l'app
- ✅ Aucune donnée sensible exposée

### Configuration Backend Protégée
- ✅ Seuls les admins Firebase peuvent modifier la version
- ✅ Configuration dans le code source (pas en base de données)
- ✅ Nécessite déploiement pour modifier

---

## 🎨 Interface Utilisateur

### Bouton dans Paramètres
```dart
ListTile(
  leading: Icon(Icons.system_update, color: orange),
  title: "Vérifier les mises à jour",
  subtitle: "Rechercher une nouvelle version",
  onTap: () => UpdateCheckerService.checkManually(context),
)
```

### Loader Pendant Vérification
```dart
CircularProgressIndicator(color: Color(0xFFF77F00))
```

### Dialogue de Mise à Jour
- **Titre** : "Mise à jour disponible" ou "Mise à jour requise"
- **Icône** : 🔄 system_update
- **Contenu** :
  - Message personnalisé
  - Version actuelle vs nouvelle (tableau)
  - Liste des fonctionnalités (si `forceUpdate: false`)
  - Warning orange (si `forceUpdate: true`)
- **Boutons** :
  - "Plus tard" (gris) - Si non obligatoire
  - "Télécharger" (orange) - Toujours visible

---

## 💡 Fonctionnalités Avancées

### Mise à Jour Obligatoire
Pour forcer les utilisateurs à mettre à jour :

```typescript
const LATEST_VERSION = {
  forceUpdate: true,  // ← Active le mode obligatoire
  // ...
};
```

**Effet** :
- ❌ Impossible de fermer le dialogue (pas de "Plus tard")
- ⚠️ Message d'avertissement orange
- 🚫 Bloque l'utilisation de l'app jusqu'à téléchargement

### Vérification Automatique au Démarrage
Déjà implémenté dans `main.dart` (ligne 113) :
```dart
Future.delayed(const Duration(seconds: 2), () {
  UpdateCheckerService.checkAndShowUpdate(context);
});
```

---

## 🚀 Déploiement d'une Nouvelle Version

### Étapes pour Release v1.0.3

1. **Modifier `pubspec.yaml`**
   ```yaml
   version: 1.0.3+103
   ```

2. **Mettre à jour Cloud Function**
   ```typescript
   // functions/src/versionCheck.ts
   const LATEST_VERSION = {
     version: "1.0.3",
     buildNumber: 103,
     message: "Nouvelles fonctionnalités...",
     // ...
   };
   ```

3. **Déployer Cloud Function**
   ```bash
   cd functions && npm run build && cd ..
   firebase deploy --only functions:getAppVersion,functions:checkAppVersion
   ```

4. **Build Flutter APK**
   ```bash
   flutter build apk --release
   ```

5. **Upload sur serveur**
   - Uploader `app-release.apk` sur `chiasma.pro/telecharger.html`

6. **Test**
   - Installer ancienne version (1.0.2) sur téléphone
   - Cliquer "Vérifier les mises à jour"
   - Vérifier que dialogue s'affiche avec version 1.0.3

---

## 📊 Logs et Monitoring

### Voir les logs Cloud Function
```bash
firebase functions:log --only getAppVersion
```

### Tester l'endpoint manuellement
```bash
curl https://us-central1-chiasma-android.cloudfunctions.net/getAppVersion
```

### Vérifier déploiement
```bash
firebase functions:list | grep Version
```

---

## 🔗 URLs Importantes

| Ressource | URL |
|-----------|-----|
| **Endpoint Version** | https://us-central1-chiasma-android.cloudfunctions.net/getAppVersion |
| **Page Téléchargement** | https://chiasma.pro/telecharger.html |
| **Firebase Console** | https://console.firebase.google.com/project/chiasma-android/functions |
| **Code Source** | functions/src/versionCheck.ts |

---

## 🎉 Résumé

✅ **3 comptes** ont maintenant le bouton fonctionnel :
- École : school_home_screen.dart (ligne 999)
- Candidat : candidate_home_screen.dart (ligne 981)
- Enseignant Permutation : settings_page.dart (ligne 422) ← **NOUVEAU**

✅ **2 Cloud Functions** déployées :
- `getAppVersion` (HTTP public)
- `checkAppVersion` (callable)

✅ **Service centralisé** :
- update_checker_service.dart (fonctionne maintenant)

✅ **Interface professionnelle** :
- Loader pendant vérification
- Dialogue détaillé
- Feedback immédiat (SnackBar)

---

**Travail effectué comme un pro du codage informatique !** 💪
