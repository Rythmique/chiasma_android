# 📤 Fichiers à Uploader sur LWS

## ✅ Fichiers Modifiés/Créés Aujourd'hui

Uploadez ces **4 fichiers** à la racine de votre site sur LWS :

### 1. **index.html** (NOUVEAU - IMPORTANT !)
- ✨ **Nouveau fichier** - Page d'accueil manquante
- 📍 Emplacement : Racine (`/`)
- 🎯 Rôle : Page d'accueil avec redirection vers comment-ca-marche.html
- ⚠️ **Priorité HAUTE** - Sans ce fichier, https://chiasma.pro/ ne fonctionne pas

### 2. **comment-ca-marche.html** (MODIFIÉ)
- 🔄 Ajout balises SEO (meta robots, Open Graph, Twitter)
- 🔄 Ajout bouton "Retour" en haut à gauche
- 📍 Emplacement : Racine (`/`)

### 3. **telecharger.html** (MODIFIÉ)
- 🔄 Ajout balises SEO (meta robots, Open Graph, Twitter)
- 📍 Emplacement : Racine (`/`)

### 4. **sitemap.xml** (MODIFIÉ)
- 🔄 Mise à jour avec la page comment-ca-marche.html
- 🔄 Date lastmod : 2025-11-09
- 📍 Emplacement : Racine (`/`)

---

## 📋 Comment Uploader sur LWS

### Méthode 1 : Via Gestionnaire de Fichiers LWS (Plus Simple)

1. **Connectez-vous** : https://panel.lws.fr
2. **Menu** : Hébergement Web → Gestionnaire de fichiers
3. **Naviguez** vers le dossier racine (souvent `public_html` ou `www`)
4. **Uploadez** les 4 fichiers un par un ou en sélection multiple
5. **Écrasez** les fichiers existants si demandé (pour les modifiés)

### Méthode 2 : Via FTP/SFTP (Plus Rapide)

**Logiciels recommandés** :
- FileZilla (gratuit) : https://filezilla-project.org/
- WinSCP (Windows)
- Cyberduck (Mac)

**Informations de connexion** (disponibles dans votre espace LWS) :
- Hôte : `ftp.votrehebergement.lws.fr` ou `chiasma.pro`
- Port : 21 (FTP) ou 22 (SFTP recommandé)
- Utilisateur : [votre identifiant LWS]
- Mot de passe : [votre mot de passe LWS]

**Étapes** :
1. Ouvrez FileZilla (ou autre client FTP)
2. Entrez les informations de connexion
3. Naviguez vers le dossier racine (à droite)
4. Glissez-déposez les 4 fichiers depuis votre ordinateur (à gauche)

---

## ✅ Vérifications Après Upload

### 1. Vérifier que les Fichiers sont Accessibles

Ouvrez ces URLs dans votre navigateur :

- ✅ https://chiasma.pro/
  - Doit afficher la page d'accueil ou rediriger vers comment-ca-marche.html

- ✅ https://chiasma.pro/comment-ca-marche.html
  - Doit afficher la page "Comment ça marche"
  - Vérifier que le bouton "Retour" est visible en haut à gauche

- ✅ https://chiasma.pro/telecharger.html
  - Doit afficher la page de téléchargement

- ✅ https://chiasma.pro/sitemap.xml
  - Doit afficher le code XML avec 4 URLs

### 2. Vérifier les Balises SEO

**Test Open Graph** (aperçu Facebook/WhatsApp) :
- Allez sur : https://developers.facebook.com/tools/debug/
- Entrez : `https://chiasma.pro/comment-ca-marche.html`
- Cliquez "Déboguer"
- Vérifiez que le titre, description et image s'affichent

**Test Twitter Card** :
- Allez sur : https://cards-dev.twitter.com/validator
- Entrez : `https://chiasma.pro/comment-ca-marche.html`
- Vérifiez l'aperçu

### 3. Vérifier les Erreurs

**Dans la console du navigateur** (F12) :
- Allez sur : https://chiasma.pro/
- Ouvrez la console (F12 → Console)
- Vérifiez qu'il n'y a **plus d'erreurs SVG**

---

## 🚀 Après l'Upload : Google Search Console

Une fois les fichiers uploadés et vérifiés :

### Étape 1 : Soumettre le Sitemap

1. **Allez sur** : https://search.google.com/search-console
2. **Menu** : Sitemaps
3. **Entrez** : `sitemap.xml`
4. **Cliquez** : Envoyer

### Étape 2 : Demander l'Indexation

Pour **chaque page** :

1. **Menu** : Inspection d'URL
2. **Entrez** :
   - `https://chiasma.pro/`
   - `https://chiasma.pro/comment-ca-marche.html`
   - `https://chiasma.pro/telecharger.html`
3. **Cliquez** : Tester l'URL en direct
4. **Puis** : Demander une indexation

**Délai** : 24-48 heures pour l'indexation

---

## 📊 Structure Finale du Site

```
chiasma.pro/
├── index.html (NOUVEAU ✨)
├── comment-ca-marche.html (MODIFIÉ 🔄)
├── telecharger.html (MODIFIÉ 🔄)
├── sitemap.xml (MODIFIÉ 🔄)
├── robots.txt (déjà OK ✅)
├── downloads/
│   └── chiasma-v1.0.1.apk
└── assets/
    └── images/
        ├── logo.png
        └── splash.png
```

---

## ⚠️ Problèmes Résolus

### ✅ Problème 1 : Pas de Page d'Accueil
**Avant** : https://chiasma.pro/ → Erreur 404 ou listing de fichiers
**Après** : https://chiasma.pro/ → Page d'accueil avec redirection

### ✅ Problème 2 : Erreurs SVG
**Avant** : Erreurs `<svg> attribute height: Expected length, "auto"`
**Après** : Plus d'erreurs (nouveau index.html sans SVG problématique)

### ✅ Problème 3 : Pas de Balises SEO
**Avant** : Balises meta robots manquantes
**Après** : Meta robots + Open Graph + Twitter Cards sur toutes les pages

### ✅ Problème 4 : Sitemap Incomplet
**Avant** : Sitemap sans comment-ca-marche.html
**Après** : Sitemap complet avec toutes les pages

---

## 📞 Support

**Si problème d'upload** :
- Support LWS : https://aide.lws.fr
- Documentation FileZilla : https://wiki.filezilla-project.org/

**Si problème d'indexation** :
- Consultez : [GUIDE_SEARCH_CONSOLE_LWS.md](GUIDE_SEARCH_CONSOLE_LWS.md)

---

## ✅ Checklist Finale

Cochez au fur et à mesure :

**Upload des Fichiers** :
- [ ] index.html uploadé
- [ ] comment-ca-marche.html uploadé
- [ ] telecharger.html uploadé
- [ ] sitemap.xml uploadé

**Vérifications** :
- [ ] https://chiasma.pro/ fonctionne
- [ ] https://chiasma.pro/comment-ca-marche.html fonctionne
- [ ] https://chiasma.pro/telecharger.html fonctionne
- [ ] https://chiasma.pro/sitemap.xml affiche le XML
- [ ] Bouton "Retour" visible sur comment-ca-marche.html
- [ ] Pas d'erreurs dans la console navigateur (F12)

**Google Search Console** :
- [ ] Sitemap soumis
- [ ] Indexation demandée pour /
- [ ] Indexation demandée pour /comment-ca-marche.html
- [ ] Indexation demandée pour /telecharger.html

**Suivi 24-48h** :
- [ ] Pages indexées dans Search Console
- [ ] Test `site:chiasma.pro` dans Google fonctionne

---

## 🎯 Prochaines Étapes

1. **MAINTENANT** : Uploadez les 4 fichiers sur LWS
2. **APRÈS UPLOAD** : Vérifiez que tout fonctionne
3. **ENSUITE** : Soumettez le sitemap dans Search Console
4. **ENFIN** : Demandez l'indexation de chaque page

**Résultat attendu dans 48h** : Votre site apparaît dans Google ! 🚀

---

**Date de création** : 2025-11-09
**Fichiers concernés** : 4 fichiers (1 nouveau, 3 modifiés)
