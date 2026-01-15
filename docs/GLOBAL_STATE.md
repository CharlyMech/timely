# Global State Management

This document provides a comprehensive guide to the global state management architecture in Timely, including Riverpod providers, ViewModels, state synchronization patterns, and the complete data flow lifecycle.

## Table of Contents

- [Overview](#overview)
- [Riverpod Architecture](#riverpod-architecture)
  - [Provider Hierarchy](#provider-hierarchy)
  - [Provider Types](#provider-types)
- [Service Providers](#service-providers)
- [Data Providers](#data-providers)
- [ViewModels](#viewmodels)
  - [EmployeeViewModel](#employeeviewmodel)
  - [EmployeeDetailViewModel](#employeedetailviewmodel)
  - [EmployeeProfileViewModel](#employeeprofileviewmodel)
  - [EmployeeRegistrationsViewModel](#employeeregistrationsviewmodel)
  - [EmployeeShiftsViewModel](#employeeshiftsviewmodel)
  - [ThemeViewModel](#themeviewmodel)
- [State Synchronization](#state-synchronization)
- [Data Loading Strategies](#data-loading-strategies)
- [State Lifecycle](#state-lifecycle)
- [Best Practices](#best-practices)

---

## Overview

Timely uses **Riverpod** for state management, implementing a multi-layered architecture that separates concerns and ensures data consistency across the application.

### Key Principles

1. **Single Source of Truth**: Each piece of state has one authoritative provider
2. **Immutable State**: All state objects are immutable with `copyWith` methods
3. **Reactive Updates**: UI rebuilds automatically when state changes
4. **State Synchronization**: Related states are kept in sync through explicit updates
5. **Separation of Concerns**: Services, repositories, and ViewModels have distinct responsibilities

### Architecture Layers

```
UI Layer (Widgets)
    ↓
    Consumes state via ref.watch()
    ↓
ViewModel Layer (Notifiers)
    ↓
    Manages state, coordinates operations
    ↓
Repository Layer
    ↓
    Orchestrates multiple services
    ↓
Service Layer
    ↓
    Abstracts data sources (Firebase/Mock)
    ↓
Data Layer (Firestore/JSON)
```

---

## Riverpod Architecture

### Provider Hierarchy

**Location**: [lib/config/providers.dart](../lib/config/providers.dart)

The provider hierarchy follows a dependency graph:

```
Foundation Providers
├─ sharedPreferencesProvider
└─ Environment (static class)
    ↓
Service Providers (environment-aware)
├─ employeeServiceProvider
├─ timeRegistrationServiceProvider
├─ shiftServiceProvider
├─ configServiceProvider
└─ shiftTypeServiceProvider
    ↓
Repository Providers
└─ employeeRepositoryProvider
    ↓
Data Providers (FutureProviders)
├─ appConfigProvider
└─ shiftTypesProvider
    ↓
ViewModel Providers (NotifierProviders)
├─ employeeViewModelProvider
├─ employeeDetailViewModelProvider (family)
├─ employeeProfileViewModelProvider (family)
├─ employeeRegistrationsViewModelProvider (family)
├─ employeeShiftsViewModelProvider (family)
└─ themeViewModelProvider
```

### Provider Types

Timely uses several Riverpod provider types, each suited for different use cases:

#### Provider

**Purpose**: Dependency injection, read-only values

```dart
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return Environment.isDev
      ? MockEmployeeService()
      : FirebaseEmployeeService();
});
```

**Characteristics**:
- Created once, never changes
- Used for service instances
- No state mutation

#### FutureProvider

**Purpose**: Async data loading with loading/error states

```dart
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final configService = ref.watch(configServiceProvider);
  return await configService.getConfig();
});
```

**Characteristics**:
- Automatically handles loading/error states
- Rebuilds when dependencies change
- Used for initial data loading

#### NotifierProvider

**Purpose**: Mutable state with business logic

```dart
final employeeViewModelProvider = NotifierProvider<EmployeeViewModel, EmployeeState>(
  () => EmployeeViewModel(),
);
```

**Characteristics**:
- Full state management capabilities
- Can expose methods for state updates
- Used for ViewModels

#### NotifierProvider.family

**Purpose**: Parameterized instances of NotifierProvider

```dart
final employeeDetailViewModelProvider = NotifierProvider.family<
  EmployeeDetailViewModel,
  EmployeeDetailState,
  String  // Parameter type (employeeId)
>((ref, employeeId) => EmployeeDetailViewModel(employeeId));
```

**Characteristics**:
- Creates separate instance per parameter value
- Used for entity-specific ViewModels
- Automatically cached by parameter

---

## Service Providers

Service providers use the **environment-aware pattern** to select implementations based on dev/prod mode.

### Implementation Pattern

```dart
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return Environment.isDev
      ? MockEmployeeService()
      : FirebaseEmployeeService();
});
```

### All Service Providers

```dart
// Employee service
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return Environment.isDev
      ? MockEmployeeService()
      : FirebaseEmployeeService();
});

// Time registration service
final timeRegistrationServiceProvider = Provider<TimeRegistrationService>((ref) {
  return Environment.isDev
      ? MockTimeRegistrationService()
      : FirebaseTimeRegistrationService();
});

// Shift service
final shiftServiceProvider = Provider<ShiftService>((ref) {
  return Environment.isDev
      ? MockShiftService()
      : FirebaseShiftService();
});

// Config service
final configServiceProvider = Provider<ConfigService>((ref) {
  return Environment.isDev
      ? MockConfigService()
      : FirebaseConfigService();
});

// Shift type service
final shiftTypeServiceProvider = Provider<ShiftTypeService>((ref) {
  return Environment.isDev
      ? MockShiftTypeService()
      : FirebaseShiftTypeService();
});
```

### Repository Provider

```dart
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    employeeService: ref.watch(employeeServiceProvider),
    timeRegistrationService: ref.watch(timeRegistrationServiceProvider),
    shiftService: ref.watch(shiftServiceProvider),
  );
});
```

---

## Data Providers

Data providers load static or rarely-changing data at app initialization.

### AppConfig Provider

**Purpose**: Load application configuration settings

```dart
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final configService = ref.watch(configServiceProvider);
  return await configService.getConfig();
});
```

**Data**:
- Default target time (480 minutes = 8 hours)
- Warning threshold (15 minutes)
- Red threshold (60 minutes)
- Working days (Monday-Friday)

**Usage**:
```dart
// In a widget
final configAsync = ref.watch(appConfigProvider);

configAsync.when(
  data: (config) => Text('Target: ${config.defaultTargetTimeMinutes}'),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### ShiftTypes Provider

**Purpose**: Load all shift type definitions

```dart
final shiftTypesProvider = FutureProvider<List<ShiftType>>((ref) async {
  final shiftTypeService = ref.watch(shiftTypeServiceProvider);
  return await shiftTypeService.getAllShiftTypes();
});
```

**Data**:
- Morning shift (08:00-16:00)
- Afternoon shift (14:00-22:00)
- Split shift (09:00-13:00)

**Usage**:
```dart
final shiftTypesAsync = ref.watch(shiftTypesProvider);

shiftTypesAsync.when(
  data: (shiftTypes) => DropdownButton(
    items: shiftTypes.map((st) => DropdownMenuItem(
      value: st.id,
      child: Text(st.name),
    )).toList(),
  ),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error loading shift types'),
);
```

---

## ViewModels

ViewModels manage screen-specific state and coordinate business operations. All ViewModels extend `Notifier` and follow a consistent pattern.

### EmployeeViewModel

**Location**: [lib/viewmodels/employee_viewmodel.dart](../lib/viewmodels/employee_viewmodel.dart)

**Purpose**: Manage the main employee list state

**Provider Definition**:
```dart
final employeeViewModelProvider = NotifierProvider<EmployeeViewModel, EmployeeState>(
  () => EmployeeViewModel(),
);
```

#### State Definition

```dart
class EmployeeState {
  final List<Employee> employees;
  final bool isLoading;
  final String? error;

  const EmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
  });

  EmployeeState copyWith({
    List<Employee>? employees,
    bool? isLoading,
    String? error,
  }) { ... }
}
```

#### Methods

**loadEmployees()**

Loads all employees with today's registration and shift.

```dart
Future<void> loadEmployees() async {
  // 1. Set loading state
  state = state.copyWith(isLoading: true, error: null);

  try {
    // 2. Fetch employees from repository
    final repository = ref.read(employeeRepositoryProvider);
    final employees = await repository.getEmployeesWithTodayRegistration();

    // 3. Update state with data
    state = state.copyWith(
      employees: employees,
      isLoading: false,
    );
  } catch (e) {
    // 4. Handle errors
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

**Flow**:
```
loadEmployees() called
    ↓
State: { isLoading: true, error: null }
    ↓
EmployeeRepository.getEmployeesWithTodayRegistration()
    ├─ Fetch all employees
    ├─ For each employee:
    │   ├─ Fetch today's registration
    │   └─ Fetch today's shift
    └─ Return enriched employees
    ↓
State: { employees: [...], isLoading: false }
    ↓
UI rebuilds automatically
```

**refreshEmployees()**

Manually refresh employee list.

```dart
Future<void> refreshEmployees() => loadEmployees();
```

**updateEmployee(Employee employee)**

Update a single employee in the list.

```dart
void updateEmployee(Employee employee) {
  final updatedEmployees = state.employees.map((e) {
    return e.id == employee.id ? employee : e;
  }).toList();

  state = state.copyWith(employees: updatedEmployees);
}
```

**Purpose**: Sync employee list when detail screen makes changes

**getEmployeeById(String id)**

Get employee from current state without re-fetching.

```dart
Employee? getEmployeeById(String id) {
  try {
    return state.employees.firstWhere((e) => e.id == id);
  } catch (e) {
    return null;
  }
}
```

#### Usage Example

```dart
class StaffScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeState = ref.watch(employeeViewModelProvider);

    if (employeeState.isLoading) {
      return CircularProgressIndicator();
    }

    if (employeeState.error != null) {
      return Text('Error: ${employeeState.error}');
    }

    return ListView.builder(
      itemCount: employeeState.employees.length,
      itemBuilder: (context, index) {
        final employee = employeeState.employees[index];
        return EmployeeCard(employee: employee);
      },
    );
  }
}
```

---

### EmployeeDetailViewModel

**Location**: [lib/viewmodels/employee_detail_viewmodel.dart](../lib/viewmodels/employee_detail_viewmodel.dart)

**Purpose**: Manage single employee detail and work day operations

**Provider Definition**:
```dart
final employeeDetailViewModelProvider = NotifierProvider.family<
  EmployeeDetailViewModel,
  EmployeeDetailState,
  String  // employeeId parameter
>((ref, employeeId) => EmployeeDetailViewModel(employeeId));
```

#### State Definition

```dart
class EmployeeDetailState {
  final Employee? employee;
  final bool isLoading;
  final String? error;

  const EmployeeDetailState({
    this.employee,
    this.isLoading = false,
    this.error,
  });

  EmployeeDetailState copyWith({
    Employee? employee,
    bool? isLoading,
    String? error,
  }) { ... }
}
```

#### Constructor

```dart
class EmployeeDetailViewModel extends FamilyNotifier<EmployeeDetailState, String> {
  late final String employeeId;

  @override
  EmployeeDetailState build(String arg) {
    employeeId = arg;
    loadEmployee();  // Auto-load on creation
    return const EmployeeDetailState(isLoading: true);
  }
}
```

**Auto-load Pattern**: ViewModel automatically loads employee on creation

#### Methods

**loadEmployee()**

Load employee with current registration and shift.

```dart
Future<void> loadEmployee() async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final repository = ref.read(employeeRepositoryProvider);
    final employee = await repository.getEmployeeWithRegistration(employeeId);

    if (employee == null) {
      throw Exception('Employee not found');
    }

    state = state.copyWith(
      employee: employee,
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

**refresh()**

Reload employee data.

```dart
Future<void> refresh() => loadEmployee();
```

**startWorkday()**

Start employee work day with validation and synchronization.

```dart
Future<void> startWorkday() async {
  if (state.employee == null) return;

  state = state.copyWith(isLoading: true);

  try {
    // 1. Validate shift exists
    if (state.employee!.todayShift == null) {
      throw Exception('No shift assigned for today');
    }

    // 2. Start work day via repository
    final repository = ref.read(employeeRepositoryProvider);
    final updatedEmployee = await repository.startEmployeeWorkday(employeeId);

    // 3. Update local state
    state = state.copyWith(
      employee: updatedEmployee,
      isLoading: false,
    );

    // 4. Sync to main employee list
    ref.read(employeeViewModelProvider.notifier).updateEmployee(updatedEmployee);

    // 5. Sync to registrations list
    if (updatedEmployee.currentRegistration != null) {
      ref.read(employeeRegistrationsViewModelProvider(employeeId).notifier)
          .updateRegistration(updatedEmployee.currentRegistration!);
    }
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
    rethrow;
  }
}
```

**Flow**:
```
startWorkday() called
    ↓
Validate: todayShift exists?
    ├─ No → Throw error
    └─ Yes → Continue
    ↓
EmployeeRepository.startEmployeeWorkday()
    ├─ Validate no active registration
    ├─ Create TimeRegistration
    └─ Return updated Employee
    ↓
Update EmployeeDetailState
    ↓
Sync to EmployeeViewModel (update list)
    ↓
Sync to EmployeeRegistrationsViewModel (add new registration)
    ↓
UI updates automatically
```

**endWorkday()**

End employee work day with confirmation.

```dart
Future<void> endWorkday() async {
  if (state.employee == null || state.employee!.currentRegistration == null) {
    return;
  }

  state = state.copyWith(isLoading: true);

  try {
    final repository = ref.read(employeeRepositoryProvider);
    final updatedEmployee = await repository.endEmployeeWorkday(employeeId);

    state = state.copyWith(
      employee: updatedEmployee,
      isLoading: false,
    );

    // Sync to other ViewModels
    ref.read(employeeViewModelProvider.notifier).updateEmployee(updatedEmployee);

    if (updatedEmployee.currentRegistration != null) {
      ref.read(employeeRegistrationsViewModelProvider(employeeId).notifier)
          .updateRegistration(updatedEmployee.currentRegistration!);
    }
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
    rethrow;
  }
}
```

**pauseWorkday()** / **resumeWorkday()**

Similar pattern to start/end with state validation and synchronization.

```dart
Future<void> pauseWorkday() async {
  // Validate: registration exists, not already paused
  // Update via repository
  // Sync to other ViewModels
}

Future<void> resumeWorkday() async {
  // Validate: registration is paused
  // Update via repository
  // Sync to other ViewModels
}
```

#### Usage Example

```dart
class TimeRegistrationDetailScreen extends ConsumerWidget {
  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(employeeDetailViewModelProvider(employeeId));

    if (detailState.isLoading) {
      return CircularProgressIndicator();
    }

    final employee = detailState.employee;
    if (employee == null) {
      return Text('Employee not found');
    }

    return Column(
      children: [
        TimeGauge(registration: employee.currentRegistration),
        if (employee.currentRegistration == null)
          ElevatedButton(
            onPressed: () => ref.read(
              employeeDetailViewModelProvider(employeeId).notifier
            ).startWorkday(),
            child: Text('Start Work Day'),
          ),
        // ... other buttons based on state
      ],
    );
  }
}
```

---

### EmployeeProfileViewModel

**Location**: [lib/viewmodels/employee_profile_viewmodel.dart](../lib/viewmodels/employee_profile_viewmodel.dart)

**Purpose**: Manage employee profile information and updates

**Provider Definition**:
```dart
final employeeProfileViewModelProvider = NotifierProvider.family<
  EmployeeProfileViewModel,
  EmployeeProfileState,
  String
>((ref, employeeId) => EmployeeProfileViewModel(employeeId));
```

#### State Definition

```dart
class EmployeeProfileState {
  final Employee? employee;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const EmployeeProfileState({
    this.employee,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });
}
```

#### Methods

**loadProfile()**

Load employee profile information.

```dart
Future<void> loadProfile() async {
  state = state.copyWith(isLoading: true);

  try {
    final employeeService = ref.read(employeeServiceProvider);
    final employee = await employeeService.getEmployeeById(employeeId);

    state = state.copyWith(
      employee: employee,
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

**updateProfile(Employee employee)**

Update employee profile with validation.

```dart
Future<void> updateProfile(Employee employee) async {
  state = state.copyWith(isSaving: true);

  try {
    // Validate email and phone
    if (employee.email != null && !Employee.emailRegex.hasMatch(employee.email!)) {
      throw Exception('Invalid email format');
    }

    if (employee.phone != null && !Employee.phoneRegex.hasMatch(employee.phone!)) {
      throw Exception('Invalid phone format');
    }

    // Update via service
    final employeeService = ref.read(employeeServiceProvider);
    await employeeService.updateEmployee(employee);

    // Update local state
    state = state.copyWith(
      employee: employee,
      isSaving: false,
    );

    // Sync to main list
    ref.read(employeeViewModelProvider.notifier).updateEmployee(employee);
  } catch (e) {
    state = state.copyWith(
      isSaving: false,
      error: e.toString(),
    );
    rethrow;
  }
}
```

---

### EmployeeRegistrationsViewModel

**Location**: [lib/viewmodels/employee_registrations_viewmodel.dart](../lib/viewmodels/employee_registrations_viewmodel.dart)

**Purpose**: Manage employee time registration history

**Provider Definition**:
```dart
final employeeRegistrationsViewModelProvider = NotifierProvider.family<
  EmployeeRegistrationsViewModel,
  EmployeeRegistrationsState,
  String
>((ref, employeeId) => EmployeeRegistrationsViewModel(employeeId));
```

#### State Definition

```dart
class EmployeeRegistrationsState {
  final List<TimeRegistration> registrations;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const EmployeeRegistrationsState({
    this.registrations = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });
}
```

#### Methods

**loadRegistrations({int limit = 30})**

Load time registration history with pagination.

```dart
Future<void> loadRegistrations({int limit = 30}) async {
  state = state.copyWith(isLoading: true);

  try {
    final service = ref.read(timeRegistrationServiceProvider);
    final registrations = await service.getEmployeeRegistrations(
      employeeId,
      limit: limit,
    );

    state = state.copyWith(
      registrations: registrations,
      isLoading: false,
      hasMore: registrations.length >= limit,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

**loadMonthlyRegistrations(int year, int month)**

Load registrations for specific month.

```dart
Future<void> loadMonthlyRegistrations(int year, int month) async {
  state = state.copyWith(isLoading: true);

  try {
    final service = ref.read(timeRegistrationServiceProvider);
    final registrations = await service.getMonthlyRegistrations(
      employeeId,
      year,
      month,
    );

    state = state.copyWith(
      registrations: registrations,
      isLoading: false,
      hasMore: false,  // Monthly view shows all for month
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

**updateRegistration(TimeRegistration registration)**

Update or add registration in list (for synchronization).

```dart
void updateRegistration(TimeRegistration registration) {
  final existingIndex = state.registrations.indexWhere(
    (r) => r.id == registration.id,
  );

  List<TimeRegistration> updatedRegistrations;

  if (existingIndex != -1) {
    // Update existing
    updatedRegistrations = List.from(state.registrations);
    updatedRegistrations[existingIndex] = registration;
  } else {
    // Add new at beginning
    updatedRegistrations = [registration, ...state.registrations];
  }

  // Sort by date descending
  updatedRegistrations.sort((a, b) => b.startTime.compareTo(a.startTime));

  state = state.copyWith(registrations: updatedRegistrations);
}
```

---

### EmployeeShiftsViewModel

**Location**: [lib/viewmodels/employee_shifts_viewmodel.dart](../lib/viewmodels/employee_shifts_viewmodel.dart)

**Purpose**: Manage employee shift assignments

**Provider Definition**:
```dart
final employeeShiftsViewModelProvider = NotifierProvider.family<
  EmployeeShiftsViewModel,
  EmployeeShiftsState,
  String
>((ref, employeeId) => EmployeeShiftsViewModel(employeeId));
```

#### State Definition

```dart
class EmployeeShiftsState {
  final List<Shift> shifts;
  final bool isLoading;
  final String? error;

  const EmployeeShiftsState({
    this.shifts = const [],
    this.isLoading = false,
    this.error,
  });
}
```

#### Methods

**loadShifts({int limit = 30})**

Load employee shifts.

```dart
Future<void> loadShifts({int limit = 30}) async {
  state = state.copyWith(isLoading: true);

  try {
    final service = ref.read(shiftServiceProvider);
    final shifts = await service.getEmployeeShifts(employeeId, limit: limit);

    state = state.copyWith(
      shifts: shifts,
      isLoading: false,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}
```

**createShift(Shift shift)**

Create new shift assignment.

```dart
Future<void> createShift(Shift shift) async {
  try {
    final service = ref.read(shiftServiceProvider);
    await service.createShift(shift);

    // Reload shifts
    await loadShifts();

    // If shift is for today, sync to detail ViewModel
    if (shift.isToday) {
      ref.invalidate(employeeDetailViewModelProvider(employeeId));
    }
  } catch (e) {
    state = state.copyWith(error: e.toString());
    rethrow;
  }
}
```

**deleteShift(String shiftId)**

Delete shift with validation.

```dart
Future<void> deleteShift(String shiftId) async {
  try {
    final service = ref.read(shiftServiceProvider);
    await service.deleteShift(shiftId);

    // Remove from local state
    final updatedShifts = state.shifts.where((s) => s.id != shiftId).toList();
    state = state.copyWith(shifts: updatedShifts);
  } catch (e) {
    state = state.copyWith(error: e.toString());
    rethrow;
  }
}
```

---

### ThemeViewModel

**Location**: [lib/viewmodels/theme_viewmodel.dart](../lib/viewmodels/theme_viewmodel.dart)

**Purpose**: Manage app theme state and persistence

**Provider Definition**:
```dart
final themeViewModelProvider = NotifierProvider<ThemeViewModel, ThemeState>(
  () => ThemeViewModel(),
);
```

#### State Definition

```dart
class ThemeState {
  final ThemeType themeType;
  final bool isLoading;

  const ThemeState({
    this.themeType = ThemeType.system,
    this.isLoading = false,
  });

  ThemeState copyWith({
    ThemeType? themeType,
    bool? isLoading,
  }) { ... }
}
```

#### Methods

**initialize(Brightness systemBrightness)**

Initialize theme from saved preference or system setting.

```dart
Future<void> initialize(Brightness systemBrightness) async {
  state = state.copyWith(isLoading: true);

  final prefs = ref.read(sharedPreferencesProvider);
  final savedTheme = prefs.getString('theme_preference');

  ThemeType themeType;

  if (savedTheme != null) {
    // Use saved preference
    themeType = ThemeType.values.firstWhere(
      (t) => t.toString() == savedTheme,
      orElse: () => ThemeType.system,
    );
  } else {
    // Use system brightness
    themeType = ThemeType.system;
  }

  state = state.copyWith(
    themeType: themeType,
    isLoading: false,
  );
}
```

**setTheme(ThemeType type)**

Update theme and save preference.

```dart
Future<void> setTheme(ThemeType type) async {
  state = state.copyWith(themeType: type);

  final prefs = ref.read(sharedPreferencesProvider);
  await prefs.setString('theme_preference', type.toString());
}
```

**getThemeData(Brightness systemBrightness)**

Get ThemeData based on current theme type.

```dart
ThemeData getThemeData(Brightness systemBrightness) {
  switch (state.themeType) {
    case ThemeType.light:
      return MyTheme.light().toThemeData();
    case ThemeType.dark:
      return MyTheme.dark().toThemeData();
    case ThemeType.system:
      return systemBrightness == Brightness.dark
          ? MyTheme.dark().toThemeData()
          : MyTheme.light().toThemeData();
  }
}
```

#### Usage Example

```dart
class App extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeViewModelProvider);
    final systemBrightness = MediaQuery.of(context).platformBrightness;

    return MaterialApp.router(
      theme: ref.read(themeViewModelProvider.notifier)
          .getThemeData(systemBrightness),
      routerConfig: router,
    );
  }
}
```

---

## State Synchronization

Timely uses an **explicit synchronization pattern** to keep related states consistent across ViewModels.

### Synchronization Pattern

When a ViewModel updates data that affects other ViewModels, it explicitly notifies them:

```dart
// In EmployeeDetailViewModel.startWorkday()

// 1. Update local state
state = state.copyWith(employee: updatedEmployee);

// 2. Sync to main employee list
ref.read(employeeViewModelProvider.notifier)
    .updateEmployee(updatedEmployee);

// 3. Sync to registrations list
ref.read(employeeRegistrationsViewModelProvider(employeeId).notifier)
    .updateRegistration(updatedEmployee.currentRegistration!);
```

### Synchronization Flow

```
User action in TimeRegistrationDetailScreen
    ↓
EmployeeDetailViewModel.startWorkday()
    ↓
    ├─ Update EmployeeDetailState (local)
    ├─ Sync to EmployeeViewModel (list)
    └─ Sync to EmployeeRegistrationsViewModel (history)
    ↓
All watching widgets rebuild automatically
```

### Why Explicit Synchronization?

**Advantages**:
- **Predictable**: Clear flow of updates
- **Performant**: Only updates what's needed
- **Debuggable**: Easy to trace state changes
- **Flexible**: Can customize sync logic per operation

**Alternative (not used)**:
- Global state stream (complex, hard to debug)
- Automatic sync (can cause infinite loops)
- Full reload (inefficient, poor UX)

---

## Data Loading Strategies

### Initial Load Pattern

Used by FutureProviders for one-time data loading:

```dart
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final service = ref.read(configServiceProvider);
  return await service.getConfig();
});

// In UI
final configAsync = ref.watch(appConfigProvider);

configAsync.when(
  data: (config) => Content(config),
  loading: () => LoadingIndicator(),
  error: (error, stack) => ErrorMessage(error),
);
```

### Manual Load Pattern

Used by ViewModels for user-triggered loading:

```dart
class EmployeeViewModel extends Notifier<EmployeeState> {
  @override
  EmployeeState build() {
    // Don't auto-load, wait for explicit call
    return const EmployeeState();
  }

  Future<void> loadEmployees() async {
    state = state.copyWith(isLoading: true);
    // ... load and update state
  }
}

// In UI (SplashScreen)
Future.microtask(() async {
  await ref.read(employeeViewModelProvider.notifier).loadEmployees();
});
```

### Auto-Load Pattern

Used by family ViewModels for automatic loading on creation:

```dart
class EmployeeDetailViewModel extends FamilyNotifier<EmployeeDetailState, String> {
  @override
  EmployeeDetailState build(String employeeId) {
    loadEmployee();  // Auto-load
    return const EmployeeDetailState(isLoading: true);
  }

  Future<void> loadEmployee() async {
    // ... load employee
  }
}

// In UI - just watch, loading happens automatically
final detailState = ref.watch(employeeDetailViewModelProvider(employeeId));
```

### Refresh Pattern

Provide manual refresh capability:

```dart
// In ViewModel
Future<void> refresh() => loadEmployees();

// In UI with RefreshIndicator
RefreshIndicator(
  onRefresh: () => ref.read(employeeViewModelProvider.notifier).refresh(),
  child: EmployeeList(...),
)
```

### Pagination Pattern

Load more data as needed:

```dart
class EmployeeRegistrationsViewModel extends FamilyNotifier<...> {
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoading: true);

    final newRegistrations = await service.getEmployeeRegistrations(
      employeeId,
      offset: state.registrations.length,
      limit: 30,
    );

    state = state.copyWith(
      registrations: [...state.registrations, ...newRegistrations],
      isLoading: false,
      hasMore: newRegistrations.length >= 30,
    );
  }
}

// In UI with scroll listener
if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
  ref.read(employeeRegistrationsViewModelProvider(employeeId).notifier).loadMore();
}
```

---

## State Lifecycle

### Complete Application Lifecycle

```
1. App Launch (main.dart)
    ↓
    ├─ Initialize WidgetsFlutterBinding
    ├─ Initialize SharedPreferences
    ├─ Initialize Firebase (prod only)
    └─ Create ProviderScope
    ↓
2. App Widget (app.dart)
    ↓
    ├─ Initialize ThemeViewModel
    └─ Create MaterialApp with router
    ↓
3. SplashScreen (/splash)
    ↓
    ├─ Load EmployeeViewModel.loadEmployees()
    │   ├─ State: loading
    │   ├─ Fetch from repository
    │   └─ State: loaded
    ├─ Initialize ThemeViewModel
    └─ Navigate to /staff
    ↓
4. StaffScreen (/staff)
    ↓
    ├─ Watch EmployeeViewModel (already loaded)
    └─ Display employee list
    ↓
5. User selects employee → /employee/:id
    ↓
6. TimeRegistrationDetailScreen
    ↓
    ├─ Create EmployeeDetailViewModel(id) [auto-loads]
    ├─ Watch EmployeeDetailViewModel
    └─ Display time gauge and buttons
    ↓
7. User taps "Start Work Day"
    ↓
    ├─ EmployeeDetailViewModel.startWorkday()
    ├─ Update TimeRegistration
    ├─ Sync to EmployeeViewModel
    ├─ Sync to EmployeeRegistrationsViewModel
    └─ UI updates
```

### ViewModel Lifecycle

**Creation**:
```
NotifierProvider created
    ↓
build() method called
    ├─ Initialize state
    ├─ Auto-load data (if using auto-load pattern)
    └─ Return initial state
```

**Update**:
```
Method called on ViewModel
    ↓
Update state via state = newState
    ↓
Riverpod notifies all watchers
    ↓
Widgets rebuild with new state
```

**Disposal**:
```
Last widget stops watching
    ↓
NotifierProvider disposed
    ↓
State cleaned up
```

**Family Provider Caching**:
```
NotifierProvider.family(ref, param)
    ↓
Check cache for existing instance with param
    ├─ Found → Return cached instance
    └─ Not found → Create new, cache, return
```

---

## Best Practices

### 1. Immutable State

Always use `copyWith` to update state:

```dart
// ✅ Good
state = state.copyWith(isLoading: true);

// ❌ Bad
state.isLoading = true;  // Won't work, state is final
```

### 2. Error Handling

Always handle errors in async operations:

```dart
Future<void> loadEmployees() async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final employees = await repository.getEmployees();
    state = state.copyWith(employees: employees, isLoading: false);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}
```

### 3. Loading States

Provide visual feedback during operations:

```dart
// Set loading before async operation
state = state.copyWith(isLoading: true);

try {
  // ... async operation
} finally {
  // Always clear loading state
  state = state.copyWith(isLoading: false);
}
```

### 4. Validation Before Operations

Validate state before performing operations:

```dart
Future<void> startWorkday() async {
  if (state.employee == null) return;  // Guard clause

  if (state.employee!.todayShift == null) {
    throw Exception('No shift assigned');  // Business rule validation
  }

  // ... proceed with operation
}
```

### 5. Explicit Synchronization

Always sync related ViewModels after updates:

```dart
// Update local state
state = state.copyWith(employee: updated);

// Sync to related ViewModels
ref.read(employeeViewModelProvider.notifier).updateEmployee(updated);
ref.read(employeeRegistrationsViewModelProvider(id).notifier).refresh();
```

### 6. Use Family for Parameterized State

Use NotifierProvider.family for entity-specific ViewModels:

```dart
// ✅ Good - separate instance per employee
final employeeDetailViewModelProvider = NotifierProvider.family<...>(...)

// ❌ Bad - shared instance, complex state management
final employeeDetailViewModelProvider = NotifierProvider<...>(...)
```

### 7. Dispose Resources

Clean up timers, listeners, etc. in dispose:

```dart
class _ScreenState extends ConsumerState<Screen> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
```

### 8. Read vs Watch

Use `ref.read()` for one-time reads, `ref.watch()` for reactive updates:

```dart
// ✅ Watch - rebuilds when state changes
final state = ref.watch(employeeViewModelProvider);

// ✅ Read - one-time access, no rebuild
onPressed: () {
  ref.read(employeeViewModelProvider.notifier).loadEmployees();
}

// ❌ Bad - watch in callback causes unnecessary rebuilds
onPressed: () {
  ref.watch(employeeViewModelProvider.notifier).loadEmployees();
}
```

---

## Summary

The Timely state management architecture provides:

- **Clear Separation**: ViewModels manage state, services manage data access
- **Predictable Updates**: Explicit state changes with immutable objects
- **Synchronization**: Related states kept consistent through explicit updates
- **Performance**: Only rebuilds widgets watching changed providers
- **Testability**: ViewModels can be tested independently
- **Scalability**: Easy to add new ViewModels without affecting existing ones

For UI integration, see [APP_FLOW.md](./APP_FLOW.md).
For data models and services, see [DATA.md](./DATA.md).
