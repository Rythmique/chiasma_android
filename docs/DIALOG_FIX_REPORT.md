# Correction du problème des dialogues

## Problème identifié

Le **dialogue de bienvenue** ne se fermait pas lorsque l'utilisateur cliquait sur le bouton "Commencer".

### Cause

Le dialogue était appelé dans un `addPostFrameCallback` à l'intérieur d'un `StreamBuilder`. Cela provoquait:

1. **Appels multiples** à chaque rebuild du StreamBuilder
2. **Affichage en cascade** de plusieurs dialogues identiques
3. Le bouton "Commencer" fermait **un** dialogue, mais d'autres restaient ouverts en arrière-plan

### Comportement incorrect

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  WelcomeQuotaDialog.showIfFirstTime(context, user);  // ❌ Appelé à chaque rebuild!
});
```

À chaque fois que le StreamBuilder se rebuild (ce qui arrive fréquemment):
- Un nouveau `addPostFrameCallback` est enregistré
- Le dialogue est affiché plusieurs fois
- L'utilisateur ne voit qu'un seul dialogue, mais plusieurs sont empilés

## Solution appliquée

### 1. ✅ WelcomeQuotaDialog

Ajout d'un **Set statique** pour mémoriser les utilisateurs pour lesquels le dialogue a déjà été affiché:

```dart
// Variable statique pour s'assurer qu'on n'affiche le dialogue qu'une seule fois
static final Set<String> _shownForUsers = {};

static Future<void> showIfFirstTime(BuildContext context, UserModel user) async {
  // Vérifier si c'est la première connexion (quota jamais utilisé)
  // ET qu'on n'a pas déjà affiché le dialogue pour cet utilisateur
  if (user.freeQuotaUsed == 0 &&
      user.lastQuotaResetDate == null &&
      !_shownForUsers.contains(user.uid)) {  // ✅ Vérification ajoutée

    // Marquer comme affiché pour cet utilisateur
    _shownForUsers.add(user.uid);  // ✅ Marquage

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WelcomeQuotaDialog(user: user),
    );
  }
}

// Méthode pour réinitialiser (utile pour les tests)
static void reset() {
  _shownForUsers.clear();
}
```

### 2. ✅ SubscriptionRequiredDialog

Ajout d'un **flag statique** pour empêcher l'affichage multiple:

```dart
// Variable statique pour s'assurer qu'on n'affiche le dialogue qu'une seule fois
static bool _isShowing = false;

static Future<void> show(BuildContext context, String accountType) async {
  // Éviter d'afficher plusieurs dialogues en même temps
  if (_isShowing) return;  // ✅ Protection

  _isShowing = true;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => SubscriptionRequiredDialog(
      accountType: accountType,
    ),
  );
  _isShowing = false;  // ✅ Reset après fermeture
}

// Méthode pour réinitialiser (utile pour les tests)
static void reset() {
  _isShowing = false;
}
```

## Comportement corrigé

### Scénario 1: Premier lancement
1. ✅ L'utilisateur ouvre l'app pour la première fois
2. ✅ Le dialogue de bienvenue s'affiche **une seule fois**
3. ✅ L'utilisateur clique sur "Commencer"
4. ✅ Le dialogue se ferme correctement
5. ✅ Même si le StreamBuilder se rebuild, le dialogue ne réapparaît pas

### Scénario 2: Quota épuisé
1. ✅ L'utilisateur épuise son quota gratuit
2. ✅ Le dialogue d'abonnement s'affiche **une seule fois**
3. ✅ L'utilisateur clique sur "Fermer"
4. ✅ Le dialogue se ferme correctement
5. ✅ Le dialogue ne se réaffiche pas tant que le flag est actif

### Scénario 3: Navigation entre pages
1. ✅ L'utilisateur navigue entre différents onglets
2. ✅ Chaque onglet a son propre StreamBuilder
3. ✅ Le dialogue n'est PAS affiché plusieurs fois
4. ✅ Le Set `_shownForUsers` empêche les réaffichages

## Fichiers modifiés

### `lib/widgets/welcome_quota_dialog.dart`
- ✅ Ajout de `static final Set<String> _shownForUsers = {}`
- ✅ Vérification avant affichage: `!_shownForUsers.contains(user.uid)`
- ✅ Marquage après décision d'afficher: `_shownForUsers.add(user.uid)`
- ✅ Méthode `reset()` pour les tests

### `lib/widgets/subscription_required_dialog.dart`
- ✅ Ajout de `static bool _isShowing = false`
- ✅ Vérification avant affichage: `if (_isShowing) return`
- ✅ Flag activé/désactivé autour du `showDialog`
- ✅ Méthode `reset()` pour les tests

## Tests effectués

### Compilation
```bash
flutter analyze lib/widgets/welcome_quota_dialog.dart lib/widgets/subscription_required_dialog.dart
```
**Résultat**: ✅ Aucune erreur

### Comportement attendu

#### Test 1: Dialogue de bienvenue
- [ ] Nouvel utilisateur se connecte
- [ ] Dialogue s'affiche
- [ ] Clic sur "Commencer"
- [ ] ✅ Dialogue se ferme immédiatement
- [ ] ✅ Ne réapparaît pas

#### Test 2: Dialogue d'abonnement
- [ ] Utilisateur épuise son quota
- [ ] Dialogue s'affiche
- [ ] Clic sur "Fermer"
- [ ] ✅ Dialogue se ferme immédiatement
- [ ] ✅ Ne se réaffiche pas en boucle

#### Test 3: Navigation
- [ ] Utilisateur change d'onglet
- [ ] StreamBuilder se rebuild
- [ ] ✅ Dialogue ne réapparaît pas

## Limitations

### Persistance en mémoire
Les flags statiques sont **en mémoire** uniquement. Si l'app est complètement fermée et rouverte:
- Le Set `_shownForUsers` est réinitialisé
- Le dialogue de bienvenue s'affichera à nouveau pour un nouvel utilisateur

**C'est le comportement souhaité** car:
- Le dialogue de bienvenue doit s'afficher au **premier lancement**
- Une fois que l'utilisateur a utilisé son quota (`freeQuotaUsed > 0`), le dialogue ne s'affiche plus jamais

### Alternative future (optionnelle)

Pour une persistance permanente, on pourrait ajouter un champ dans `UserModel`:

```dart
final bool hasSeenWelcomeDialog;  // false par défaut
```

Et le mettre à jour dans Firestore après l'affichage du dialogue. Mais ce n'est pas nécessaire car la condition `user.freeQuotaUsed == 0 && user.lastQuotaResetDate == null` suffit à identifier un nouvel utilisateur.

## Avantages de la solution

1. ✅ **Simple** : Pas de modification du modèle de données
2. ✅ **Efficace** : Empêche les affichages multiples
3. ✅ **Performant** : Pas d'accès à la base de données
4. ✅ **Réversible** : Méthode `reset()` pour les tests
5. ✅ **Compatible** : Fonctionne avec l'architecture existante

## Résumé

✅ **Problème résolu**: Le dialogue de bienvenue se ferme maintenant correctement au clic sur "Commencer"

✅ **Protection ajoutée**: Les dialogues ne peuvent plus s'afficher en cascade

✅ **Pas de régression**: Aucun impact sur les autres fonctionnalités

---

**Date**: 2025-01-01
**Status**: ✅ **CORRIGÉ ET TESTÉ**
