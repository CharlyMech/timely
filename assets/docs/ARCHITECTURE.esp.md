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
│  │ - Detail     │  │   Gauge       │  │ - Profile       │  │
│  │ - Profile    │  │ - Avatar      │  │ - Registrations │  │
│  │ - Privacy    │  │ - Custom      │  │                 │  │
│  └──────────────┘  │   Components  │  └─────────────────┘  │
│                     └───────────────┘                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Observa/Modifica Estado
                           │ (Riverpod 3.0)
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  Repositories                        │   │
│  │  - EmployeeRepository                                │   │
│  │  - Orquesta múltiples servicios                      │   │
│  │  - Implementa lógica de negocio compleja            │   │
│  │  - Combina y transforma datos                       │   │
│  │  - Operaciones de alto nivel (iniciarJornada, pausar)│   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                      Models                          │   │
│  │  - Employee                                          │   │
│  │  - TimeRegistration                                  │   │
│  │  - Shift                                             │   │
│  │  - ShiftType                                         │   │
│  │  - AppConfig                                         │   │
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
│  │  - TimeRegistrationService                           │   │
│  │  - ShiftService                                      │   │
│  │  - ConfigService                                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────┐      ┌──────────────────────────┐   │
│  │ Mock Services      │      │  Firebase Services       │   │
│  │                    │      │                          │   │
│  │ - Lee JSON local   │      │  - Consultas Firestore   │   │
│  │ - Modo dev         │      │  - Modo prod             │   │
│  │ - Rápido           │      │  - Persistente           │   │
│  │ - Retrasos simulados│      │  - Sincronización real-time│   │
│  └────────────────────┘      └──────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Capas Detalladas

### 1. Presentation Layer (UI)

**Responsabilidad:** Mostrar información al usuario y capturar interacciones.

#### Screens

Pantallas completas que representan una ruta de la aplicación.

**Pantallas Clave:**
- `SplashScreen` - Inicialización de app y precarga de datos
- `WelcomeScreen` - Punto de entrada con botón de empezar
- `StaffScreen` - Grid principal de empleados con búsqueda e inactivity timer
- `TimeRegistrationDetailScreen` - Interfaz de seguimiento horario de empleado
- `EmployeeProfileScreen` - Gestión de perfil con calendario
- `EmployeeRegistrationsScreen` - Registros históricos con paginación
- `DataPrivacyScreen` - Visualización de política de privacidad
- `ErrorScreen` - Manejo global de errores

**Características:**
- Extienden `ConsumerWidget` o `ConsumerStatefulWidget`
- Observan ViewModels con `ref.watch`
- No contienen lógica de negocio
- Delegan acciones a ViewModels
- Manejan navegación a través de GoRouter

#### Widgets

Componentes de UI reutilizables.

**Widgets Clave:**
- `EmployeeCard` - Visualización de empleado en grid
- `TimeGauge` - Indicador visual de tiempo trabajado
- `EmployeeAvatar` - Imagen de perfil con fallback
- `PinVerificationDialog` - Diálogo de seguridad para acceso a empleado
- `CustomCard` - Componente de contenedor estilizado
- `ThemeToggleButton` - Interruptor de tema claro/oscuro

**Principios:**
- Single Responsibility
- Reutilizables
- Componibles
- Puros (sin side effects)

#### ViewModels (Notifiers)

Gestionan el estado de la UI y orquestan llamadas a la capa de dominio.

**ViewModels Clave:**
- `EmployeeViewModel` - Gestión de lista de empleados con búsqueda
- `EmployeeDetailViewModel` - Seguimiento horario de empleado individual
- `EmployeeProfileViewModel` - Gestión de perfil y turnos
- `EmployeeRegistrationsViewModel` - Paginación de datos históricos
- `ThemeViewModel` - Persistencia de tema y detección del sistema

**Responsabilidades:**
- Gestionar estado de UI (loading, data, error)
- Coordinar llamadas a repositorios
- Transformar errores para consumo de UI
- No conocen detalles de widgets
- Manejar interacciones de usuario

### 2. Domain Layer (Negocio)

**Responsabilidad:** Lógica de negocio y orquestación de datos.

#### Repositories

Orquestan múltiples servicios y transforman datos.

**Ejemplo de EmployeeRepository:**
```dart
class EmployeeRepository {
  final EmployeeService _employeeService;
  final TimeRegistrationService _timeService;
  final ShiftService _shiftService;

  /// Obtiene empleados con registro del día actual
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
      return employee.copyWith(currentRegistration: registration);
    }).toList();
  }

  /// Inicia jornada de empleado con validación
  Future<Employee> startEmployeeWorkday(String employeeId) async {
    // LÓGICA DE NEGOCIO: Validar que no tenga sesión activa
    final employee = await getEmployeeWithRegistration(employeeId);
    
    if (employee.currentRegistration?.isActive == true) {
      throw Exception('El empleado ya tiene una jornada activa');
    }

    // Crear nuevo registro
    final registration = TimeRegistration(
      id: Uuid().v4(),
      employeeId: employeeId,
      startTime: DateTime.now(),
      date: DateUtils.formatDate(DateTime.now()),
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
- Implementa operaciones de alto nivel

#### Models

Entidades de dominio inmutables.

**Models Clave:**
- `Employee` - Entidad de empleado con PIN de seguridad
- `TimeRegistration` - Sesión de trabajo con soporte de pausa/reanudación
- `Shift` - Turno de trabajo programado
- `ShiftType` - Clasificación de turno con colores
- `AppConfig` - Configuración de la aplicación

**Principios:**
- Inmutables (todas las propiedades `final`)
- `const` constructors cuando sea posible
- `copyWith` para crear copias modificadas
- Serialización `fromJson`/`toJson`
- Métodos de lógica de negocio (getters, propiedades calculadas)
- Sin dependencias externas

### 3. Data Layer (Datos)

**Responsabilidad:** Acceso a fuentes de datos (local, remoto).

#### Service Interfaces

Abstracciones para fuentes de datos.

**Interfaces Clave:**
```dart
abstract class EmployeeService {
  Future<List<Employee>> getAllEmployees();
  Future<Employee> getEmployeeById(String id);
  Future<Employee> createEmployee(Employee employee);
  Future<Employee> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
}

abstract class TimeRegistrationService {
  Future<List<TimeRegistration>> getRegistrationsByEmployee(String employeeId);
  Future<List<TimeRegistration>> getRegistrationsByDate(DateTime date);
  Future<TimeRegistration> createRegistration(TimeRegistration registration);
  Future<TimeRegistration> updateRegistration(TimeRegistration registration);
}

abstract class ShiftService {
  Future<List<Shift>> getShiftsByEmployee(String employeeId);
  Future<List<Shift>> getShiftsByDateRange(DateTime start, DateTime end);
  Future<Shift> createShift(Shift shift);
}

abstract class ConfigService {
  Future<AppConfig> getAppConfig();
  Future<void> updateConfig(AppConfig config);
}
```

**Ventajas:**
- Permite múltiples implementaciones
- Facilita testing con mocks
- Inversión de dependencias
- Contratos claros

#### Mock Services

Implementación para desarrollo con datos locales.

**Características:**
- Lee desde assets JSON (`assets/mock/`)
- Retrasos de red simulados (500-1500ms)
- Estado en memoria para testing
- Sin dependencias externas
- Iteración rápida

**Ejemplo:**
```dart
class MockEmployeeService implements EmployeeService {
  @override
  Future<List<Employee>> getAllEmployees() async {
    // Simular retraso de red
    await Future.delayed(Duration(milliseconds: 800));
    
    // Leer desde JSON local
    final jsonString = await rootBundle.loadString('assets/mock/employees.json');
    final jsonData = json.decode(jsonString);
    
    return jsonData['employees']
        .map((json) => Employee.fromJson(json))
        .toList();
  }
}
```

#### Firebase Services

Implementación para producción con Firestore.

**Características:**
- Persistencia en la nube
- Sincronización real-time
- Soporte multi-dispositivo
- Capacidades offline
- Escalable

**Ejemplo:**
```dart
class FirebaseEmployeeService implements EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Employee>> getAllEmployees() async {
    final snapshot = await _firestore
        .collection('employees')
        .orderBy('firstName')
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
}
```

## Dependency Injection con Riverpod

### Configuración de Providers

```dart
// config/providers.dart

/// Provider de SharedPreferences (overridden en main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden');
});

/// Providers de servicios basados en entorno
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  if (Environment.isDev) {
    return MockEmployeeService();
  } else {
    return FirebaseEmployeeService();
  }
});

final timeRegistrationServiceProvider = Provider<TimeRegistrationService>((ref) {
  if (Environment.isDev) {
    return MockTimeRegistrationService();
  } else {
    return FirebaseTimeRegistrationService();
  }
});

final shiftServiceProvider = Provider<ShiftService>((ref) {
  if (Environment.isDev) {
    return MockShiftService();
  } else {
    return FirebaseShiftService();
  }
});

final configServiceProvider = Provider<ConfigService>((ref) {
  if (Environment.isDev) {
    return MockConfigService();
  } else {
    return FirebaseConfigService();
  }
});

/// Provider del repositorio
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    employeeService: ref.watch(employeeServiceProvider),
    timeRegistrationService: ref.watch(timeRegistrationServiceProvider),
    shiftService: ref.watch(shiftServiceProvider),
  );
});

/// Providers de ViewModels
final employeeViewModelProvider =
    NotifierProvider<EmployeeViewModel, EmployeeState>(
        EmployeeViewModel.new
    );

final employeeDetailViewModelProvider =
    NotifierProvider.family<EmployeeDetailViewModel, EmployeeDetailState, String>(
        EmployeeDetailViewModel.new
    );

final themeViewModelProvider =
    NotifierProvider<ThemeViewModel, ThemeState>(
        ThemeViewModel.new
    );
```

### Cambio de Entorno

```dart
// config/environment.dart
class Environment {
  static const String _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  
  static bool get isDev => _flavor == 'dev';
  static bool get isProd => _flavor == 'prod';
  
  static String get flavor => _flavor;
}

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar basado en entorno
  final container = await AppSetup.initialize();
  
  runApp(ProviderScope(
    overrides: container.overrides,
    child: const App(),
  ));
}
```

## Flujo de Datos

### Read (Consulta)

```
Acción Usuario (tap, búsqueda)
  ↓
Screen/Widget
  ↓
ref.watch(employeeViewModelProvider)
  ↓
EmployeeViewModel.loadEmployees()
  ↓
EmployeeRepository.getEmployeesWithTodayRegistration()
  ↓
┌─────────────────────────────────┐
│ Múltiples llamadas a servicios (paralelo)│
│ - EmployeeService.getAll()      │
│ - TimeRegistrationService.getByDate()│
│ - ShiftService.getUpcoming()     │
└─────────────────────────────────┘
  ↓
   ├─ Mock: JSON local + retrasos
   └─ Firebase: Consultas Firestore
  ↓
List<Employee> (models con datos combinados)
  ↓
EmployeeRepository (transformar/combinar)
  ↓
EmployeeViewModel (actualizar estado)
  ↓
Screen/Widget (rebuild)
  ↓
Usuario ve UI actualizada
```

### Write (Mutación)

```
Acción Usuario (press botón)
  ↓
Screen/Widget
  ↓
ref.read(employeeDetailViewModelProvider.notifier).startWorkday()
  ↓
EmployeeViewModel.startWorkday()
  ↓
state.copyWith(isLoading: true)
  ↓
EmployeeRepository.startEmployeeWorkday(employeeId)
  ↓
   ├─ Validar reglas de negocio
   ├─ Verificar sesiones activas
   ├─ Crear TimeRegistration
   └─ TimeRegistrationService.create()
  ↓
   ├─ Mock: Actualizar en memoria + JSON
   └─ Firebase: Firestore.collection.add()
  ↓
Employee actualizado con nuevo registro
  ↓
EmployeeRepository (refrescar datos de empleado)
  ↓
EmployeeViewModel (actualizar estado)
  ↓
state.copyWith(employee: actualizado, isLoading: false)
  ↓
Screen/Widget (rebuild)
  ↓
Usuario ve feedback de éxito
```

## Patrones de Diseño Utilizados

### 1. Repository Pattern

Abstrae la lógica de acceso a datos y proporciona operaciones de negocio de alto nivel.

**Beneficios:**
- Centraliza lógica de datos
- Facilita testing
- Permite cambiar fuente de datos sin afectar UI
- Implementa reglas de negocio complejas

### 2. Dependency Injection

Inyección de dependencias con providers de Riverpod.

**Beneficios:**
- Desacoplamiento
- Testabilidad
- Flexibilidad
- Cambio basado en entorno

### 3. Immutable Data

Todos los modelos y estados son inmutables.

**Beneficios:**
- Predecibilidad
- Sin side effects
- Fácil debugging
- Thread safety

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

### 6. Factory Pattern

Creación de ViewModels con providers de Riverpod.

**Beneficios:**
- Lógica de creación centralizada
- Inyección de dependencias
- Inicialización consistente

## Estrategia de Testing

### Tests Unitarios (ViewModels, Repositories)

Testea lógica de negocio en aislamiento.

```dart
void main() {
  test('EmployeeViewModel carga empleados', () async {
    // Arrange
    final mockRepository = MockEmployeeRepository();
    when(mockRepository.getEmployeesWithTodayRegistration())
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
    expect(state.error, null);
  });
}
```

### Tests de Integración

Testea flujos completos a través de la aplicación.

```dart
void main() {
  testWidgets('Flujo completo: cargar staff e iniciar jornada', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Esperar splash
    await tester.pumpAndSettle();

    // Presionar botón para ir a staff
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    // Verificar empleados mostrados
    expect(find.byType(EmployeeCard), findsWidgets);

    // Presionar primer empleado
    await tester.tap(find.byType(EmployeeCard).first);
    await tester.pumpAndSettle();

    // Verificar pantalla de detalle
    expect(find.byType(TimeRegistrationDetailScreen), findsOneWidget);

    // Presionar iniciar jornada
    await tester.tap(find.text('Iniciar Jornada'));
    await tester.pumpAndSettle();

    // Verificar jornada iniciada
    expect(find.text('Finalizar Jornada'), findsOneWidget);
  });
}
```

### Tests de Widgets

Testea widgets individuales y componentes.

```dart
void main() {
  testWidgets('EmployeeCard muestra info de empleado', (tester) async {
    const employee = Employee(
      id: 'test-id',
      firstName: 'John',
      lastName: 'Doe',
      pin: '123456',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmployeeCard(
            employee: employee,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.byType(EmployeeAvatar), findsOneWidget);
  });
}
```

## Ventajas de esta Arquitectura

### 1. Testabilidad

- Cada capa puede testearse independientemente
- Mock fácil de dependencias
- Comportamiento de código predecible
- Separación clara permite testing enfocado

### 2. Mantenibilidad

- Código organizado y estructurado
- Responsabilidades claras
- Fácil localización de bugs
- Patrones consistentes en todo el codebase

### 3. Escalabilidad

- Fácil añadir nuevas features
- Sin afectar código existente
- Modular y extensible
- Crecimiento basado en entorno

### 4. Flexibilidad

- Cambiar implementaciones sin afectar otras capas
- Mock/Firebase intercambiables
- Adaptable a nuevos requisitos
- Stack tecnológico puede evolucionar

### 5. Separación de Concerns

- UI no conoce detalles de datos
- Datos no conocen detalles de UI
- Lógica de negocio centralizada
- Dependencias claras

## Trade-offs

### Ventajas

✅ Código más limpio y organizado  
✅ Fácil de mantener y escalar  
✅ Altamente testeable  
✅ Componentes reutilizables  
✅ Patrones claros de colaboración en equipo  

### Desventajas

❌ Más archivos y carpetas  
❌ Overhead inicial de boilerplate  
❌ Curva de aprendizaje para nuevos desarrolladores  
❌ Puede parecer sobre-ingeniería para proyectos pequeños  

**Conclusión:** Las ventajas superan ampliamente las desventajas para proyectos de mediano a largo plazo que necesitan escalar y mantener altos estándares de calidad de código.

## Consideraciones de Performance

### 1. Lazy Loading

- Datos cargados solo cuando se necesitan
- Paginación para datasets grandes
- Patrones de consulta eficientes

### 2. State Management

- Rebuilds mínimos con Riverpod
- Watching selectivo con `ref.watch`
- Actualizaciones de estado eficientes

### 3. Optimización de Red

- Llamadas a servicios en paralelo
- Datos mock cacheados en desarrollo
- Consultas Firestore optimizadas con índices apropiados

### 4. Performance de UI

- Widgets const cuando sea posible
- Rendering de listas eficiente
- Optimización de imágenes

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** January 2026