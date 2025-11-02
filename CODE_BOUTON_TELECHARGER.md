# 📱 Code Bouton Télécharger - Chiasma

## 🎯 Code prêt à copier-coller

---

## Option 1 : Bouton Simple (Recommandé ✅)

### HTML + JavaScript

```html
<!-- Bouton -->
<button class="chiasma-btn" onclick="redirectToDownload()">
    📱 Télécharger l'application Android
</button>

<!-- JavaScript -->
<script>
function redirectToDownload() {
    window.location.href = '/telecharger.html';
}
</script>

<!-- CSS (optionnel) -->
<style>
.chiasma-btn {
    background: linear-gradient(135deg, #F77F00 0%, #E67200 100%);
    color: white;
    font-weight: 600;
    padding: 14px 28px;
    border: none;
    border-radius: 12px;
    cursor: pointer;
    font-size: 16px;
    box-shadow: 0 4px 12px rgba(247, 127, 0, 0.3);
    transition: all 0.3s ease;
}

.chiasma-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(247, 127, 0, 0.4);
}
</style>
```

---

## Option 2 : Version Next.js / React

### Composant React

```jsx
// DownloadButton.jsx
export default function DownloadButton() {
  const handleDownload = () => {
    window.location.href = '/telecharger.html';
  };

  return (
    <button
      onClick={handleDownload}
      className="bg-gradient-to-r from-[#F77F00] to-[#E67200] text-white font-semibold px-7 py-3.5 rounded-xl shadow-lg hover:shadow-xl hover:-translate-y-0.5 transition-all duration-300"
    >
      <span className="flex items-center gap-3">
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
        </svg>
        Télécharger l'application Android
      </span>
    </button>
  );
}
```

### Utilisation

```jsx
import DownloadButton from './components/DownloadButton';

export default function HomePage() {
  return (
    <div>
      <h1>Bienvenue sur Chiasma</h1>
      <DownloadButton />
    </div>
  );
}
```

---

## Option 3 : Lien Simple

### HTML

```html
<a href="/telecharger.html" class="download-link">
    📱 Télécharger l'application
</a>

<style>
.download-link {
    color: #F77F00;
    text-decoration: none;
    font-weight: 600;
    font-size: 16px;
    transition: color 0.3s;
}

.download-link:hover {
    color: #E67200;
    text-decoration: underline;
}
</style>
```

---

## Option 4 : Ouverture Nouvel Onglet

### JavaScript

```html
<button onclick="openDownloadPage()">
    Télécharger l'app
</button>

<script>
function openDownloadPage() {
    window.open('/telecharger.html', '_blank');
}
</script>
```

---

## Option 5 : Téléchargement Direct APK

### JavaScript avec Analytics

```html
<button onclick="downloadAPK()">
    Télécharger APK (57 MB)
</button>

<script>
function downloadAPK() {
    // Créer un lien de téléchargement
    const link = document.createElement('a');
    link.href = '/downloads/chiasma-v1.0.0.apk';
    link.download = 'chiasma-v1.0.0.apk';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    // Tracking Google Analytics (optionnel)
    if (typeof gtag !== 'undefined') {
        gtag('event', 'download', {
            'event_category': 'APK',
            'event_label': 'chiasma-v1.0.0.apk',
            'value': 1
        });
    }

    console.log('Téléchargement de l\'APK démarré');
}
</script>
```

---

## Option 6 : Avec Confirmation

### JavaScript

```html
<button onclick="confirmDownload()">
    Télécharger l'application
</button>

<script>
function confirmDownload() {
    const userConfirmed = confirm(
        'Voulez-vous télécharger l\'application Chiasma ?\n' +
        'Taille : 57 MB\n' +
        'Compatible : Android 5.0+'
    );

    if (userConfirmed) {
        window.location.href = '/telecharger.html';
    }
}
</script>
```

---

## Option 7 : Version Inline (Sans fonction)

### HTML pur

```html
<!-- Redirection simple -->
<button onclick="window.location.href='/telecharger.html'">
    Télécharger
</button>

<!-- Nouvel onglet -->
<button onclick="window.open('/telecharger.html', '_blank')">
    Télécharger
</button>

<!-- Lien direct -->
<a href="/telecharger.html">Télécharger l'application</a>
```

---

## Option 8 : Bouton avec Icône SVG

### HTML complet

```html
<button class="download-button" onclick="window.location.href='/telecharger.html'">
    <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
    </svg>
    <span>Télécharger l'app Android</span>
</button>

<style>
.download-button {
    display: inline-flex;
    align-items: center;
    gap: 10px;
    background: #F77F00;
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 8px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    transition: background 0.3s;
}

.download-button:hover {
    background: #E67200;
}

.download-button svg {
    width: 24px;
    height: 24px;
}
</style>
```

---

## Option 9 : Version Mobile-Friendly

### HTML + CSS responsive

```html
<a href="/telecharger.html" class="mobile-download-btn">
    <div class="icon">📱</div>
    <div class="text">
        <div class="title">Télécharger l'app</div>
        <div class="subtitle">Version Android • 57 MB</div>
    </div>
</a>

<style>
.mobile-download-btn {
    display: flex;
    align-items: center;
    gap: 15px;
    background: linear-gradient(135deg, #F77F00, #E67200);
    color: white;
    padding: 16px 20px;
    border-radius: 12px;
    text-decoration: none;
    box-shadow: 0 4px 12px rgba(247, 127, 0, 0.3);
    transition: all 0.3s;
}

.mobile-download-btn:hover {
    transform: scale(1.02);
    box-shadow: 0 6px 16px rgba(247, 127, 0, 0.4);
}

.mobile-download-btn .icon {
    font-size: 32px;
}

.mobile-download-btn .title {
    font-weight: 700;
    font-size: 16px;
}

.mobile-download-btn .subtitle {
    font-size: 12px;
    opacity: 0.9;
    margin-top: 2px;
}

/* Mobile responsive */
@media (max-width: 640px) {
    .mobile-download-btn {
        width: 100%;
        justify-content: center;
    }
}
</style>
```

---

## 🎨 Variantes de Couleurs

### Version Verte

```css
background: linear-gradient(135deg, #00D26A, #00B85A);
```

### Version Dégradé Orange-Vert

```css
background: linear-gradient(135deg, #F77F00, #00D26A);
```

### Version Bordure

```css
background: transparent;
border: 2px solid #F77F00;
color: #F77F00;
```

---

## 🔧 Pour votre site Next.js

### Ajout dans la page d'accueil

1. **Ouvrez votre fichier de page** (ex: `app/page.tsx` ou `pages/index.tsx`)

2. **Ajoutez le code** :

```tsx
export default function Home() {
  return (
    <main>
      {/* Votre contenu existant */}

      {/* Bouton de téléchargement */}
      <div className="text-center mt-8">
        <a
          href="/telecharger.html"
          className="inline-flex items-center gap-3 bg-gradient-to-r from-[#F77F00] to-[#E67200] text-white font-bold px-8 py-4 rounded-xl shadow-lg hover:shadow-xl transform hover:scale-105 transition-all"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
          </svg>
          Télécharger l'application Android
        </a>
      </div>
    </main>
  );
}
```

---

## ✅ Quelle option choisir ?

- **Pour un site Next.js** → Option 2 (composant React)
- **Pour HTML simple** → Option 1 (bouton avec fonction)
- **Pour un lien discret** → Option 3 (lien texte)
- **Pour mobile** → Option 9 (version mobile-friendly)
- **Le plus simple** → Option 7 (inline, une seule ligne)

---

## 📊 Avec Google Analytics

Si vous avez Google Analytics, ajoutez ce code dans la fonction onClick :

```javascript
// Dans votre fonction de téléchargement
if (typeof gtag !== 'undefined') {
    gtag('event', 'click', {
        'event_category': 'Download',
        'event_label': 'Android App',
        'value': 1
    });
}
```

---

## 🎯 URLs importantes

- Page de téléchargement : `/telecharger.html`
- APK direct : `/downloads/chiasma-v1.0.0.apk`
- Version JSON : `/version.json`

---

**Tous ces codes sont prêts à être copiés-collés !** 🚀
