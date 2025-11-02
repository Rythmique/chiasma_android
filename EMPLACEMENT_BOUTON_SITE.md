# 📍 Guide : Déplacer le Bouton de Téléchargement sur chiasma.pro

## 🎯 Où placer le bouton ?

Voici les emplacements les plus courants pour un bouton de téléchargement sur un site Next.js.

---

## 1️⃣ Dans le Menu de Navigation (Header)

### Fichier à modifier : `components/Header.tsx` ou `app/layout.tsx`

Le bouton apparaîtra en permanence en haut de toutes les pages.

```tsx
export default function Header() {
  return (
    <header className="flex justify-between items-center p-4">
      {/* Logo et menu existant */}
      <nav className="flex gap-6 items-center">
        <a href="/">Accueil</a>
        <a href="/about">À propos</a>
        <a href="/contact">Contact</a>

        {/* Bouton de téléchargement dans le menu */}
        <a
          href="/telecharger.html"
          className="bg-gradient-to-r from-[#F77F00] to-[#E67200] text-white font-semibold px-6 py-2 rounded-lg hover:shadow-lg transition-all"
        >
          📱 Télécharger
        </a>
      </nav>
    </header>
  );
}
```

### Version avec styles inline (si Tailwind n'est pas utilisé) :

```tsx
<a
  href="/telecharger.html"
  style={{
    background: 'linear-gradient(135deg, #F77F00, #E67200)',
    color: 'white',
    fontWeight: '600',
    padding: '8px 24px',
    borderRadius: '8px',
    textDecoration: 'none',
    display: 'inline-block'
  }}
>
  📱 Télécharger
</a>
```

---

## 2️⃣ Dans la Section Hero (Haut de page d'accueil)

### Fichier à modifier : `app/page.tsx` ou `pages/index.tsx`

Le bouton sera visible immédiatement quand on arrive sur le site.

```tsx
export default function Home() {
  return (
    <main>
      {/* Section Hero */}
      <section className="text-center py-20">
        <h1 className="text-5xl font-bold mb-4">
          Chiasma - Plateforme de Permutation
        </h1>
        <p className="text-xl mb-8">
          Trouvez votre permutation idéale en Côte d'Ivoire
        </p>

        {/* Bouton de téléchargement dans le hero */}
        <a
          href="/telecharger.html"
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '12px',
            background: 'linear-gradient(135deg, #F77F00, #E67200)',
            color: 'white',
            fontWeight: '600',
            fontSize: '18px',
            padding: '16px 32px',
            borderRadius: '12px',
            textDecoration: 'none',
            boxShadow: '0 4px 12px rgba(247, 127, 0, 0.3)',
            position: 'relative',
            zIndex: 9999
          }}
        >
          📱 Télécharger l'application Android
        </a>
      </section>

      {/* Reste du contenu */}
    </main>
  );
}
```

---

## 3️⃣ Bouton Flottant (Fixe en bas à droite)

### Fichier à modifier : `app/layout.tsx`

Le bouton suivra l'utilisateur pendant qu'il scrolle.

```tsx
export default function RootLayout({ children }) {
  return (
    <html lang="fr">
      <body>
        {children}

        {/* Bouton flottant fixe */}
        <a
          href="/telecharger.html"
          style={{
            position: 'fixed',
            bottom: '24px',
            right: '24px',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            background: 'linear-gradient(135deg, #F77F00, #E67200)',
            color: 'white',
            fontWeight: '600',
            padding: '14px 24px',
            borderRadius: '50px',
            textDecoration: 'none',
            boxShadow: '0 4px 20px rgba(247, 127, 0, 0.4)',
            zIndex: 9999,
            transition: 'all 0.3s ease'
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.transform = 'scale(1.05)';
            e.currentTarget.style.boxShadow = '0 6px 24px rgba(247, 127, 0, 0.5)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.transform = 'scale(1)';
            e.currentTarget.style.boxShadow = '0 4px 20px rgba(247, 127, 0, 0.4)';
          }}
        >
          📱 Télécharger
        </a>
      </body>
    </html>
  );
}
```

---

## 4️⃣ Dans le Footer (Pied de page)

### Fichier à modifier : `components/Footer.tsx` ou `app/layout.tsx`

Le bouton sera visible en bas de chaque page.

```tsx
export default function Footer() {
  return (
    <footer className="bg-gray-100 py-12">
      <div className="container mx-auto px-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">

          {/* Colonne 1 : À propos */}
          <div>
            <h3 className="font-bold text-lg mb-4">Chiasma</h3>
            <p>Plateforme de permutation pour enseignants</p>
          </div>

          {/* Colonne 2 : Liens */}
          <div>
            <h3 className="font-bold text-lg mb-4">Liens</h3>
            <ul>
              <li><a href="/contact">Contact</a></li>
              <li><a href="/about">À propos</a></li>
            </ul>
          </div>

          {/* Colonne 3 : Téléchargement */}
          <div>
            <h3 className="font-bold text-lg mb-4">Télécharger l'app</h3>
            <a
              href="/telecharger.html"
              style={{
                display: 'inline-block',
                background: 'linear-gradient(135deg, #F77F00, #E67200)',
                color: 'white',
                fontWeight: '600',
                padding: '12px 24px',
                borderRadius: '10px',
                textDecoration: 'none',
                boxShadow: '0 4px 12px rgba(247, 127, 0, 0.3)'
              }}
            >
              📱 Application Android
            </a>
          </div>

        </div>
      </div>
    </footer>
  );
}
```

---

## 5️⃣ Au Milieu du Contenu (Call-to-Action)

### Fichier à modifier : `app/page.tsx`

Insérez le bouton entre deux sections de contenu.

```tsx
export default function Home() {
  return (
    <main>
      {/* Section 1 */}
      <section className="py-12">
        <h2>Nos fonctionnalités</h2>
        <p>Description...</p>
      </section>

      {/* Call-to-Action avec bouton */}
      <section className="bg-gradient-to-r from-orange-50 to-green-50 py-16 text-center">
        <h2 className="text-3xl font-bold mb-4">
          Prêt à trouver votre permutation ?
        </h2>
        <p className="text-lg mb-8">
          Téléchargez l'application mobile maintenant
        </p>

        <a
          href="/telecharger.html"
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '12px',
            background: 'linear-gradient(135deg, #F77F00, #E67200)',
            color: 'white',
            fontWeight: '600',
            fontSize: '18px',
            padding: '16px 32px',
            borderRadius: '12px',
            textDecoration: 'none',
            boxShadow: '0 4px 12px rgba(247, 127, 0, 0.3)',
            zIndex: 9999,
            position: 'relative'
          }}
        >
          📱 Télécharger l'application
        </a>
      </section>

      {/* Section 2 */}
      <section className="py-12">
        <h2>Témoignages</h2>
        <p>Description...</p>
      </section>
    </main>
  );
}
```

---

## 6️⃣ Dans une Sidebar (Barre latérale)

### Si votre site a une barre latérale

```tsx
export default function Sidebar() {
  return (
    <aside className="w-64 p-6 bg-gray-50">
      <h3 className="font-bold mb-4">Navigation</h3>
      <ul className="space-y-2 mb-8">
        <li><a href="/">Accueil</a></li>
        <li><a href="/features">Fonctionnalités</a></li>
      </ul>

      {/* Bouton dans la sidebar */}
      <a
        href="/telecharger.html"
        style={{
          display: 'block',
          textAlign: 'center',
          background: 'linear-gradient(135deg, #F77F00, #E67200)',
          color: 'white',
          fontWeight: '600',
          padding: '12px 16px',
          borderRadius: '10px',
          textDecoration: 'none',
          boxShadow: '0 4px 12px rgba(247, 127, 0, 0.3)'
        }}
      >
        📱 Télécharger
      </a>
    </aside>
  );
}
```

---

## 🎨 Modifier le Style selon l'Emplacement

### Pour le Header (petit et discret) :
```tsx
style={{
  padding: '8px 20px',
  fontSize: '14px',
  borderRadius: '8px'
}}
```

### Pour le Hero (grand et visible) :
```tsx
style={{
  padding: '18px 36px',
  fontSize: '20px',
  borderRadius: '14px'
}}
```

### Pour le Footer (moyen) :
```tsx
style={{
  padding: '12px 24px',
  fontSize: '16px',
  borderRadius: '10px'
}}
```

### Pour bouton flottant (rond) :
```tsx
style={{
  padding: '14px 24px',
  borderRadius: '50px', // Bordure arrondie complète
  fontSize: '15px'
}}
```

---

## 📂 Structure typique d'un projet Next.js

```
votre-projet/
├── app/
│   ├── page.tsx           ← Page d'accueil (Hero, CTA)
│   ├── layout.tsx         ← Layout global (Header, Footer, Bouton flottant)
│   └── about/
│       └── page.tsx       ← Autres pages
├── components/
│   ├── Header.tsx         ← Menu de navigation
│   ├── Footer.tsx         ← Pied de page
│   └── DownloadButton.tsx ← Composant bouton réutilisable
└── public/
    └── telecharger.html   ← Page de téléchargement
```

---

## 🔧 Créer un Composant Réutilisable (Recommandé)

### Créez `components/DownloadButton.tsx` :

```tsx
export default function DownloadButton({
  size = 'medium',
  variant = 'gradient'
}: {
  size?: 'small' | 'medium' | 'large';
  variant?: 'gradient' | 'outline';
}) {
  const sizes = {
    small: { padding: '8px 20px', fontSize: '14px' },
    medium: { padding: '14px 28px', fontSize: '16px' },
    large: { padding: '18px 36px', fontSize: '20px' }
  };

  const styles = {
    ...sizes[size],
    display: 'inline-block',
    background: variant === 'gradient'
      ? 'linear-gradient(135deg, #F77F00, #E67200)'
      : 'transparent',
    border: variant === 'outline' ? '2px solid #F77F00' : 'none',
    color: variant === 'gradient' ? 'white' : '#F77F00',
    fontWeight: '600',
    borderRadius: '12px',
    textDecoration: 'none',
    boxShadow: variant === 'gradient'
      ? '0 4px 12px rgba(247, 127, 0, 0.3)'
      : 'none',
    position: 'relative' as const,
    zIndex: 9999
  };

  return (
    <a href="/telecharger.html" style={styles}>
      📱 Télécharger l'app
    </a>
  );
}
```

### Utilisation dans n'importe quelle page :

```tsx
import DownloadButton from '@/components/DownloadButton';

export default function Home() {
  return (
    <main>
      {/* Petit bouton dans le header */}
      <DownloadButton size="small" />

      {/* Grand bouton dans le hero */}
      <DownloadButton size="large" />

      {/* Version outline */}
      <DownloadButton variant="outline" />
    </main>
  );
}
```

---

## 🎯 Ma Recommandation

Pour un site de téléchargement d'application, je recommande :

### ✅ Combinaison idéale :

1. **Header** : Petit bouton "Télécharger" (toujours visible)
2. **Hero** : Grand bouton call-to-action (première impression)
3. **Footer** : Bouton moyen (rappel en bas de page)

```tsx
// app/layout.tsx
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        {/* Header avec petit bouton */}
        <Header />

        {children}

        {/* Footer avec bouton moyen */}
        <Footer />
      </body>
    </html>
  );
}

// app/page.tsx
export default function Home() {
  return (
    <main>
      {/* Hero avec GRAND bouton */}
      <section className="hero">
        <h1>Chiasma</h1>
        <DownloadButton size="large" />
      </section>
    </main>
  );
}
```

---

## 📱 Version Mobile Responsive

Pour que le bouton s'adapte à toutes les tailles d'écran :

```tsx
<a
  href="/telecharger.html"
  style={{
    display: 'inline-block',
    background: 'linear-gradient(135deg, #F77F00, #E67200)',
    color: 'white',
    fontWeight: '600',
    padding: '14px 28px',
    borderRadius: '12px',
    textDecoration: 'none',
    boxShadow: '0 4px 12px rgba(247, 127, 0, 0.3)',
    position: 'relative',
    zIndex: 9999
  }}
  className="download-btn-responsive"
>
  📱 Télécharger l'app
</a>

<style jsx>{`
  @media (max-width: 640px) {
    .download-btn-responsive {
      width: 100%;
      text-align: center;
      padding: 12px 20px !important;
      font-size: 15px !important;
    }
  }
`}</style>
```

---

## ✅ Checklist de Placement

- [ ] Identifier le fichier Next.js à modifier (layout.tsx, page.tsx, etc.)
- [ ] Choisir l'emplacement (header, hero, footer, flottant)
- [ ] Copier le code du bouton correspondant
- [ ] Ajuster la taille et le style selon l'emplacement
- [ ] Tester sur desktop
- [ ] Tester sur mobile
- [ ] Vérifier que le clic redirige vers `/telecharger.html`

---

**Conseil** : Commencez par placer le bouton dans la **section hero** de votre page d'accueil (`app/page.tsx`), c'est l'emplacement le plus visible et le plus efficace ! 🎯
