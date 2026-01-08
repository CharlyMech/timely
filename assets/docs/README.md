# Timely - Technical Documentation

[Ver versión en español](./README.esp.md)

## Index

1. [Overview](#overview)
2. [Project Architecture](#project-architecture)
3. [State Management](#state-management)
4. [Execution Flow](#execution-flow)
5. [Folder Structure](#folder-structure)
6. [Development Guide](#development-guide)

## Overview

**Timely** is a mobile time registration application developed in Flutter that allows employees to manage their work hours simply and efficiently.

### Main Features

-  Employee check-in and check-out registration
-  Responsive employee grid view
-  Employee time registration detail with real-time tracking
-  Automatic calculation of hours worked with status indicators
-  Employee profile dashboard with shift calendar
-  Shift management system (morning, afternoon, evening, night)
-  Complete registration history with pagination
-  PIN-protected employee data access
-  Data privacy information screen (GDPR compliant)
-  Support for development mode (mock) and production (Firebase)
-  Light and dark themes with system preference detection
-  Inactivity timeout (5 minutes) with automatic return to staff screen

### Technologies Used

-  **Flutter 3.10+** - Cross-platform UI framework
-  **Dart 3.10+** - Programming language
-  **Riverpod 3.0** - State management with Notifiers
-  **GoRouter** - Declarative navigation with type-safe routes
-  **Firebase Firestore** - Cloud NoSQL database for production
-  **SharedPreferences** - Local persistence for user preferences
-  **table_calendar** - Interactive calendar widget for shift visualization
-  **intl** - Internationalization and date formatting (Spanish locale)

---

## Project Architecture

The application follows **Clean Architecture** with clear separation of responsibilities:

```
┌─────────────────────────────────────────────────┐
│                   UI Layer                      │
│  (Screens, Widgets, ViewModels)                 │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│              Repository Layer                   │
│  (Business Logic, Data Orchestration)           │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│               Service Layer                     │
│  (Data Sources: Firebase, Mock)                 │
└─────────────────────────────────────────────────┘
```

### Architecture Layers

#### 1. **UI Layer (Presentation)**

-  **Screens**: Complete application screens.
-  **Widgets**: Reusable components.
-  **ViewModels**: UI state management using Riverpod Notifiers.

#### 2. **Repository Layer (Domain)**

-  Orchestrates multiple services.
-  Implements business logic.
-  Combines data from different sources.

#### 3. **Service Layer (Data)**

-  Abstraction of data sources.
-  Specific implementations (Firebase, Mock).
-  CRUD operations.

#### 4. **Models (Entities)**

-  Immutable domain models
-  Serialization/Deserialization (JSON)
-  Business logic methods (getters, computed properties)
-  Core models: Employee, TimeRegistration, Shift

---

## State Management

### Riverpod 3.0

Timely uses **Riverpod 3.0** with the new `Notifier` API for state management.

#### Main Providers

```dart
// Staff screen provider
final employeeViewModelProvider =
    NotifierProvider<EmployeeViewModel, EmployeeState>(
        EmployeeViewModel.new
    );

// Employee detail provider (family - parameterized by employee ID)
final employeeDetailViewModelProvider =
    NotifierProvider.family<EmployeeDetailViewModel, EmployeeDetailState, String>(
        EmployeeDetailViewModel.new
    );

// Employee profile provider (family)
final employeeProfileViewModelProvider =
    NotifierProvider.family<EmployeeProfileViewModel, EmployeeProfileState, String>(
        EmployeeProfileViewModel.new
    );

// Employee registrations provider (family)
final employeeRegistrationsViewModelProvider =
    NotifierProvider.family<EmployeeRegistrationsViewModel, EmployeeRegistrationsState, String>(
        EmployeeRegistrationsViewModel.new
    );

// Theme provider
final themeViewModelProvider =
    NotifierProvider<ThemeViewModel, ThemeState>(
        ThemeViewModel.new
    );
```

### Best Practices

1. **Never modify providers in `initState`**

   ```dart
   @override
   void initState() {
     super.initState();
     // ✅ GOOD:
     Future.microtask(() => ref.read(provider.notifier).load());
   }
   ```

2. **Use `ref.watch` in build, `ref.read` in callbacks**

3. **States always immutable**
   -  Use `final` for all properties.
   -  Implement `copyWith` for updates.
   -  Don't use setters.

---

## Folder Structure

```
lib/
├── main.dart                      # Entry point
├── app.dart                       # Main app widget
│
├── config/                        # Configuration
│   ├── environment.dart           # Environment variables (dev/prod)
│   ├── providers.dart             # Riverpod providers
│   ├── router.dart                # GoRouter configuration
│   ├── setup.dart                 # App initialization
│   └── theme.dart                 # Theme extension
│
├── constants/                     # Constants
│   └── themes.dart                # Theme definitions (light/dark)
│
├── models/                        # Domain models
│   ├── employee.dart              # Employee model
│   ├── time_registration.dart     # Time registration model
│   └── shift.dart                 # Shift model
│
├── repositories/                  # Repository layer
│   └── employee_repository.dart   # Employee repository
│
├── services/                      # Services layer
│   ├── employee_service.dart      # Employee service interface
│   ├── time_registration_service.dart # Time registration interface
│   ├── shift_service.dart         # Shift service interface
│   ├── mock/                      # Mock implementations
│   │   ├── mock_employee_service.dart
│   │   ├── mock_time_registration_service.dart
│   │   └── mock_shift_service.dart
│   └── firebase/                  # Firebase implementations
│       ├── firebase_employee_service.dart
│       ├── firebase_time_registration_service.dart
│       └── firebase_shift_service.dart
│
├── viewmodels/                    # ViewModels (State Management)
│   ├── employee_viewmodel.dart
│   ├── employee_detail_viewmodel.dart
│   ├── employee_profile_viewmodel.dart
│   ├── employee_registrations_viewmodel.dart
│   └── theme_viewmodel.dart
│
├── screens/                       # Screens
│   ├── splash_screen.dart
│   ├── welcome_screen.dart
│   ├── staff_screen.dart
│   ├── time_registration_detail_screen.dart
│   ├── employee_profile_screen.dart
│   ├── employee_registrations_screen.dart
│   └── data_privacy_screen.dart
│
├── widgets/                       # Reusable widgets
│   ├── employee_card.dart
│   ├── employee_detail_appbar.dart
│   ├── staff_appbar.dart
│   ├── data_info_button.dart
│   └── pin_verification_dialog.dart
│
└── utils/                         # Utilities
    └── date_utils.dart            # Date/time functions
```

---

## Development Guide

### Environment Setup

#### Prerequisites

-  Flutter SDK 3.10+
-  Dart SDK 3.10+
-  Android Studio / VS Code
-  Android emulator or physical device

#### Installation

```bash
# 1. Clone repository
git clone <repository-url>
cd timely

# 2. Install dependencies
flutter pub get

# 3. Run in development mode (mock data)
flutter run --dart-define=FLAVOR=dev

# 4. Run in production mode (Firebase)
flutter run --dart-define=FLAVOR=prod
```

### Execution Modes

#### Development Mode (Mock)

Uses mock data from `assets/mock/employees.json`:

```bash
flutter run --dart-define=FLAVOR=dev
```

**Features:**

-  No Firebase required.
-  Predefined test data.
-  Fast for local development.

#### Production Mode (Firebase)

Uses Firebase Firestore:

```bash
flutter run --dart-define=FLAVOR=prod
```

**Required Configuration:**

-  Created Firebase project.
-  `google-services.json` (Android).
-  `GoogleService-Info.plist` (iOS).
-  Configured Firestore.

---

## Additional Resources

-  [Flutter Documentation](https://docs.flutter.dev)
-  [Riverpod Documentation](https://riverpod.dev)
-  [GoRouter Documentation](https://pub.dev/packages/go_router)
-  [Firebase Flutter](https://firebase.flutter.dev)

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** December 2025

**Version:** 1.0.0
