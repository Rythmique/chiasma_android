# 📤 Instructions pour uploader sur votre site chiasma.pro

## 🎯 Ce que vous devez faire

Vous avez maintenant **2 fichiers** à uploader sur votre site web hébergé chez LWS :

### Fichier 1 : La page HTML
**Nom** : `telecharger-chiasma.html`
**Emplacement** : `/home/user/myapp/telecharger-chiasma.html`

### Fichier 2 : L'APK Android
**Nom** : `chiasma-v1.0.0.apk`
**Emplacement** : `/home/user/myapp/chiasma-v1.0.0.apk`

---

## 🔧 Étape 1 : Connexion à votre hébergement LWS

### Option A : Via FileZilla (Recommandé)

1. **Téléchargez FileZilla** (si pas déjà installé) :
   https://filezilla-project.org/download.php?type=client

2. **Connectez-vous à votre serveur FTP** :
   - **Hôte** : `ftp.chiasma.pro`
   - **Nom d'utilisateur** : (vos identifiants LWS)
   - **Mot de passe** : (votre mot de passe LWS)
   - **Port** : `21` (FTP standard)

3. **Cliquez sur "Connexion rapide"**

### Option B : Via le panneau LWS

1. Connectez-vous à : https://panel.lws.fr/
2. Allez dans "Hébergement Web"
3. Cliquez sur "Gestionnaire de fichiers" (File Manager)

---

## 📂 Étape 2 : Structure de fichiers à créer

Sur votre serveur, créez cette structure :

```
public_html/                          (racine de votre site)
  ├── index.html                      (votre page d'accueil existante)
  ├── telecharger.html                ← NOUVEAU (renommer telecharger-chiasma.html)
  └── downloads/                      ← NOUVEAU DOSSIER
      └── chiasma-v1.0.0.apk         ← NOUVEAU (57 MB)
```

---

## 🚀 Étape 3 : Upload des fichiers

### 3.1 Créer le dossier "downloads"

**Via FileZilla** :
1. Dans le panneau de droite (serveur distant), naviguez vers `public_html/`
2. Clic droit → "Créer un répertoire"
3. Nommez-le : `downloads`

**Via panneau LWS** :
1. Naviguez vers `public_html/`
2. Bouton "Nouveau dossier"
3. Nom : `downloads`

### 3.2 Uploader l'APK dans le dossier downloads

**Via FileZilla** :
1. À gauche, naviguez vers : `\\wsl.localhost\Ubuntu\home\user\myapp\`
2. À droite, ouvrez le dossier `public_html/downloads/`
3. Glissez-déposez le fichier `chiasma-v1.0.0.apk` de gauche à droite
4. ⏳ **Attendez** - Le fichier fait 57 MB, ça peut prendre 2-5 minutes

**Via panneau LWS** :
1. Allez dans `public_html/downloads/`
2. Cliquez sur "Upload" ou "Téléverser"
3. Sélectionnez `chiasma-v1.0.0.apk`
4. Attendez la fin du transfert

### 3.3 Uploader la page HTML

**Via FileZilla** :
1. À gauche, naviguez vers : `\\wsl.localhost\Ubuntu\home\user\myapp\`
2. À droite, allez dans `public_html/` (racine)
3. Glissez-déposez `telecharger-chiasma.html`
4. **RENOMMEZ-LE** en `telecharger.html` (enlever "-chiasma")

**Via panneau LWS** :
1. Allez dans `public_html/`
2. Uploadez `telecharger-chiasma.html`
3. Renommez-le en `telecharger.html`

---

## ✅ Étape 4 : Vérification

Une fois uploadé, vérifiez que ça fonctionne :

### Test 1 : Page de téléchargement
Ouvrez dans votre navigateur :
```
https://www.chiasma.pro/telecharger.html
```

✅ Vous devriez voir une belle page orange/verte avec le bouton "Télécharger l'APK"

### Test 2 : Lien de l'APK
Cliquez sur le bouton de téléchargement, ou testez directement :
```
https://www.chiasma.pro/downloads/chiasma-v1.0.0.apk
```

✅ Le téléchargement de l'APK (57 MB) devrait démarrer

---

## 🔗 Étape 5 : Ajouter un lien depuis votre site existant

### Sur votre site Next.js (chiasma.pro)

Ajoutez un bouton/lien quelque part sur votre page d'accueil :

```html
<a href="/telecharger.html" class="download-link">
  📱 Télécharger l'application Android
</a>
```

Ou si vous voulez l'intégrer dans votre code Next.js :

```jsx
import Link from 'next/link'

<Link href="/telecharger.html">
  <a className="btn-download">
    📱 Télécharger l'application Android
  </a>
</Link>
```

---

## 📱 Étape 6 : Tester sur mobile

1. Ouvrez votre téléphone Android
2. Allez sur : `https://www.chiasma.pro/telecharger.html`
3. Téléchargez l'APK
4. Installez-le (autorisez les sources inconnues si demandé)
5. Lancez l'application Chiasma !

---

## 🎨 Personnalisation (optionnel)

Si vous voulez personnaliser la page :

### Changer l'URL du lien "Retour au site"
Ligne 197 du fichier HTML :
```html
<a href="/" class="nav-link">← Retour au site</a>
```
Remplacez `"/"` par l'URL de votre choix

### Modifier les couleurs
Lignes 9-15 du fichier HTML, changez les valeurs :
```css
--primary: #F77F00;    /* Orange Chiasma */
--secondary: #00D26A;  /* Vert Chiasma */
```

### Ajouter Google Analytics
Ligne 363 du fichier HTML, ajoutez votre code de tracking

---

## ❓ Problèmes courants

### Erreur 404 sur /telecharger.html
- Vérifiez que le fichier est bien dans `public_html/` (pas dans un sous-dossier)
- Vérifiez que le nom est exactement `telecharger.html` (pas `.htm`)

### Erreur 404 sur l'APK
- Vérifiez que l'APK est bien dans `public_html/downloads/`
- Vérifiez le nom exact : `chiasma-v1.0.0.apk`

### Le téléchargement ne démarre pas
- Vérifiez que vous avez uploadé l'APK complet (57 MB)
- Attendez que le transfert FTP soit 100% terminé

### La page s'affiche bizarrement
- Vérifiez que le fichier HTML n'a pas été modifié pendant l'upload
- Essayez de vider le cache de votre navigateur (Ctrl+F5)

---

## 📞 Support

Si vous rencontrez des problèmes :
1. Contactez le support LWS : https://aide.lws.fr/
2. Vérifiez les permissions des fichiers (755 pour dossiers, 644 pour fichiers)
3. Consultez les logs FTP pour voir les erreurs de transfert

---

## ✨ Résultat final

Une fois tout installé, vos utilisateurs pourront :

1. Visiter `www.chiasma.pro`
2. Cliquer sur "Télécharger l'application"
3. Arriver sur une belle page professionnelle
4. Télécharger l'APK en un clic
5. Installer Chiasma sur leur téléphone Android

**Bonne chance ! 🚀**
