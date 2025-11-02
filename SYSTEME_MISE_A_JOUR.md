# 🔄 Système de Mise à Jour pour Installations Hors Play Store

## 📋 Vue d'ensemble

Votre application Chiasma dispose maintenant de **2 systèmes de mise à jour** :

### 1. Via Play Store (in_app_update)
- ✅ Fonctionne automatiquement si l'app est installée depuis le Play Store
- ✅ Utilise l'API officielle de Google

### 2. Via serveur Chiasma (nouveau !)
- ✅ Fonctionne pour les installations depuis chiasma.pro
- ✅ Détection automatique au démarrage
- ✅ Vérification manuelle dans les paramètres

---

## 🎯 Comment ça fonctionne

### Au démarrage de l'app

1. **L'app vérifie** : `https://chiasma.pro/version.json`
2. **Compare** la version installée avec la version disponible
3. **Si nouvelle version** : Affiche une popup
4. **L'utilisateur clique** → Redirigé vers chiasma.pro/telecharger.html

### Vérification manuelle

L'utilisateur peut cliquer sur **"Vérifier les mises à jour"** dans les paramètres.

---

## 📁 Fichiers créés

### 1. Service de vérification
**Fichier** : `lib/services/update_checker_service.dart`
- Vérifie la version depuis votre serveur
- Affiche les dialogues de mise à jour
- Gère les mises à jour forcées (critiques)

### 2. Fichier de version
**Fichier** : `version.json`
- À uploader sur votre serveur

---

## 🚀 Installation sur votre serveur

### Étape 1 : Uploader version.json

**Via WinSCP** :
1. Connectez-vous à `ftp.chiasma.pro`
2. Naviguez vers `htdocs/`
3. Uploadez le fichier `version.json`

**Structure finale** :
```
htdocs/
  ├── telecharger.html
  ├── version.json          ← NOUVEAU
  └── downloads/
      └── chiasma-v1.0.0.apk
```

**URL finale** : `https://chiasma.pro/version.json`

### Étape 2 : Vérifier que c'est accessible

Ouvrez dans votre navigateur :
```
https://chiasma.pro/version.json
```

Vous devriez voir :
```json
{
  "version": "1.0.0",
  "buildNumber": 1,
  "message": "Une nouvelle version de Chiasma est disponible...",
  ...
}
```

---

## 📝 Comment publier une nouvelle version

### Scénario : Vous sortez la version 1.1.0

#### 1. Modifiez pubspec.yaml

```yaml
version: 1.1.0+2  # Version 1.1.0, build 2
```

#### 2. Buildez la nouvelle APK

```bash
flutter build apk --release
```

#### 3. Renommez l'APK

```bash
cp build/app/outputs/flutter-apk/app-release.apk chiasma-v1.1.0.apk
```

#### 4. Uploadez sur votre serveur

**Via WinSCP** :
- Uploadez `chiasma-v1.1.0.apk` dans `htdocs/downloads/`

#### 5. Mettez à jour version.json

**Modifiez le fichier** `version.json` :

```json
{
  "version": "1.1.0",
  "buildNumber": 2,
  "message": "Nouvelle version disponible ! Découvrez les améliorations.",
  "forceUpdate": false,
  "releaseNotes": [
    "Correction de bugs",
    "Amélioration des performances",
    "Nouvelles fonctionnalités XYZ"
  ],
  "downloadUrl": "https://chiasma.pro/downloads/chiasma-v1.1.0.apk",
  "releaseDate": "2025-11-15"
}
```

#### 6. Uploadez version.json mis à jour

**Via WinSCP** :
- Remplacez `htdocs/version.json` par la nouvelle version

---

## ⚡ Types de mises à jour

### Mise à jour standard (forceUpdate: false)

```json
{
  "forceUpdate": false,
  ...
}
```

- ✅ L'utilisateur peut cliquer "Plus tard"
- ✅ Peut continuer à utiliser l'app
- ✅ Pour corrections mineures

### Mise à jour forcée (forceUpdate: true)

```json
{
  "forceUpdate": true,
  ...
}
```

- ❌ L'utilisateur NE PEUT PAS fermer la popup
- ❌ DOIT télécharger pour continuer
- ❌ **À utiliser uniquement pour bugs critiques ou problèmes de sécurité**

---

## 🧪 Test du système

### Test 1 : Simulation de nouvelle version

1. **Modifiez temporairement** `version.json` sur le serveur :
   ```json
   {
     "version": "99.0.0",
     "buildNumber": 999,
     ...
   }
   ```

2. **Ouvrez l'app** → La popup devrait s'afficher

3. **Remettez** la bonne version après le test

### Test 2 : Vérification manuelle

1. Ouvrez l'app
2. Allez dans **Paramètres** (icône ⚙️)
3. Cliquez sur **"Vérifier les mises à jour"**
4. Devrait afficher : "✓ Vous avez la dernière version"

---

## 🔧 Paramètres du système

### URL du serveur

**Modifiable dans** : `lib/services/update_checker_service.dart`

```dart
static const String _versionUrl = 'https://chiasma.pro/version.json';
static const String _downloadUrl = 'https://chiasma.pro/telecharger.html';
```

### Délai de vérification

**Modifiable dans** : `lib/main.dart`

```dart
Future.delayed(const Duration(seconds: 2), () {
  // Change "2" pour modifier le délai en secondes
```

---

## 📊 Statistiques (optionnel)

Pour tracker combien d'utilisateurs téléchargent les mises à jour, ajoutez Google Analytics ou un système de tracking sur votre page `telecharger.html`.

Le code est déjà préparé (ligne 363 du fichier HTML).

---

## ❓ FAQ

### Q : Les utilisateurs Play Store recevront-ils les mises à jour normalement ?
**R** : Oui ! Le système Play Store reste prioritaire. Le système Chiasma est un complément pour installations hors Play Store.

### Q : Que se passe-t-il si version.json n'est pas accessible ?
**R** : L'app continue de fonctionner normalement. Aucune erreur visible pour l'utilisateur.

### Q : Peut-on désactiver temporairement le système ?
**R** : Oui, mettez `buildNumber: 0` dans version.json.

### Q : Comment voir les logs de vérification ?
**R** : En mode debug, ouvrez la console Flutter. Vous verrez :
```
Version actuelle: 1.0.0 (1)
Dernière version: 1.1.0 (2)
```

---

## ✅ Checklist de publication

Quand vous publiez une nouvelle version :

- [ ] Modifier `pubspec.yaml` (incrémenter version + buildNumber)
- [ ] Build APK : `flutter build apk --release`
- [ ] Renommer APK : `chiasma-v{VERSION}.apk`
- [ ] Uploader APK dans `htdocs/downloads/`
- [ ] Modifier `version.json` avec nouvelle version
- [ ] Uploader `version.json` dans `htdocs/`
- [ ] Tester en ouvrant l'app
- [ ] Optionnel : Publier aussi sur Play Store

---

## 🎉 Félicitations !

Votre système de mise à jour est maintenant **100% opérationnel** !

Les utilisateurs qui téléchargent depuis chiasma.pro recevront automatiquement les notifications de mise à jour. 🚀
