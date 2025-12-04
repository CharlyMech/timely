# Flujo de Ejecución de Timely

Este documento describe en detalle el flujo de ejecución de la aplicación Timely, desde el inicio hasta las diferentes funcionalidades.

## Tabla de Contenidos

1. [Inicialización de la Aplicación](#inicialización-de-la-aplicación)
2. [Flujo de Navegación](#flujo-de-navegación)
3. [Flujo de Datos](#flujo-de-datos)
4. [Ciclo de Vida de Screens](#ciclo-de-vida-de-screens)
5. [Casos de Uso Principales](#casos-de-uso-principales)

---

## Inicialización de la Aplicación

### 1. Punto de Entrada (main.dart)

```dart
void main() async {
  // 1. Inicializar bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Configurar la aplicación
  final container = await AppSetup.initialize();

  // 3. Lanzar la app con ProviderScope
  runApp(
    ProviderScope(
      overrides: container.overrides,
      child: const App(),
    ),
  );
}
```

**Orden de ejecución:**

```
main()
  ↓
WidgetsFlutterBinding.ensureInitialized()
  ↓
AppSetup.initialize()
  ↓
  ├─ SharedPreferences.getInstance()
  ├─ Firebase.initializeApp() [si FLAVOR=prod]
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
    // 1. Cargar SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 2. Configurar Firebase si es producción
    if (Environment.isProd) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 3. Logs de configuración
    _printConfiguration();

    // 4. Retornar overrides de providers
    return SetupContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  }
}
```

**Línea de tiempo:**

```
T=0ms    → Llamada a initialize()
T=10ms   → SharedPreferences cargado
T=50ms   → Firebase inicializado (si prod)
T=60ms   → Logs de configuración
T=70ms   → Return con overrides
```

### 3. App Widget

```dart
class App extends ConsumerStatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();

    // Post-frame callback para inicializar tema
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final brightness = AppSetup.getSystemBrightness();
      ref.read(themeViewModelProvider.notifier).initialize(brightness);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeViewModelProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final themeData = ref
        .read(themeViewModelProvider.notifier)
        .getThemeData(brightness);

    return MaterialApp.router(
      theme: themeData,
      routerConfig: router,
    );
  }
}
```

**Flujo:**

```
_AppState.initState()
  ↓
addPostFrameCallback() [después del primer frame]
  ↓
ThemeViewModel.initialize()
  ↓
build() → MaterialApp.router
  ↓
Router navega a /splash (initialLocation)
```

---

## Flujo de Navegación

### Rutas Definidas

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

### Diagrama de Navegación

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
               │ button "Empezar"
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

### 1. Splash Screen → Welcome

**Trigger:** Automático después de cargar datos (mínimo 2 segundos)

```dart
// SplashScreen
Future<void> _initializeApp() async {
  // 1. Cargar empleados
  await ref.read(employeeViewModelProvider.notifier).loadEmployees();

  // 2. Esperar mínimo 2 segundos
  await Future.delayed(const Duration(seconds: 2));

  // 3. Navegar
  if (mounted) {
    context.go('/welcome');
  }
}
```

**Línea de tiempo:**

```
T=0s     → SplashScreen mounted
T=0.1s   → Iniciar carga de empleados
T=2.3s   → Empleados cargados (de JSON)
T=2.3s   → Delay restante = 0s
T=2.3s   → Navegación a /welcome
```

### 2. Welcome → Staff

**Trigger:** Usuario presiona botón "Empezar"

```dart
ElevatedButton(
  onPressed: () => context.go('/staff'),
  child: Text('Empezar'),
)
```

**Flujo:**

```
Usuario toca botón
  ↓
onPressed()
  ↓
context.go('/staff')
  ↓
GoRouter resuelve ruta
  ↓
Construye StaffScreen()
  ↓
StaffScreen build()
  ↓
ref.watch(employeeViewModelProvider) → Ya tiene datos cargados
  ↓
Muestra grid de empleados
```

### 3. Staff → Employee Detail

**Trigger:** Usuario toca una tarjeta de empleado

```dart
EmployeeCard(
  employee: employee,
  onTap: () => context.push('/employee/${employee.id}'),
)
```

**Flujo:**

```
Usuario toca EmployeeCard
  ↓
onTap()
  ↓
context.push('/employee/123')
  ↓
GoRouter extrae parámetro 'id' = '123'
  ↓
Construye TimeRegistrationDetailScreen(employeeId: '123')
  ↓
Screen inicializa provider.family('123')
  ↓
Carga datos del empleado específico
```

### 4. Timeout de Inactividad (Staff Screen)

**Trigger:** 5 minutos sin interacción

```dart
class _StaffScreenState extends ConsumerState<StaffScreen> {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer = Timer(
      Duration(minutes: 5),
      _onInactivityTimeout,
    );
  }

  void _onInactivityTimeout() {
    if (mounted) {
      context.go('/welcome');
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _startInactivityTimer();
  }
}
```

**Eventos que resetean el timer:**
- Tap en cualquier parte del screen
- Pan/scroll
- Tap en botón de búsqueda
- Pull to refresh
- Tap en EmployeeCard

---

## Flujo de Datos

### Arquitectura de Capas

```
┌─────────────────────────────────────────┐
│              UI Layer                   │
│  Screen observa ViewModel (ref.watch)   │
└───────────────┬─────────────────────────┘
                │
                │ ref.read(...).action()
                ↓
┌─────────────────────────────────────────┐
│          ViewModel Layer                │
│  - Actualiza state                      │
│  - Llama a Repository                   │
└───────────────┬─────────────────────────┘
                │
                │ repository.method()
                ↓
┌─────────────────────────────────────────┐
│         Repository Layer                │
│  - Orquesta servicios                   │
│  - Lógica de negocio                    │
└───────────────┬─────────────────────────┘
                │
                │ service.method()
                ↓
┌─────────────────────────────────────────┐
│          Service Layer                  │
│  - Mock: Lee JSON                       │
│  - Firebase: Consulta Firestore         │
└─────────────────────────────────────────┘
```

### Ejemplo Completo: Cargar Lista de Empleados

#### 1. UI Layer (Screen)

```dart
class StaffScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observar estado
    final employeeState = ref.watch(employeeViewModelProvider);

    // 2. UI reactiva
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
    // 1. Indicar carga
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 2. Llamar al repositorio
      final employees = await _repository.getEmployeesWithTodayRegistration();

      // 3. Actualizar estado con éxito
      state = state.copyWith(
        employees: employees,
        isLoading: false,
      );
    } catch (e) {
      // 4. Manejar error
      state = state.copyWith(
        error: 'Error al cargar empleados: $e',
        isLoading: false,
      );
    }
  }
}
```

#### 3. Repository Layer

```dart
class EmployeeRepository {
  final EmployeeService _employeeService;
  final TimeRegistrationService _timeService;

  Future<List<Employee>> getEmployeesWithTodayRegistration() async {
    // 1. Obtener todos los empleados
    final employees = await _employeeService.getAllEmployees();

    // 2. Obtener registros de hoy
    final today = DateTime.now();
    final registrations = await _timeService.getRegistrationsByDate(today);

    // 3. Combinar datos
    return employees.map((employee) {
      final registration = registrations.firstWhere(
        (r) => r.employeeId == employee.id,
        orElse: () => null,
      );

      return employee.copyWith(todayRegistration: registration);
    }).toList();
  }
}
```

#### 4. Service Layer

**Mock Implementation:**

```dart
class MockEmployeeService implements EmployeeService {
  @override
  Future<List<Employee>> getAllEmployees() async {
    // 1. Leer archivo JSON
    final jsonString = await rootBundle.loadString(
      'assets/mock/employees.json',
    );

    // 2. Parsear JSON
    final jsonData = json.decode(jsonString);
    final List employeesJson = jsonData['employees'];

    // 3. Convertir a modelos
    return employeesJson
        .map((json) => Employee.fromJson(json))
        .toList();
  }
}
```

**Firebase Implementation:**

```dart
class FirebaseEmployeeService implements EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Employee>> getAllEmployees() async {
    // 1. Query Firestore
    final snapshot = await _firestore
        .collection('employees')
        .orderBy('name')
        .get();

    // 2. Convertir documentos a modelos
    return snapshot.docs
        .map((doc) => Employee.fromJson(doc.data()))
        .toList();
  }
}
```

### Línea de Tiempo Completa

```
T=0ms     → Usuario navega a StaffScreen
T=0ms     → build() ejecuta
T=0ms     → ref.watch(employeeViewModelProvider)
T=0ms     → EmployeeViewModel ya tiene datos del splash
T=1ms     → UI muestra grid con 6 empleados

[Usuario hace pull-to-refresh]

T=0ms     → onRefresh callback
T=0ms     → ref.read(...).refreshEmployees()
T=0ms     → state.copyWith(isLoading: true)
T=1ms     → UI muestra loading indicator
T=1ms     → _repository.getEmployees()
T=1ms     → _employeeService.getAllEmployees()
T=50ms    → Mock lee JSON del asset
T=51ms    → Parsea JSON
T=52ms    → Crea objetos Employee
T=52ms    → _timeService.getRegistrationsByDate()
T=100ms   → Mock retorna registros
T=101ms   → Repository combina datos
T=102ms   → ViewModel actualiza state
T=102ms   → state.copyWith(employees: [...], isLoading: false)
T=103ms   → ref.watch detecta cambio
T=103ms   → UI reconstruye
T=104ms   → Grid actualizado
```

---

## Ciclo de Vida de Screens

### 1. SplashScreen

```
mounted
  ↓
initState()
  ↓
Future.microtask(() => _initializeApp())
  ↓
build() [muestra logo + spinner]
  ↓
_initializeApp() ejecuta en microtask
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
build() [muestra bienvenida + botón]
  ↓
[Usuario toca botón]
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
  └─ construye UI con datos
  ↓
[Usuario interactúa]
  ├─ onTap → _resetInactivityTimer()
  ├─ onPanDown → _resetInactivityTimer()
  └─ onRefresh → refreshEmployees()
  ↓
[5 min sin actividad]
  ↓
_onInactivityTimeout()
  ↓
context.go('/welcome')
  ↓
dispose()
  └─ _inactivityTimer?.cancel()
```

### 4. TimeRegistrationDetailScreen

```
mounted(employeeId: '123')
  ↓
initState()
  └─ Future.microtask(() => _loadData())
  ↓
build()
  ├─ ref.watch(employeeDetailViewModelProvider('123'))
  └─ state inicial: isLoading = true
  ↓
_loadData()
  ├─ loadEmployee()
  └─ startTimer() [si hay registro activo]
  ↓
build() [reconstruye con datos]
  ├─ Muestra información del empleado
  ├─ Muestra registro horario
  └─ Botón según estado (Iniciar/Finalizar)
  ↓
[Usuario toca "Iniciar Jornada"]
  ↓
startWorkday()
  ├─ Llamada a repository
  ├─ Actualiza estado
  └─ Inicia timer
  ↓
Timer tick cada segundo
  ↓
setState() → reconstruye tiempo
  ↓
dispose()
  └─ _timer?.cancel()
```

---

## Casos de Uso Principales

### Caso de Uso 1: Iniciar Jornada

**Actor:** Empleado
**Precondición:** Empleado no tiene registro activo hoy

**Flujo:**

```
1. Usuario navega a StaffScreen
2. Usuario toca su tarjeta de empleado
3. Sistema navega a TimeRegistrationDetailScreen
4. Sistema carga datos del empleado
5. Sistema verifica: no hay registro activo
6. Sistema muestra botón "Iniciar Jornada"
7. Usuario toca "Iniciar Jornada"
8. Sistema:
   a. Crea nuevo TimeRegistration con checkIn = now
   b. Guarda en servicio (Mock/Firebase)
   c. Actualiza estado del ViewModel
   d. Inicia timer en UI
9. Sistema muestra cronómetro en tiempo real
10. Usuario ve tiempo transcurrido actualizándose
```

**Código:**

```dart
// Usuario toca botón
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
      SnackBar(content: Text('Jornada iniciada')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

// ViewModel
Future<void> startWorkday() async {
  try {
    final updatedEmployee = await _repository.startEmployeeWorkday(employeeId);
    state = state.copyWith(employee: updatedEmployee);
  } catch (e) {
    state = state.copyWith(error: 'Error al iniciar jornada: $e');
    rethrow;
  }
}

// Repository
Future<Employee> startEmployeeWorkday(String employeeId) async {
  // 1. Crear nuevo registro
  final registration = TimeRegistration(
    id: Uuid().v4(),
    employeeId: employeeId,
    date: DateTime.now(),
    checkIn: DateTime.now(),
    checkOut: null,
  );

  // 2. Guardar
  await _timeService.createRegistration(registration);

  // 3. Obtener empleado actualizado
  return await getEmployeeWithRegistration(employeeId);
}
```

**Resultado:** Empleado tiene jornada activa, cronómetro funcionando

---

### Caso de Uso 2: Finalizar Jornada

**Actor:** Empleado
**Precondición:** Empleado tiene registro activo hoy

**Flujo:**

```
1. Usuario está en TimeRegistrationDetailScreen
2. Sistema muestra cronómetro activo
3. Sistema muestra botón "Finalizar Jornada"
4. Usuario toca "Finalizar Jornada"
5. Sistema:
   a. Actualiza TimeRegistration con checkOut = now
   b. Calcula totalHours
   c. Guarda en servicio
   d. Actualiza estado
   e. Detiene timer
6. Sistema muestra resumen:
   - Hora entrada
   - Hora salida
   - Total horas trabajadas
7. Usuario ve confirmación
```

**Línea de tiempo:**

```
Check-in:  09:00:00
Current:   17:30:45
Check-out: 17:30:45
Total:     8h 30m 45s
```

---

### Caso de Uso 3: Pull to Refresh

**Actor:** Usuario
**Precondición:** Usuario en StaffScreen

**Flujo:**

```
1. Usuario arrastra hacia abajo en el grid
2. Sistema detecta gesto de pull
3. Sistema muestra indicador de refresh
4. Sistema ejecuta:
   a. ref.read(...).refreshEmployees()
   b. state.copyWith(isLoading: true)
5. UI muestra loading
6. Sistema recarga datos:
   a. Obtiene empleados del servicio
   b. Obtiene registros de hoy
   c. Combina información
7. Sistema actualiza estado
8. UI oculta indicador de refresh
9. UI muestra datos actualizados
```

**Duración típica:** 100-200ms (mock), 500-1000ms (Firebase)

---

### Caso de Uso 4: Timeout de Inactividad

**Actor:** Sistema
**Precondición:** Usuario en StaffScreen, sin interacción por 5 minutos

**Flujo:**

```
T=0min    → Usuario llega a StaffScreen
T=0min    → Sistema inicia timer de 5 minutos
T=2min    → Usuario toca un empleado
T=2min    → Sistema cancela timer anterior
T=2min    → Sistema inicia nuevo timer de 5 minutos
T=4min    → Usuario regresa atrás
T=7min    → Timer expira (5min desde última interacción)
T=7min    → Sistema ejecuta _onInactivityTimeout()
T=7min    → Sistema navega a /welcome
T=7min    → Usuario ve pantalla de bienvenida
```

**Eventos que resetean el timer:**
- Tap
- Pan/Scroll
- Button press
- Refresh

---

## Optimizaciones de Rendimiento

### 1. Precarga de Datos (SplashScreen)

Los empleados se cargan en el splash para que estén disponibles inmediatamente en StaffScreen:

```
SplashScreen carga → Empleados en memoria
  ↓
Usuario navega a StaffScreen → Datos ya disponibles
  ↓
UI instantánea, sin loading
```

### 2. Provider.family Cachea Instancias

```dart
// Primera llamada: crea instancia
ref.watch(employeeDetailViewModelProvider('123'));

// Segunda llamada: usa instancia cacheada
ref.watch(employeeDetailViewModelProvider('123'));

// Diferente parámetro: crea nueva instancia
ref.watch(employeeDetailViewModelProvider('456'));
```

### 3. Select para Rebuilds Eficientes

```dart
// ❌ Reconstruye en cualquier cambio de estado
final state = ref.watch(employeeViewModelProvider);

// ✅ Solo reconstruye cuando cambia isLoading
final isLoading = ref.watch(
  employeeViewModelProvider.select((s) => s.isLoading),
);
```

---

## Debugging del Flujo

### Logs Estratégicos

```dart
// En cada paso crítico del flujo
print('🔵 [Paso] Descripción');  // Info
print('✅ [Paso] Éxito');         // Success
print('❌ [Paso] Error: $e');     // Error
```

**Ejemplo de salida:**

```
I/flutter: 🔵 SplashScreen: Iniciando carga de empleados...
I/flutter: 🔵 EmployeeViewModel: Iniciando loadEmployees()
I/flutter: 🔵 EmployeeViewModel: Llamando a repository.getEmployees()
I/flutter: ✅ EmployeeViewModel: Empleados obtenidos: 6
I/flutter: ✅ EmployeeViewModel: Estado actualizado correctamente
I/flutter: ✅ SplashScreen: Empleados cargados correctamente
I/flutter: 🔵 SplashScreen: Navegando a /welcome
I/flutter: ✅ SplashScreen: Navegación completada
```

---

**Última actualización:** Diciembre 2024
