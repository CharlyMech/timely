# State Management con Riverpod 3.0

## Introducción

Timely utiliza **Riverpod 3.0** como solución de state management. Esta versión introduce la nueva API de `Notifier` que reemplaza a `StateNotifier`, proporcionando una API más simple y consistente.

## Conceptos Fundamentales

### 1. Provider

Un **Provider** es un objeto que encapsula un estado y permite que los widgets lo observen.

```dart
final counterProvider = StateProvider<int>((ref) => 0);
```

### 2. Notifier

Un **Notifier** es una clase que gestiona el estado de manera más compleja, con lógica de negocio.

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

`WidgetRef` es el objeto que permite interactuar con providers desde widgets.

```dart
// En ConsumerWidget
@override
Widget build(BuildContext context, WidgetRef ref) {
  final count = ref.watch(counterProvider);
  return Text('$count');
}

// En ConsumerStatefulWidget
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}
```

## Arquitectura de State Management en Timely

### Capa de Estado (ViewModels)

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
│  - Gestiona estado de UI            │
│  - Llama a Repository               │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        Repository                   │
│  - Lógica de negocio                │
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

**Uso en UI:**

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeViewModelProvider);

    return Switch(
      value: themeState.themeType == ThemeType.dark,
      onChanged: (isDark) {
        ref.read(themeViewModelProvider.notifier).setTheme(
          isDark ? ThemeType.dark : ThemeType.light,
        );
      },
    );
  }
}
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
    EmployeeDetailViewModel, EmployeeDetailState, String>(
  EmployeeDetailViewModel.new,
);
```

**Uso en UI:**

```dart
class EmployeeDetailScreen extends ConsumerWidget {
  const EmployeeDetailScreen({required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pasar el employeeId al provider
    final state = ref.watch(employeeDetailViewModelProvider(employeeId));

    if (state.isLoading) {
      return CircularProgressIndicator();
    }

    return Text(state.employee?.name ?? 'Unknown');
  }
}
```

### 3. Provider (Servicios/Dependencias)

Para proveer dependencias (servicios, repositorios).

**Ejemplo: Providers de Configuración**

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

### Pattern 1: ref.watch vs ref.read vs ref.listen

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
  // ✅ CORRECTO: Lee el valor sin escuchar cambios
  onPressed: () => ref.read(employeeViewModelProvider.notifier).load(),
  child: Text('Cargar'),
)
```

#### ref.listen
**Cuándo:** Para side effects (navegación, snackbars, etc.).

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✅ CORRECTO: Ejecuta side effect cuando cambia el estado
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

### Pattern 2: Modificar Providers Correctamente

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
  // ✅ CORRECTO: Delaying la modificación
  Future.microtask(() {
    ref.read(employeeViewModelProvider.notifier).loadEmployees();
  });
}
```

### Pattern 3: Estado Inmutable con copyWith

Siempre usar `copyWith` para actualizar estado:

```dart
// ❌ INCORRECTO: Mutación directa
state.employees.add(newEmployee); // No compila (es final)

// ✅ CORRECTO: Crear nuevo estado
state = state.copyWith(
  employees: [...state.employees, newEmployee],
);
```

### Pattern 4: Manejo de Errores

```dart
Future<void> loadEmployees() async {
  // 1. Indicar carga
  state = state.copyWith(isLoading: true, error: null);

  try {
    // 2. Operación async
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
      error: 'Error al cargar empleados: $e',
    );

    // 5. Opcional: Re-throw para que UI maneje
    rethrow;
  }
}
```

### Pattern 5: Select para Optimización

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

## Ciclo de Vida de Providers

### Auto-dispose

Por defecto, los providers en Riverpod 3.0 tienen auto-dispose activado.

```dart
// Se destruye automáticamente cuando no tiene listeners
final employeeProvider = NotifierProvider<EmployeeViewModel, EmployeeState>(
  EmployeeViewModel.new,
);

// Mantener vivo permanentemente
final employeeProvider = NotifierProvider<EmployeeViewModel, EmployeeState>(
  EmployeeViewModel.new,
  keepAlive: true,
);
```

### Family Providers

Los family providers crean instancias separadas por parámetro:

```dart
// Crea una instancia para cada employeeId diferente
ref.watch(employeeDetailViewModelProvider('123'));
ref.watch(employeeDetailViewModelProvider('456'));

// Dos instancias diferentes, estados independientes
```

## Testing con Riverpod

### Unit Tests de ViewModels

```dart
void main() {
  test('EmployeeViewModel carga empleados correctamente', () async {
    // 1. Crear container con mock repository
    final container = ProviderContainer(
      overrides: [
        employeeRepositoryProvider.overrideWithValue(
          MockEmployeeRepository(),
        ),
      ],
    );

    // 2. Leer el notifier
    final notifier = container.read(employeeViewModelProvider.notifier);

    // 3. Ejecutar acción
    await notifier.loadEmployees();

    // 4. Verificar estado
    final state = container.read(employeeViewModelProvider);
    expect(state.employees.length, 6);
    expect(state.isLoading, false);
    expect(state.error, null);

    // 5. Limpiar
    container.dispose();
  });
}
```

### Widget Tests con Providers

```dart
testWidgets('StaffScreen muestra empleados', (tester) async {
  // 1. Crear widget con ProviderScope
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        employeeViewModelProvider.overrideWith(
          () => MockEmployeeViewModel(),
        ),
      ],
      child: MaterialApp(
        home: StaffScreen(),
      ),
    ),
  );

  // 2. Verificar UI
  await tester.pump();
  expect(find.text('Personal'), findsOneWidget);
  expect(find.byType(EmployeeCard), findsNWidgets(6));
});
```

## Debugging

### Logging de Estados

```dart
class EmployeeViewModel extends Notifier<EmployeeState> {
  @override
  EmployeeState build() {
    print('🔵 EmployeeViewModel: Inicializando');
    return const EmployeeState();
  }

  Future<void> loadEmployees() async {
    print('🔵 Cargando empleados...');
    // ...
    print('✅ Empleados cargados: ${state.employees.length}');
  }
}
```

### Riverpod DevTools

```dart
// Habilitar logging en desarrollo
void main() {
  runApp(
    ProviderScope(
      observers: [
        if (kDebugMode) LoggerProviderObserver(),
      ],
      child: const App(),
    ),
  );
}

class LoggerProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('[${provider.name ?? provider.runtimeType}] $newValue');
  }
}
```

## Best Practices

### 1. Un Provider por Feature
```dart
// ✅ BIEN: Provider específico
final employeeListProvider = ...;
final employeeDetailProvider = ...;

// ❌ MAL: Provider genérico para todo
final appStateProvider = ...;
```

### 2. Estados Granulares
```dart
// ✅ BIEN: Estados separados
class EmployeeState {
  final List<Employee> employees;
  final bool isLoading;
  final String? error;
}

// ❌ MAL: Todo en un Map
class AppState {
  final Map<String, dynamic> data;
}
```

### 3. Inmutabilidad Siempre
```dart
// ✅ BIEN
class EmployeeState {
  final List<Employee> employees; // final = immutable

  const EmployeeState({required this.employees});
}

// ❌ MAL
class EmployeeState {
  List<Employee> employees; // mutable
}
```

### 4. Separar Lógica de UI
```dart
// ✅ BIEN: Lógica en ViewModel
class EmployeeViewModel extends Notifier<EmployeeState> {
  Future<void> startWorkday(String id) async {
    final employee = await _repository.startWorkday(id);
    state = state.copyWith(/* ... */);
  }
}

// ❌ MAL: Lógica en Widget
class EmployeeCard extends StatelessWidget {
  void _onStartWorkday() async {
    final response = await http.post(/* ... */);
    // ... lógica de negocio aquí
  }
}
```

### 5. Nombres Descriptivos
```dart
// ✅ BIEN
final employeeListViewModelProvider = ...;
final employeeDetailViewModelProvider = ...;

// ❌ MAL
final provider1 = ...;
final employeeProvider = ...; // ¿Lista? ¿Detalle?
```

## Recursos

- [Riverpod Official Docs](https://riverpod.dev)
- [Riverpod 3.0 Migration Guide](https://riverpod.dev/docs/3.0_migration)
- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/modifiers/family)

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** December 2025
