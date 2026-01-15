# Timely - Time Registration System Documentation

Welcome to the **Timely** documentation. This is a comprehensive guide for understanding, using, and contributing to the Timely time registration application.

## Table of Contents

- [Overview](#overview)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the Application](#running-the-application)
- [Execution Modes](#execution-modes)
  - [Development Mode (Mock Data)](#development-mode-mock-data)
  - [Production Mode (Firebase)](#production-mode-firebase)
- [Firebase Setup](#firebase-setup)
  - [Seeding Data](#seeding-data)
  - [Deploying Rules and Indexes](#deploying-rules-and-indexes)
- [Application Usage](#application-usage)
- [Documentation Index](#documentation-index)
- [License](#license)

---

## Overview

**Timely** is a modern time registration and employee management system designed for small and medium-sized enterprises (PYME). The application provides real-time tracking of employee work hours, shift management, and comprehensive time analytics.

### Key Features

- **Work Time Tracking**: Start, pause, resume, and end work shifts
- **Shift Management**: Pre-defined shift types (Morning, Afternoon, Split shifts)
- **Real-time Monitoring**: Visual time gauge showing progress against target hours
- **Employee Management**: Profile management with contact information and status
- **Time History**: Complete registration history with filtering and analytics
- **Dual Theme Support**: Light, dark, and system-based theming
- **Responsive Design**: Optimized layouts for mobile and tablet devices
- **Dual Execution Mode**: Firebase production mode or Mock development mode

---

## Technology Stack

### Framework & Language
- **Flutter**: ^3.10.0
- **Dart**: SDK ^3.10.0

### State Management
- **flutter_riverpod**: ^3.0.3 - Reactive state management
- **go_router**: ^17.0.0 - Declarative routing

### Backend & Database
- **firebase_core**: ^3.6.0 - Firebase SDK
- **cloud_firestore**: ^5.4.4 - NoSQL cloud database

### UI & Design
- **google_fonts**: ^6.2.1 - Custom typography (Space Grotesk, DM Sans)
- **flutter_svg**: ^2.2.3 - SVG asset support
- **table_calendar**: ^3.1.2 - Calendar widget

### Utilities
- **uuid**: ^4.5.2 - Unique identifier generation
- **intl**: ^0.20.2 - Internationalization and date formatting
- **shared_preferences**: ^2.5.3 - Local data persistence

---

## Getting Started

### Prerequisites

**For Application Development:**
- Flutter SDK ^3.10.0 or higher
- Dart SDK ^3.10.0 or higher
- An IDE (VS Code, Android Studio, or IntelliJ IDEA)
- iOS Simulator (macOS only) or Android Emulator

**For Firebase Setup (Production Mode):**
- Node.js 18+ and npm
- Firebase CLI (`npm install -g firebase-tools`)
- A Firebase project with Firestore enabled

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/charlymech/timely.git
   cd timely
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. (Optional) For Firebase production mode, install Node.js dependencies:
   ```bash
   cd scripts
   npm install
   ```

### Running the Application

**Development Mode (Default):**
```bash
flutter run
# or explicitly
flutter run --dart-define=FLAVOR=dev
```

**Production Mode (Firebase):**
```bash
flutter run --dart-define=FLAVOR=prod
```

**Build for Release:**
```bash
# Android
flutter build apk --dart-define=FLAVOR=prod

# iOS
flutter build ios --dart-define=FLAVOR=prod
```

---

## Execution Modes

Timely supports two execution modes to facilitate development and production deployment.

### Development Mode (Mock Data)

**Purpose**: Local development and testing without Firebase dependency.

**Characteristics:**
- Uses mock JSON data from `assets/mock/employees.json`
- In-memory data persistence (resets on restart)
- 2-second artificial delay to simulate network latency
- No Firebase initialization required
- Faster development iteration

**When to use:**
- Local development and UI testing
- Feature development without backend dependency
- Quick prototyping
- Offline development

**Data Source**: Mock services in [lib/services/mock/](../lib/services/mock/)

### Production Mode (Firebase)

**Purpose**: Production deployment with real-time cloud database.

**Characteristics:**
- Firebase Firestore as database backend
- Real-time data synchronization
- Persistent data storage
- Multi-user support
- Cloud-based authentication and rules

**When to use:**
- Production deployment
- Testing with real Firebase backend
- Multi-device testing
- Integration testing

**Data Source**: Firebase services in [lib/services/firebase/](../lib/services/firebase/)

### Switching Between Modes

The application automatically selects the appropriate service implementation based on the `FLAVOR` environment variable:

```dart
// In lib/config/providers.dart
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return Environment.isDev
      ? MockEmployeeService()
      : FirebaseEmployeeService();
});
```

---

## Firebase Setup

### Prerequisites

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Firestore Database in your project
3. Download the Firebase configuration file:
   - For Android: `google-services.json` → `android/app/`
   - For iOS: `GoogleService-Info.plist` → `ios/Runner/`
4. Run `flutterfire configure` to generate `lib/config/firebase_options.dart`

### Seeding Data

Timely includes Node.js scripts to populate your Firestore database with test data.

**Quick Start:**
```bash
cd scripts
npm run setup
```

This will:
1. Check prerequisites (Node 18+, Firebase CLI)
2. Install npm dependencies
3. Seed data to Firestore
4. Deploy Firestore rules
5. Deploy Firestore indexes

**Available Scripts:**

| Command | Description |
|---------|-------------|
| `npm run setup` | Complete setup: seed data + deploy rules + deploy indexes |
| `npm run setup:clear` | Clear existing data before seeding |
| `npm run setup:dry-run` | Preview changes without writing to Firestore |
| `npm run seed` | Seed data only |
| `npm run seed:clear` | Clear and seed data |
| `npm run seed:dry-run` | Preview seed data |

**What Gets Seeded:**
- **App Configuration**: Work day settings, thresholds, working days
- **Shift Types**: Morning, Afternoon, Split shifts with time ranges
- **Employees**: 4 test employees with profile information
- **Shifts**: Pre-generated shifts from December 2025 to February 2026
- **Time Registrations**: Sample completed work registrations

For detailed information about data seeding, see the [scripts README](../scripts/README.md).

### Deploying Rules and Indexes

**Firestore Security Rules:**
```bash
cd scripts
npm run deploy:rules
```

**Firestore Indexes:**
```bash
cd scripts
npm run deploy:indexes
```

**Security Rules Summary:**
- Settings, employees, shift types, shifts: Read-only
- Time registrations: Full read/write access

For more details, see [firestore.rules](../firestore.rules) and [firestore.indexes.json](../firestore.indexes.json).

---

## Application Usage

### First Launch

1. **Splash Screen**: The app initializes data and theme preferences
2. **Staff Screen**: Main screen showing employee list with search functionality
3. **Employee Selection**: Tap an employee to open their time registration detail

### Time Registration Workflow

1. **Start Work Day**: Tap "Comenzar jornada" to start tracking time
2. **Pause**: Tap "Pausar jornada" to pause work (lunch break, etc.)
3. **Resume**: Tap "Reanudar jornada" to continue tracking after pause
4. **End Work Day**: Tap "Finalizar jornada" to complete the work day

### Navigation

- **Staff Screen** (`/staff`): Main employee list
- **Time Registration Detail** (`/employee/:id`): Work tracking and time gauge
- **Employee Profile** (`/employee/:id/profile`): Employee information (requires PIN)
- **Time Registrations History** (`/employee/:id/registrations`): Past work records

### Authentication

- Employee profiles are protected by a 6-digit PIN
- Tap the employee avatar to access profile (PIN required)
- PINs are defined in the employee data model

### Theme Switching

- Tap the theme toggle button in the app bar
- Options: Light, Dark, System (follows device setting)
- Preference is saved locally via SharedPreferences

---

## Documentation Index

This documentation is organized into specialized sections for different aspects of the application:

### Application Documentation

- **[DATA.md](./DATA.md)** - Data models, repositories, services, and entity relationships
  - Entity schemas and validation
  - Repository pattern implementation
  - Firebase and Mock service implementations
  - Data flow and relationships

- **[APP_FLOW.md](./APP_FLOW.md)** - Application flow, routing, screens, and layouts
  - Navigation structure and routes
  - Screen descriptions and purposes
  - Responsive layout system
  - Configuration and theming
  - Access control and verification

- **[GLOBAL_STATE.md](./GLOBAL_STATE.md)** - State management with Riverpod
  - Riverpod provider architecture
  - ViewModel implementations
  - State synchronization patterns
  - Data loading and caching strategies
  - Complete state management lifecycle

### Technical Documentation

- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - Contributing guidelines
  - Development workflow
  - Branch naming conventions
  - Pull request guidelines
  - Issue reporting
  - Code style and standards

- **[CONTACT.md](./CONTACT.md)** - Project author and contact information
  - About the author
  - Social media links
  - GitHub profile
  - Portfolio website

---

## License

This project is licensed under the **PolyForm Noncommercial License 1.0.0**.

### License Summary

- **Non-commercial use**: Permitted under the terms of the [LICENSE](../LICENSE) file
- **Commercial use**: Requires a separate paid commercial license
- **Contributions**: By contributing, you agree your work may be licensed under the same terms
- **No warranty**: The software is provided "as is" without warranty of any kind

### Commercial Licensing

For commercial use, you must obtain a separate commercial license. See [COMMERCIAL_LICENSE.md](../COMMERCIAL_LICENSE.md) for details.

To request a commercial license, contact:
- **Email**: sanchezreciocarlos99@outlook.com
- **Subject**: [Timely Commercial License Request]
- **GitHub Issues**: https://github.com/charlymech/timely/issues

**Important**: This project is **source-available software**, not open source. Commercial use without a license is prohibited.

For more information about contributing to this project while respecting the license, see [CONTRIBUTING.md](./CONTRIBUTING.md).

---

## Support & Questions

- **Documentation**: Start with this README and explore the linked documentation
- **Issues**: Report bugs or request features via [GitHub Issues](https://github.com/charlymech/timely/issues)
- **Contact**: For licensing or commercial inquiries, see [CONTACT.md](./CONTACT.md)

---

**Happy time tracking!** 🕒
