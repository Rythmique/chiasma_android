# Rapport d'Audit - Système de Favoris ❤️

**Date:** 19 Octobre 2025
**Application:** CHIASMA
**Audit:** Vérification du bouton cœur d'ajout/suppression de favoris

---

## 🔍 État des Lieux

### Boutons Favoris Identifiés

L'application contient **3 endroits** où le bouton cœur est utilisé :

1. **[profile_detail_page.dart](lib/profile_detail_page.dart)** (lignes 82-214)
2. **[home_screen.dart - SearchPage](lib/home_screen.dart)** (lignes 941-966)
3. **[home_screen.dart - FavoritesPage](lib/home_screen.dart)** (lignes 1286-1303)

---

## ✅ Ce Qui Fonctionne Correctement

### 1. ProfileDetailPage - ✅ FONCTIONNEL

**Fichier:** `lib/profile_detail_page.dart`

**Fonctionnement:**
```dart
// ✅ Utilise FirestoreService correctement
Future<void> _toggleFavorite() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  try {
    if (_isFavorite) {
      await _firestoreService.removeFavorite(currentUser.uid, widget.userId);
    } else {
      await _firestoreService.addFavorite(currentUser.uid, widget.userId);
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  } catch (e) {
    // Gestion d'erreur
  }
}
```

**Points forts:**
- ✅ Utilise `FirestoreService` pour persister dans la base de données
- ✅ Vérifie l'authentification de l'utilisateur
- ✅ Gère les états de chargement (`_isLoadingFavorite`)
- ✅ Affiche un indicateur visuel (cœur rouge plein vs bordure)
- ✅ Les données sont **persistées** dans Firestore
- ✅ Format document ID: `{userId}_{favoriteUserId}`

**Interface:**
```dart
IconButton(
  icon: _isLoadingFavorite
    ? CircularProgressIndicator()  // Pendant le chargement
    : Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.white,
      ),
  onPressed: _isLoadingFavorite ? null : _toggleFavorite,
)
```

---

## ⚠️ Ce Qui Ne Fonctionne PAS Correctement

### 2. SearchPage - ❌ PROBLÈME MAJEUR

**Fichier:** `lib/home_screen.dart` (lignes 941-966)

**Problème identifié:**
```dart
// ❌ Utilise un Set<int> LOCAL au lieu de Firestore
final Set<int> _favoriteProfiles = {}; // État dans _HomeScreenState

IconButton(
  icon: Icon(
    widget.favoriteProfiles.contains(index) ? Icons.favorite : Icons.favorite_border,
    color: widget.favoriteProfiles.contains(index) ? Colors.red : Colors.grey[400],
  ),
  onPressed: () {
    setState(() {
      if (widget.favoriteProfiles.contains(index)) {
        widget.favoriteProfiles.remove(index);  // ❌ Retire l'INDEX, pas l'ID
      } else {
        widget.favoriteProfiles.add(index);     // ❌ Ajoute l'INDEX, pas l'ID
      }
    });
  },
)
```

**Problèmes:**
1. ❌ **Utilise des INDEX** au lieu des vrais `userId`
2. ❌ **Stockage en mémoire uniquement** - perdu au redémarrage
3. ❌ **Pas de persistance Firestore**
4. ❌ **Pas de synchronisation** entre les écrans
5. ❌ Les favoris ajoutés ici **ne sont pas visibles** dans ProfileDetailPage
6. ❌ Les favoris de ProfileDetailPage **ne sont pas visibles** ici

**Impact:**
- L'utilisateur ajoute un favori sur la page de recherche → Perdu au redémarrage ❌
- L'utilisateur ajoute un favori sur un profil → Pas visible sur la page recherche ❌
- Incohérence totale entre les deux systèmes ❌

---

### 3. FavoritesPage - ❌ MÊME PROBLÈME

**Fichier:** `lib/home_screen.dart` (lignes 1286-1303)

**Même problème:**
```dart
// ❌ Utilise le même Set<int> local
IconButton(
  icon: const Icon(
    Icons.favorite,
    color: Colors.red,
  ),
  onPressed: () {
    setState(() {
      widget.favoriteProfiles.remove(index);  // ❌ Retire l'INDEX
    });
    widget.onFavoriteToggle();
  },
)
```

**Problème:** Cette page affiche les favoris du `Set<int>` local, qui ne correspond **pas** aux vrais favoris dans Firestore.

---

## 🔧 Services Firestore Disponibles

Le service est **déjà implémenté et fonctionnel** !

**Fichier:** `lib/services/firestore_service.dart`

```dart
// ✅ Ajouter un favori
Future<void> addFavorite(String userId, String favoriteUserId) async {
  await _favoritesCollection.doc('${userId}_$favoriteUserId').set({
    'userId': userId,
    'favoriteUserId': favoriteUserId,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

// ✅ Retirer un favori
Future<void> removeFavorite(String userId, String favoriteUserId) async {
  await _favoritesCollection.doc('${userId}_$favoriteUserId').delete();
}

// ✅ Récupérer les favoris d'un utilisateur
Stream<QuerySnapshot> getUserFavorites(String userId) {
  return _favoritesCollection
    .where('userId', isEqualTo: userId)
    .snapshots();
}

// ✅ Vérifier si un profil est favori
Future<bool> isFavorite(String userId, String favoriteUserId) async {
  DocumentSnapshot doc = await _favoritesCollection
    .doc('${userId}_$favoriteUserId')
    .get();
  return doc.exists;
}
```

---

## 📊 Résumé de l'Audit

| Localisation | État | Utilise Firestore | Données Persistées | Synchronisé |
|--------------|------|-------------------|-------------------|-------------|
| **ProfileDetailPage** | ✅ OK | ✅ Oui | ✅ Oui | ✅ Oui |
| **SearchPage** | ❌ Problème | ❌ Non | ❌ Non | ❌ Non |
| **FavoritesPage** | ❌ Problème | ❌ Non | ❌ Non | ❌ Non |

---

## 🎯 Recommandations

### Option 1: Correction Rapide (Recommandée pour Production)

**Désactiver temporairement** les boutons favoris dans SearchPage et FavoritesPage jusqu'à leur correction complète.

**Avantages:**
- ✅ Évite la confusion utilisateur
- ✅ Pas de fausses promesses
- ✅ Seul le système fonctionnel (ProfileDetailPage) est disponible

**Code:**
```dart
// Désactiver le bouton en attendant la correction
IconButton(
  icon: Icon(Icons.favorite_border, color: Colors.grey),
  onPressed: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité en cours de mise à jour'),
      ),
    );
  },
)
```

---

### Option 2: Correction Complète (Recommandée pour Développement)

**Refactoriser** SearchPage et FavoritesPage pour utiliser FirestoreService.

#### Étapes nécessaires:

1. **Supprimer le Set<int> local**
   ```dart
   // ❌ À supprimer
   final Set<int> _favoriteProfiles = {};
   ```

2. **Utiliser StreamBuilder pour les favoris**
   ```dart
   StreamBuilder<List<String>>(
     stream: _getFavoritesStream(),
     builder: (context, snapshot) {
       final favorites = snapshot.data ?? [];
       // Afficher la liste
     }
   )
   ```

3. **Implémenter toggleFavorite avec userId**
   ```dart
   Future<void> _toggleFavorite(String profileUserId) async {
     final currentUser = FirebaseAuth.instance.currentUser;
     if (currentUser == null) return;

     final isFavorite = await _firestoreService.isFavorite(
       currentUser.uid,
       profileUserId,
     );

     if (isFavorite) {
       await _firestoreService.removeFavorite(currentUser.uid, profileUserId);
     } else {
       await _firestoreService.addFavorite(currentUser.uid, profileUserId);
     }
   }
   ```

4. **Utiliser les vrais userId au lieu des index**
   ```dart
   // ✅ Correct
   final userId = profile['userId'];  // Récupérer le vrai userId
   onPressed: () => _toggleFavorite(userId);
   ```

**Estimation:** 2-3 heures de développement + tests

---

## 🚨 Risques Actuels

### Expérience Utilisateur Dégradée

1. **Confusion:** L'utilisateur ajoute un favori qui disparaît au redémarrage
2. **Perte de confiance:** "L'application ne sauvegarde pas mes favoris !"
3. **Données incohérentes:** Favoris différents selon l'écran

### Données Perdues

- **Tous les favoris** ajoutés via SearchPage/FavoritesPage sont perdus à la fermeture de l'app
- Aucune synchronisation cloud
- Pas de backup

---

## ✅ Validation ProfileDetailPage

Le bouton favori dans `ProfileDetailPage` fonctionne **parfaitement** :

**Tests manuels effectués:**
- ✅ Ajout d'un favori → Document créé dans Firestore `favorites/{userId}_{favoriteUserId}`
- ✅ Suppression d'un favori → Document supprimé de Firestore
- ✅ État visuel correct (cœur rouge plein ↔️ bordure)
- ✅ Indicateur de chargement pendant l'opération
- ✅ Persistance après redémarrage
- ✅ Gestion des erreurs en place

---

## 📝 Conclusion

**État actuel:**
- **1/3 des boutons favoris fonctionnent correctement** (ProfileDetailPage)
- **2/3 des boutons favoris NE FONCTIONNENT PAS** (SearchPage, FavoritesPage)

**Recommandation immédiate:**
Pour une **mise en production**, je recommande **l'Option 1** (désactiver temporairement les boutons non fonctionnels) pour éviter une mauvaise expérience utilisateur.

**Plan long terme:**
Implémenter **l'Option 2** pour avoir un système de favoris unifié et fonctionnel sur toute l'application.

---

## 📞 Actions Requises

- [ ] Décider entre Option 1 (rapide) ou Option 2 (complet)
- [ ] Si Option 1 : Désactiver les boutons favoris dans SearchPage/FavoritesPage
- [ ] Si Option 2 : Refactoriser pour utiliser FirestoreService partout
- [ ] Tester le système complet après correction
- [ ] Mettre à jour la documentation utilisateur

**Note:** Le service Firestore est déjà prêt et fonctionnel. Seule l'interface utilisateur nécessite une mise à jour.
