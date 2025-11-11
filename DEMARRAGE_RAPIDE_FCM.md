# 🚀 Démarrage Rapide - Notifications Push avec Son et Vibration

## Ce qu'il faut faire MAINTENANT (5-10 minutes)

### Étape 1: Installer Firebase CLI

```bash
npm install -g firebase-tools
```

### Étape 2: Se connecter à Firebase

```bash
firebase login
```

### Étape 3: Initialiser et déployer

```bash
cd /home/user/myapp
firebase init functions
```

**Répondez:**
- Projet: **Chiasma** (votre projet)
- Langage: **JavaScript**
- ESLint: **Non**
- Installer npm: **Oui**

**Puis déployez:**

```bash
firebase deploy --only functions
```

### Étape 4: C'est tout! ✅

Les notifications push avec **son + vibration** sont maintenant actives!

---

## 🧪 Pour tester

1. Ouvrez l'app sur 2 téléphones
2. École accepte une candidature
3. Le candidat reçoit la notification avec **son 🔔 + vibration 📳**

---

## 📖 Pour plus de détails

Voir [INSTALL_CLOUD_FUNCTIONS.md](INSTALL_CLOUD_FUNCTIONS.md)

---

## ❓ Besoin d'aide?

**Logs en direct:**
```bash
firebase functions:log
```

**Vérifier que c'est déployé:**
Firebase Console → Functions → Vous devriez voir 3 fonctions

---

**Note:** Vous n'avez RIEN à changer dans le code Flutter. Tout est déjà configuré! 🎉
