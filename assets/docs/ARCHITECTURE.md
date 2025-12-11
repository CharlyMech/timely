# Timely Architecture

[Ver versión en español](./ARCHITECTURE.esp.md)

## Overview

Timely implements **Clean Architecture** with clear separation of responsibilities across layers. This architecture enables:

-  Testability
-  Maintainability
-  Scalability
-  Separation of concerns
-  Independence from external frameworks and libraries

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
│  │ - Detail     │  │   Widget      │  │                 │   │
│  └──────────────┘  └───────────────┘  └─────────────────┘   │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ Observes/Modifies State
                           │ (Riverpod)
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  Repositories                        │   │
│  │  - EmployeeRepository                                │   │
│  │  - Orchestrates multiple services                    │   │
│  │  - Implements complex business logic                 │   │
│  │  - Combines and transforms data                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                      Models                          │   │
│  │  - Employee                                          │   │
│  │  - TimeRegistration                                  │   │
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
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────┐      ┌──────────────────────────┐   │
│  │ Mock Services      │      │  Firebase Services       │   │
│  │                    │      │                          │   │
│  │ - Reads local JSON │      │  - Firestore queries     │   │
│  │ - Dev mode         │      │  - Prod mode             │   │
│  │ - Fast             │      │  - Persistent            │   │
│  └────────────────────┘      └──────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Detailed Layers

### 1. Presentation Layer (UI)

**Responsibility:** Display information to the user and capture interactions.

#### Screens

Complete screens representing an application route.

**Characteristics:**

-  Extend `ConsumerWidget` or `ConsumerStatefulWidget`
-  Observe ViewModels with `ref.watch`
-  Contain no business logic
-  Delegate actions to ViewModels

#### Widgets

Reusable UI components.

**Principles:**

-  Single Responsibility
-  Reusable
-  Composable
-  Pure (no side effects)

#### ViewModels (Notifiers)

Manage UI state and orchestrate domain layer calls.

**Responsibilities:**

-  Manage UI state
-  Coordinate repository calls
-  Transform errors for UI
-  No knowledge of widget details

### 2. Domain Layer (Business)

**Responsibility:** Business logic and data orchestration.

#### Repositories

Orchestrate multiple services and transform data.

**Characteristics:**

-  Contains business logic
-  Orchestrates multiple services
-  Transforms and combines data
-  Independent of UI frameworks
-  Easy to test

#### Models

Immutable domain entities.

**Principles:**

-  Immutable (all properties `final`)
-  `const` constructors when possible
-  `copyWith` for creating modified copies
-  `fromJson`/`toJson` serialization
-  No business logic (data only)

### 3. Data Layer (Data)

**Responsibility:** Access to data sources (local, remote).

#### Service Interfaces

Abstractions for data sources.

**Advantages:**

-  Allows multiple implementations
-  Facilitates testing with mocks
-  Dependency inversion

#### Mock Services

Implementation for development with local data.

**Usage:**

-  Fast local development
-  Testing
-  Demos without backend

#### Firebase Services

Implementation for production with Firestore.

**Usage:**

-  Production
-  Cloud persistence
-  Multi-device synchronization

## Dependency Injection with Riverpod

### Provider Configuration

```dart
// config/providers.dart

/// SharedPreferences provider (overridden in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden');
});

/// Employee service provider (changes based on FLAVOR)
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  if (Environment.isDev) {
    return MockEmployeeService();
  } else {
    return FirebaseEmployeeService();
  }
});

/// Repository provider
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
```

## Data Flow

### Read (Query)

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
  ├─ Mock: Local JSON
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

### Write (Mutation)

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

## Design Patterns Used

### 1. Repository Pattern

Abstracts data access logic.

**Benefits:**

-  Centralizes data logic
-  Facilitates testing
-  Allows changing data source without affecting UI

### 2. Dependency Injection

Dependency injection with Riverpod.

**Benefits:**

-  Decoupling
-  Testability
-  Flexibility

### 3. Immutable Data

All models and states are immutable.

**Benefits:**

-  Predictability
-  No side effects
-  Easy debugging

### 4. Observer Pattern

Riverpod implements observer for reactive state.

**Benefits:**

-  Automatic reactive UI
-  UI-State decoupling
-  Optimized performance

### 5. Strategy Pattern

Multiple service implementations (Mock/Firebase).

**Benefits:**

-  Interchangeable at runtime
-  Flexibility
-  Simplified testing

## Testing Strategy

### Unit Tests (ViewModels, Repositories)

Test business logic in isolation.

### Integration Tests

Test complete flows through the application.

## Advantages of this Architecture

### 1. Testability

-  Each layer can be tested independently
-  Easy mocking of dependencies
-  Predictable code

### 2. Maintainability

-  Organized and structured code
-  Clear responsibilities
-  Easy bug location

### 3. Scalability

-  Easy to add new features
-  Without affecting existing code
-  Modular and extensible

### 4. Flexibility

-  Change implementations without affecting other layers
-  Mock/Firebase interchangeable
-  Adaptable to new requirements

### 5. Separation of Concerns

-  UI doesn't know data details
-  Data doesn't know UI details
-  Centralized business logic

## Trade-offs

### Advantages

✅ Cleaner and more organized code ✅ Easy to maintain and scale ✅ Highly testable ✅ Reusable

### Disadvantages

❌ More files and folders ❌ Initial boilerplate ❌ Learning curve for new developers

**Conclusion:** The advantages far outweigh the disadvantages for medium to long-term projects.

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** December 2025
