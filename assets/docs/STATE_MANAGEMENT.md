# State Management with Riverpod 3.0

[Ver versión en español](./STATE_MANAGEMENT.esp.md)

## Introduction

Timely uses **Riverpod 3.0** as its state management solution. This version introduces the new `Notifier` API that replaces `StateNotifier`, providing a simpler and more consistent API.

## Fundamental Concepts

### 1. Provider

A **Provider** is an object that encapsulates state and allows widgets to observe it.

### 2. Notifier

A **Notifier** is a class that manages state in a more complex way, with business logic.

```dart
class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
}

final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);
```

### 3. WidgetRef

`WidgetRef` is the object that allows interaction with providers from widgets.

## State Management Architecture in Timely

```
┌─────────────────────────────────────┐
│          UI (Widgets)               │
│  - ConsumerWidget/StatefulWidget    │
└──────────────┬──────────────────────┘
               │ ref.watch / ref.read
               │
┌──────────────▼──────────────────────┐
│         ViewModels                  │
│  - Notifier<State>                  │
│  - Manages UI state                 │
│  - Calls Repository                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        Repository                   │
│  - Business logic                   │
│  - Combines services                │
└─────────────────────────────────────┘
```

## Types of Providers in Timely

### 1. NotifierProvider (Simple State)

For simple local state without parameters.

**Example: ThemeViewModel**

```dart
// State
class ThemeState {
  final ThemeType themeType;
  final bool isLoading;

  const ThemeState({
    required this.themeType,
    this.isLoading = false,
  });

  ThemeState copyWith({
    ThemeType? themeType,
    bool? isLoading,
  }) {
    return ThemeState(
      themeType: themeType ?? this.themeType,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ViewModel
class ThemeViewModel extends Notifier<ThemeState> {
  late SharedPreferences _prefs;

  @override
  ThemeState build() {
    _prefs = ref.read(sharedPreferencesProvider);
    return const ThemeState(themeType: ThemeType.system);
  }

  Future<void> setTheme(ThemeType theme) async {
    state = state.copyWith(themeType: theme);
    await _prefs.setString('theme', theme.toString());
  }
}

// Provider
final themeViewModelProvider =
    NotifierProvider<ThemeViewModel, ThemeState>(ThemeViewModel.new);
```

### 2. NotifierProvider.family (Parameterized State)

For state that depends on a parameter (e.g., employee ID).

**Example: EmployeeDetailViewModel**

```dart
// State
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
  }) {
    return EmployeeDetailState(
      employee: employee ?? this.employee,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ViewModel with parameter (employeeId)
class EmployeeDetailViewModel extends Notifier<EmployeeDetailState> {
  EmployeeDetailViewModel(this.employeeId);

  final String employeeId;
  late EmployeeRepository _repository;

  @override
  EmployeeDetailState build() {
    _repository = ref.read(employeeRepositoryProvider);
    return const EmployeeDetailState();
  }

  Future<void> loadEmployee() async {
    state = state.copyWith(isLoading: true);
    try {
      final employee = await _repository.getEmployee(employeeId);
      state = state.copyWith(employee: employee, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

// Provider.family
final employeeDetailViewModelProvider = NotifierProvider.family<
    EmployeeDetailViewModel, EmployeeDetailState, String>(
  EmployeeDetailViewModel.new,
);
```

### 3. Provider (Services/Dependencies)

For providing dependencies (services, repositories).

```dart
// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden');
});

// Service provider
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  if (Environment.isDev) {
    return MockEmployeeService();
  } else {
    return FirebaseEmployeeService();
  }
});

// Repository provider
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    employeeService: ref.watch(employeeServiceProvider),
    timeRegistrationService: ref.watch(timeRegistrationServiceProvider),
  );
});
```

## Usage Patterns

### Pattern 1: ref.watch vs ref.read vs ref.listen

#### ref.watch
**When:** In the `build` method to react to changes.

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ CORRECT: Listens to changes and rebuilds
  final employees = ref.watch(employeeViewModelProvider);
  return ListView.builder(...);
}
```

#### ref.read
**When:** In callbacks (onPressed, onTap, etc.) to read the value once.

```dart
ElevatedButton(
  // ✅ CORRECT: Reads value without listening to changes
  onPressed: () => ref.read(employeeViewModelProvider.notifier).load(),
  child: Text('Load'),
)
```

#### ref.listen
**When:** For side effects (navigation, snackbars, etc.).

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ CORRECT: Executes side effect when state changes
  ref.listen<EmployeeState>(
    employeeViewModelProvider,
    (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    },
  );

  return Scaffold(...);
}
```

### Pattern 2: Modifying Providers Correctly

#### ❌ INCORRECT: Modifying in initState

```dart
@override
void initState() {
  super.initState();
  // ❌ ERROR: Modifying provider during build
  ref.read(employeeViewModelProvider.notifier).loadEmployees();
}
```

**Error:**
```
Tried to modify a provider while the widget tree was building.
```

#### ✅ CORRECT: Use Future.microtask

```dart
@override
void initState() {
  super.initState();
  // ✅ CORRECT: Delaying modification
  Future.microtask(() {
    ref.read(employeeViewModelProvider.notifier).loadEmployees();
  });
}
```

### Pattern 3: Immutable State with copyWith

Always use `copyWith` to update state:

```dart
// ❌ INCORRECT: Direct mutation
state.employees.add(newEmployee); // Doesn't compile (it's final)

// ✅ CORRECT: Create new state
state = state.copyWith(
  employees: [...state.employees, newEmployee],
);
```

### Pattern 4: Error Handling

```dart
Future<void> loadEmployees() async {
  // 1. Indicate loading
  state = state.copyWith(isLoading: true, error: null);

  try {
    // 2. Async operation
    final employees = await _repository.getEmployees();

    // 3. Update with success
    state = state.copyWith(
      employees: employees,
      isLoading: false,
    );
  } catch (e, stackTrace) {
    // 4. Handle error
    print('Error: $e');
    print('Stack: $stackTrace');

    state = state.copyWith(
      isLoading: false,
      error: 'Error loading employees: $e',
    );

    // 5. Optional: Re-throw for UI handling
    rethrow;
  }
}
```

### Pattern 5: Select for Optimization

Use `select` to listen to only part of the state:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ Only rebuilds when isLoading changes
  final isLoading = ref.watch(
    employeeViewModelProvider.select((state) => state.isLoading),
  );

  if (isLoading) {
    return CircularProgressIndicator();
  }

  return EmployeeList();
}
```

## Best Practices

### 1. One Provider per Feature
```dart
// ✅ GOOD: Specific provider
final employeeListProvider = ...;
final employeeDetailProvider = ...;

// ❌ BAD: Generic provider for everything
final appStateProvider = ...;
```

### 2. Granular States
```dart
// ✅ GOOD: Separate states
class EmployeeState {
  final List<Employee> employees;
  final bool isLoading;
  final String? error;
}

// ❌ BAD: Everything in a Map
class AppState {
  final Map<String, dynamic> data;
}
```

### 3. Always Immutable
```dart
// ✅ GOOD
class EmployeeState {
  final List<Employee> employees; // final = immutable

  const EmployeeState({required this.employees});
}

// ❌ BAD
class EmployeeState {
  List<Employee> employees; // mutable
}
```

### 4. Separate Logic from UI
```dart
// ✅ GOOD: Logic in ViewModel
class EmployeeViewModel extends Notifier<EmployeeState> {
  Future<void> startWorkday(String id) async {
    final employee = await _repository.startWorkday(id);
    state = state.copyWith(/* ... */);
  }
}

// ❌ BAD: Logic in Widget
class EmployeeCard extends StatelessWidget {
  void _onStartWorkday() async {
    final response = await http.post(/* ... */);
    // ... business logic here
  }
}
```

### 5. Descriptive Names
```dart
// ✅ GOOD
final employeeListViewModelProvider = ...;
final employeeDetailViewModelProvider = ...;

// ❌ BAD
final provider1 = ...;
final employeeProvider = ...; // List? Detail?
```

## Resources

- [Riverpod Official Docs](https://riverpod.dev)
- [Riverpod 3.0 Migration Guide](https://riverpod.dev/docs/3.0_migration)
- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/modifiers/family)

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** December 2025
