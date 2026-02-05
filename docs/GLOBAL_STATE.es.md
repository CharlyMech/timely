# Gestión Global del Estado

Este documento proporciona una guía completa de la arquitectura de **gestión de estado global** en Timely, incluyendo proveedores de Riverpod, ViewModels, patrones de sincronización de estado y el ciclo completo de flujo de datos.

## Tabla de Contenidos

-  [Resumen](#resumen)
-  [Arquitectura Riverpod](#arquitectura-riverpod)

   -  [Jerarquía de Providers](#jerarquía-de-providers)
   -  [Tipos de Providers](#tipos-de-providers)

-  [Proveedores de Servicios](#proveedores-de-servicios)
-  [Proveedores de Datos](#proveedores-de-datos)
-  [ViewModels](#viewmodels)

   -  [EmployeeViewModel](#employeeviewmodel)
   -  [EmployeeDetailViewModel](#employeedetailviewmodel)
   -  [EmployeeProfileViewModel](#employeeprofileviewmodel)
   -  [EmployeeRegistrationsViewModel](#employeeregistrationsviewmodel)
   -  [EmployeeShiftsViewModel](#employeeshiftsviewmodel)
   -  [ThemeViewModel](#themeviewmodel)

-  [Sincronización de Estado](#sincronización-de-estado)
-  [Estrategias de Carga de Datos](#estrategias-de-carga-de-datos)
-  [Ciclo de Vida del Estado](#ciclo-de-vida-del-estado)
-  [Buenas Prácticas](#buenas-prácticas)

---

## Resumen

Timely utiliza **Riverpod** para la gestión de estado, implementando una arquitectura de múltiples capas que separa responsabilidades y asegura la consistencia de los datos en toda la aplicación.

### Principios Clave

1. **Fuente Única de Verdad**: Cada estado tiene un único proveedor autoritativo.
2. **Estado Inmutable**: Todos los objetos de estado son inmutables con métodos `copyWith`.
3. **Actualizaciones Reactivas**: La UI se reconstruye automáticamente cuando el estado cambia.
4. **Sincronización de Estado**: Estados relacionados se mantienen sincronizados mediante actualizaciones explícitas.
5. **Separación de Responsabilidades**: Servicios, repositorios y ViewModels tienen funciones distintas.

### Capas de Arquitectura

```
Capa de UI (Widgets)
    ↓
    Consume estado con ref.watch()
    ↓
Capa ViewModel (Notifiers)
    ↓
    Gestiona estado, coordina operaciones
    ↓
Capa de Repositorio
    ↓
    Orquesta múltiples servicios
    ↓
Capa de Servicios
    ↓
    Abstrae fuentes de datos (Firebase/Mock)
    ↓
Capa de Datos (Firestore/JSON)
```

---

## Arquitectura Riverpod

### Jerarquía de Providers

**Ubicación**: [lib/config/providers.dart](../lib/config/providers.dart)

La jerarquía de providers sigue un **grafo de dependencias**:

```
Providers Fundamentales
├─ sharedPreferencesProvider
└─ Environment (clase estática)
    ↓
Providers de Servicios (dependen del entorno)
├─ employeeServiceProvider
├─ timeRegistrationServiceProvider
├─ shiftServiceProvider
├─ configServiceProvider
├─ shiftTypeServiceProvider
└─ auditServiceProvider
    ↓
Providers de Repositorio
└─ employeeRepositoryProvider
    ↓
Providers de Datos (FutureProviders)
├─ appConfigProvider
└─ shiftTypesProvider
    ↓
Providers de ViewModels (NotifierProviders)
├─ employeeViewModelProvider
├─ employeeDetailViewModelProvider (family)
├─ employeeProfileViewModelProvider (family)
├─ employeeRegistrationsViewModelProvider (family)
├─ employeeShiftsViewModelProvider (family)
└─ themeViewModelProvider
```

### Tipos de Providers

Timely utiliza varios tipos de providers, cada uno adecuado para distintos casos de uso:

#### Provider

**Propósito**: Inyección de dependencias, valores de solo lectura.

```dart
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return Environment.isDev
      ? MockEmployeeService()
      : FirebaseEmployeeService();
});
```

**Características**:

-  Se crea una sola vez y nunca cambia
-  Usado para instancias de servicios
-  No permite mutación de estado

#### FutureProvider

**Propósito**: Carga de datos asíncrona con estados de carga/error.

```dart
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final configService = ref.watch(configServiceProvider);
  return await configService.getConfig();
});
```

**Características**:

-  Maneja automáticamente estados de carga/error
-  Se reconstruye cuando cambian sus dependencias
-  Usado para carga inicial de datos

#### NotifierProvider

**Propósito**: Estado mutable con lógica de negocio.

```dart
final employeeViewModelProvider = NotifierProvider<EmployeeViewModel, EmployeeState>(
  () => EmployeeViewModel(),
);
```

**Características**:

-  Manejo completo del estado
-  Expone métodos para actualizar estado
-  Usado para ViewModels

#### NotifierProvider.family

**Propósito**: Instancias parametrizadas de NotifierProvider.

```dart
final employeeDetailViewModelProvider = NotifierProvider.family<
  EmployeeDetailViewModel,
  EmployeeDetailState,
  String  // Tipo de parámetro (employeeId)
>((ref, employeeId) => EmployeeDetailViewModel(employeeId));
```

**Características**:

-  Crea una instancia separada por valor de parámetro
-  Usado para ViewModels específicos de entidades
-  Cache automático por parámetro

---

## Proveedores de Servicios

Los service providers utilizan un **patrón dependiente del entorno** para seleccionar la implementación según modo dev/prod.

### Patrón de Implementación

```dart
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return Environment.isDev
      ? MockEmployeeService()
      : FirebaseEmployeeService();
});
```

### Todos los Service Providers

```dart
// Servicio de empleados (con integración de auditoría en prod)
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  if (Environment.isDev) {
    return MockEmployeeService();
  }
  final auditService = ref.watch(auditServiceProvider);
  return FirebaseEmployeeService(auditService: auditService);
});

// Servicio de registros de tiempo (con integración de auditoría en prod)
final timeRegistrationServiceProvider = Provider<TimeRegistrationService>((ref) {
  if (Environment.isDev) {
    return MockTimeRegistrationService();
  }
  final auditService = ref.watch(auditServiceProvider);
  return FirebaseTimeRegistrationService(auditService: auditService);
});

// Servicio de turnos (con integración de auditoría en prod)
final shiftServiceProvider = Provider<ShiftService>((ref) {
  if (Environment.isDev) {
    return MockShiftService();
  }
  final auditService = ref.watch(auditServiceProvider);
  return FirebaseShiftService(auditService: auditService);
});

// Servicio de configuración
final configServiceProvider = Provider<ConfigService>((ref) {
  return Environment.isDev
      ? MockConfigService()
      : FirebaseConfigService();
});

// Servicio de tipos de turno (con integración de auditoría en prod)
final shiftTypeServiceProvider = Provider<ShiftTypeService>((ref) {
  if (Environment.isDev) {
    return MockShiftTypeService();
  }
  final auditService = ref.watch(auditServiceProvider);
  return FirebaseShiftTypeService(auditService: auditService);
});

// Servicio de auditoría (opcional - null en modo dev)
final auditServiceProvider = Provider<AuditService?>((ref) {
  // Auditoría deshabilitada en modo desarrollo
  if (Environment.isDev) return null;

  // Auditoría habilitada en producción
  return FirebaseAuditService();
});
```

### Provider de Servicio de Auditoría

El servicio de auditoría es consciente del entorno y proporciona registro completo de acciones para cumplimiento:

```dart
final auditServiceProvider = Provider<AuditService?>((ref) {
  // Auditoría deshabilitada en modo desarrollo
  if (Environment.isDev) return null;

  // Auditoría habilitada en producción
  return FirebaseAuditService();
});
```

**Características Clave**:
- Devuelve `null` en modo desarrollo (sin registro de auditoría)
- Devuelve `FirebaseAuditService` en modo producción
- Usado por servicios Firebase para registrar todas las acciones críticas
- Proporciona trazabilidad para requisitos de cumplimiento

### Provider de Repositorio

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

## Proveedores de Datos

Los data providers cargan datos estáticos o que cambian poco al inicio de la app.

### AppConfig Provider

**Propósito**: Cargar configuración de la aplicación

```dart
final appConfigProvider = FutureProvider<AppConfig>((ref) async {
  final configService = ref.watch(configServiceProvider);
  return await configService.getConfig();
});
```

**Datos**:

-  Duración laboral por defecto (480 min = 8h)
-  Umbral de alerta (15 min)
-  Umbral rojo (60 min)
-  Días laborables (Lunes-Viernes)

**Uso**:

```dart
final configAsync = ref.watch(appConfigProvider);

configAsync.when(
  data: (config) => Text('Target: ${config.defaultTargetTimeMinutes}'),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

### ShiftTypes Provider

**Propósito**: Cargar todos los tipos de turno

```dart
final shiftTypesProvider = FutureProvider<List<ShiftType>>((ref) async {
  final shiftTypeService = ref.watch(shiftTypeServiceProvider);
  return await shiftTypeService.getAllShiftTypes();
});
```

**Datos**:

-  Turno mañana (08:00-16:00)
-  Turno tarde (14:00-22:00)
-  Turno dividido (09:00-13:00)

**Uso**:

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

Los ViewModels gestionan el estado de pantalla y coordinan operaciones de negocio. Todos extienden `Notifier`.

### EmployeeViewModel

**Ubicación**: [lib/viewmodels/employee_viewmodel.dart](../lib/viewmodels/employee_viewmodel.dart)

**Propósito**: Gestionar la lista principal de empleados

**Provider**:

```dart
final employeeViewModelProvider = NotifierProvider<EmployeeViewModel, EmployeeState>(
  () => EmployeeViewModel(),
);
```

#### Estado

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

  EmployeeState copyWith({ ... }) { ... }
}
```

#### Métodos Clave

-  `loadEmployees()`: Carga todos los empleados con registro y turno de hoy
-  `refreshEmployees()`: Refresca manualmente la lista
-  `updateEmployee(Employee employee)`: Actualiza un empleado en la lista
-  `getEmployeeById(String id)`: Obtiene empleado desde el estado actual

**Flujo**:

```
loadEmployees() llamado
    ↓
State: isLoading = true
    ↓
EmployeeRepository.getEmployeesWithTodayRegistration()
    ↓
State: employees cargados, isLoading = false
    ↓
UI se reconstruye automáticamente
```

---

### EmployeeDetailViewModel

**Propósito**: Gestionar detalle de empleado y operaciones del día laboral

**Provider**:

```dart
final employeeDetailViewModelProvider = NotifierProvider.family<
  EmployeeDetailViewModel,
  EmployeeDetailState,
  String
>((ref, employeeId) => EmployeeDetailViewModel(employeeId));
```

**Métodos Clave**:

-  `loadEmployee()`: Carga empleado con registro y turno
-  `startWorkday()`: Inicia jornada laboral, valida y sincroniza
-  `endWorkday()`: Finaliza jornada laboral
-  `pauseWorkday() / resumeWorkday()`: Pausa y reanuda jornada

**Sincronización**:

-  Actualiza `EmployeeViewModel`
-  Actualiza `EmployeeRegistrationsViewModel`
-  UI se reconstruye automáticamente

---

### Otros ViewModels

-  **EmployeeProfileViewModel**: Gestiona información de perfil y actualizaciones
-  **EmployeeRegistrationsViewModel**: Gestiona historial de registros de tiempo, paginación y refresco
-  **EmployeeShiftsViewModel**: Gestiona asignaciones de turnos, creación y eliminación
-  **ThemeViewModel**: Gestiona tema de la app y persistencia en SharedPreferences

---

## Sincronización de Estado

Timely usa **sincronización explícita** entre ViewModels:

```dart
// Ejemplo en startWorkday()
state = state.copyWith(employee: updatedEmployee);
ref.read(employeeViewModelProvider.notifier).updateEmployee(updatedEmployee);
ref.read(employeeRegistrationsViewModelProvider(employeeId).notifier)
    .updateRegistration(updatedEmployee.currentRegistration!);
```

**Ventajas**:

-  Predecible
-  Performante
-  Fácil de depurar
-  Flexible

---

## Estrategias de Carga de Datos

1. **Initial Load**: FutureProvider, carga una vez al inicio.
2. **Manual Load**: ViewModels, llamado por acción de usuario.
3. **Auto-Load**: Family Notifiers, carga automática al crear instancia.
4. **Refresh**: Recarga manual desde UI (`RefreshIndicator`).
5. **Pagination**: Carga incremental con scroll infinito.

---

## Ciclo de Vida del Estado

-  **Creación**: `build()` inicializa estado y carga auto (si aplica)
-  **Actualización**: `state = newState`, Riverpod notifica watchers
-  **Disposición**: Último watcher deja de observar → Provider destruido
-  **Family Caching**: Cache por parámetro, evita recreación innecesaria

---

## Buenas Prácticas

1. **Estado inmutable**: Usar `copyWith()`
2. **Manejo de errores**: Capturar excepciones en async
3. **Estados de carga**: Proveer feedback visual
4. **Validación antes de operaciones**: Guard clauses
5. **Sincronización explícita**: Mantener consistencia entre ViewModels
6. **Family para estado parametrizado**
7. **Liberar recursos**: Cancelar timers/listeners
8. **ref.read vs ref.watch**: Lectura puntual vs reactiva

---

## Resumen

La arquitectura de gestión de estado de Timely ofrece:

-  **Separación clara**: ViewModels para estado, servicios para acceso a datos
-  **Actualizaciones predecibles**: Estado inmutable con cambios explícitos
-  **Sincronización**: Estados relacionados consistentes
-  **Performance**: Solo widgets observando el provider cambian
-  **Testabilidad**: ViewModels testeables independientemente
-  **Escalabilidad**: Fácil agregar nuevos ViewModels sin afectar los existentes
-  **Trazabilidad de Auditoría**: Registro completo de todas las acciones críticas mediante integración con AuditService

Para integración con UI: [APP_FLOW.md](./APP_FLOW.md)
Para modelos de datos, servicios y modelos de auditoría: [DATA.md](./DATA.md)
