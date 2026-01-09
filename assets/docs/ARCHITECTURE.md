# Timely Architecture

[Ver versión en español](./ARCHITECTURE.esp.md)

## Overview

Timely implements **Clean Architecture** with clear separation of responsibilities across layers. This architecture enables:

- ✅ Testability
- ✅ Maintainability
- ✅ Scalability
- ✅ Separation of concerns
- ✅ Independence from external frameworks and libraries

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                      │
│  ┌──────────────┐  ┌───────────────┐  ┌─────────────────┐   │
│  │   Screens    │  │    Widgets    │  │   ViewModels    │   │
│  │              │  │               │  │   (Notifiers)   │   │
│  │ - Splash     │  │ - Employee    │  │ - Employee      │   │
│  │ - Welcome    │  │   Card        │  │ - Theme         │   │
│  │ - Staff      │  │ - Time        │  │ - Detail        │   │
│  │ - Detail     │  │   Gauge       │  │ - Profile       │   │
│  │ - Profile    │  │ - Avatar      │  │ - Registrations │   │
│  │ - Privacy    │  │ - Custom      │  │                 │   │
│  └──────────────┘  │   Components  │  └─────────────────┘   │
│                     └───────────────┘                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Observes/Modifies State
                           │ (Riverpod 3.0)
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  Repositories                        │   │
│  │  - EmployeeRepository                                │   │
│  │  - Orchestrates multiple services                    │   │
│  │  - Implements complex business logic                 │   │
│  │  - Combines and transforms data                      │   │
│  │  - High-level operations (startWorkday, pauseWork)   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                      Models                          │   │
│  │  - Employee                                          │   │
│  │  - TimeRegistration                                  │   │
│  │  - Shift                                             │   │
│  │  - ShiftType                                         │   │
│  │  - AppConfig                                         │   │
│  │  - Immutable domain entities                         │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Uses
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
│  │ - Reads local JSON │      │  - Firestore queries     │   │
│  │ - Dev mode         │      │  - Prod mode             │   │
│  │ - Fast             │      │  - Persistent            │   │
│  │ - Simulated delays │      │  - Real-time sync        │   │
│  └────────────────────┘      └──────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Detailed Layers

### 1. Presentation Layer (UI)

**Responsibility:** Display information to the user and capture interactions.

#### Screens

Complete screens representing an application route.

**Key Screens:**
- `SplashScreen` - App initialization and data preloading
- `WelcomeScreen` - Entry point with start button
- `StaffScreen` - Main employee grid with search and inactivity timer
- `TimeRegistrationDetailScreen` - Employee time tracking interface
- `EmployeeProfileScreen` - Profile management with calendar
- `EmployeeRegistrationsScreen` - Historical records with pagination
- `DataPrivacyScreen` - Privacy policy display
- `ErrorScreen` - Global error handling

**Characteristics:**
- Extend `ConsumerWidget` or `ConsumerStatefulWidget`
- Observe ViewModels with `ref.watch`
- Contain no business logic
- Delegate actions to ViewModels
- Handle navigation through GoRouter

#### Widgets

Reusable UI components.

**Key Widgets:**
- `EmployeeCard` - Employee display in grid
- `TimeGauge` - Visual work time indicator
- `EmployeeAvatar` - Profile image with fallback
- `PinVerificationDialog` - Security dialog for employee access
- `CustomCard` - Styled container component
- `ThemeToggleButton` - Dark/light mode switcher

**Principles:**
- Single Responsibility
- Reusable
- Composable
- Pure (no side effects)

#### ViewModels (Notifiers)

Manage UI state and orchestrate domain layer calls.

**Key ViewModels:**
- `EmployeeViewModel` - Employee list management with search
- `EmployeeDetailViewModel` - Individual employee time tracking
- `EmployeeProfileViewModel` - Profile and shift management
- `EmployeeRegistrationsViewModel` - Historical data pagination
- `ThemeViewModel` - Theme persistence and system detection

**Responsibilities:**
- Manage UI state (loading, data, error)
- Coordinate repository calls
- Transform errors for UI consumption
- No knowledge of widget details
- Handle user interactions

### 2. Domain Layer (Business)

**Responsibility:** Business logic and data orchestration.

#### Repositories

Orchestrate multiple services and transform data.

**EmployeeRepository Example:**
```dart
class EmployeeRepository {
  final EmployeeService _employeeService;
  final TimeRegistrationService _timeService;
  final ShiftService _shiftService;

  /// Get employees with today's registration
  Future<List<Employee>> getEmployeesWithTodayRegistration() async {
    // 1. Get employees
    final employees = await _employeeService.getAllEmployees();

    // 2. Get today's registrations
    final today = DateTime.now();
    final registrations = await _timeService.getRegistrationsByDate(today);

    // 3. BUSINESS LOGIC: Combine data
    return employees.map((employee) {
      final registration = registrations.firstWhere(
        (r) => r.employeeId == employee.id,
        orElse: () => null,
      );
      return employee.copyWith(currentRegistration: registration);
    }).toList();
  }

  /// Start employee workday with validation
  Future<Employee> startEmployeeWorkday(String employeeId) async {
    // BUSINESS LOGIC: Validate no active session
    final employee = await getEmployeeWithRegistration(employeeId);
    
    if (employee.currentRegistration?.isActive == true) {
      throw Exception('Employee already has an active work session');
    }

    // Create new registration
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

**Characteristics:**
- Contains business logic
- Orchestrates multiple services
- Transforms and combines data
- Independent of UI frameworks
- Easy to test
- Implements high-level operations

#### Models

Immutable domain entities.

**Key Models:**
- `Employee` - Employee entity with security PIN
- `TimeRegistration` - Work session with pause/resume support
- `Shift` - Scheduled work shift
- `ShiftType` - Shift classification with colors
- `AppConfig` - Application configuration

**Principles:**
- Immutable (all properties `final`)
- `const` constructors when possible
- `copyWith` for creating modified copies
- `fromJson`/`toJson` serialization
- Business logic methods (getters, computed properties)
- No external dependencies

### 3. Data Layer (Data)

**Responsibility:** Access to data sources (local, remote).

#### Service Interfaces

Abstractions for data sources.

**Key Interfaces:**
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

**Advantages:**
- Allows multiple implementations
- Facilitates testing with mocks
- Dependency inversion
- Clear contracts

#### Mock Services

Implementation for development with local data.

**Features:**
- Reads from JSON assets (`assets/mock/`)
- Simulated network delays (500-1500ms)
- In-memory state for testing
- No external dependencies
- Fast iteration

**Example:**
```dart
class MockEmployeeService implements EmployeeService {
  @override
  Future<List<Employee>> getAllEmployees() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 800));
    
    // Read from local JSON
    final jsonString = await rootBundle.loadString('assets/mock/employees.json');
    final jsonData = json.decode(jsonString);
    
    return jsonData['employees']
        .map((json) => Employee.fromJson(json))
        .toList();
  }
}
```

#### Firebase Services

Implementation for production with Firestore.

**Features:**
- Cloud persistence
- Real-time synchronization
- Multi-device support
- Offline capabilities
- Scalable

**Example:**
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

## Dependency Injection with Riverpod

### Provider Configuration

```dart
// config/providers.dart

/// SharedPreferences provider (overridden in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden');
});

/// Environment-based service providers
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

/// Repository provider
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    employeeService: ref.watch(employeeServiceProvider),
    timeRegistrationService: ref.watch(timeRegistrationServiceProvider),
    shiftService: ref.watch(shiftServiceProvider),
  );
});

/// ViewModel providers
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

### Environment Switching

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
  
  // Initialize based on environment
  final container = await AppSetup.initialize();
  
  runApp(ProviderScope(
    overrides: container.overrides,
    child: const App(),
  ));
}
```

## Data Flow

### Read (Query)

```
User Action (tap, search)
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
│ Multiple service calls (parallel)│
│ - EmployeeService.getAll()      │
│ - TimeRegistrationService.getByDate()│
│ - ShiftService.getUpcoming()     │
└─────────────────────────────────┘
  ↓
   ├─ Mock: Local JSON + delays
   └─ Firebase: Firestore queries
  ↓
List<Employee> (models with combined data)
  ↓
EmployeeRepository (transform/combine)
  ↓
EmployeeViewModel (update state)
  ↓
Screen/Widget (rebuild)
  ↓
User sees updated UI
```

### Write (Mutation)

```
User Action (button press)
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
   ├─ Validate business rules
   ├─ Check for active sessions
   ├─ Create TimeRegistration
   └─ TimeRegistrationService.create()
  ↓
   ├─ Mock: Update in-memory + JSON
   └─ Firebase: Firestore.collection.add()
  ↓
Updated Employee with new registration
  ↓
EmployeeRepository (refresh employee data)
  ↓
EmployeeViewModel (update state)
  ↓
state.copyWith(employee: updated, isLoading: false)
  ↓
Screen/Widget (rebuild)
  ↓
User sees success feedback
```

## Design Patterns Used

### 1. Repository Pattern

Abstracts data access logic and provides high-level business operations.

**Benefits:**
- Centralizes data logic
- Facilitates testing
- Allows changing data source without affecting UI
- Implements complex business rules

### 2. Dependency Injection

Dependency injection with Riverpod providers.

**Benefits:**
- Decoupling
- Testability
- Flexibility
- Environment-based switching

### 3. Immutable Data

All models and states are immutable.

**Benefits:**
- Predictability
- No side effects
- Easy debugging
- Thread safety

### 4. Observer Pattern

Riverpod implements observer for reactive state.

**Benefits:**
- Automatic reactive UI
- UI-State decoupling
- Optimized performance

### 5. Strategy Pattern

Multiple service implementations (Mock/Firebase).

**Benefits:**
- Interchangeable at runtime
- Flexibility
- Simplified testing

### 6. Factory Pattern

ViewModel creation with Riverpod providers.

**Benefits:**
- Centralized creation logic
- Dependency injection
- Consistent initialization

## Testing Strategy

### Unit Tests (ViewModels, Repositories)

Test business logic in isolation.

```dart
void main() {
  test('EmployeeViewModel loads employees', () async {
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

### Integration Tests

Test complete flows through the application.

```dart
void main() {
  testWidgets('Full flow: load staff and start workday', (tester) async {
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

    // Tap first employee
    await tester.tap(find.byType(EmployeeCard).first);
    await tester.pumpAndSettle();

    // Verify detail screen
    expect(find.byType(TimeRegistrationDetailScreen), findsOneWidget);

    // Tap start workday
    await tester.tap(find.text('Iniciar Jornada'));
    await tester.pumpAndSettle();

    // Verify workday started
    expect(find.text('Finalizar Jornada'), findsOneWidget);
  });
}
```

### Widget Tests

Test individual widgets and components.

```dart
void main() {
  testWidgets('EmployeeCard displays employee info', (tester) async {
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

## Advantages of this Architecture

### 1. Testability

- Each layer can be tested independently
- Easy mocking of dependencies
- Predictable code behavior
- Clear separation allows focused testing

### 2. Maintainability

- Organized and structured code
- Clear responsibilities
- Easy bug location
- Consistent patterns across codebase

### 3. Scalability

- Easy to add new features
- Without affecting existing code
- Modular and extensible
- Environment-based growth

### 4. Flexibility

- Change implementations without affecting other layers
- Mock/Firebase interchangeable
- Adaptable to new requirements
- Technology stack can evolve

### 5. Separation of Concerns

- UI doesn't know data details
- Data doesn't know UI details
- Centralized business logic
- Clear dependencies

## Trade-offs

### Advantages

✅ Cleaner and more organized code  
✅ Easy to maintain and scale  
✅ Highly testable  
✅ Reusable components  
✅ Clear team collaboration patterns  

### Disadvantages

❌ More files and folders  
❌ Initial boilerplate overhead  
❌ Learning curve for new developers  
❌ May seem over-engineered for small projects  

**Conclusion:** The advantages far outweigh the disadvantages for medium to long-term projects that need to scale and maintain high code quality standards.

## Performance Considerations

### 1. Lazy Loading

- Data loaded only when needed
- Pagination for large datasets
- Efficient query patterns

### 2. State Management

- Minimal rebuilds with Riverpod
- Selective watching with `ref.watch`
- Efficient state updates

### 3. Network Optimization

- Parallel service calls
- Cached mock data in development
- Optimized Firestore queries with proper indexes

### 4. UI Performance

- Const widgets where possible
- Efficient list rendering
- Image optimization

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** January 2026