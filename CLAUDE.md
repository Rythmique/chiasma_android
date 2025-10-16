# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application with a login screen interface. The app is configured for cross-platform development (Android, Web) and uses Material Design 3 with an orange and green color scheme.

## Development Commands

### Running the Application
```bash
flutter run                    # Run on connected device/emulator
flutter run -d chrome          # Run on Chrome (web)
flutter run -d android         # Run on Android emulator
```

### Testing
```bash
flutter test                   # Run all tests
flutter test test/widget_test.dart  # Run specific test file
```

### Code Quality
```bash
flutter analyze                # Run static analysis
flutter format .               # Format all Dart files
flutter fix --apply .          # Apply automated fixes for analysis issues
```

### Dependencies
```bash
flutter pub get                # Install dependencies
flutter pub add <package>      # Add a new dependency
flutter pub add dev:<package>  # Add a dev dependency
flutter pub outdated           # Check for outdated packages
```

### Build
```bash
flutter build apk              # Build Android APK
flutter build web              # Build web assets
```

## Architecture

### Project Structure
```
lib/
  main.dart         - Application entry point with MaterialApp and theme configuration
  login_screen.dart - Login UI with matricule, email, and password fields (French labels)
test/
  widget_test.dart  - Widget tests (note: current test is outdated and expects counter UI)
```

### Theme Configuration
- Material Design 3 enabled (`useMaterial3: true`)
- Color scheme generated from seed color (orange primary, green secondary)
- Theme defined in `main.dart` using `ColorScheme.fromSeed()`

### Current Features
- **Login Screen**: Displays a form with three fields:
  - Numéro de matricule (badge/ID number)
  - Adresse mail (email)
  - Mot de passe (password)
- No navigation, state management, or authentication logic implemented yet
- Login button has placeholder `onPressed` callback

### Important Context
There is a comprehensive `GEMINI.md` file (37KB) that contains extensive AI development guidelines for Flutter in Firebase Studio. Key guidance from that file includes:
- Material Design 3 theming with `ColorScheme.fromSeed`
- Recommended use of `provider` package for state management
- `go_router` for complex navigation
- `google_fonts` for typography
- `dart:developer` for structured logging
- Firebase AI SDK integration patterns
- Accessibility standards
- Visual design principles emphasizing bold, modern UI

## Development Notes

### Current Test Status
The test file `test/widget_test.dart` is outdated - it tests for a counter UI that doesn't exist in the current app. Tests should be updated to match the actual LoginScreen implementation.

### State Management
No state management solution is currently implemented. Based on project guidelines, consider `provider` package for app-wide state when needed.

### Future Considerations
- Authentication logic needs to be implemented for login functionality
- Navigation structure (likely using `go_router` per guidelines)
- Form validation for login fields
- State management for user session
