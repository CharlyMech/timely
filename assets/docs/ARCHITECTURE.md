# Arquitectura de Timely

## Visión General

Timely implementa una **arquitectura limpia (Clean Architecture)** con separación clara de responsabilidades en capas. Esta arquitectura permite:

- ✅ Testabilidad
- ✅ Mantenibilidad
- ✅ Escalabilidad
- ✅ Separación de concerns
- ✅ Independencia de frameworks y librerías externas

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                      │
│  ┌──────────────┐  ┌───────────────┐  ┌─────────────────┐  │
│  │   Screens    │  │    Widgets    │  │   ViewModels    │  │
│  │              │  │               │  │   (Notifiers)   │  │
│  │ - Splash     │  │ - Employee    │  │ - Employee      │  │
│  │ - Welcome    │  │   Card        │  │ - Theme         │  │
│  │ - Staff      │  │ - Time        │  │ - Detail        │  │
│  │ - Detail     │  │   Widget      │  │                 │  │
│  └──────────────┘  └───────────────┘  └─────────────────┘  │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Observa/Modifica Estado
                           │ (Riverpod)
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  Repositories                        │   │
│  │  - EmployeeRepository                                │   │
│  │  - Orquesta múltiples servicios                      │   │
│  │  - Implementa lógica de negocio compleja            │   │
│  │  - Combina y transforma datos                       │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                      Models                          │   │
│  │  - Employee                                          │   │
│  │  - TimeRegistration                                  │   │
│  │  - Entidades de dominio inmutables                  │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Usa
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                       DATA LAYER                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Service Interfaces                      │   │
│  │  - EmployeeService                                   │   │
│  │  - TimeRegistrationService                          │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌────────────────────┐      ┌──────────────────────────┐   │
│  │ Mock Services      │      │  Firebase Services       │   │
│  │                    │      │                          │   │
│  │ - Lee JSON local   │      │  - Firestore queries     │   │
│  │ - Dev mode         │      │  - Prod mode             │   │
│  │ - Rápido           │      │  - Persistente           │   │
│  └────────────────────┘      └──────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Capas Detalladas

### 1. Presentation Layer (UI)

**Responsabilidad:** Mostrar información al usuario y capturar interacciones.

#### Screens

Pantallas completas que representan una ruta de la aplicación.

```dart
class StaffScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(employeeViewModelProvider);
    // Construir UI basado en estado
  }
}
```

**Características:**
- Extienden `ConsumerWidget` o `ConsumerStatefulWidget`
- Observan ViewModels con `ref.watch`
- No contienen lógica de negocio
- Delegan acciones a ViewModels

#### Widgets

Componentes reutilizables de UI.

```dart
class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  // Solo presentación, sin lógica
}
```

**Principios:**
- Single Responsibility
- Reutilizables
- Composables
- Puros (sin side effects)

#### ViewModels (Notifiers)

Gestionan el estado de la UI y orquestan llamadas a la capa de dominio.

```dart
class EmployeeViewModel extends Notifier<EmployeeState> {
  late EmployeeRepository _repository;

  @override
  EmployeeState build() {
    _repository = ref.read(employeeRepositoryProvider);
    return const EmployeeState();
  }

  Future<void> loadEmployees() async {
    state = state.copyWith(isLoading: true);
    try {
      final employees = await _repository.getEmployees();
      state = state.copyWith(employees: employees, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

**Responsabilidades:**
- Gestionar estado de UI
- Coordinar llamadas a repositorios
- Transformar errores para UI
- No conocen detalles de widgets

### 2. Domain Layer (Negocio)

**Responsabilidad:** Lógica de negocio y orquestación de datos.

#### Repositories

Orquestan múltiples servicios y transforman datos.

```dart
class EmployeeRepository {
  final EmployeeService _employeeService;
  final TimeRegistrationService _timeService;

  EmployeeRepository({
    required EmployeeService employeeService,
    required TimeRegistrationService timeService,
  })  : _employeeService = employeeService,
        _timeService = timeService;

  /// Obtiene empleados con su registro del día actual
  Future<List<Employee>> getEmployeesWithTodayRegistration() async {
    // 1. Obtener empleados
    final employees = await _employeeService.getAllEmployees();

    // 2. Obtener registros de hoy
    final today = DateTime.now();
    final registrations = await _timeService.getRegistrationsByDate(today);

    // 3. LÓGICA DE NEGOCIO: Combinar datos
    return employees.map((employee) {
      final registration = registrations.firstWhere(
        (r) => r.employeeId == employee.id,
        orElse: () => null,
      );

      return employee.copyWith(todayRegistration: registration);
    }).toList();
  }

  /// Inicia la jornada de un empleado
  Future<Employee> startEmployeeWorkday(String employeeId) async {
    // LÓGICA DE NEGOCIO: Validar que no tenga jornada activa
    final employee = await getEmployeeWithRegistration(employeeId);

    if (employee.todayRegistration?.checkOut == null &&
        employee.todayRegistration?.checkIn != null) {
      throw Exception('El empleado ya tiene una jornada activa');
    }

    // Crear nuevo registro
    final registration = TimeRegistration(
      id: Uuid().v4(),
      employeeId: employeeId,
      date: DateTime.now(),
      checkIn: DateTime.now(),
      checkOut: null,
    );

    await _timeService.createRegistration(registration);

    return await getEmployeeWithRegistration(employeeId);
  }
}
```

**Características:**
- Contiene lógica de negocio
- Orquesta múltiples servicios
- Transforma y combina datos
- Independiente de frameworks de UI
- Fácil de testear

#### Models

Entidades de dominio inmutables.

```dart
class Employee {
  final String id;
  final String name;
  final String position;
  final String? imageUrl;
  final TimeRegistration? todayRegistration;

  const Employee({
    required this.id,
    required this.name,
    required this.position,
    this.imageUrl,
    this.todayRegistration,
  });

  // Inmutabilidad con copyWith
  Employee copyWith({
    String? id,
    String? name,
    String? position,
    String? imageUrl,
    TimeRegistration? todayRegistration,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      imageUrl: imageUrl ?? this.imageUrl,
      todayRegistration: todayRegistration ?? this.todayRegistration,
    );
  }

  // Serialización
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'imageUrl': imageUrl,
    };
  }
}
```

**Principios:**
- Inmutables (todas las propiedades `final`)
- `const` constructors cuando sea posible
- `copyWith` para crear copias modificadas
- Serialización `fromJson`/`toJson`
- Sin lógica de negocio (solo datos)

### 3. Data Layer (Datos)

**Responsabilidad:** Acceso a fuentes de datos (local, remoto).

#### Service Interfaces

Abstracciones para fuentes de datos.

```dart
/// Interfaz abstracta del servicio de empleados
abstract class EmployeeService {
  Future<List<Employee>> getAllEmployees();
  Future<Employee> getEmployeeById(String id);
  Future<Employee> createEmployee(Employee employee);
  Future<Employee> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
}
```

**Ventajas:**
- Permite múltiples implementaciones
- Facilita testing con mocks
- Inversión de dependencias

#### Mock Services

Implementación para desarrollo con datos locales.

```dart
class MockEmployeeService implements EmployeeService {
  @override
  Future<List<Employee>> getAllEmployees() async {
    // Leer JSON local
    final jsonString = await rootBundle.loadString(
      'assets/mock/employees.json',
    );

    final jsonData = json.decode(jsonString);
    final List employeesJson = jsonData['employees'];

    return employeesJson
        .map((json) => Employee.fromJson(json))
        .toList();
  }

  // ... otras implementaciones
}
```

**Uso:**
- Desarrollo local rápido
- Testing
- Demos sin backend

#### Firebase Services

Implementación para producción con Firestore.

```dart
class FirebaseEmployeeService implements EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Employee>> getAllEmployees() async {
    final snapshot = await _firestore
        .collection('employees')
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => Employee.fromJson({
              ...doc.data(),
              'id': doc.id,
            }))
        .toList();
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    final docRef = await _firestore
        .collection('employees')
        .add(employee.toJson());

    return employee.copyWith(id: docRef.id);
  }

  // ... otras implementaciones
}
```

**Uso:**
- Producción
- Persistencia en la nube
- Sincronización multi-dispositivo

## Dependency Injection con Riverpod

### Provider Configuration

```dart
// config/providers.dart

/// Provider de SharedPreferences (overridden en main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden');
});

/// Provider del servicio de empleados (cambia según FLAVOR)
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  if (Environment.isDev) {
    return MockEmployeeService();
  } else {
    return FirebaseEmployeeService();
  }
});

/// Provider del servicio de registros
final timeRegistrationServiceProvider = Provider<TimeRegistrationService>((ref) {
  if (Environment.isDev) {
    return MockTimeRegistrationService();
  } else {
    return FirebaseTimeRegistrationService();
  }
});

/// Provider del repositorio
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    employeeService: ref.watch(employeeServiceProvider),
    timeRegistrationService: ref.watch(timeRegistrationServiceProvider),
  );
});

/// ViewModels
final employeeViewModelProvider =
    NotifierProvider<EmployeeViewModel, EmployeeState>(
        EmployeeViewModel.new
    );

final employeeDetailViewModelProvider = NotifierProvider.family<
    EmployeeDetailViewModel, EmployeeDetailState, String>(
  EmployeeDetailViewModel.new,
);

final themeViewModelProvider =
    NotifierProvider<ThemeViewModel, ThemeState>(
        ThemeViewModel.new
    );
```

### Grafo de Dependencias

```
ProviderScope (root)
  ↓
sharedPreferencesProvider (overridden in main)
  ↓
employeeServiceProvider
  ├─ MockEmployeeService (dev)
  └─ FirebaseEmployeeService (prod)
  ↓
timeRegistrationServiceProvider
  ├─ MockTimeRegistrationService (dev)
  └─ FirebaseTimeRegistrationService (prod)
  ↓
employeeRepositoryProvider
  ├─ depends on: employeeServiceProvider
  └─ depends on: timeRegistrationServiceProvider
  ↓
employeeViewModelProvider
  └─ depends on: employeeRepositoryProvider
```

## Flujo de Datos

### Read (Consulta)

```
User Action (tap)
  ↓
Screen/Widget
  ↓
ref.watch(employeeViewModelProvider)
  ↓
EmployeeViewModel.loadEmployees()
  ↓
EmployeeRepository.getEmployees()
  ↓
EmployeeService.getAllEmployees()
  ↓
  ├─ Mock: JSON local
  └─ Firebase: Firestore query
  ↓
List<Employee> (models)
  ↓
EmployeeRepository (transform/combine)
  ↓
EmployeeViewModel (update state)
  ↓
Screen/Widget (rebuild)
  ↓
User sees updated UI
```

### Write (Mutación)

```
User Action (button press)
  ↓
Screen/Widget
  ↓
ref.read(...).startWorkday()
  ↓
EmployeeViewModel.startWorkday()
  ↓
state.copyWith(isLoading: true)
  ↓
EmployeeRepository.startEmployeeWorkday()
  ↓
  ├─ Validate business rules
  ├─ Create TimeRegistration
  └─ TimeRegistrationService.create()
  ↓
  ├─ Mock: Update in-memory + JSON
  └─ Firebase: Firestore.collection.add()
  ↓
Updated Employee
  ↓
EmployeeViewModel (update state)
  ↓
state.copyWith(employee: updated, isLoading: false)
  ↓
Screen/Widget (rebuild)
  ↓
User sees success feedback
```

## Patrones de Diseño Utilizados

### 1. Repository Pattern

Abstrae la lógica de acceso a datos.

**Beneficios:**
- Centraliza lógica de datos
- Facilita testing
- Permite cambiar fuente de datos sin afectar UI

### 2. Dependency Injection

Inyección de dependencias con Riverpod.

**Beneficios:**
- Desacoplamiento
- Testabilidad
- Flexibilidad

### 3. Immutable Data

Todos los modelos y estados son inmutables.

**Beneficios:**
- Predecibilidad
- Sin side effects
- Fácil debugging

### 4. Observer Pattern

Riverpod implementa observer para estado reactivo.

**Beneficios:**
- UI reactiva automática
- Desacoplamiento UI-Estado
- Performance optimizado

### 5. Strategy Pattern

Múltiples implementaciones de servicios (Mock/Firebase).

**Beneficios:**
- Intercambiable en runtime
- Flexibilidad
- Testing simplificado

## Testing Strategy

### Unit Tests (ViewModels, Repositories)

```dart
void main() {
  test('EmployeeViewModel loads employees', () async {
    // Arrange
    final mockRepository = MockEmployeeRepository();
    when(mockRepository.getEmployees())
        .thenAnswer((_) async => [employee1, employee2]);

    final container = ProviderContainer(
      overrides: [
        employeeRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    // Act
    await container
        .read(employeeViewModelProvider.notifier)
        .loadEmployees();

    // Assert
    final state = container.read(employeeViewModelProvider);
    expect(state.employees.length, 2);
    expect(state.isLoading, false);
  });
}
```

### Integration Tests

```dart
void main() {
  testWidgets('Full flow: load and display employees', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Wait for splash
    await tester.pumpAndSettle();

    // Tap button to go to staff
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    // Verify employees displayed
    expect(find.byType(EmployeeCard), findsWidgets);
  });
}
```

## Ventajas de esta Arquitectura

### 1. Testabilidad

- Cada capa puede testearse independientemente
- Mock fácil de dependencias
- Código predecible

### 2. Mantenibilidad

- Código organizado y estructurado
- Responsabilidades claras
- Fácil localizar bugs

### 3. Escalabilidad

- Fácil añadir nuevas features
- Sin afectar código existente
- Modular y extensible

### 4. Flexibilidad

- Cambiar implementaciones sin afectar otras capas
- Mock/Firebase intercambiables
- Adaptable a nuevos requisitos

### 5. Separación de Concerns

- UI no conoce detalles de datos
- Datos no conocen detalles de UI
- Lógica de negocio centralizada

## Trade-offs

### Ventajas
✅ Código más limpio y organizado
✅ Fácil de mantener y escalar
✅ Altamente testeable
✅ Reutilizable

### Desventajas
❌ Más archivos y carpetas
❌ Boilerplate inicial
❌ Curva de aprendizaje para nuevos desarrolladores

**Conclusión:** Las ventajas superan ampliamente las desventajas para proyectos de mediano a largo plazo.

---

**Última actualización:** Diciembre 2024
