# State Management con Riverpod 3.0

[Ver versión en español](./STATE_MANAGEMENT.esp.md)

## Introducción

Timely utiliza **Riverpod 3.0** como su solución de gestión de estado. Esta versión introduce la nueva API de `Notifier` que reemplaza a `StateNotifier`, proporcionando una API más simple y consistente.

## Conceptos Fundamentales

### 1. Provider

Un **Provider** es un objeto que encapsula estado y permite a los widgets observarlo.

### 2. Notifier

Un **Notifier** es una clase que gestiona estado de manera más compleja, con lógica de negocio.

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

`WidgetRef` es un objeto que permite interacción con providers desde widgets.

## Arquitectura de Gestión de Estado en Timely

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
│  - Gestiona estado de UI                 │
│  - Llama a Repository                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        Repository                   │
│  - Lógica de negocio                   │
│  - Combina servicios                │
└─────────────────────────────────────┘
```

## Tipos de Providers en Timely

### 1. NotifierProvider (Estado Simple)

Para estado local simple sin parámetros.

**Ejemplo: ThemeViewModel**

```dart
// Estado
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

### 2. NotifierProvider.family (Estado Parametrizado)

Para estado que depende de un parámetro (ej. ID de empleado).

**Ejemplo: EmployeeDetailViewModel**

```dart
// Estado
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

// ViewModel con parámetro (employeeId)
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
    EmployeeDetailViewModel, 
    EmployeeDetailState, 
    String>(
  EmployeeDetailViewModel.new,
);
```

### 3. Provider (Servicios/Dependencias)

Para proporcionar dependencias (servicios, repositorios).

```dart
// Provider de SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden');
});

// Provider de servicio
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  if (Environment.isDev) {
    return MockEmployeeService();
  } else {
    return FirebaseEmployeeService();
  }
});

// Provider de repositorio
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    employeeService: ref.watch(employeeServiceProvider),
    timeRegistrationService: ref.watch(timeRegistrationServiceProvider),
  );
});
```

## Patrones de Uso

### Patrón 1: ref.watch vs ref.read vs ref.listen

#### ref.watch
**Cuándo:** En el método `build` para reaccionar a cambios.

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ CORRECTO: Escucha cambios y reconstruye
  final employees = ref.watch(employeeViewModelProvider);
  return ListView.builder(...);
}
```

#### ref.read
**Cuándo:** En callbacks (onPressed, onTap, etc.) para leer el valor una vez.

```dart
ElevatedButton(
  // ✅ CORRECTO: Lee valor sin escuchar cambios
  onPressed: () => ref.read(employeeViewModelProvider.notifier).load(),
  child: Text('Load'),
)
```

#### ref.listen
**Cuándo:** Para efectos secundarios (navegación, snackbars, etc.).

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ CORRECTO: Ejecuta efecto secundario cuando cambia el estado
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

### Patrón 2: Modificando Providers Correctamente

#### ❌ INCORRECTO: Modificar en initState

```dart
@override
void initState() {
  super.initState();
  // ❌ ERROR: Modificando provider durante build
  ref.read(employeeViewModelProvider.notifier).loadEmployees();
}
```

**Error:**
```
Tried to modify a provider while the widget tree was building.
```

#### ✅ CORRECTO: Usar Future.microtask

```dart
@override
void initState() {
  super.initState();
  // ✅ CORRECTO: Retrasar modificación
  Future.microtask(() {
    ref.read(employeeViewModelProvider.notifier).loadEmployees();
  });
}
```

### Patrón 3: Estado Inmutable con copyWith

Siempre usar `copyWith` para actualizar estado:

```dart
// ❌ INCORRECTO: Mutación directa
state.employees.add(newEmployee); // No compila (es final)

// ✅ CORRECTO: Crear nuevo estado
state = state.copyWith(
  employees: [...state.employees, newEmployee],
);
```

### Patrón 4: Manejo de Errores

```dart
Future<void> loadEmployees() async {
  // 1. Indicar carga
  state = state.copyWith(isLoading: true, error: null);

  try {
    // 2. Operación asíncrona
    final employees = await _repository.getEmployees();

    // 3. Actualizar con éxito
    state = state.copyWith(
      employees: employees,
      isLoading: false,
    );
  } catch (e, stackTrace) {
    // 4. Manejar error
    print('Error: $e');
    print('Stack: $stackTrace');

    state = state.copyWith(
      isLoading: false,
      error: 'Error loading employees: $e',
    );

    // 5. Opcional: Re-lanzar para manejo UI
    rethrow;
  }
}
```

### Patrón 5: Select para Optimización

Usar `select` para escuchar solo parte del estado:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ Solo reconstruye cuando cambia isLoading
  final isLoading = ref.watch(
    employeeViewModelProvider.select((state) => state.isLoading),
  );

  if (isLoading) {
    return CircularProgressIndicator();
  }

  return EmployeeList();
}
```

## Mejores Prácticas

### 1. Un Provider por Feature

```dart
// ✅ BUENO: Provider específico
final employeeListViewModelProvider = ...;
final employeeDetailViewModelProvider = ...;

// ❌ MALO: Provider genérico para todo
final appStateProvider = ...;
```

### 2. Estados Granulares

```dart
// ✅ BUENO: Estados separados
class EmployeeState {
  final List<Employee> employees;
  final bool isLoading;
  final String? error;
}

// ❌ MALO: Todo en un Map
class AppState {
  final Map<String, dynamic> data;
}
```

### 3. Siempre Inmutable

```dart
// ✅ BUENO
class EmployeeState {
  final List<Employee> employees; // final = inmutable

  const EmployeeState({required this.employees});
}

// ❌ MALO
class EmployeeState {
  List<Employee> employees; // mutable
}
```

### 4. Separar Lógica de la UI

```dart
// ✅ BUENO: Lógica en ViewModel
class EmployeeViewModel extends Notifier<EmployeeState> {
  Future<void> startWorkday(String id) async {
    final employee = await _repository.startWorkday(id);
    state = state.copyWith(/* ... */);
  }
}

// ❌ MALO: Lógica en Widget
class EmployeeCard extends StatelessWidget {
  void _onStartWorkday() async {
    final response = await http.post(/* ... */);
    // ... lógica de negocio aquí
  }
}
```

### 5. Nombres Descriptivos

```dart
// ✅ BUENO
final employeeListViewModelProvider = ...;
final employeeDetailViewModelProvider = ...;

// ❌ MALO
final provider1 = ...;
final employeeProvider = ...; // ¿Lista? Detalle?
```

## Providers Específicos de Timely

### EmployeeViewModel

```dart
final employeeViewModelProvider =
    NotifierProvider<EmployeeViewModel, EmployeeState>(
        EmployeeViewModel.new
    );

class EmployeeViewModel extends Notifier<EmployeeState> {
  late EmployeeRepository _repository;

  @override
  EmployeeState build() {
    _repository = ref.read(employeeRepositoryProvider);
    return const EmployeeState();
  }

  Future<void> loadEmployees() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final employees = await _repository.getEmployeesWithTodayRegistration();
      state = state.copyWith(employees: employees, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refreshEmployees() async {
    // Similar a loadEmployees pero para pull-to-refresh
    await loadEmployees();
  }
}
```

### EmployeeDetailViewModel (Family)

```dart
final employeeDetailViewModelProvider =
    NotifierProvider.family<EmployeeDetailViewModel, EmployeeDetailState, String>(
        EmployeeDetailViewModel.new
    );

class EmployeeDetailViewModel extends Notifier<EmployeeDetailState> {
  EmployeeDetailViewModel(this.employeeId);

  final String employeeId;
  late EmployeeRepository _repository;

  @override
  EmployeeDetailState build() {
    _repository = ref.read(employeeRepositoryProvider);
    return const EmployeeDetailState();
  }

  Future<void> startWorkday() async {
    try {
      state = state.copyWith(isLoading: true);
      final updatedEmployee = await _repository.startEmployeeWorkday(employeeId);
      state = state.copyWith(employee: updatedEmployee, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> endWorkday() async {
    try {
      state = state.copyWith(isLoading: true);
      final updatedEmployee = await _repository.endEmployeeWorkday(employeeId);
      state = state.copyWith(employee: updatedEmployee, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> pauseWorkday() async {
    try {
      state = state.copyWith(isLoading: true);
      final updatedEmployee = await _repository.pauseEmployeeWorkday(employeeId);
      state = state.copyWith(employee: updatedEmployee, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> resumeWorkday() async {
    try {
      state = state.copyWith(isLoading: true);
      final updatedEmployee = await _repository.resumeEmployeeWorkday(employeeId);
      state = state.copyWith(employee: updatedEmployee, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

### ThemeViewModel

```dart
final themeViewModelProvider =
    NotifierProvider<ThemeViewModel, ThemeState>(
        ThemeViewModel.new
    );

class ThemeViewModel extends Notifier<ThemeState> {
  late SharedPreferences _prefs;

  @override
  ThemeState build() {
    _prefs = ref.read(sharedPreferencesProvider);
    final savedTheme = _prefs.getString('theme');
    return ThemeState(
      themeType: savedTheme != null 
          ? ThemeType.values.firstWhere((t) => t.toString() == savedTheme)
          : ThemeType.system,
    );
  }

  Future<void> setTheme(ThemeType themeType) async {
    state = state.copyWith(themeType: themeType);
    await _prefs.setString('theme', themeType.toString());
  }

  Future<void> toggleTheme() async {
    final newTheme = state.themeType == ThemeType.light 
        ? ThemeType.dark 
        : ThemeType.light;
    await setTheme(newTheme);
  }

  ThemeData getThemeData(BuildContext context) {
    switch (state.themeType) {
      case ThemeType.light:
        return MyTheme.light;
      case ThemeType.dark:
        return MyTheme.dark;
      case ThemeType.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        return brightness == Brightness.dark ? MyTheme.dark : MyTheme.light;
    }
  }
}
```

## Recursos

- [Documentación Oficial de Riverpod](https://riverpod.dev)
- [Guía de Migración a Riverpod 3.0](https://riverpod.dev/docs/3.0_migration)
- [Mejores Prácticas de Riverpod](https://riverpod.dev/docs/concepts/modifiers/family)

---

## Licencia

Esta documentación es parte del proyecto Timely, licenciado bajo una Licencia de Código Abierto Personalizada con Restricciones Comerciales.

Para términos completos, ver el archivo [LICENSE](../../LICENSE).

---

**Última Actualización:** Enero 2026