# Timely Execution Flow

[Ver versión en español](./EXECUTION_FLOW.esp.md)

This document describes in detail the execution flow of the Timely application, from startup to different functionalities.

## Table of Contents

1. [Application Initialization](#application-initialization)
2. [Navigation Flow](#navigation-flow)
3. [Data Flow](#data-flow)
4. [Screen Lifecycle](#screen-lifecycle)
5. [Main Use Cases](#main-use-cases)

---

## Application Initialization

### 1. Entry Point (main.dart)

```dart
void main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Configure the application
  final container = await AppSetup.initialize();

  // 3. Launch the app with ProviderScope
  runApp(
    ProviderScope(
      overrides: container.overrides,
      child: const App(),
    ),
  );
}
```

**Execution Order:**

```
main()
  ↓
WidgetsFlutterBinding.ensureInitialized()
  ↓
AppSetup.initialize()
  ↓
  ├─ SharedPreferences.getInstance()
  ├─ Firebase.initializeApp() [if FLAVOR=prod]
  └─ return SetupContainer(overrides)
  ↓
runApp(ProviderScope(...))
  ↓
App Widget
```

### 2. AppSetup.initialize()

```dart
class AppSetup {
  static Future<SetupContainer> initialize() async {
    // 1. Load SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 2. Configure Firebase if production
    if (Environment.isProd) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 3. Configuration logs
    _printConfiguration();

    // 4. Return provider overrides
    return SetupContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  }
}
```

---

## Navigation Flow

### Routes Defined

```dart
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => WelcomeScreen()),
    GoRoute(path: '/staff', builder: (_, __) => StaffScreen()),
    GoRoute(
      path: '/employee/:id',
      builder: (_, state) => TimeRegistrationDetailScreen(
        employeeId: state.pathParameters['id']!,
      ),
    ),
  ],
);
```

### Navigation Diagram

```
        ┌──────────────┐
        │ SplashScreen │
        │   /splash    │
        └──────┬───────┘
               │ auto (2s)
               ↓
        ┌──────────────┐
        │WelcomeScreen │
        │  /welcome    │
        └──────┬───────┘
               │ button "Start"
               ↓
        ┌──────────────┐
        │ StaffScreen  │ ←─────────┐
        │   /staff     │            │
        └──────┬───────┘            │
               │ tap on employee    │ timeout (5min)
               ↓                    │
  ┌────────────────────────┐       │
  │ TimeRegistrationDetail │       │
  │   /employee/:id        │ ──────┘
  └────────────────────────┘
```

---

## Data Flow

### Architecture Layers

```
┌─────────────────────────────────────────┐
│              UI Layer                   │
│  Screen observes ViewModel (ref.watch)  │
└───────────────┬─────────────────────────┘
                │
                │ ref.read(...).action()
                ↓
┌─────────────────────────────────────────┐
│          ViewModel Layer                │
│  - Updates state                        │
│  - Calls Repository                     │
└───────────────┬─────────────────────────┘
                │
                │ repository.method()
                ↓
┌─────────────────────────────────────────┐
│         Repository Layer                │
│  - Orchestrates services                │
│  - Business logic                       │
└───────────────┬─────────────────────────┘
                │
                │ service.method()
                ↓
┌─────────────────────────────────────────┐
│          Service Layer                  │
│  - Mock: Reads JSON                     │
│  - Firebase: Queries Firestore          │
└─────────────────────────────────────────┘
```

### Complete Example: Load Employee List

#### 1. UI Layer (Screen)

```dart
class StaffScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observe state
    final employeeState = ref.watch(employeeViewModelProvider);

    // 2. Reactive UI
    if (employeeState.isLoading) {
      return CircularProgressIndicator();
    }

    if (employeeState.error != null) {
      return ErrorWidget(employeeState.error);
    }

    return EmployeeGrid(employees: employeeState.employees);
  }
}
```

#### 2. ViewModel Layer

```dart
class EmployeeViewModel extends Notifier<EmployeeState> {
  late EmployeeRepository _repository;

  @override
  EmployeeState build() {
    _repository = ref.read(employeeRepositoryProvider);
    return const EmployeeState();
  }

  Future<void> loadEmployees() async {
    // 1. Indicate loading
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 2. Call repository
      final employees = await _repository.getEmployeesWithTodayRegistration();

      // 3. Update state with success
      state = state.copyWith(
        employees: employees,
        isLoading: false,
      );
    } catch (e) {
      // 4. Handle error
      state = state.copyWith(
        error: 'Error loading employees: $e',
        isLoading: false,
      );
    }
  }
}
```

---

## Screen Lifecycle

### 1. SplashScreen

```
mounted
  ↓
initState()
  ↓
Future.microtask(() => _initializeApp())
  ↓
build() [shows logo + spinner]
  ↓
_initializeApp() executes in microtask
  ├─ loadEmployees()
  ├─ Future.delayed(2s)
  └─ context.go('/welcome')
  ↓
dispose()
```

### 2. WelcomeScreen

```
mounted
  ↓
build() [shows welcome + button]
  ↓
[User taps button]
  ↓
context.go('/staff')
  ↓
dispose()
```

### 3. StaffScreen

```
mounted
  ↓
initState()
  ├─ _startInactivityTimer()
  └─ super.initState()
  ↓
build()
  ├─ ref.watch(employeeViewModelProvider)
  └─ builds UI with data
  ↓
[User interacts]
  ├─ onTap → _resetInactivityTimer()
  ├─ onPanDown → _resetInactivityTimer()
  └─ onRefresh → refreshEmployees()
  ↓
[5 min without activity]
  ↓
_onInactivityTimeout()
  ↓
context.go('/welcome')
  ↓
dispose()
  └─ _inactivityTimer?.cancel()
```

---

## Main Use Cases

### Use Case 1: Start Workday

**Actor:** Employee
**Precondition:** Employee has no active registration today

**Flow:**

```
1. User navigates to StaffScreen
2. User taps their employee card
3. System navigates to TimeRegistrationDetailScreen
4. System loads employee data
5. System verifies: no active registration
6. System shows "Start Workday" button
7. User taps "Start Workday"
8. System:
   a. Creates new TimeRegistration with checkIn = now
   b. Saves to service (Mock/Firebase)
   c. Updates ViewModel state
   d. Starts timer in UI
9. System shows real-time timer
10. User sees elapsed time updating
```

**Code:**

```dart
// User taps button
ElevatedButton(
  onPressed: () => _startWorkday(),
)

// Handler
Future<void> _startWorkday() async {
  try {
    await ref
        .read(employeeDetailViewModelProvider(widget.employeeId).notifier)
        .startWorkday();

    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Workday started')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

**Result:** Employee has active workday, timer running

---

### Use Case 2: End Workday

**Actor:** Employee
**Precondition:** Employee has active registration today

**Flow:**

```
1. User is in TimeRegistrationDetailScreen
2. System shows active timer
3. System shows "End Workday" button
4. User taps "End Workday"
5. System:
   a. Updates TimeRegistration with checkOut = now
   b. Calculates totalHours
   c. Saves to service
   d. Updates state
   e. Stops timer
6. System shows summary:
   - Check-in time
   - Check-out time
   - Total hours worked
7. User sees confirmation
```

---

### Use Case 3: Pull to Refresh

**Actor:** User
**Precondition:** User in StaffScreen

**Flow:**

```
1. User drags down on grid
2. System detects pull gesture
3. System shows refresh indicator
4. System executes:
   a. ref.read(...).refreshEmployees()
   b. state.copyWith(isLoading: true)
5. UI shows loading
6. System reloads data:
   a. Gets employees from service
   b. Gets today's registrations
   c. Combines information
7. System updates state
8. UI hides refresh indicator
9. UI shows updated data
```

**Typical Duration:** 100-200ms (mock), 500-1000ms (Firebase)

---

## Performance Optimizations

### 1. Data Preloading (SplashScreen)

Employees are loaded in splash to be immediately available in StaffScreen:

```
SplashScreen loads → Employees in memory
  ↓
User navigates to StaffScreen → Data already available
  ↓
Instant UI, no loading
```

### 2. Provider.family Caches Instances

```dart
// First call: creates instance
ref.watch(employeeDetailViewModelProvider('123'));

// Second call: uses cached instance
ref.watch(employeeDetailViewModelProvider('123'));

// Different parameter: creates new instance
ref.watch(employeeDetailViewModelProvider('456'));
```

### 3. Select for Efficient Rebuilds

```dart
// ❌ Rebuilds on any state change
final state = ref.watch(employeeViewModelProvider);

// ✅ Only rebuilds when isLoading changes
final isLoading = ref.watch(
  employeeViewModelProvider.select((s) => s.isLoading),
);
```

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** December 2025
