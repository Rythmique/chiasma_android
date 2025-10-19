# ✅ Phase 1 : Séparation des Parcours - TERMINÉE

## 🎯 Objectif
Créer 3 parcours distincts dans l'application avec des inscriptions et connexions différentes.

---

## ✅ Modifications apportées

### 1. **Nouveau fichier : OnboardingPage**
📁 `lib/onboarding_page.dart`

**Fonctionnalité :**
- Page d'accueil qui propose 3 choix :
  - 👨‍🏫 **Enseignant (Permutation)** → `accountType: 'teacher_transfer'`
  - 🎓 **Candidat Enseignant** → `accountType: 'teacher_candidate'`
  - 🏫 **Établissement** → `accountType: 'school'`
- Design moderne avec cartes cliquables
- Redirection vers `RegisterScreen` avec le bon `accountType`

---

### 2. **UserModel modifié**
📁 `lib/models/user_model.dart`

**Ajouté :**
```dart
final String accountType; // 'teacher_transfer', 'teacher_candidate', 'school'
```

**Modifications :**
- Valeur par défaut : `'teacher_transfer'` (compatibilité avec comptes existants)
- Ajouté dans `toMap()`
- Ajouté dans `fromFirestore()`
- Ajouté dans `copyWith()`

---

### 3. **RegisterScreen modifié**
📁 `lib/register_screen.dart`

**Ajouté :**
```dart
final String accountType;

const RegisterScreen({
  super.key,
  this.accountType = 'teacher_transfer',
});
```

**Modifications :**
- Accepte le paramètre `accountType` depuis OnboardingPage
- Passe `accountType` à `AuthService.signUpWithEmailAndPassword()`

---

### 4. **AuthService modifié**
📁 `lib/services/auth_service.dart`

**Ajouté :**
```dart
Future<UserCredential?> signUpWithEmailAndPassword({
  String accountType = 'teacher_transfer', // Nouveau paramètre
  ...
})
```

**Modifications :**
- Vérifie le matricule uniquement pour `teacher_transfer`
- Ajoute `accountType` dans le UserModel lors de la création
- Candidats et écoles ne sont pas obligés d'avoir un matricule unique

---

### 5. **LoginScreen modifié**
📁 `lib/login_screen.dart`

**Ajouté :**
```dart
final _firestoreService = FirestoreService();
```

**Modifications :**
- Récupère le type de compte après connexion
- Redirection selon `accountType` :
  - `'teacher_transfer'` → `HomeScreen` (permutations)
  - `'teacher_candidate'` → `HomeScreen` (temporaire, TODO Phase 2)
  - `'school'` → `HomeScreen` (temporaire, TODO Phase 3)
- Bouton "S'inscrire" redirige vers `OnboardingPage` au lieu de `RegisterScreen`

---

## 📊 Structure Firestore mise à jour

### Collection `users`

```javascript
{
  uid: "abc123",
  email: "user@example.com",
  accountType: "teacher_transfer",  // ← NOUVEAU CHAMP

  // Reste inchangé
  matricule: "...",
  nom: "...",
  telephones: [...],
  fonction: "...",
  zoneActuelle: "...",
  dren: "...",
  infosZoneActuelle: "...",
  zonesSouhaitees: [...],
  createdAt: Timestamp,
  updatedAt: Timestamp,
  isOnline: false,
  isVerified: false,
  isAdmin: false,
  profileViewsCount: 0,
  freeViewsRemaining: 5,
  hasActiveSubscription: false,
  subscriptionEndDate: null,
}
```

---

## 🧪 Test du flux

### Scénario 1 : Inscription Enseignant (Permutation)

1. Lancer l'app : `flutter run`
2. Écran de login → Cliquer "Pas encore de compte ?"
3. **OnboardingPage** s'affiche
4. Choisir "Enseignant - Je cherche à permuter"
5. Formulaire d'inscription classique (avec matricule)
6. Après inscription → Redirection vers `HomeScreen`
7. **accountType = 'teacher_transfer'** enregistré dans Firestore

### Scénario 2 : Inscription Candidat (TODO Phase 2)

1. OnboardingPage → Choisir "Candidat Enseignant"
2. Formulaire d'inscription (même pour l'instant, sera personnalisé en Phase 2)
3. **accountType = 'teacher_candidate'** enregistré

### Scénario 3 : Inscription Établissement (TODO Phase 3)

1. OnboardingPage → Choisir "Établissement"
2. Formulaire d'inscription (même pour l'instant, sera personnalisé en Phase 3)
3. **accountType = 'school'** enregistré

### Scénario 4 : Connexion

1. Se connecter avec email/mot de passe/matricule
2. Le système lit `accountType` dans Firestore
3. Redirection automatique vers le bon écran d'accueil

---

## 🎯 Compatibilité avec les comptes existants

**Tous les comptes existants fonctionnent normalement :**
- Si `accountType` n'existe pas dans Firestore → Valeur par défaut = `'teacher_transfer'`
- Les utilisateurs existants peuvent se connecter sans problème
- Ils seront redirigés vers `HomeScreen` (permutations)

---

## ⚠️ TODO pour les phases suivantes

### Phase 2 : Candidats Enseignants
- [ ] Créer `CandidateHomeScreen`
- [ ] Personnaliser le formulaire d'inscription pour candidats
- [ ] Créer modèle `JobApplication`
- [ ] Page liste des offres d'emploi
- [ ] Page "Ma candidature"

### Phase 3 : Établissements
- [ ] Créer `SchoolHomeScreen`
- [ ] Personnaliser le formulaire d'inscription pour écoles
- [ ] Créer modèle `JobOffer`
- [ ] Page liste des candidats
- [ ] Page création d'offre

---

## 📁 Fichiers créés/modifiés

| Fichier | Action | Statut |
|---------|--------|--------|
| `lib/onboarding_page.dart` | Créé | ✅ |
| `lib/models/user_model.dart` | Modifié | ✅ |
| `lib/register_screen.dart` | Modifié | ✅ |
| `lib/services/auth_service.dart` | Modifié | ✅ |
| `lib/login_screen.dart` | Modifié | ✅ |

---

## ✅ Vérifications

```bash
# Analyser le code
flutter analyze lib/onboarding_page.dart \
                lib/models/user_model.dart \
                lib/services/auth_service.dart \
                lib/login_screen.dart \
                lib/register_screen.dart

# Résultat : 1 issue found (warning mineur acceptable)
```

---

## 🚀 Prochaine étape

**Vous êtes prêt pour la Phase 2 !**

Lancez l'app pour tester :
```bash
flutter run
```

**Testez le flux :**
1. Cliquez sur "S'inscrire"
2. Vous devriez voir la nouvelle OnboardingPage avec 3 choix
3. Sélectionnez "Enseignant (Permutation)"
4. Remplissez le formulaire
5. Vérifiez que la connexion fonctionne

---

**Phase 1 complète ! 🎉**

Passez à la Phase 2 quand vous êtes prêt.
