# 📄 Page "Comment ça marche" - Documentation

## ✨ Ce qui a été créé

### 1️⃣ **Fichiers créés**

- **`comment-ca-marche.html`** : La page web complète et responsive
- **`GUIDE_SCREENSHOTS.md`** : Guide détaillé pour prendre les screenshots
- **`README_PAGE_EXPLICATIVE.md`** : Ce fichier

### 2️⃣ **Caractéristiques de la page**

✅ **Design moderne et professionnel**
- Couleurs Chiasma (Orange #F77F00, Vert #009E60)
- Animations au scroll
- Responsive mobile/desktop
- Navigation rapide entre sections

✅ **Structure claire**
- 3 sections principales (Enseignants, Candidats, Écoles)
- 4 étapes par section
- Explications simples sans jargon technique
- Tarifs clairement affichés

✅ **Optimisé pour l'utilisateur**
- Temps de chargement rapide
- Boutons d'action visibles
- Contact WhatsApp intégré
- SEO-friendly

---

## 📁 Structure attendue sur votre serveur

```
votre-site/
├── comment-ca-marche.html        ← La page principale
├── telecharger.html              ← Page de téléchargement (à créer/lier)
└── images/
    ├── enseignants/
    │   ├── 01-ecran-accueil.jpg
    │   ├── 02-barre-quota.jpg
    │   ├── 03-recherche-profil.jpg
    │   └── 04-choix-abonnement.jpg
    ├── candidats/
    │   ├── 01-ecran-accueil.jpg
    │   ├── 02-barre-quota.jpg
    │   ├── 03-postuler-offre.jpg
    │   └── 04-choix-abonnement.jpg
    └── ecoles/
        ├── 01-ecran-accueil.jpg
        ├── 02-barre-quota.jpg
        ├── 03-publier-offre.jpg
        └── 04-choix-abonnement.jpg
```

---

## 🚀 Étapes de déploiement

### **Étape 1 : Prendre les screenshots**
Suivez le guide dans `GUIDE_SCREENSHOTS.md`

### **Étape 2 : Uploader les fichiers**

Via FTP/FileZilla/cPanel :
1. Uploadez `comment-ca-marche.html` à la racine de votre site
2. Créez le dossier `images/`
3. Créez les sous-dossiers `enseignants/`, `candidats/`, `ecoles/`
4. Uploadez les screenshots dans les bons dossiers

### **Étape 3 : Vérifier**
Ouvrez `https://chiasma.pro/comment-ca-marche.html` dans votre navigateur

---

## 🎨 Personnalisation (optionnel)

### Modifier les couleurs

Dans le fichier HTML, section `<style>`, lignes 19-24 :

```css
:root {
    --orange: #F77F00;    /* Couleur principale */
    --green: #009E60;     /* Couleur secondaire */
    --dark: #2C3E50;      /* Texte foncé */
    --light: #F8F9FA;     /* Fond clair */
    --gray: #6C757D;      /* Texte gris */
}
```

### Modifier les tarifs

Cherchez `.pricing-card` dans le HTML et modifiez les prix directement.

### Modifier les textes

Tous les textes sont en français et facilement modifiables dans le HTML.

---

## 📱 Remplacer les placeholders par vos images

### Méthode simple

Dans le fichier HTML, cherchez ce type de code :

```html
<div class="step-image placeholder">
    <!-- INSTRUCTION: Remplacez ce div par: -->
    <!-- <img src="images/enseignants/01-ecran-accueil.jpg" alt="..."> -->
    <div>
        <div class="placeholder-icon">📱</div>
        <p><strong>Screenshot à ajouter ici :</strong>...</p>
    </div>
</div>
```

Remplacez-le par :

```html
<div class="step-image">
    <img src="images/enseignants/01-ecran-accueil.jpg" alt="Écran d'accueil enseignant">
</div>
```

### Ou laissez les placeholders

Les placeholders sont élégants et donnent une indication claire de ce qui doit être ajouté. Vous pouvez les laisser temporairement.

---

## 🔗 Liens à vérifier

### Dans le header (ligne 311)
Le bouton "Télécharger l'application" pointe vers `telecharger.html`

Si votre page de téléchargement a un autre nom, modifiez :
```html
<a href="telecharger.html" class="cta-button">Télécharger l'application</a>
```

### Dans le footer (ligne 320)
Le numéro WhatsApp est : `+225 0758747888`

Si vous voulez changer le numéro :
```html
<a href="https://wa.me/2250758747888">+225 0758747888</a>
```

---

## 📊 Performance et SEO

### Meta tags inclus
```html
<meta name="description" content="Découvrez comment fonctionne Chiasma...">
<title>Comment ça marche - Chiasma</title>
```

### Optimisations
- ✅ Code CSS intégré (pas de fichier externe)
- ✅ Animations légères
- ✅ Images lazy-loading compatible
- ✅ Responsive design
- ✅ Accessibilité (alt sur images)

---

## 🐛 Dépannage

### Les images ne s'affichent pas
**Causes possibles :**
1. Mauvais chemin de fichier
2. Noms de fichiers incorrects (majuscules/minuscules)
3. Permissions de fichiers sur le serveur

**Solution :**
Vérifiez que les chemins correspondent exactement :
- `images/enseignants/01-ecran-accueil.jpg`
- `images/candidats/02-barre-quota.jpg`
- etc.

### La page ne s'affiche pas correctement sur mobile
**Solution :**
Videz le cache de votre navigateur mobile ou testez en navigation privée.

### Les animations ne fonctionnent pas
**Solution :**
Assurez-vous que JavaScript est activé dans le navigateur.

---

## 📞 Support

**Besoin d'aide ?**
- WhatsApp : +225 0758747888
- Email : support@chiasma.pro

---

## 📝 Checklist finale

Avant de mettre en ligne :

- [ ] Tous les screenshots sont pris
- [ ] Images renommées correctement
- [ ] Dossiers créés sur le serveur
- [ ] Images uploadées dans les bons dossiers
- [ ] `comment-ca-marche.html` uploadé
- [ ] Page testée dans un navigateur
- [ ] Page testée sur mobile
- [ ] Liens de navigation vérifiés
- [ ] Numéro WhatsApp correct
- [ ] Tarifs à jour

---

**✨ Votre page est prête à être déployée ! ✨**
