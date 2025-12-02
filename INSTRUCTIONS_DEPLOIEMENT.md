# 📦 Instructions de Déploiement - Chiasma v1.0.3

## 📋 Fichiers à uploader sur chiasma.pro

Voici les fichiers que tu dois uploader sur ton serveur web :

### 1. version.json
**Emplacement sur le serveur :** `https://chiasma.pro/version.json`

Ce fichier permet aux anciennes versions (1.0.1) de détecter la nouvelle version.

```
Source : /home/user/myapp/version.json
Destination : racine du site web (même niveau que index.html)
```

### 2. telecharger.html
**Emplacement sur le serveur :** `https://chiasma.pro/telecharger.html`

Page de téléchargement professionnelle avec design moderne.

```
Source : /home/user/myapp/telecharger.html
Destination : racine du site web
```

### 3. APK Files
**Emplacement sur le serveur :** `https://chiasma.pro/` (ou dans un dossier `/downloads/`)

Les 3 versions d'APK optimisées :

```
Source : /home/user/myapp/build/app/outputs/flutter-apk/
- app-arm64-v8a-release.apk      → chiasma-arm64-v8a-1.0.3.apk (25 MB)
- app-armeabi-v7a-release.apk    → chiasma-armeabi-v7a-1.0.3.apk (23 MB)
- app-x86_64-release.apk         → chiasma-x86_64-1.0.3.apk (26 MB)
```

**Note :** Renomme les APK comme indiqué ci-dessus pour que la page HTML fonctionne.

---

## 🚀 Étapes de Déploiement

### Étape 1 : Préparer les fichiers APK

```bash
# Renommer les APK avec des noms plus explicites
cd /home/user/myapp/build/app/outputs/flutter-apk/

cp app-arm64-v8a-release.apk chiasma-arm64-v8a-1.0.3.apk
cp app-armeabi-v7a-release.apk chiasma-armeabi-v7a-1.0.3.apk
cp app-x86_64-release.apk chiasma-x86_64-1.0.3.apk
```

### Étape 2 : Uploader sur le serveur

#### Option A : Via FTP/SFTP (FileZilla)
1. Connecte-toi à ton serveur web
2. Navigue vers le dossier racine (`public_html` ou `www`)
3. Upload les fichiers :
   - `version.json`
   - `telecharger.html`
   - `chiasma-arm64-v8a-1.0.3.apk`
   - `chiasma-armeabi-v7a-1.0.3.apk`
   - `chiasma-x86_64-1.0.3.apk`

#### Option B : Via cPanel
1. Connecte-toi à ton cPanel
2. Va dans "Gestionnaire de fichiers"
3. Navigue vers `public_html`
4. Clique sur "Upload"
5. Upload tous les fichiers listés ci-dessus

#### Option C : Via SSH
```bash
# Si tu as accès SSH à ton serveur
scp /home/user/myapp/version.json user@chiasma.pro:/path/to/web/root/
scp /home/user/myapp/telecharger.html user@chiasma.pro:/path/to/web/root/
scp /home/user/myapp/build/app/outputs/flutter-apk/*.apk user@chiasma.pro:/path/to/web/root/
```

### Étape 3 : Vérifier que tout fonctionne

Teste les URLs suivantes dans ton navigateur :

1. **version.json**
   ```
   https://chiasma.pro/version.json
   ```
   Devrait afficher le JSON avec version 1.0.3

2. **Page de téléchargement**
   ```
   https://chiasma.pro/telecharger.html
   ```
   Devrait afficher une belle page avec boutons de téléchargement

3. **APK principal**
   ```
   https://chiasma.pro/chiasma-arm64-v8a-1.0.3.apk
   ```
   Devrait télécharger l'APK

---

## ✅ Vérification Post-Déploiement

### Test depuis la ligne de commande

```bash
# Vérifier version.json
curl https://chiasma.pro/version.json

# Vérifier que les APK sont accessibles
curl -I https://chiasma.pro/chiasma-arm64-v8a-1.0.3.apk
```

Tu devrais voir `200 OK` et pas `403 Forbidden` ou `404 Not Found`.

---

## 🎯 Résultat Attendu

Une fois déployé :

✅ **Utilisateurs version 1.0.1** :
- Verront une alerte "Mise à jour obligatoire" au démarrage
- Seront redirigés vers la page de téléchargement
- Pourront télécharger la version 1.0.3

✅ **Utilisateurs version 1.0.3** :
- Utiliseront automatiquement la Cloud Function pour les futures mises à jour
- Ne dépendront plus de version.json

---

## 🔧 Maintenance Future

Pour les prochaines mises à jour (1.0.4, 1.0.5, etc.) :

1. **Mettre à jour la Cloud Function** (functions/src/versionCheck.ts)
2. **Déployer la Cloud Function** :
   ```bash
   firebase deploy --only functions:getAppVersion
   ```
3. **Optionnel** : Mettre à jour version.json (pour compatibilité avec v1.0.1 si elle existe encore)

**Tu n'auras plus besoin de version.json** une fois que tous les utilisateurs seront en version 1.0.3 ou supérieure !

---

## 📞 Support

Si tu rencontres des problèmes :
- Vérifie les permissions des fichiers sur le serveur (644 pour les fichiers)
- Vérifie que les chemins sont corrects
- Teste avec `curl -v` pour voir les détails de la requête HTTP

