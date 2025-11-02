# Tarifs et Liens de Paiement - Chiasma

**Date**: 2025-01-01
**Statut**: En attente des liens de paiement

---

## 📋 Structure des Tarifs

### 1. Permutation (teacher_transfer)

| Durée | Prix | Lien de paiement |
|-------|------|------------------|
| 1 mois | 500 F | ⏳ À fournir |
| 3 mois | 1 500 F | ⏳ À fournir |
| 12 mois | 2 500 F | ⏳ À fournir |

**Quota gratuit**: 5 consultations

---

### 2. Candidat (teacher_candidate)

| Durée | Prix | Lien de paiement |
|-------|------|------------------|
| 1 semaine | 500 F | ⏳ À fournir |
| 1 mois | 1 500 F | ⏳ À fournir |
| 12 mois | 20 000 F | ⏳ À fournir |

**Quota gratuit**: 2 candidatures

---

### 3. École (school)

| Durée | Prix | Lien de paiement |
|-------|------|------------------|
| 1 semaine | 2 000 F | ⏳ À fournir |
| 1 mois | 5 000 F | ⏳ À fournir |
| 12 mois | 90 000 F | ⏳ À fournir |

**Quota gratuit**: 1 offre

---

## 🔧 Comment Configurer les Liens

### Étape 1: Fournir les liens
Fournissez les liens de paiement pour chaque tarif ci-dessus.

### Étape 2: Mise à jour du code
Les liens seront ajoutés dans le fichier:
```
lib/widgets/subscription_required_dialog.dart
```

Dans la section `_paymentLinks` (lignes 15-31):

```dart
static final Map<String, Map<String, String>> _paymentLinks = {
  'teacher_transfer': {
    '1_month': 'VOTRE_LIEN_ICI',    // 500 F
    '3_months': 'VOTRE_LIEN_ICI',   // 1 500 F
    '12_months': 'VOTRE_LIEN_ICI',  // 2 500 F
  },
  'teacher_candidate': {
    '1_week': 'VOTRE_LIEN_ICI',     // 500 F
    '1_month': 'VOTRE_LIEN_ICI',    // 1 500 F
    '12_months': 'VOTRE_LIEN_ICI',  // 20 000 F
  },
  'school': {
    '1_week': 'VOTRE_LIEN_ICI',     // 2 000 F
    '1_month': 'VOTRE_LIEN_ICI',    // 5 000 F
    '12_months': 'VOTRE_LIEN_ICI',  // 90 000 F
  },
};
```

---

## 💡 Comportement de l'Interface

### Avec lien de paiement configuré:
- ✅ Le bouton est actif (orange vif)
- ✅ Message: "Cliquez pour payer via le lien sécurisé"
- ✅ Clic ouvre le lien de paiement externe

### Sans lien de paiement:
- ⚠️ Le bouton est désactivé (gris)
- ⚠️ Message: "Contactez-nous via WhatsApp pour ce tarif"
- ⚠️ L'utilisateur doit passer par WhatsApp

---

## 📱 Fonctionnalités Implémentées

### ✅ Dialogue d'Abonnement Amélioré

1. **Boutons de prix dynamiques**
   - Un bouton par durée/prix
   - Adapté au type de compte
   - Design moderne et professionnel

2. **Liens de paiement**
   - Sous chaque bouton de prix
   - Cliquables si configurés
   - Ouvre le navigateur externe

3. **Dialogue dismissible**
   - ✅ Peut être fermé en cliquant à l'extérieur
   - ✅ Bouton "Fermer" explicite
   - ✅ Les actions restent bloquées jusqu'à vérification

4. **Contact WhatsApp**
   - Numéro affiché: +225 0758747888
   - Bouton copier le numéro
   - Bouton direct vers WhatsApp

### ✅ Accès Visuel Non Bloqué

- ✅ Utilisateurs voient l'interface normalement
- ✅ Pas de blocage visuel total
- ✅ Actions bloquées individuellement
- ✅ Dialogue affiché lors du clic sur action bloquée

---

## 🎨 Aperçu de l'Interface

### Structure du Dialogue:
```
┌─────────────────────────────────┐
│      [Icône Abonnement]         │
│                                 │
│    Abonnement requis            │
│    Votre quota est épuisé...    │
│                                 │
│  [🕐 1 mois        500 F]       │
│  Cliquez pour payer...          │
│                                 │
│  [🕐 3 mois      1 500 F]       │
│  Cliquez pour payer...          │
│                                 │
│  [🕐 12 mois     2 500 F]       │
│  Cliquez pour payer...          │
│                                 │
│  ─────────────────────────      │
│                                 │
│  ℹ️ Besoin d'aide ?             │
│  📱 +225 0758747888 [Copier]    │
│  [💬 Contacter via WhatsApp]    │
│                                 │
│  [Fermer]                       │
└─────────────────────────────────┘
```

---

## 📝 Prochaines Étapes

1. ⏳ **Vous**: Fournir les 9 liens de paiement
2. ⏳ **Claude**: Mettre à jour le fichier avec les liens
3. ✅ **Test**: Vérifier que les liens s'ouvrent correctement
4. ✅ **Déploiement**: Build et distribution

---

## 💬 Format Attendu pour les Liens

Veuillez fournir les liens sous ce format:

```
PERMUTATION:
- 1 mois (500 F): https://...
- 3 mois (1 500 F): https://...
- 12 mois (2 500 F): https://...

CANDIDAT:
- 1 semaine (500 F): https://...
- 1 mois (1 500 F): https://...
- 12 mois (20 000 F): https://...

ÉCOLE:
- 1 semaine (2 000 F): https://...
- 1 mois (5 000 F): https://...
- 12 mois (90 000 F): https://...
```

---

**Généré avec**: Claude Code
**Dernière mise à jour**: 2025-01-01
