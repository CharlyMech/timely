# Application Flow & Navigation

This document describes the complete application flow, including routing, screen architecture, layouts, configuration, theming, and access control mechanisms.

## Table of Contents

- [Overview](#overview)
- [Navigation Architecture](#navigation-architecture)
  - [Router Configuration](#router-configuration)
  - [Route Definitions](#route-definitions)
  - [Navigation Flow](#navigation-flow)
- [Screens](#screens)
  - [SplashScreen](#splashscreen)
  - [StaffScreen](#staffscreen)
  - [TimeRegistrationDetailScreen](#timeregistrationdetailscreen)
  - [EmployeeProfileScreen](#employeeprofilescreen)
  - [EmployeeRegistrationsScreen](#employeeregistrationsscreen)
  - [DataPrivacyScreen](#dataprivacyscreen)
  - [ErrorScreen](#errorscreen)
- [Layouts & Responsive Design](#layouts--responsive-design)
  - [Responsive Breakpoints](#responsive-breakpoints)
  - [Layout System](#layout-system)
  - [Screen-Specific Layouts](#screen-specific-layouts)
- [Configuration](#configuration)
  - [Environment Configuration](#environment-configuration)
  - [App Setup](#app-setup)
  - [Constants](#constants)
- [Theming](#theming)
  - [Theme Architecture](#theme-architecture)
  - [Theme Types](#theme-types)
  - [Color Palette](#color-palette)
  - [Typography](#typography)
- [Access Control](#access-control)
  - [PIN Verification](#pin-verification)
  - [Inactivity Timeout](#inactivity-timeout)
- [Widgets & Components](#widgets--components)

---

## Overview

Timely uses **declarative routing** with GoRouter for navigation and a **responsive layout system** that adapts to mobile and tablet devices. The application follows a simple navigation hierarchy with clear screen purposes and transitions.

### Key Features

- **Declarative Routing**: Path-based routing with GoRouter
- **Responsive Layouts**: Separate mobile and tablet layouts per screen
- **Theme Management**: Light/Dark/System themes with persistent preferences
- **Access Control**: PIN-based authentication for sensitive screens
- **Inactivity Protection**: Auto-logout after 5 minutes of inactivity

---

## Navigation Architecture

### Router Configuration

**Location**: [lib/config/router.dart](../lib/config/router.dart)

The router is configured using **GoRouter** with path-based routes and type-safe navigation.

```dart
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/staff', builder: (context, state) => const StaffScreen()),
    GoRoute(
      path: '/employee/:id',
      builder: (context, state) {
        final employeeId = state.pathParameters['id']!;
        return TimeRegistrationDetailScreen(employeeId: employeeId);
      },
    ),
    GoRoute(
      path: '/employee/:id/profile',
      builder: (context, state) {
        final employeeId = state.pathParameters['id']!;
        return EmployeeProfileScreen(employeeId: employeeId);
      },
    ),
    GoRoute(
      path: '/employee/:id/registrations',
      builder: (context, state) {
        final employeeId = state.pathParameters['id']!;
        final employeeName = state.extra as String?;
        return EmployeeRegistrationsScreen(
          employeeId: employeeId,
          employeeName: employeeName ?? 'Employee',
        );
      },
    ),
    GoRoute(
      path: '/data-privacy',
      builder: (context, state) => const DataPrivacyScreen(),
    ),
    GoRoute(
      path: '/error',
      builder: (context, state) {
        final errorMessage = state.extra as Map<String, dynamic>?;
        return ErrorScreen(
          errorMessage: errorMessage?['message'] as String? ?? 'Unknown error',
          stackTrace: errorMessage?['stackTrace'] as String?,
        );
      },
    ),
  ],
);
```

### Route Definitions

| Route | Path | Parameters | Extra Data | Purpose |
|-------|------|------------|------------|---------|
| Splash | `/splash` | None | None | Initial loading screen |
| Staff | `/staff` | None | None | Main employee list |
| Time Detail | `/employee/:id` | `id`: Employee ID | None | Work time tracking |
| Profile | `/employee/:id/profile` | `id`: Employee ID | None | Employee profile |
| Registrations | `/employee/:id/registrations` | `id`: Employee ID | `employeeName`: String | Time history |
| Data Privacy | `/data-privacy` | None | None | Privacy policy |
| Error | `/error` | None | `{message, stackTrace}` | Error display |

### Navigation Methods

**Declarative Navigation**:
```dart
// Navigate to staff screen
context.go('/staff');

// Navigate to employee detail
context.go('/employee/${employee.id}');

// Navigate to profile
context.go('/employee/${employee.id}/profile');

// Navigate with extra data
context.go(
  '/employee/${employee.id}/registrations',
  extra: employee.fullName,
);
```

**Programmatic Navigation**:
```dart
// Push new route
context.push('/employee/${employee.id}');

// Pop current route
context.pop();

// Replace current route
context.replace('/error', extra: {'message': errorMessage});
```

### Navigation Flow

```
App Launch
    ↓
SplashScreen (/splash)
    │
    ├─ Success → /staff
    └─ Error → /error
        ↓
    StaffScreen (/staff)
        │
        └─ Select Employee → /employee/:id
            ↓
        TimeRegistrationDetailScreen
            │
            ├─ Avatar tap (with PIN) → /employee/:id/profile
            │       ↓
            │   EmployeeProfileScreen
            │       └─ Back → /employee/:id
            │
            ├─ Registrations link → /employee/:id/registrations
            │       ↓
            │   EmployeeRegistrationsScreen
            │       └─ Back → /employee/:id
            │
            ├─ Data Privacy → /data-privacy
            │       ↓
            │   DataPrivacyScreen
            │       └─ Back → /employee/:id
            │
            └─ Back → /staff
```

---

## Screens

### SplashScreen

**Location**: [lib/screens/splash_screen.dart](../lib/screens/splash_screen.dart)

**Route**: `/splash`

**Purpose**: Initial loading screen that initializes app data and theme preferences.

#### Lifecycle

```dart
initState()
    ↓
    ├─ Start inactivity timer (5 minutes)
    └─ Load data asynchronously
        ↓
Future.microtask()
    ↓
    ├─ Load employees (EmployeeViewModel.loadEmployees)
    ├─ Initialize theme (ThemeViewModel.initialize)
    └─ Wait for completion
        ↓
        ├─ Success → context.go('/staff')
        └─ Error → context.go('/error', extra: errorData)
```

#### Features

- **Loading State**: Shows loading indicator during initialization
- **Error Handling**: Navigates to error screen on failure
- **Inactivity Timer**: Auto-resets after 5 minutes of inactivity
- **Theme Initialization**: Detects system brightness and loads preference

#### UI

```
┌─────────────────────────┐
│                         │
│     [App Logo/Icon]     │
│                         │
│   Loading Indicator     │
│                         │
│   "Initializing..."     │
│                         │
└─────────────────────────┘
```

---

### StaffScreen

**Location**: [lib/screens/staff_screen.dart](../lib/screens/staff_screen.dart)

**Route**: `/staff`

**Purpose**: Main screen displaying employee list with search functionality.

#### Features

- **Employee List**: Displays all employees with status and current registration
- **Search**: Real-time search by name (debounced)
- **Responsive Grid**: Adapts to mobile (1-2 columns) and tablet (3-4 columns)
- **Pull to Refresh**: Swipe down to reload employee data
- **Inactivity Timer**: Returns to splash after 5 minutes
- **Theme Toggle**: Switch between light/dark/system themes

#### State Management

```dart
Consumer(
  builder: (context, ref, child) {
    final employeeState = ref.watch(employeeViewModelProvider);

    return employeeState.when(
      loading: () => LoadingIndicator(),
      error: (error) => ErrorMessage(error),
      data: (employees) => EmployeeList(employees),
    );
  },
)
```

#### Layouts

- **Mobile**: [staff_screen_mobile_layout.dart](../lib/layouts/mobile/staff_screen_mobile_layout.dart)
- **Tablet**: [staff_screen_tablet_layout.dart](../lib/layouts/tablet/staff_screen_tablet_layout.dart)

#### UI Structure

**Mobile Layout**:
```
┌─────────────────────────┐
│ [Logo] [Search] [Theme] │ ← StaffAppBar
├─────────────────────────┤
│                         │
│   [Employee Card 1]     │
│   [Employee Card 2]     │
│   [Employee Card 3]     │
│   ...                   │
│                         │
└─────────────────────────┘
```

**Tablet Layout**:
```
┌───────────────────────────────────────┐
│ [Logo]     [Search]         [Theme]   │ ← StaffAppBar
├───────────────────────────────────────┤
│                                       │
│  [Card 1]  [Card 2]  [Card 3]        │
│  [Card 4]  [Card 5]  [Card 6]        │
│  ...                                  │
│                                       │
└───────────────────────────────────────┘
```

#### Interactions

- **Tap Employee Card**: Navigate to `/employee/:id`
- **Search Input**: Filters employee list in real-time
- **Pull Down**: Refresh employee data
- **Logo Tap**: Clears search filter
- **Theme Toggle**: Cycles through Light → Dark → System

---

### TimeRegistrationDetailScreen

**Location**: [lib/screens/time_registration_detail_screen.dart](../lib/screens/time_registration_detail_screen.dart)

**Route**: `/employee/:id`

**Purpose**: Work time tracking interface with visual time gauge and action buttons.

#### Features

- **Time Gauge**: Circular progress showing elapsed vs target time
- **Work Controls**: Start, Pause, Resume, End work day buttons
- **Status Display**: Current work status (Not started, Active, Paused, Completed)
- **Shift Info**: Displays assigned shift type and times
- **Registration History Link**: Navigate to past registrations
- **Employee Avatar**: Tap to access profile (requires PIN)

#### State Management

```dart
Consumer(
  builder: (context, ref, child) {
    final detailState = ref.watch(employeeDetailViewModelProvider(employeeId));

    return detailState.when(
      loading: () => LoadingIndicator(),
      error: (error) => ErrorMessage(error),
      data: (employee) => DetailLayout(employee),
    );
  },
)
```

#### Layouts

- **Mobile**: [time_registration_detail_mobile_layout.dart](../lib/layouts/mobile/time_registration_detail_mobile_layout.dart)
- **Tablet**: [time_registration_detail_tablet_layout.dart](../lib/layouts/tablet/time_registration_detail_tablet_layout.dart)

#### UI Structure

**Mobile Layout**:
```
┌─────────────────────────┐
│ ← [Avatar] Employee Name│ ← EmployeeDetailAppBar
├─────────────────────────┤
│                         │
│    ┌─────────────┐      │
│    │   ⏱️ 08:00  │      │ ← TimeGauge (280px)
│    │   480 min   │      │
│    └─────────────┘      │
│                         │
│  Shift: Morning         │
│  08:00 - 16:00          │
│                         │
│  [Comenzar jornada]     │ ← Action Buttons
│  or                     │
│  [Pausar jornada]       │
│  [Finalizar jornada]    │
│                         │
│  → Ver registros        │
│                         │
└─────────────────────────┘
```

**Tablet Layout**:
```
┌───────────────────────────────────────┐
│ ← [Avatar] Employee Name              │
├───────────────────────────────────────┤
│                                       │
│  ┌─────────┐    Shift: Morning       │
│  │ ⏱️ 08:00│    08:00 - 16:00        │
│  │ 480 min │                          │
│  └─────────┘    [Comenzar jornada]   │
│   (350px)       [Pausar jornada]     │
│                 [Finalizar jornada]  │
│                                       │
│                 → Ver registros       │
│                                       │
└───────────────────────────────────────┘
```

#### Work Day States

| State | Condition | Available Actions |
|-------|-----------|-------------------|
| **Not Started** | No registration for today | Start Work Day |
| **Active** | Registration exists, not paused, not ended | Pause Work Day, End Work Day |
| **Paused** | Registration has pauseTime, no resumeTime | Resume Work Day |
| **Completed** | Registration has endTime | View Only (no actions) |
| **No Shift** | No shift assigned for today | Cannot start (error message) |

#### Interactions

- **Start Work Day**: Creates time registration, validates shift exists
- **Pause Work Day**: Sets pause timestamp, disables other actions
- **Resume Work Day**: Sets resume timestamp, re-enables actions
- **End Work Day**: Shows confirmation dialog, calculates total time
- **Avatar Tap**: Shows PIN verification dialog → Navigate to profile
- **Registrations Link**: Navigate to `/employee/:id/registrations`

---

### EmployeeProfileScreen

**Location**: [lib/screens/employee_profile_screen.dart](../lib/screens/employee_profile_screen.dart)

**Route**: `/employee/:id/profile`

**Purpose**: Display and edit employee profile information.

#### Access Control

- **PIN Protected**: Requires 6-digit PIN verification
- **Accessed via**: Avatar tap in TimeRegistrationDetailScreen

#### Features

- **Profile Display**: Shows avatar, name, email, phone, address
- **Status Management**: Display current status (active/inactive/vacation/leave)
- **Contact Information**: Email and phone with validation
- **Address Information**: Physical address display
- **Edit Mode**: Update employee information (future feature)

#### Layouts

- **Mobile**: [employee_profile_mobile_layout.dart](../lib/layouts/mobile/employee_profile_mobile_layout.dart)
- **Tablet**: [employee_profile_tablet_layout.dart](../lib/layouts/tablet/employee_profile_tablet_layout.dart)

#### UI Structure

**Mobile Layout**:
```
┌─────────────────────────┐
│ ←  Profile              │
├─────────────────────────┤
│                         │
│      [Avatar]           │
│   John Doe              │
│   Active                │
│                         │
│  📧 Email               │
│  john@example.com       │
│                         │
│  📱 Phone               │
│  +34 612 345 678        │
│                         │
│  📍 Address             │
│  123 Main St, City      │
│                         │
└─────────────────────────┘
```

**Tablet Layout**:
```
┌───────────────────────────────────────┐
│ ←  Profile                            │
├───────────────────────────────────────┤
│                                       │
│  ┌────────┐    John Doe              │
│  │[Avatar]│    Active                 │
│  └────────┘                           │
│             📧 john@example.com       │
│             📱 +34 612 345 678        │
│             📍 123 Main St, City      │
│                                       │
└───────────────────────────────────────┘
```

---

### EmployeeRegistrationsScreen

**Location**: [lib/screens/employee_registrations_screen.dart](../lib/screens/employee_registrations_screen.dart)

**Route**: `/employee/:id/registrations`

**Purpose**: Display historical time registrations with filtering and analytics.

#### Features

- **Registration History**: List of past work days with times and status
- **Filtering**: By date range, month, status
- **Status Indicators**: Color-coded status (green/orange/red)
- **Time Statistics**: Total worked time, average per day
- **Pagination**: Load more registrations as needed

#### Layouts

- **Mobile**: [employee_registrations_mobile_layout.dart](../lib/layouts/mobile/employee_registrations_mobile_layout.dart)
- **Tablet**: [employee_registrations_tablet_layout.dart](../lib/layouts/tablet/employee_registrations_tablet_layout.dart)

#### UI Structure

**Mobile Layout**:
```
┌─────────────────────────┐
│ ←  Registrations        │
├─────────────────────────┤
│                         │
│  December 2025          │ ← Month Filter
│                         │
│  ┌───────────────────┐  │
│  │ 01/12/2025    🟢 │  │
│  │ 08:00 - 16:30    │  │
│  │ 480 min          │  │
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ 02/12/2025    🟠 │  │
│  │ 08:15 - 16:00    │  │
│  │ 450 min          │  │
│  └───────────────────┘  │
│                         │
└─────────────────────────┘
```

**Tablet Layout**:
```
┌───────────────────────────────────────┐
│ ←  Registrations - John Doe           │
├───────────────────────────────────────┤
│                                       │
│  [Month Filter: December 2025]        │
│                                       │
│  Date       Start  End    Total  Status│
│  ─────────────────────────────────────│
│  01/12/25   08:00  16:30  480m   🟢  │
│  02/12/25   08:15  16:00  450m   🟠  │
│  03/12/25   08:00  17:15  510m   🟠  │
│  ...                                  │
│                                       │
└───────────────────────────────────────┘
```

#### Status Colors

- **🟢 Green**: Within ±15 minutes of target time
- **🟠 Orange**: 15-60 minutes difference from target
- **🔴 Red**: More than 60 minutes difference from target

---

### DataPrivacyScreen

**Location**: [lib/screens/data_privacy_screen.dart](../lib/screens/data_privacy_screen.dart)

**Route**: `/data-privacy`

**Purpose**: Display privacy policy and data handling information.

#### Features

- **Privacy Policy**: Full text of data privacy policy
- **Data Handling**: Information about data collection and storage
- **Contact Info**: How to contact about privacy concerns

---

### ErrorScreen

**Location**: [lib/screens/error_screen.dart](../lib/screens/error_screen.dart)

**Route**: `/error`

**Purpose**: Display error messages with optional stack trace.

#### Features

- **Error Message**: User-friendly error description
- **Stack Trace**: Technical details (debug mode only)
- **Retry Action**: Button to return to splash/home

#### UI Structure

```
┌─────────────────────────┐
│                         │
│      ⚠️ Error           │
│                         │
│  Something went wrong   │
│                         │
│  [Error message here]   │
│                         │
│  [Return to Home]       │
│                         │
│  (Stack trace in debug) │
│                         │
└─────────────────────────┘
```

---

## Layouts & Responsive Design

### Responsive Breakpoints

**Location**: [lib/utils/responsive_utils.dart](../lib/utils/responsive_utils.dart)

```dart
class ResponsiveBreakpoints {
  static const double mobile = 600.0;   // < 600px
  static const double tablet = 1024.0;  // 600-1024px
  static const double desktop = 1024.0; // > 1024px
}
```

#### Device Classification

```dart
bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;
}

bool isTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= ResponsiveBreakpoints.mobile && width < ResponsiveBreakpoints.desktop;
}

bool isDesktop(BuildContext context) {
  return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;
}
```

### Layout System

Each screen uses a **responsive builder pattern** to select the appropriate layout:

```dart
class StaffScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    if (responsive.isMobile) {
      return StaffScreenMobileLayout(...);
    } else {
      return StaffScreenTabletLayout(...);
    }
  }
}
```

### Responsive Values

**Context Extension**:
```dart
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}

// Usage
final padding = context.responsive.screenPadding;  // 12px mobile, 32px tablet
final spacing = context.responsive.spacing;        // 8px mobile, 16px tablet
```

**Responsive Value Function**:
```dart
T responsiveValue<T>({
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  if (isMobile) return mobile;
  if (isTablet) return tablet ?? mobile;
  return desktop ?? tablet ?? mobile;
}

// Usage
final fontSize = responsiveValue(
  mobile: 14.0,
  tablet: 16.0,
  desktop: 18.0,
);
```

### Preset Responsive Dimensions

| Property | Mobile | Tablet | Desktop |
|----------|--------|--------|---------|
| **screenPadding** | 12px | 32px | 48px |
| **spacing** | 8px | 16px | 24px |
| **avatarRadius** | 60px | 80px | 100px |
| **iconSize** | 24px | 28px | 32px |
| **borderRadius** | 8px | 12px | 16px |
| **Time Gauge** | 280px | 350px | 400px |

### Screen-Specific Layouts

#### StaffScreen Layouts

**Mobile** ([staff_screen_mobile_layout.dart](../lib/layouts/mobile/staff_screen_mobile_layout.dart)):
- Single column list
- Compact employee cards
- Full-width search bar
- Smaller avatar (60px)

**Tablet** ([staff_screen_tablet_layout.dart](../lib/layouts/tablet/staff_screen_tablet_layout.dart)):
- Multi-column grid (3-4 columns)
- Expanded employee cards
- Wider search bar
- Larger avatar (80px)

#### TimeRegistrationDetailScreen Layouts

**Mobile** ([time_registration_detail_mobile_layout.dart](../lib/layouts/mobile/time_registration_detail_mobile_layout.dart)):
- Vertical layout
- Time gauge centered (280px diameter)
- Buttons below gauge (stacked)
- Compact shift information

**Tablet** ([time_registration_detail_tablet_layout.dart](../lib/layouts/tablet/time_registration_detail_tablet_layout.dart)):
- Horizontal layout
- Time gauge on left (350px diameter)
- Buttons and info on right (side-by-side)
- Expanded shift information

---

## Configuration

### Environment Configuration

**Location**: [lib/config/environment.dart](../lib/config/environment.dart)

```dart
class Environment {
  static const String flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static bool get isDev => flavor == 'dev';
  static bool get isFirebase => flavor == 'firebase';
}
```

**Usage**:
```bash
# Development mode
flutter run --dart-define=FLAVOR=dev

# Firebase mode
flutter run --dart-define=FLAVOR=firebase
```

**Impact**:
- Service selection (Firebase vs Mock)
- Firebase initialization
- Logging verbosity
- Debug features

### App Setup

**Location**: [lib/config/setup.dart](../lib/config/setup.dart)

```dart
class AppSetup {
  static Future<void> initializePreferences() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SharedPreferences.getInstance();
  }

  static void logConfiguration() {
    if (kDebugMode) {
      print('Environment: ${Environment.flavor}');
      print('Is Dev: ${Environment.isDev}');
      print('Is Firebase: ${Environment.isFirebase}');
    }
  }

  static Brightness getSystemBrightness() {
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }
}
```

**Initialization Flow** (in [main.dart](../lib/main.dart)):
```dart
void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 3. Initialize date formatting
  Intl.defaultLocale = 'es_ES';

  // 4. Log configuration (debug only)
  AppSetup.logConfiguration();

  // 5. Initialize Firebase (firebase flavor only)
  if (Environment.isFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 6. Run app with providers
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}
```

### Constants

**Location**: [lib/constants/themes.dart](../lib/constants/themes.dart)

```dart
enum ThemeType {
  light,
  dark,
  system,
}

class MyTheme {
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  // ... other colors
}
```

**Color Constants**:
```dart
// Status Colors
static const greenColor = Color(0xFF46B56C);
static const orangeColor = Color(0xFFFFAB2E);
static const redColor = Color(0xFFD64C4C);

// Primary Color
static const primaryColor = Color(0xFFEFCC80);  // Golden
```

---

## Theming

### Theme Architecture

**Components**:
1. **ThemeType Enum**: Light, Dark, System
2. **MyTheme Class**: Color palette definitions
3. **ThemeViewModel**: State management for theme preference
4. **Theme Extension**: Convert MyTheme to Flutter ThemeData

**Flow**:
```
User selects theme
    ↓
ThemeViewModel.setTheme(type)
    ↓
Save to SharedPreferences
    ↓
Update state
    ↓
App rebuilds with new theme
```

### Theme Types

#### Light Theme

```dart
static MyTheme light() {
  return MyTheme(
    primaryColor: const Color(0xFFEFCC80),     // Golden
    backgroundColor: const Color(0xFFF3F3F3),  // Light gray
    surfaceColor: const Color(0xFFFAFAFA),     // Off-white
    onBackgroundColor: const Color(0xFF333333), // Dark text
    onSurfaceColor: const Color(0xFF333333),
    // ... other colors
  );
}
```

**Characteristics**:
- Light backgrounds (#F3F3F3, #FAFAFA)
- Dark text (#333333)
- Golden accent (#EFCC80)
- High contrast for readability

#### Dark Theme

```dart
static MyTheme dark() {
  return MyTheme(
    primaryColor: const Color(0xFFEFCC80),     // Golden (same)
    backgroundColor: const Color(0xFF121212),  // Dark gray
    surfaceColor: const Color(0xFF1f1f1f),     // Slightly lighter
    onBackgroundColor: const Color(0xFFE6E7EB), // Light text
    onSurfaceColor: const Color(0xFFE6E7EB),
    // ... other colors
  );
}
```

**Characteristics**:
- Dark backgrounds (#121212, #1f1f1f)
- Light text (#E6E7EB)
- Same golden accent
- Reduced eye strain in low light

#### System Theme

```dart
static MyTheme system(Brightness brightness) {
  return brightness == Brightness.dark
      ? MyTheme.dark()
      : MyTheme.light();
}
```

**Behavior**:
- Follows system dark mode setting
- Automatically updates when system setting changes
- Default on first launch

### Color Palette

#### Primary Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary** | #EFCC80 | Main accent, buttons, highlights |
| **Secondary** | #D0D0D0 | Inactive states, disabled buttons |

#### Background Colors

| Theme | Background | Surface |
|-------|------------|---------|
| **Light** | #F3F3F3 | #FAFAFA |
| **Dark** | #121212 | #1f1f1f |

#### Text Colors

| Theme | On Background | On Surface | On Primary |
|-------|---------------|------------|------------|
| **Light** | #333333 | #333333 | #333333 |
| **Dark** | #E6E7EB | #E6E7EB | #333333 |

#### Status Colors

| Status | Hex | Usage |
|--------|-----|-------|
| **Green** | #46B56C | Success, on-time status |
| **Orange** | #FFAB2E | Warning, slight deviation |
| **Red** | #D64C4C | Error, significant deviation |

### Typography

**Fonts**:
- **Headings**: Space Grotesk (display, headline, title)
- **Body**: DM Sans (body, label)

**Text Styles**:
```dart
TextTheme(
  displayLarge: GoogleFonts.spaceGrotesk(fontSize: 57, fontWeight: FontWeight.w400),
  displayMedium: GoogleFonts.spaceGrotesk(fontSize: 45, fontWeight: FontWeight.w400),
  displaySmall: GoogleFonts.spaceGrotesk(fontSize: 36, fontWeight: FontWeight.w400),

  headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w400),
  headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w400),
  headlineSmall: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w400),

  titleLarge: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w500),
  titleMedium: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w500),
  titleSmall: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w500),

  bodyLarge: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w400),
  bodyMedium: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400),
  bodySmall: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400),

  labelLarge: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
  labelMedium: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
  labelSmall: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500),
)
```

### Theme Persistence

**Storage**: SharedPreferences (key: `'theme_preference'`)

**Lifecycle**:
```
App Launch
    ↓
ThemeViewModel.initialize(systemBrightness)
    ↓
Load preference from SharedPreferences
    │
    ├─ If found: Use saved preference
    └─ If not: Use system brightness
    ↓
Apply theme to MaterialApp
```

**Saving**:
```dart
Future<void> setTheme(ThemeType type) async {
  state = state.copyWith(themeType: type);
  await _prefs.setString('theme_preference', type.toString());
}
```

---

## Access Control

### PIN Verification

**Purpose**: Protect sensitive employee information (profile access)

**Implementation**: [lib/widgets/pin_verification_dialog.dart](../lib/widgets/pin_verification_dialog.dart)

#### Dialog Flow

```
User taps avatar
    ↓
Show PIN verification dialog
    ↓
User enters 6-digit PIN
    ↓
    ├─ Correct PIN → Navigate to profile
    └─ Incorrect PIN → Show error, clear input
```

#### UI

```
┌─────────────────────────┐
│   Verificar PIN         │
├─────────────────────────┤
│                         │
│  Ingrese su PIN de 6    │
│  dígitos                │
│                         │
│  [● ● ● ● ● ●]          │
│                         │
│  [Cancelar] [Verificar] │
│                         │
└─────────────────────────┘
```

#### Code Example

```dart
void _showPinDialog(BuildContext context, Employee employee) {
  showDialog(
    context: context,
    builder: (context) => PinVerificationDialog(
      correctPin: employee.pin,
      onSuccess: () {
        context.pop();  // Close dialog
        context.push('/employee/${employee.id}/profile');
      },
    ),
  );
}
```

### Inactivity Timeout

**Purpose**: Auto-logout for security in shared kiosk environments

**Duration**: 5 minutes (300 seconds)

**Screens**: SplashScreen, StaffScreen

#### Implementation

```dart
class _StaffScreenState extends ConsumerState<StaffScreen> {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        context.go('/splash');
      }
    });
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetInactivityTimer,
      onPanDown: (_) => _resetInactivityTimer(),
      child: Scaffold(...),
    );
  }
}
```

**Behavior**:
- Timer starts on screen load
- Resets on any user interaction (tap, scroll, etc.)
- Navigates to splash on timeout
- Timer cancelled on screen dispose

---

## Widgets & Components

### Core Widgets

**Location**: [lib/widgets/](../lib/widgets/)

#### CustomCard

**Purpose**: Reusable elevated card component

```dart
CustomCard(
  onTap: () => print('Tapped'),
  child: Text('Card content'),
)
```

**Features**:
- Responsive padding and border radius
- Optional tap handling
- Elevation and shadow
- Theme-aware background color

#### CustomText

**Purpose**: Pre-styled text components

```dart
TitleText('Title')
SubtitleText('Subtitle')
```

**Variants**:
- `TitleText`: Bold, larger size
- `SubtitleText`: Regular weight, smaller size

#### EmployeeCard

**Purpose**: Display employee in list/grid

```dart
EmployeeCard(
  employee: employee,
  onTap: () => context.go('/employee/${employee.id}'),
)
```

**Displays**:
- Avatar
- Name
- Status (active/inactive/vacation/leave)
- Current registration status (if working)

#### EmployeeAvatar

**Purpose**: Circular avatar with fallback

```dart
EmployeeAvatar(
  avatarUrl: employee.avatarUrl,
  name: employee.fullName,
  radius: 60,
)
```

**Features**:
- Shows image from URL if available
- Falls back to initial letter if no image
- Responsive sizing
- Theme-aware colors

#### TimeGauge

**Purpose**: Circular progress indicator for work time

```dart
TimeGauge(
  registration: employee.currentRegistration,
  targetMinutes: shift.shiftType.targetTimeMinutes,
  size: 280,
)
```

**Features**:
- Circular progress animation
- Color-coded status (green/orange/red)
- Shows elapsed time or percentage
- Updates in real-time during work day

#### StaffAppBar

**Purpose**: App bar for StaffScreen

```dart
StaffAppBar(
  onLogoTap: () => clearSearch(),
  onSearchChanged: (query) => filterEmployees(query),
  onSearchClear: () => clearSearch(),
)
```

**Features**:
- Logo with tap callback
- Search field with debouncing
- Clear search button
- Theme toggle button

#### EmployeeDetailAppBar

**Purpose**: App bar for TimeRegistrationDetailScreen

```dart
EmployeeDetailAppBar(
  employee: employee,
  onAvatarTap: () => showPinDialog(),
)
```

**Features**:
- Back button
- Employee name
- Avatar with tap to profile (PIN protected)

#### PinVerificationDialog

**Purpose**: 6-digit PIN input dialog

```dart
PinVerificationDialog(
  correctPin: '123456',
  onSuccess: () => navigateToProfile(),
)
```

**Features**:
- Masked 6-digit input
- Validation on submit
- Error message on incorrect PIN
- Auto-focus and keyboard handling

#### ThemeToggleButton

**Purpose**: Cycle through theme options

```dart
ThemeToggleButton()
```

**Features**:
- Icon changes based on current theme (☀️/🌙/🔄)
- Cycles: Light → Dark → System
- Saves preference automatically

---

## Summary

The Timely application flow provides:

- **Clear Navigation**: Simple, predictable routing structure
- **Responsive Design**: Adapts to mobile and tablet with optimized layouts
- **Flexible Theming**: Light/Dark/System themes with persistent preferences
- **Access Control**: PIN-based authentication and inactivity timeout
- **Modular Components**: Reusable widgets for consistent UI
- **Environment Awareness**: Dev/Prod modes with appropriate service selection

For information on how this UI layer integrates with state management, see [GLOBAL_STATE.md](./GLOBAL_STATE.md).
For data architecture details, see [DATA.md](./DATA.md).
