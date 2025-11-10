# Diagnostic : Notifications & Version Windows

**Date** : 10 novembre 2025
**Version app** : 1.0.1+2

---

## 🔔 PARTIE 1 : PROBLÈME DES NOTIFICATIONS

### 🔍 Analyse du système actuel

J'ai analysé votre code et identifié **4 PROBLÈMES MAJEURS** qui expliquent pourquoi les notifications ne fonctionnent pas correctement.

---

## ❌ PROBLÈME #1 : Pas de notifications VISUELLES locales

### État actuel

Votre app utilise **Firebase Cloud Messaging (FCM)** pour recevoir les notifications push depuis Firebase, MAIS elle n'affiche **AUCUNE notification visuelle locale** sur l'appareil Android.

### Code problématique

Voir [lib/services/fcm_service.dart:69-79](lib/services/fcm_service.dart:69-79) :

```dart
// Handler pour les notifications quand l'app est au premier plan
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  debugPrint('Message reçu au premier plan: ${message.notification?.title}');

  if (message.notification != null) {
    debugPrint('Titre: ${message.notification!.title}');
    debugPrint('Corps: ${message.notification!.body}');
  }

  // ⚠️ PROBLÈME : Vous pouvez afficher une notification locale ici si nécessaire
  // ou un snackbar/toast
  // → MAIS VOUS NE FAITES RIEN ! ❌
});
```

**Ce qui se passe** :
1. Firebase envoie une notification push
2. Le code la reçoit correctement ✅
3. Le code affiche un message dans les logs (debugPrint) ✅
4. **MAIS** : Aucune notification visible n'est affichée à l'utilisateur ❌
5. L'utilisateur ne voit RIEN, n'entend RIEN ❌

### Conséquence

- ❌ Quand l'app est ouverte (au premier plan) : **AUCUNE notification visuelle/sonore**
- ✅ Quand l'app est fermée/en arrière-plan : Firebase affiche automatiquement une notification système (mais sans customisation)

---

## ❌ PROBLÈME #2 : Package manquant pour les notifications locales

### Diagnostic

Votre `pubspec.yaml` **NE CONTIENT PAS** le package `flutter_local_notifications`.

**Vérification effectuée** :
```bash
grep -n "flutter_local_notifications" /home/user/myapp/pubspec.yaml
# → Résultat : VIDE (package absent)
```

### Pourquoi c'est un problème

Sans `flutter_local_notifications`, vous **NE POUVEZ PAS** :
- Afficher une notification visuelle avec titre, texte, icône
- Jouer un son de notification
- Faire vibrer l'appareil
- Afficher un badge sur l'icône de l'app
- Créer des notifications avec actions (boutons)

### Package manquant

```yaml
dependencies:
  flutter_local_notifications: ^17.2.5  # ← MANQUANT !
```

---

## ❌ PROBLÈME #3 : Permissions manquantes dans AndroidManifest.xml

### Permissions absentes

Votre [AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) ne contient **AUCUNE** permission liée aux notifications.

**Permissions manquantes pour Android 13+ (API 33+)** :

```xml
<!-- MANQUANT : Permission pour afficher les notifications (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- MANQUANT : Permission pour vibrer -->
<uses-permission android:name="android.permission.VIBRATE"/>

<!-- MANQUANT : Permission pour les notifications en plein écran -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>

<!-- MANQUANT : Permission pour réveiller l'appareil -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### Conséquence sur Android 13+

Sur Android 13 et supérieur (API 33+), **les notifications sont BLOQUÉES par défaut** si vous ne demandez pas explicitement la permission `POST_NOTIFICATIONS`.

**Résultat actuel** :
- Android 12 et inférieur : Les notifications FCM fonctionnent quand l'app est fermée
- **Android 13+** : **AUCUNE notification**, même quand l'app est fermée ❌

---

## ❌ PROBLÈME #4 : Configuration manquante pour le canal de notifications

### Canal de notification absent

Android 8+ (API 26+) exige la création d'un **Notification Channel** avant d'afficher des notifications.

**Votre code actuel** : AUCUN canal créé ❌

### Ce qui est nécessaire

```dart
// Créer un canal de notification (Android 8+)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // ID
  'Notifications importantes', // Nom
  description: 'Ce canal est utilisé pour les notifications importantes',
  importance: Importance.high, // Importance élevée
  playSound: true, // Jouer un son ✅
  enableVibration: true, // Vibrer ✅
  showBadge: true, // Afficher un badge ✅
);
```

Sans canal, **Android refuse d'afficher les notifications**.

---

## 📊 Résumé des problèmes de notifications

| Problème | Impact | Priorité |
|----------|--------|----------|
| **#1 : Pas de notifications locales** | Aucune notification visible quand l'app est ouverte | 🔴 CRITIQUE |
| **#2 : Package manquant** | Impossible d'afficher des notifications visuelles/sonores | 🔴 CRITIQUE |
| **#3 : Permissions manquantes** | Notifications bloquées sur Android 13+ | 🔴 CRITIQUE |
| **#4 : Canal manquant** | Notifications bloquées sur Android 8+ | 🔴 CRITIQUE |

---

## ✅ Ce qui fonctionne actuellement

Malgré ces problèmes, certaines parties fonctionnent :

| Fonctionnalité | État | Explication |
|----------------|------|-------------|
| **FCM initialisé** | ✅ OK | Firebase Cloud Messaging est configuré |
| **Token FCM sauvegardé** | ✅ OK | Le token est enregistré dans Firestore |
| **Notifications Firestore** | ✅ OK | Les notifications sont stockées dans la base de données |
| **Badge de notifications** | ✅ OK | Le badge rouge sur l'icône de la cloche fonctionne |
| **Liste des notifications** | ✅ OK | La page des notifications affiche la liste |
| **Notifications en arrière-plan** | ⚠️ PARTIEL | Fonctionne sur Android 12 et inférieur uniquement |
| **Notifications au premier plan** | ❌ NON | Aucune notification affichée |
| **Son de notification** | ❌ NON | Aucun son joué |
| **Vibration** | ❌ NON | Aucune vibration |

---

## 🛠️ SOLUTION : Ce qu'il faut faire

### Étape 1 : Ajouter le package manquant

Dans `pubspec.yaml` :

```yaml
dependencies:
  flutter_local_notifications: ^17.2.5
```

### Étape 2 : Ajouter les permissions dans AndroidManifest.xml

```xml
<!-- Notifications Android 13+ -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>

<!-- Recevoir les messages FCM en arrière-plan -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### Étape 3 : Modifier FCMService pour afficher des notifications locales

Remplacer le code dans [fcm_service.dart:69-79](lib/services/fcm_service.dart:69-79) :

```dart
// Initialiser flutter_local_notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Handler pour les notifications au premier plan
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  debugPrint('Message reçu au premier plan: ${message.notification?.title}');

  if (message.notification != null) {
    // Afficher une notification locale VISIBLE avec SON et VIBRATION ✅
    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notifications importantes',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true, // SON ✅
          enableVibration: true, // VIBRATION ✅
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
});
```

### Étape 4 : Créer le canal de notifications

Au démarrage de l'app (dans `main.dart` ou `fcm_service.dart`) :

```dart
// Créer le canal de notifications (Android 8+)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notifications importantes',
  description: 'Ce canal est utilisé pour les notifications importantes',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
```

### Étape 5 : Demander la permission sur Android 13+

```dart
// Demander la permission POST_NOTIFICATIONS sur Android 13+
if (Platform.isAndroid) {
  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidImplementation?.requestNotificationsPermission();
}
```

---

## 📱 Comportement après correction

| Scénario | Avant (actuel) | Après (corrigé) |
|----------|----------------|-----------------|
| **Nouveau message reçu (app ouverte)** | ❌ Rien | ✅ Notification + son + vibration |
| **Nouvelle candidature (app fermée)** | ⚠️ Notification système (sans son) | ✅ Notification + son + vibration + badge |
| **Offre d'emploi publiée** | ❌ Rien | ✅ Notification + son |
| **Sur Android 13+** | ❌ Bloqué | ✅ Demande permission + fonctionne |
| **Son de notification** | ❌ Jamais | ✅ Toujours |
| **Vibration** | ❌ Jamais | ✅ Toujours |
| **Badge sur icône** | ⚠️ Partiel | ✅ Toujours |

---

## 🖥️ PARTIE 2 : VERSION WINDOWS (EXE)

### ✅ OUI, C'EST POSSIBLE !

Flutter supporte officiellement **Windows Desktop** depuis la version 3.0. Vous POUVEZ créer un fichier `.exe` pour Windows.

---

## 📋 Prérequis pour créer une version Windows

### 1. Activer le support Windows dans Flutter

```bash
flutter config --enable-windows-desktop
```

### 2. Créer les fichiers Windows

```bash
flutter create --platforms=windows .
```

Cela va créer un dossier `windows/` avec tous les fichiers nécessaires.

### 3. Vérifier les dépendances

Certains de vos packages peuvent ne pas être compatibles avec Windows :

| Package | Compatible Windows ? |
|---------|---------------------|
| `firebase_core` | ✅ OUI |
| `firebase_auth` | ✅ OUI |
| `cloud_firestore` | ✅ OUI |
| `firebase_storage` | ✅ OUI |
| `firebase_messaging` | ❌ **NON** (mobile uniquement) |
| `url_launcher` | ✅ OUI |
| `file_picker` | ✅ OUI |
| `image_picker` | ❌ **NON** (mobile uniquement) |
| `in_app_update` | ❌ **NON** (Android uniquement) |

### 4. Construire l'exe Windows

```bash
flutter build windows --release
```

Le fichier `.exe` sera créé dans :
```
build/windows/x64/runner/Release/myapp.exe
```

---

## ⚠️ Limitations de la version Windows

### Fonctionnalités qui NE FONCTIONNERONT PAS

1. **Notifications push (Firebase Messaging)** ❌
   - `firebase_messaging` n'est pas supporté sur Windows
   - Les notifications push ne fonctionneront pas
   - **Solution** : Utiliser uniquement les notifications Firestore (stockées dans la base de données)

2. **Sélection d'images depuis la caméra** ❌
   - `image_picker` (caméra) n'est pas supporté sur Windows
   - **Solution** : Utiliser `file_picker` pour sélectionner des fichiers uniquement

3. **Mise à jour automatique** ❌
   - `in_app_update` est spécifique à Android
   - **Solution** : Créer un système de mise à jour manuel ou utiliser un package Windows comme `flutter_window_updater`

4. **FCM Token** ❌
   - Le token FCM ne sera pas généré sur Windows
   - **Solution** : Gérer ce cas dans le code (vérifier si `kIsWeb` ou plateforme desktop)

---

## 📦 Structure d'une version Windows

Après le build, vous aurez :

```
build/windows/x64/runner/Release/
├── myapp.exe                    ← Fichier principal (10-20 MB)
├── flutter_windows.dll          ← DLL Flutter
├── data/                        ← Assets et ressources
│   ├── icudtl.dat
│   └── flutter_assets/
├── plugins/                     ← Plugins natifs
└── msvcp140.dll, vcruntime140.dll  ← Bibliothèques Visual C++
```

**Taille estimée** : 50-100 MB (compressé : 20-40 MB)

---

## 🚀 Comment distribuer la version Windows

### Option 1 : Archive ZIP

```bash
# Après le build
cd build/windows/x64/runner/Release/
zip -r chiasma-windows-v1.0.1.zip .
```

Uploadez le ZIP sur votre site web.

### Option 2 : Installateur (NSIS ou Inno Setup)

Créer un vrai installateur Windows avec :
- Installation dans `Program Files`
- Icône sur le bureau
- Entrée dans le menu Démarrer
- Désinstallateur

**Outil recommandé** : [Inno Setup](https://jrsoftware.org/isinfo.php) (gratuit)

### Option 3 : Microsoft Store

Publier l'app sur le Microsoft Store (requiert un compte développeur Microsoft - 19 USD/an).

---

## 🎯 Version Windows : Cas d'usage recommandé

La version Windows est **idéale pour** :

✅ **Établissements scolaires** : Gérer les offres d'emploi depuis un PC de bureau
✅ **Enseignants** : Consulter les profils et gérer les permutations sur grand écran
✅ **Candidats** : Postuler aux offres depuis un ordinateur

**Mais moins adapté pour** :

❌ Notifications push en temps réel (pas de FCM sur Windows)
❌ Prise de photo avec la caméra
❌ Fonctionnalités mobiles spécifiques

---

## 💡 Recommandation

### Pour les notifications

**PRIORITÉ CRITIQUE** : Corriger les 4 problèmes identifiés

1. Ajouter `flutter_local_notifications`
2. Ajouter les permissions Android
3. Modifier `fcm_service.dart` pour afficher des notifications locales
4. Créer le canal de notifications
5. Demander la permission sur Android 13+

**Temps estimé** : 2-3 heures de développement + tests

### Pour la version Windows

**PRIORITÉ MOYENNE** : Faisable mais optionnel

1. Activer le support Windows
2. Créer les fichiers Windows
3. Adapter le code pour gérer les packages incompatibles
4. Builder et tester

**Temps estimé** : 4-6 heures de développement + tests

---

## 📊 Résumé final

| Question | Réponse |
|----------|---------|
| **Pourquoi les notifications ne fonctionnent pas ?** | 4 problèmes : pas de notifications locales, package manquant, permissions manquantes, canal manquant |
| **Pourquoi pas de son/vibration ?** | Le code ne crée jamais de notification locale avec son/vibration |
| **Version Windows possible ?** | ✅ OUI, Flutter supporte Windows nativement |
| **Fichier .exe possible ?** | ✅ OUI, via `flutter build windows` |
| **Limitations Windows** | Pas de notifications push FCM, pas de caméra, pas de mise à jour auto |
| **Priorité #1** | Corriger les notifications sur Android (critique) |
| **Priorité #2** | Version Windows (optionnel, pour les écoles) |

---

**Voulez-vous que je corrige les notifications maintenant ?**

Cela implique :
1. Ajouter le package `flutter_local_notifications`
2. Modifier `AndroidManifest.xml`
3. Modifier `fcm_service.dart`
4. Créer le canal de notifications
5. Reconstruire l'APK

**Ou préférez-vous d'abord activer le support Windows et tester un build ?**
