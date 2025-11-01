# Chiasma - Plateforme de Gestion des Mutations et Recrutement

Application Flutter pour la gestion des mutations d'enseignants et le recrutement scolaire en Côte d'Ivoire.

## 🎯 Fonctionnalités Principales

### Pour les Enseignants (Permutation)
- Recherche de partenaires de permutation
- Messagerie intégrée
- Gestion des favoris
- Système de quotas: 5 consultations gratuites

### Pour les Candidats
- Consultation des offres d'emploi
- Soumission de candidatures
- Suivi des candidatures
- Système de quotas: 2 candidatures gratuites

### Pour les Écoles
- Publication d'offres d'emploi
- Consultation des candidats
- Gestion des candidatures reçues
- Système de quotas: 1 offre gratuite

## 🔒 Système d'Abonnement

- **Quotas gratuits** pour tous les nouveaux utilisateurs
- **Vérification par admin** après paiement
- **Abonnements** avec durées personnalisables (1 semaine à 12 mois)
- **Contrôle d'accès** automatique basé sur quota et vérification

## 🛠️ Technologies

- **Framework**: Flutter
- **Backend**: Firebase (Firestore, Auth, Storage)
- **État**: StreamBuilder pour réactivité temps réel
- **Paiement**: WhatsApp + Vérification manuelle admin

## 📚 Documentation

Consultez le dossier [`docs/`](docs/) pour:
- Guides d'administration
- Structure Firebase
- Règles Firestore
- Rapports d'audit
- Guides de production

## 🚀 Démarrage Rapide

```bash
# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run

# Build pour production
flutter build apk
```

## 📋 Guides Importants

- [Guide Admin](ADMIN_GUIDE.md) - Administration de la plateforme
- [Système d'Abonnement](SUBSCRIPTION_SYSTEM_GUIDE.md) - Gestion des abonnements
- [Structure Firebase](FIREBASE_STRUCTURE.md) - Architecture de la base de données
- [Règles Firestore](FIRESTORE_RULES_GUIDE.md) - Sécurité et permissions
- [Production](PRODUCTION_READINESS_CHECKLIST.md) - Checklist de déploiement

## 🔐 Sécurité

- Authentification Firebase
- Règles Firestore strictes
- Vérification admin obligatoire
- Contrôle d'accès multi-niveaux
- Transactions atomiques pour quotas

## 📱 Types de Comptes

1. **teacher_transfer** - Enseignants cherchant permutation
2. **teacher_candidate** - Candidats cherchant emploi
3. **school** - Établissements recruteurs
4. **admin** - Administrateurs de la plateforme

## 💳 Tarifs

### Permutation
- 1 mois: 500 F
- 3 mois: 1 500 F
- 12 mois: 2 500 F

### Candidat
- 1 semaine: 500 F
- 1 mois: 1 500 F
- 12 mois: 20 000 F

### École
- 1 semaine: 2 000 F
- 1 mois: 5 000 F
- 12 mois: 90 000 F

## 📞 Support

Contact: WhatsApp (configuré dans l'app)

## 📄 Licence

Propriétaire - Chiasma © 2025
