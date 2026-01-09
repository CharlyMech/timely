# Timely - Technical Documentation

[Ver versión en español](./README.esp.md)

## Index

1. [Overview](#overview)
2. [Project Architecture](#project-architecture)
3. [State Management](#state-management)
4. [Data Model](#data-model)
5. [Execution Flow](#execution-flow)
6. [Folder Structure](#folder-structure)
7. [Development Guide](#development-guide)
8. [Contributing](#contributing)

## Overview

**Timely** is a mobile time registration application developed in Flutter that allows employees to manage their work hours simply and efficiently.

### Main Features

- ✅ Employee check-in and check-out registration
- ✅ Responsive employee grid view with search functionality
- ✅ Employee time registration detail with real-time tracking
- ✅ Automatic calculation of hours worked with status indicators (green/orange/red)
- ✅ Employee profile dashboard with shift calendar integration
- ✅ Complete shift management system (morning, afternoon, evening, night)
- ✅ Complete registration history with pagination
- ✅ PIN-protected employee data access (6-digit security)
- ✅ Data privacy information screen (GDPR compliant)
- ✅ Dual environment support: Development (Mock) and Production (Firebase)
- ✅ Light and dark themes with system preference detection
- ✅ Inactivity timeout (5 minutes) with automatic return to staff screen
- ✅ Pull-to-refresh functionality across all data screens
- ✅ Landscape/portrait responsive design

### Technologies Used

- **Flutter 3.10+** - Cross-platform UI framework
- **Dart 3.10+** - Programming language
- **Riverpod 3.0.3** - State management with Notifiers
- **GoRouter 17.0.0** - Declarative navigation with type-safe routes
- **Firebase Core 3.6.0** & **Cloud Firestore 5.4.4** - Cloud NoSQL database for production
- **SharedPreferences 2.5.3** - Local persistence for user preferences
- **table_calendar 3.1.2** - Interactive calendar widget for shift visualization
- **Google Fonts 6.2.1** - Typography (Space Grotesk + DM Sans)
- **Flutter SVG 2.2.3** - SVG support for icons and graphics
- **intl** - Internationalization and date formatting (Spanish locale)

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

- **Screens**: Complete application screens with routing
- **Widgets**: Reusable UI components
- **ViewModels**: UI state management using Riverpod Notifiers

#### 2. **Repository Layer (Domain)**

- Orchestrates multiple services
- Implements complex business logic
- Combines and transforms data from different sources
- Provides high-level operations to UI layer

#### 3. **Service Layer (Data)**

- Abstraction of data sources
- Specific implementations (Firebase, Mock)
- CRUD operations with error handling
- Environment-based switching

#### 4. **Models (Entities)**

- Immutable domain models with JSON serialization
- Business logic methods (getters, computed properties)
- Core models: Employee, TimeRegistration, Shift, ShiftType, AppConfig

---

## State Management

### Riverpod 3.0 Architecture

Timely uses **Riverpod 3.0** with the new `Notifier` API for reactive state management.

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

// App configuration provider
final appConfigProvider =
    FutureProvider<AppConfig>((ref) async {
      final configService = ref.read(configServiceProvider);
      return await configService.getAppConfig();
    });
```

### State Management Best Practices

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
   - Use `final` for all properties
   - Implement `copyWith` for updates
   - Don't use setters

4. **Error handling in ViewModels**
   - Catch exceptions and convert to user-friendly messages
   - Update state with error information
   - Maintain loading states appropriately

---

## Data Model

### Core Models

#### Employee Model
```dart
class Employee {
  final String id;                    // UUID
  final String firstName;             // First name
  final String lastName;              // Last name
  final String? avatarUrl;            // Optional avatar URL
  final String pin;                   // 6-digit PIN
  final TimeRegistration? currentRegistration; // Active session
  
  String get fullName => '$firstName $lastName';
}
```

#### TimeRegistration Model
```dart
class TimeRegistration {
  final String id;                    // UUID
  final String employeeId;            // Foreign key
  final DateTime startTime;           // Check-in time
  final DateTime? endTime;            // Check-out time (null if active)
  final DateTime? pauseTime;          // Pause start time
  final DateTime? resumeTime;         // Pause end time
  final String date;                  // DD/MM/YYYY format
  
  int get totalMinutes;               // Calculated work time
  bool get isActive;                  // true if endTime is null
  bool get isPaused;                  // true if currently paused
  TimeRegistrationStatus get status; // green/orange/red based on duration
}
```

#### Shift Model
```dart
class Shift {
  final String id;                    // UUID
  final String employeeId;            // Foreign key
  final DateTime date;                // Shift date
  final DateTime startTime;           // Shift start
  final DateTime endTime;             // Shift end
  final String shiftTypeId;           // Shift type reference
  
  Duration get duration;              // Calculated duration
  bool get isToday;                   // Date comparison
  bool get isPast;                    // Date comparison
  bool get isFuture;                  // Date comparison
}
```

#### ShiftType Model
```dart
class ShiftType {
  final String id;                    // UUID
  final String name;                  // Type name (e.g., "Mañana")
  final String colorHex;              // Color for UI
  
  Color get color;                    // Hex to Color conversion
}
```

### Entity Relationships

```
Employee (1) ←→ (Many) TimeRegistration
Employee (1) ←→ (Many) Shift
Shift (Many) ←→ (1) ShiftType
```

For detailed data model documentation, see [DATA_MODEL.md](./DATA_MODEL.md).

---

## Execution Flow

### Application Startup Flow

```mermaid
graph TD
    A[main.dart] --> B[AppSetup.initialize]
    B --> C[SharedPreferences initialization]
    B --> D[Firebase initialization (prod only)]
    B --> E[ProviderScope with environment overrides]
    E --> F[App Widget with GoRouter]
    F --> G[SplashScreen]
    G --> H[Load initial data]
    H --> I[WelcomeScreen]
    I --> J[User taps "Empezar"]
    J --> K[StaffScreen]
```

### Key Navigation Flow

1. **SplashScreen** (`/splash`) - App initialization and data preloading
2. **WelcomeScreen** (`/welcome`) - Welcome screen with entry button
3. **StaffScreen** (`/staff`) - Main employee grid with search
4. **TimeRegistrationDetailScreen** (`/employee/:id`) - Employee time tracking
5. **EmployeeProfileScreen** (`/employee/:id/profile`) - Profile and calendar
6. **EmployeeRegistrationsScreen** (`/employee/:id/registrations`) - History
7. **DataPrivacyScreen** (`/data-privacy`) - Privacy policy
8. **ErrorScreen** (`/error`) - Global error handling

### Data Flow Patterns

#### Read Operations
```
UI Action → ViewModel → Repository → Service → Data Source
UI ← State Update ← Repository ← Service ← Models
```

#### Write Operations
```
UI Action → ViewModel → Repository → Business Rules → Service → Data Source
UI ← Success/Error ← State Update ← Repository ← Service ← Result
```

For detailed execution flow documentation, see [EXECUTION_FLOW.md](./EXECUTION_FLOW.md).

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
│   ├── theme.dart                 # Theme extension
│   └── firebase_options.dart      # Firebase configuration
│
├── constants/                     # Constants
│   └── themes.dart                # Theme definitions (light/dark)
│
├── models/                        # Domain models
│   ├── app_config.dart            # App configuration model
│   ├── employee.dart              # Employee model
│   ├── shift_type.dart            # Shift type model
│   ├── shift.dart                 # Shift model
│   └── time_registration.dart     # Time registration model
│
├── repositories/                  # Repository layer
│   └── employee_repository.dart   # Employee repository with business logic
│
├── services/                      # Services layer
│   ├── config_service.dart        # Configuration service interface
│   ├── employee_service.dart      # Employee service interface
│   ├── shift_service.dart         # Shift service interface
│   ├── time_registration_service.dart # Time registration interface
│   ├── mock/                      # Mock implementations
│   │   ├── mock_config_service.dart
│   │   ├── mock_employee_service.dart
│   │   ├── mock_shift_service.dart
│   │   └── mock_time_registration_service.dart
│   └── firebase/                  # Firebase implementations
│       ├── firebase_config_service.dart
│       ├── firebase_employee_service.dart
│       ├── firebase_shift_service.dart
│       └── firebase_time_registration_service.dart
│
├── viewmodels/                    # ViewModels (State Management)
│   ├── employee_detail_viewmodel.dart
│   ├── employee_profile_viewmodel.dart
│   ├── employee_registrations_viewmodel.dart
│   ├── employee_viewmodel.dart
│   └── theme_viewmodel.dart
│
├── screens/                       # Screens
│   ├── data_privacy_screen.dart
│   ├── employee_profile_screen.dart
│   ├── employee_registrations_screen.dart
│   ├── error_screen.dart
│   ├── splash_screen.dart
│   ├── staff_screen.dart
│   └── time_registration_detail_screen.dart
│
├── widgets/                       # Reusable widgets
│   ├── custom_card.dart
│   ├── custom_text.dart
│   ├── data_info_button.dart
│   ├── employee_avatar.dart
│   ├── employee_card.dart
│   ├── employee_detail_appbar.dart
│   ├── pin_verification_dialog.dart
│   ├── staff_appbar.dart
│   ├── theme_toggle_button.dart
│   └── time_gauge.dart
│
└── utils/                         # Utilities
    └── date_utils.dart            # Date/time functions
```

---

## Development Guide

### Environment Setup

#### Prerequisites

- Flutter SDK 3.10+
- Dart SDK 3.10+
- Android Studio / VS Code
- Android emulator or physical device
- (Optional) Firebase account for production mode

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

Uses mock data from `assets/mock/` JSON files:

```bash
flutter run --dart-define=FLAVOR=dev
```

**Features:**
- No Firebase required
- Predefined test data
- Fast for local development
- Simulated network delays for realistic testing

#### Production Mode (Firebase)

Uses Firebase Firestore:

```bash
flutter run --dart-define=FLAVOR=prod
```

**Required Configuration:**
- Created Firebase project
- `google-services.json` (Android) in `android/app/`
- `GoogleService-Info.plist` (iOS) in `ios/Runner/`
- Configured Firestore security rules
- Proper indexes for queries

### Code Quality

#### Linting and Type Checking

```bash
# Run linting
flutter analyze

# Run type checking
dart analyze --fatal-infos
```

#### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Generate test coverage
flutter test --coverage
```

---

## Contributing

We welcome contributions to Timely! Please read our [Contributing Guide](./CONTRIBUTING.md) for detailed information on:

- Development practices and coding standards
- Branch naming conventions
- Pull request process
- Code review guidelines
- Testing requirements
- Documentation standards

### Quick Start for Contributors

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following our coding standards
4. Add tests for new functionality
5. Update documentation as needed
6. Submit a pull request with a clear description

---

## Additional Documentation

- [**Architecture**](./ARCHITECTURE.md) - Detailed technical architecture
- [**Data Model**](./DATA_MODEL.md) - Complete data model documentation
- [**Execution Flow**](./EXECUTION_FLOW.md) - Detailed application flow
- [**State Management**](./STATE_MANAGEMENT.md) - Riverpod implementation details
- [**Contributing**](./CONTRIBUTING.md) - Development and contribution guidelines

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Riverpod Documentation](https://riverpod.dev)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Firebase Flutter](https://firebase.flutter.dev)

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** January 2026  
**Version:** 1.0.0