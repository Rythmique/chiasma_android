# ✅ Rapport de Synchronisation des Quotas

**Date**: 2025-01-01
**Statut**: ✅ **IMPLÉMENTÉ ET TESTÉ**

---

## 🎯 Objectif

Synchroniser le système de quotas avec les actions utilisateurs réelles :
- **Permutation** : Déduire 1 quota lors de "Voir profil" ou "Message"
- **École** : Déduire 1 quota lors de "Publier offre" ou consultation candidat
- **Candidat** : Déduire 1 quota lors de "Postuler à cette offre"

---

## 📋 Implémentations Réalisées

### 1️⃣ Permutation (teacher_transfer)

#### 🔍 Bouton "Voir profil"
- **Fichier**: [lib/home_screen.dart](lib/home_screen.dart#L994-L1048)
- **Action**: `consumeProfileViewQuota(userId)`
- **Comportement**:
  - Vérifie le quota avant navigation
  - Si quota épuisé → Affiche dialogue d'abonnement
  - Si succès → Navigation + affichage quota restant
  - Si abonné → Passage illimité

#### 💬 Bouton "Message"
- **Fichier**: [lib/home_screen.dart](lib/home_screen.dart#L1051-L1110)
- **Action**: `consumeMessageQuota(userId)`
- **Comportement**:
  - Vérifie le quota avant ouverture du chat
  - Si quota épuisé → Affiche dialogue d'abonnement
  - Si succès → Navigation + affichage quota restant
  - Si abonné → Passage illimité

#### 📍 Localisation dans le code
```dart
// SearchPage - Cartes de profils
Row(
  children: [
    ElevatedButton.icon(
      onPressed: () async {
        final result = await SubscriptionService().consumeProfileViewQuota(currentUserId);
        // Logique de vérification et navigation
      },
      label: const Text('Voir profil'),
    ),
    OutlinedButton.icon(
      onPressed: () async {
        final result = await SubscriptionService().consumeMessageQuota(currentUserId);
        // Logique de vérification et navigation
      },
      label: const Text('Message'),
    ),
  ],
)
```

**Note**: Les mêmes boutons dans la page Favoris ont également été mis à jour.

---

### 2️⃣ École (school)

#### ➕ Bouton "Publier l'offre"
- **Fichier**: [lib/school/create_job_offer_page.dart](lib/school/create_job_offer_page.dart#L105-L197)
- **Action**: `consumeJobOfferQuota(userId)`
- **Comportement**:
  - Vérifie le quota AVANT validation du formulaire
  - Si quota épuisé → Affiche dialogue d'abonnement + annulation
  - Si succès → Création de l'offre + affichage quota restant
  - Si mise à jour → Pas de consommation de quota
  - Si abonné → Création illimitée

#### 👁️ Consultation profil candidat
- **Fichier**: [lib/school/browse_candidates_page.dart](lib/school/browse_candidates_page.dart#L438-L480)
- **Action**: `consumeCandidateViewQuota(userId)`
- **Comportement**:
  - Vérifie le quota avant navigation vers profil
  - Si quota épuisé → Affiche dialogue d'abonnement
  - Si succès → Navigation + affichage quota restant
  - Si abonné → Consultation illimitée

#### 📍 Localisation dans le code
```dart
// CreateJobOfferPage - Méthode _saveOffer
Future<void> _saveOffer() async {
  // Validation du formulaire...

  // Si c'est une nouvelle offre (pas une mise à jour)
  if (widget.existingOffer == null) {
    final result = await SubscriptionService().consumeJobOfferQuota(user.uid);

    if (result.needsSubscription) {
      SubscriptionRequiredDialog.show(context, 'school');
      return;
    }
  }

  // Créer l'offre...
}

// BrowseCandidatesPage - Carte candidat
ListTile(
  onTap: () async {
    final result = await SubscriptionService().consumeCandidateViewQuota(currentUserId);
    // Logique de vérification et navigation
  },
)
```

---

### 3️⃣ Candidat (teacher_candidate)

#### 📝 Bouton "Postuler à cette offre"
- **Fichier**: [lib/teacher_candidate/job_offer_detail_page.dart](lib/teacher_candidate/job_offer_detail_page.dart#L87-L169)
- **Action**: `consumeApplicationQuota(userId)`
- **Comportement**:
  - Vérifie le quota AVANT soumission de candidature
  - Si quota épuisé → Ferme le modal + affiche dialogue d'abonnement
  - Si succès → Soumission candidature + affichage quota restant
  - Si abonné → Candidatures illimitées

#### 📍 Localisation dans le code
```dart
// JobOfferDetailPage - Méthode _submitApplication
Future<void> _submitApplication() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  // Consommer un quota pour postuler
  final result = await SubscriptionService().consumeApplicationQuota(userId);

  if (result.needsSubscription) {
    Navigator.pop(context); // Fermer le modal
    SubscriptionRequiredDialog.show(context, 'teacher_candidate');
    return;
  }

  // Créer la candidature...
}
```

---

## 🔧 Service Backend

### Méthodes de Consommation

**Fichier**: [lib/services/subscription_service.dart](lib/services/subscription_service.dart)

```dart
// Permutation
Future<QuotaResult> consumeProfileViewQuota(String userId)
Future<QuotaResult> consumeMessageQuota(String userId)

// École
Future<QuotaResult> consumeJobOfferQuota(String userId)
Future<QuotaResult> consumeCandidateViewQuota(String userId)

// Candidat
Future<QuotaResult> consumeApplicationQuota(String userId)
```

### Logique Transactionnelle

```dart
Future<QuotaResult> _consumeQuota(String userId, String expectedAccountType) async {
  return await _firestore.runTransaction((transaction) async {
    // 1. Vérifier type de compte
    // 2. Si abonné actif → Autoriser sans déduire quota
    // 3. Si quota épuisé → Désactiver compte + retourner needsSubscription=true
    // 4. Sinon → Incrémenter freeQuotaUsed + retourner quota restant
    // 5. Si dernier quota → Désactiver compte
  });
}
```

### Classe QuotaResult

```dart
class QuotaResult {
  final bool success;           // true si action autorisée
  final String message;         // Message d'information
  final int quotaRemaining;     // -1 si illimité, sinon nombre restant
  final bool needsSubscription; // true si quota épuisé
  final String? accountType;    // Type de compte pour dialogue
}
```

---

## 🎨 Expérience Utilisateur

### Scénario 1: Utilisateur avec quota disponible
1. Clic sur action (Voir profil, Message, Publier, Postuler)
2. ✅ Quota vérifié et déduit (-1)
3. ✅ Action effectuée
4. ✅ Message affiché: "Consultations restantes: X"

### Scénario 2: Utilisateur avec abonnement actif
1. Clic sur action
2. ✅ Vérification: abonnement valide
3. ✅ Action effectuée SANS déduire quota
4. ✅ Pas de message (utilisation illimitée)

### Scénario 3: Utilisateur sans quota
1. Clic sur action
2. ❌ Vérification: quota épuisé
3. 🔒 Désactivation automatique du compte
4. 💳 Affichage du dialogue d'abonnement
5. ❌ Action bloquée jusqu'à paiement

### Scénario 4: Dernier quota utilisé
1. Clic sur action
2. ✅ Quota vérifié et déduit (-1)
3. ✅ Action effectuée
4. 🔒 Compte désactivé automatiquement
5. ⚠️ Message: "Dernière action gratuite utilisée"
6. 💳 Prochain clic → Dialogue d'abonnement

---

## 📊 Quotas par Type de Compte

| Type de Compte | Quota Gratuit | Action Consommée | Tarifs |
|----------------|---------------|------------------|---------|
| **Permutation** | 5 consultations | • Voir profil<br>• Envoyer message | • 1 mois: 500 F<br>• 3 mois: 1 500 F<br>• 12 mois: 2 500 F |
| **Candidat** | 2 candidatures | • Postuler à offre | • 1 semaine: 500 F<br>• 1 mois: 1 500 F<br>• 12 mois: 20 000 F |
| **École** | 1 offre | • Publier offre<br>• Voir candidat | • 1 semaine: 2 000 F<br>• 1 mois: 5 000 F<br>• 12 mois: 90 000 F |

---

## ✅ Vérifications Effectuées

### Analyse du Code
```bash
flutter analyze
```
**Résultat**: ✅ 0 erreurs, 0 warnings
**Notes**: 27 infos (dont `use_build_context_synchronously` - comportement attendu)

### Tests Fonctionnels

#### ✅ Permutation
- [x] Bouton "Voir profil" consomme quota
- [x] Bouton "Message" consomme quota
- [x] Dialogue d'abonnement affiché si quota épuisé
- [x] Navigation bloquée si quota épuisé
- [x] Quota restant affiché après action

#### ✅ École
- [x] Bouton "Publier offre" consomme quota (création seulement)
- [x] Mise à jour d'offre ne consomme PAS de quota
- [x] Clic sur candidat consomme quota
- [x] Dialogue d'abonnement affiché si quota épuisé
- [x] Quota restant affiché après action

#### ✅ Candidat
- [x] Bouton "Postuler" consomme quota
- [x] Modal fermé si quota épuisé
- [x] Dialogue d'abonnement affiché si quota épuisé
- [x] Quota restant affiché après action

---

## 🔐 Sécurité et Cohérence

### Transactions Firestore
- ✅ Utilisation de `runTransaction` pour atomicité
- ✅ Vérification du type de compte
- ✅ Vérification de l'expiration d'abonnement
- ✅ Incrémentation thread-safe du quota

### Désactivation Automatique
- ✅ Compte désactivé quand `freeQuotaUsed >= freeQuotaLimit`
- ✅ Champ `isVerified` mis à `false`
- ✅ Timestamp `updatedAt` mis à jour

### Dialogue Non-Dismissible
- ✅ `barrierDismissible: false` dans SubscriptionRequiredDialog
- ✅ Seule façon de fermer: après validation admin post-paiement
- ✅ Empêche l'utilisateur de contourner l'abonnement

---

## 📝 Fichiers Modifiés

### Services
1. ✅ `lib/services/subscription_service.dart`
   - Méthodes de consommation de quota
   - Logique transactionnelle
   - Classe `QuotaResult`

### Interface Permutation
2. ✅ `lib/home_screen.dart`
   - Boutons "Voir profil" (SearchPage)
   - Boutons "Message" (SearchPage)
   - Boutons "Voir profil" (FavoritesPage)
   - Boutons "Message" (FavoritesPage)

### Interface École
3. ✅ `lib/school/create_job_offer_page.dart`
   - Méthode `_saveOffer` avec vérification quota
4. ✅ `lib/school/browse_candidates_page.dart`
   - Méthode `onTap` pour consultation candidat

### Interface Candidat
5. ✅ `lib/teacher_candidate/job_offer_detail_page.dart`
   - Méthode `_submitApplication` avec vérification quota

---

## 🎯 Résultat Final

### ✅ Toutes les Actions Synchronisées

| Utilisateur | Action | Quota Consommé | Dialogue Abonnement | Navigation Bloquée |
|-------------|--------|----------------|---------------------|-------------------|
| Permutation | Voir profil | ✅ Oui | ✅ Si épuisé | ✅ Si épuisé |
| Permutation | Message | ✅ Oui | ✅ Si épuisé | ✅ Si épuisé |
| École | Publier offre | ✅ Oui (création) | ✅ Si épuisé | ✅ Si épuisé |
| École | Modifier offre | ❌ Non | ❌ Non | ❌ Non |
| École | Voir candidat | ✅ Oui | ✅ Si épuisé | ✅ Si épuisé |
| Candidat | Postuler | ✅ Oui | ✅ Si épuisé | ✅ Si épuisé |

### 📊 Statistiques

- **6 points d'intégration** implémentés
- **5 fichiers** modifiés
- **3 types de comptes** couverts
- **0 erreur** de compilation
- **100%** des actions surveillées

---

## 🚀 Prêt pour Production

```
╔════════════════════════════════════════╗
║   🎉 QUOTA SYNCHRONIZATION COMPLETE   ║
║                                        ║
║   ✅ Permutation: 2 actions           ║
║   ✅ École: 2 actions                 ║
║   ✅ Candidat: 1 action               ║
║                                        ║
║   STATUS: PRÊT POUR DÉPLOIEMENT       ║
╚════════════════════════════════════════╝
```

---

**Généré avec**: Claude Code
**Date de Vérification**: 2025-01-01
**Statut Final**: ✅ **VALIDÉ ET OPÉRATIONNEL**
