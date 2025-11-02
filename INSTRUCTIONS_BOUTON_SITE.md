# 📱 Ajouter le Bouton de Téléchargement sur votre Site

## 🎯 Guide complet pour chiasma.pro

---

## Étape 1 : Copier le script dans `<head>`

### Ouvrez votre fichier HTML principal

Si votre site est en Next.js, le fichier est probablement :
- `app/layout.tsx` ou
- `pages/_document.tsx`

### Copiez ce code AVANT la balise `</head>` :

```html
<script>
  function redirectToDownload() {
    window.location.href = '/telecharger.html';
  }

  function openDownloadNewTab() {
    window.open('/telecharger.html', '_blank');
  }

  function downloadApkDirectly() {
    const link = document.createElement('a');
    link.href = '/downloads/chiasma-v1.0.0.apk';
    link.download = 'chiasma-v1.0.0.apk';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
</script>

<style>
  .chiasma-download-btn {
    display: inline-flex;
    align-items: center;
    gap: 12px;
    background: linear-gradient(135deg, #F77F00 0%, #E67200 100%);
    color: white;
    font-weight: 600;
    font-size: 16px;
    padding: 14px 28px;
    border: none;
    border-radius: 12px;
    cursor: pointer;
    box-shadow: 0 4px 12px rgba(247, 127, 0, 0.3);
    transition: all 0.3s ease;
  }

  .chiasma-download-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(247, 127, 0, 0.4);
  }
</style>
```

---

## Étape 2 : Ajouter le bouton dans votre page

### Option A : Bouton simple (HTML)

```html
<button class="chiasma-download-btn" onclick="redirectToDownload()">
  📱 Télécharger l'application Android
</button>
```

### Option B : Avec icône SVG

```html
<button class="chiasma-download-btn" onclick="redirectToDownload()">
  <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
  </svg>
  Télécharger l'app
</button>
```

### Option C : Lien simple

```html
<a href="/telecharger.html" class="chiasma-download-btn">
  📱 Télécharger l'application
</a>
```

---

## Étape 3 : Pour Next.js (React/TypeScript)

### Dans `app/layout.tsx` ou `pages/_document.tsx`

Ajoutez dans la section `<head>` :

```tsx
<head>
  {/* Vos autres balises head */}

  <script dangerouslySetInnerHTML={{
    __html: `
      function redirectToDownload() {
        window.location.href = '/telecharger.html';
      }
      function openDownloadNewTab() {
        window.open('/telecharger.html', '_blank');
      }
    `
  }} />

  <style dangerouslySetInnerHTML={{
    __html: `
      .chiasma-download-btn {
        display: inline-flex;
        align-items: center;
        gap: 12px;
        background: linear-gradient(135deg, #F77F00 0%, #E67200 100%);
        color: white;
        font-weight: 600;
        font-size: 16px;
        padding: 14px 28px;
        border: none;
        border-radius: 12px;
        cursor: pointer;
        box-shadow: 0 4px 12px rgba(247, 127, 0, 0.3);
        transition: all 0.3s ease;
        text-decoration: none;
      }
      .chiasma-download-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 16px rgba(247, 127, 0, 0.4);
      }
    `
  }} />
</head>
```

### Dans votre page (ex: `app/page.tsx`)

```tsx
export default function Home() {
  return (
    <main>
      <h1>Bienvenue sur Chiasma</h1>

      {/* Bouton de téléchargement */}
      <button
        className="chiasma-download-btn"
        onClick={() => window.location.href = '/telecharger.html'}
      >
        📱 Télécharger l'application Android
      </button>
    </main>
  );
}
```

---

## Étape 4 : Variantes du bouton

### 1. Nouvel onglet

```html
<button class="chiasma-download-btn" onclick="openDownloadNewTab()">
  📱 Télécharger l'app
</button>
```

### 2. Téléchargement direct de l'APK

```html
<button class="chiasma-download-btn" onclick="downloadApkDirectly()">
  📥 Télécharger APK (57 MB)
</button>
```

### 3. Version inline (sans fonction)

```html
<button class="chiasma-download-btn"
        onclick="window.location.href='/telecharger.html'">
  📱 Télécharger
</button>
```

### 4. Lien texte simple

```html
<a href="/telecharger.html" style="color: #F77F00; font-weight: 600;">
  📱 Télécharger l'application →
</a>
```

---

## Étape 5 : Positions recommandées

### A. Dans le menu de navigation

```html
<nav>
  <a href="/">Accueil</a>
  <a href="/about">À propos</a>
  <button class="chiasma-download-btn" onclick="redirectToDownload()">
    📱 Télécharger
  </button>
</nav>
```

### B. Dans la section hero (haut de page)

```html
<section class="hero">
  <h1>Chiasma - Plateforme de permutation</h1>
  <p>Trouvez votre permutation idéale</p>
  <button class="chiasma-download-btn" onclick="redirectToDownload()">
    📱 Télécharger l'application Android
  </button>
</section>
```

### C. Dans le footer

```html
<footer>
  <div>
    <h3>Télécharger l'app</h3>
    <button class="chiasma-download-btn" onclick="redirectToDownload()">
      📱 Application Android
    </button>
  </div>
</footer>
```

---

## Étape 6 : Styles avancés

### Version avec Tailwind CSS (pour Next.js)

```tsx
<a
  href="/telecharger.html"
  className="inline-flex items-center gap-3 bg-gradient-to-r from-[#F77F00] to-[#E67200] text-white font-semibold px-7 py-3.5 rounded-xl shadow-lg hover:shadow-xl hover:-translate-y-0.5 transition-all duration-300"
>
  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
  </svg>
  Télécharger l'app
</a>
```

### Version avec animation

```html
<style>
@keyframes pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.05); }
}

.chiasma-download-btn-animated {
  animation: pulse 2s infinite;
}

.chiasma-download-btn-animated:hover {
  animation: none;
}
</style>

<button class="chiasma-download-btn chiasma-download-btn-animated"
        onclick="redirectToDownload()">
  📱 Télécharger maintenant
</button>
```

---

## Étape 7 : Tracking avec Google Analytics

### Si vous avez Google Analytics

Ajoutez ce code dans votre script :

```javascript
function redirectToDownload() {
  // Tracking
  if (typeof gtag !== 'undefined') {
    gtag('event', 'click', {
      'event_category': 'Download',
      'event_label': 'Android App Button',
      'value': 1
    });
  }

  // Redirection
  window.location.href = '/telecharger.html';
}
```

---

## ✅ Checklist d'installation

- [ ] Script copié dans `<head>`
- [ ] Styles CSS ajoutés
- [ ] Bouton placé sur la page
- [ ] Test du clic → Redirige vers `/telecharger.html`
- [ ] Test sur mobile
- [ ] Test sur desktop

---

## 🧪 Tester le bouton

1. **Ouvrez votre site** : `https://chiasma.pro`
2. **Cliquez sur le bouton**
3. **Doit rediriger vers** : `https://chiasma.pro/telecharger.html`
4. **Sur la page de téléchargement** : Cliquez sur "Télécharger l'APK"
5. **Le fichier APK** doit se télécharger (57 MB)

---

## 🎨 Personnalisation des couleurs

### Changer la couleur orange

Remplacez `#F77F00` et `#E67200` par vos couleurs :

```css
background: linear-gradient(135deg, #VOTRE_COULEUR_1 0%, #VOTRE_COULEUR_2 100%);
```

### Exemples de dégradés

```css
/* Bleu */
background: linear-gradient(135deg, #3B82F6 0%, #2563EB 100%);

/* Vert */
background: linear-gradient(135deg, #10B981 0%, #059669 100%);

/* Rouge */
background: linear-gradient(135deg, #EF4444 0%, #DC2626 100%);
```

---

## 📱 Version mobile optimisée

```css
@media (max-width: 640px) {
  .chiasma-download-btn {
    width: 100%;
    justify-content: center;
    font-size: 15px;
    padding: 12px 20px;
  }
}
```

---

## 🚀 Exemple complet pour Next.js

### Fichier `app/page.tsx`

```tsx
export default function Home() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-8">
      <h1 className="text-4xl font-bold mb-4">Chiasma</h1>
      <p className="text-lg mb-8">Plateforme de permutation pour enseignants</p>

      {/* Bouton de téléchargement */}
      <a
        href="/telecharger.html"
        className="chiasma-download-btn"
      >
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
        </svg>
        Télécharger l'application Android
      </a>
    </main>
  );
}
```

---

## ❓ Problèmes courants

### Le bouton ne fonctionne pas
- Vérifiez que le script est bien dans `<head>`
- Vérifiez la console JavaScript (F12)
- Essayez `onclick="window.location.href='/telecharger.html'"` directement

### Le style ne s'applique pas
- Vérifiez que le CSS est dans `<head>` ou dans un fichier CSS
- Vérifiez qu'il n'y a pas de conflit avec d'autres styles
- Ajoutez `!important` si nécessaire

### La page ne redirige pas
- Vérifiez que `/telecharger.html` existe bien
- Testez en ouvrant directement `https://chiasma.pro/telecharger.html`

---

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez la console du navigateur (F12 → Console)
2. Vérifiez que tous les fichiers sont bien uploadés
3. Testez sur différents navigateurs

---

**Le fichier complet du script est disponible dans `script-head-telecharger.html` !** 🚀
