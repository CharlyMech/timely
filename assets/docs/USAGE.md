# Using Timely

This guide provides comprehensive instructions for setting up, running, and working with the Timely project.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Application](#running-the-application)
- [Development Modes](#development-modes)
- [Firebase Configuration](#firebase-configuration)
- [Project Structure](#project-structure)
- [Adding New Features](#adding-new-features)
- [Testing](#testing)
- [Building for Production](#building-for-production)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, ensure you have the following installed:

### Required

- **Flutter SDK** 3.10 or higher
  ```bash
  flutter --version
  ```

- **Dart SDK** 3.10 or higher (comes with Flutter)
  ```bash
  dart --version
  ```

- **Git**
  ```bash
  git --version
  ```

### Recommended

- **Android Studio** or **VS Code** with Flutter extensions
- **Android SDK** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Chrome** (for web development)

### IDE Setup

#### VS Code

Install the following extensions:
- Flutter
- Dart
- Flutter Widget Snippets

#### Android Studio

Install the following plugins:
- Flutter
- Dart

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/timely.git
cd timely
```

### 2. Install Dependencies

```bash
flutter pub get
```

This command downloads all the dependencies specified in `pubspec.yaml`.

### 3. Verify Installation

```bash
flutter doctor
```

Ensure all checks pass. Fix any issues reported by `flutter doctor`.

---

## Running the Application

Timely supports two execution modes: **Development** (mock data) and **Production** (Firebase).

### Development Mode (Recommended for Testing)

Development mode uses mock data from JSON files, requiring no backend setup.

```bash
flutter run --dart-define=FLAVOR=dev
```

**Features:**
- Uses local mock data from `assets/mock/`
- No Firebase configuration needed
- Fast startup and testing
- Ideal for UI development and testing

### Production Mode

Production mode uses Firebase Firestore for data storage.

```bash
flutter run --dart-define=FLAVOR=prod
```

**Requirements:**
- Firebase project configured
- `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
- Active internet connection

### Running on Specific Devices

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id> --dart-define=FLAVOR=dev

# Run on Chrome
flutter run -d chrome --dart-define=FLAVOR=dev

# Run on physical Android device
flutter run -d <device-serial> --dart-define=FLAVOR=dev
```

---

## Development Modes

### Mock Mode (Development)

**How it works:**
- Reads employee data from `assets/mock/employees.json`
- Stores time registrations in memory (not persistent)
- Automatically loads on app start

**Mock Data Location:**
```
assets/mock/
├── employees.json      # Employee data
└── registrations.json  # Sample registrations
```

**Editing Mock Data:**

1. Open `assets/mock/employees.json`
2. Add or modify employee entries
3. Restart the app to see changes

Example employee:
```json
{
  "id": "emp-001",
  "name": "John Doe",
  "position": "Developer",
  "imageUrl": "https://example.com/photo.jpg"
}
```

### Firebase Mode (Production)

**How it works:**
- Connects to Firebase Firestore
- Real-time data synchronization
- Persistent data storage
- Multi-device sync

**Firestore Collections:**
- `employees` - Employee records
- `time_registrations` - Time registration records

---

## Firebase Configuration

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Follow the setup wizard
4. Enable Firestore Database

### 2. Add Android App

1. In Firebase Console, add an Android app
2. Package name: `com.example.timely` (or your custom package)
3. Download `google-services.json`
4. Place file in `android/app/`

### 3. Add iOS App (Optional)

1. In Firebase Console, add an iOS app
2. Bundle ID: `com.example.timely`
3. Download `GoogleService-Info.plist`
4. Place file in `ios/Runner/`

### 4. Configure Firestore

#### Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /employees/{employeeId} {
      allow read, write: if true;  // Adjust based on your auth
    }

    match /time_registrations/{registrationId} {
      allow read, write: if true;  // Adjust based on your auth
    }
  }
}
```

#### Create Collections

Firebase will automatically create collections when you add data. Alternatively:

1. Go to Firestore in Firebase Console
2. Click "Start collection"
3. Collection ID: `employees`
4. Add sample document

### 5. Verify Configuration

```bash
flutter run --dart-define=FLAVOR=prod
```

Check the console for Firebase connection logs.

---

## Project Structure

```
timely/
├── android/                # Android native code
├── ios/                    # iOS native code
├── web/                    # Web assets
│
├── assets/
│   ├── docs/              # Documentation
│   ├── images/            # Images and icons
│   ├── mock/              # Mock data (JSON)
│   └── screenshots/       # App screenshots
│
├── lib/
│   ├── config/
│   │   ├── environment.dart       # Environment configuration
│   │   ├── providers.dart         # Riverpod providers
│   │   ├── router.dart            # App navigation
│   │   ├── setup.dart             # App initialization
│   │   └── theme.dart             # Theme configuration
│   │
│   ├── constants/
│   │   └── themes.dart            # Theme constants
│   │
│   ├── models/
│   │   ├── employee.dart          # Employee model
│   │   └── time_registration.dart # Registration model
│   │
│   ├── repositories/
│   │   └── employee_repository.dart
│   │
│   ├── services/
│   │   ├── employee_service.dart
│   │   ├── time_registration_service.dart
│   │   ├── mock/                  # Mock implementations
│   │   └── firebase/              # Firebase implementations
│   │
│   ├── viewmodels/
│   │   ├── employee_viewmodel.dart
│   │   ├── employee_detail_viewmodel.dart
│   │   └── theme_viewmodel.dart
│   │
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── welcome_screen.dart
│   │   ├── staff_screen.dart
│   │   └── time_registration_detail_screen.dart
│   │
│   ├── widgets/
│   │   ├── employee_card.dart
│   │   └── time_registration_widget.dart
│   │
│   ├── utils/
│   │   └── date_utils.dart
│   │
│   ├── app.dart            # Main app widget
│   └── main.dart           # Entry point
│
├── test/                   # Tests
│   ├── unit/              # Unit tests
│   ├── widget/            # Widget tests
│   └── integration/       # Integration tests
│
├── pubspec.yaml           # Dependencies
├── analysis_options.yaml  # Dart analyzer rules
└── README.md              # Project overview
```

---

## Adding New Features

Follow this workflow to add new features while maintaining clean architecture:

### 1. Create the Model

```bash
# Create new model file
touch lib/models/vacation.dart
```

```dart
// lib/models/vacation.dart
class Vacation {
  final String id;
  final String employeeId;
  final DateTime startDate;
  final DateTime endDate;

  const Vacation({
    required this.id,
    required this.employeeId,
    required this.startDate,
    required this.endDate,
  });

  // Add fromJson, toJson, copyWith methods
}
```

### 2. Create Service Interface

```dart
// lib/services/vacation_service.dart
abstract class VacationService {
  Future<List<Vacation>> getVacations(String employeeId);
  Future<Vacation> requestVacation(Vacation vacation);
}
```

### 3. Implement Mock Service

```dart
// lib/services/mock/mock_vacation_service.dart
class MockVacationService implements VacationService {
  @override
  Future<List<Vacation>> getVacations(String employeeId) async {
    // Load from JSON
  }
}
```

### 4. Create Repository

```dart
// lib/repositories/vacation_repository.dart
class VacationRepository {
  final VacationService _vacationService;

  VacationRepository({required VacationService vacationService})
      : _vacationService = vacationService;

  Future<List<Vacation>> getEmployeeVacations(String employeeId) {
    return _vacationService.getVacations(employeeId);
  }
}
```

### 5. Create ViewModel

```dart
// lib/viewmodels/vacation_viewmodel.dart
class VacationViewModel extends Notifier<VacationState> {
  late VacationRepository _repository;

  @override
  VacationState build() {
    _repository = ref.read(vacationRepositoryProvider);
    return const VacationState();
  }

  Future<void> loadVacations(String employeeId) async {
    // Implementation
  }
}
```

### 6. Create UI

```dart
// lib/screens/vacation_screen.dart
class VacationScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vacationViewModelProvider);
    // Build UI
  }
}
```

### 7. Add Route

```dart
// lib/config/router.dart
GoRoute(
  path: '/vacations',
  name: 'vacations',
  builder: (context, state) => const VacationScreen(),
)
```

### 8. Write Tests

```dart
// test/unit/viewmodels/vacation_viewmodel_test.dart
void main() {
  test('loads vacations correctly', () async {
    // Test implementation
  });
}
```

---

## Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/viewmodels/employee_viewmodel_test.dart

# Run tests with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Structure

```
test/
├── unit/
│   ├── models/
│   ├── repositories/
│   └── viewmodels/
│
├── widget/
│   ├── screens/
│   └── widgets/
│
└── integration/
    └── app_test.dart
```

### Writing Tests

#### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('EmployeeViewModel', () {
    test('loads employees successfully', () async {
      // Arrange
      final mockRepository = MockEmployeeRepository();
      when(mockRepository.getEmployees())
          .thenAnswer((_) async => [testEmployee]);

      // Act
      final viewModel = EmployeeViewModel(repository: mockRepository);
      await viewModel.loadEmployees();

      // Assert
      expect(viewModel.state.employees.length, 1);
      expect(viewModel.state.isLoading, false);
    });
  });
}
```

---

## Building for Production

### Android APK

```bash
flutter build apk --dart-define=FLAVOR=prod
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle

```bash
flutter build appbundle --dart-define=FLAVOR=prod
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --dart-define=FLAVOR=prod
```

Then use Xcode to archive and upload to App Store.

---

## Troubleshooting

### Issue: "Tried to modify a provider while the widget tree was building"

**Solution:** Use `Future.microtask` in `initState`:

```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    ref.read(employeeViewModelProvider.notifier).loadEmployees();
  });
}
```

### Issue: Hot reload not working

**Solution:** Perform hot restart:
- Press `R` in the terminal
- Or use IDE's hot restart button

### Issue: Firebase not connecting

**Check:**
1. `google-services.json` is in `android/app/`
2. Package name matches Firebase configuration
3. Internet connection is active
4. Firestore rules allow access

### Issue: Mock data not loading

**Check:**
1. JSON files exist in `assets/mock/`
2. `pubspec.yaml` includes assets:
   ```yaml
   flutter:
     assets:
       - assets/mock/
   ```
3. Run `flutter pub get` after modifying `pubspec.yaml`

### Issue: Build fails

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run --dart-define=FLAVOR=dev
```

---

## License

This project is licensed under a Custom Open Source License with Commercial Restrictions.

For details, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** December 2025
