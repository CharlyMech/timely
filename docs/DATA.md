# Data Architecture

This document describes the complete data architecture of the Timely application, including data models, entity relationships, repositories, services, and data flow patterns.

## Table of Contents

- [Overview](#overview)
- [Data Models](#data-models)
  - [Employee](#employee)
  - [Role](#role)
  - [TimeRegistration](#timeregistration)
  - [Shift](#shift)
  - [ShiftType](#shifttype)
  - [AppConfig](#appconfig)
- [Audit Models](#audit-models)
  - [Audit Enums](#audit-enums)
  - [LoginAudit](#loginaudit)
  - [EmployeeAudit](#employeeaudit)
  - [TimeRegistrationAudit](#timeregistrationaudit)
  - [ShiftAudit](#shiftaudit)
  - [ShiftTypeAudit](#shifttypeaudit)
  - [UserAudit](#useraudit)
- [Entity Relationships](#entity-relationships)
- [Service Architecture](#service-architecture)
  - [Abstract Service Interfaces](#abstract-service-interfaces)
  - [Firebase Implementations](#firebase-implementations)
  - [Mock Implementations](#mock-implementations)
  - [API Client Infrastructure](#api-client-infrastructure)
- [Audit Service](#audit-service)
- [Repository Pattern](#repository-pattern)
- [Data Flow](#data-flow)
- [Data Validation](#data-validation)

---

## Overview

Timely uses a **clean architecture** approach with clear separation between data models, services, and repositories. The data layer is designed to be **environment-agnostic**, supporting both Firebase production and Mock development modes through abstract interfaces.

### Key Principles

1. **Immutable Data Models**: All entities are immutable with `copyWith` methods
2. **Service Abstraction**: Abstract interfaces allow swapping between Firebase, Mock, and API implementations
3. **Repository Pattern**: Repositories orchestrate multiple services for complex operations
4. **Type Safety**: Comprehensive use of Dart's null safety and type system
5. **Computed Properties**: Models include derived properties for business logic
6. **Audit Trail**: Complete logging of all critical actions for compliance and traceability

---

## Data Models

All data models are located in [lib/models/](../lib/models/) and implement serialization/deserialization methods for JSON and Firestore.

### Employee

**Location**: [lib/models/employee.dart](../lib/models/employee.dart)

Represents an employee in the system with profile information and current work state.

#### Schema

```dart
class Employee {
  final String id;                    // Unique identifier (UUID)
  final String firstName;             // Employee first name
  final String lastName;              // Employee last name
  final String pin;                   // 6-digit PIN for authentication
  final String? email;                // Optional email (validated)
  final String phone;                 // Phone number (Spanish format)
  final String? avatarUrl;            // Optional profile picture URL
  final String? address;              // Optional physical address
  final EmployeeStatus status;        // Current status (active/inactive/vacation/leave)
  final String personId;              // DNI or NIE (validated)
  final String roleId;                // Reference to Role entity (UUID)
  final WorkType workType;            // Work schedule type (complete/partial)
  final TimeRegistration? currentRegistration;  // Today's time registration
  final Shift? todayShift;            // Today's assigned shift
}
```

#### Enums

```dart
enum EmployeeStatus {
  active,     // Currently working
  inactive,   // Not working
  vacation,   // On vacation
  leave       // On leave
}

enum WorkType {
  complete,   // Full-time work schedule (Jornada completa)
  partial     // Part-time work schedule (Jornada parcial)
}
```

#### Validation Rules

- **PIN**: Must be exactly 6 digits
- **Email**: Must match regex pattern: `r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'`
- **Phone**: Must match Spanish phone pattern: `r'^[679]\d{8}$'`
  - Valid formats: `612345678`, `723456789`, `934567890`
  - Must start with 6, 7, or 9
  - Exactly 9 digits
- **PersonId**: Must match DNI or NIE pattern: `r'^(\d{8}[A-Z]|[XYZ]\d{7}[A-Z])$'`
  - DNI format: 8 digits followed by a letter (e.g., `12345678A`)
  - NIE format: X, Y, or Z followed by 7 digits and a letter (e.g., `X1234567L`)

#### Serialization

```dart
// From JSON (Mock service)
Employee.fromJson(Map<String, dynamic> json)

// From Firestore
Employee.fromFirestore(DocumentSnapshot doc)

// To JSON
Map<String, dynamic> toJson()

// To Firestore
Map<String, dynamic> toFirestore()
```

#### Business Logic

- Status determines UI display (color, icon)
- Current registration determines available actions (start/pause/resume/end)
- Today's shift provides target hours and expected schedule
- Role determines employee permissions and access level
- WorkType affects scheduling and hour calculations

---

### Role

**Location**: [lib/models/role.dart](../lib/models/role.dart)

Represents an employee role with associated permissions and display information.

#### Schema

```dart
class Role {
  final String id;                    // Unique identifier (UUID)
  final RoleType type;                // Role type enum
  final String displayName;           // Human-readable role name
}
```

#### Enums

```dart
enum RoleType {
  manager,    // Manager role
  staff,      // Staff role
  admin       // Admin role
}
```

#### Default Roles

The system includes three predefined roles:

**Manager**:
```dart
{
  id: "role-001-manager-uuid-001",
  type: RoleType.manager,
  displayName: "Manager"
}
```

**Staff**:
```dart
{
  id: "role-002-staff-uuid-002",
  type: RoleType.staff,
  displayName: "Staff"
}
```

**Admin**:
```dart
{
  id: "role-003-admin-uuid-003",
  type: RoleType.admin,
  displayName: "Admin"
}
```

#### Serialization

```dart
// From JSON (Mock service)
Role.fromJson(Map<String, dynamic> json)

// To JSON
Map<String, dynamic> toJson()
```

#### Business Logic

- Roles are referenced by employees via `roleId`
- No role-based guards or permissions enforced in this version
- Roles are read-only and managed globally
- Used for display and organizational purposes

---

### TimeRegistration

**Location**: [lib/models/time_registration.dart](../lib/models/time_registration.dart)

Represents a single work day time tracking record with start, end, pause, and resume timestamps.

#### Schema

```dart
class TimeRegistration {
  final String id;                    // Unique identifier
  final String employeeId;            // Reference to employee
  final String shiftId;               // Reference to shift
  final DateTime startTime;           // Work start timestamp
  final DateTime? endTime;            // Work end timestamp (null if active)
  final DateTime? pauseTime;          // Pause start timestamp (null if not paused)
  final DateTime? resumeTime;         // Pause end timestamp (null if not resumed)
  final String date;                  // Date in DD/MM/YYYY format
  final DateTime? createdAt;          // Creation timestamp
  final DateTime? lastUpdatedAt;      // Last modification timestamp
}
```

#### Computed Properties

```dart
// Total worked minutes (excluding pause time)
int get totalMinutes {
  if (endTime == null) return 0;

  final totalWorkMinutes = endTime!.difference(startTime).inMinutes;

  // Subtract pause duration if exists
  if (pauseTime != null && resumeTime != null) {
    final pauseMinutes = resumeTime!.difference(pauseTime!).inMinutes;
    return totalWorkMinutes - pauseMinutes;
  }

  return totalWorkMinutes;
}

// Remaining minutes to reach target
int? remainingMinutes(int targetMinutes) {
  if (endTime == null) return null;
  return targetMinutes - totalMinutes;
}

// Check if currently paused
bool get isPaused => pauseTime != null && resumeTime == null;

// Check if work day is active
bool get isActive => endTime == null;

// Get status color based on time difference from target
TimeRegistrationStatus getStatus(int targetMinutes, AppConfig config) {
  final remaining = remainingMinutes(targetMinutes);
  if (remaining == null) return TimeRegistrationStatus.green;

  final difference = remaining.abs();

  if (difference <= config.warningThresholdMinutes) {
    return TimeRegistrationStatus.green;  // Within ±15 minutes
  } else if (difference <= config.redThresholdMinutes) {
    return TimeRegistrationStatus.orange; // 15-60 minutes difference
  } else {
    return TimeRegistrationStatus.red;    // >60 minutes difference
  }
}
```

#### Status Enum

```dart
enum TimeRegistrationStatus {
  green,   // On time (within ±15 minutes)
  orange,  // Warning (15-60 minutes difference)
  red      // Error (>60 minutes difference)
}
```

#### Time Calculation Logic

The `totalMinutes` calculation accounts for pause periods:

```
Example 1 (No pause):
  Start: 08:00
  End: 16:00
  Total: 480 minutes (8 hours)

Example 2 (With pause):
  Start: 08:00
  Pause: 12:00
  Resume: 13:00
  End: 17:00
  Total: (17:00 - 08:00) - (13:00 - 12:00) = 540 - 60 = 480 minutes (8 hours)

Example 3 (Currently paused):
  Start: 08:00
  Pause: 12:00
  Resume: null
  End: null
  isPaused: true
  isActive: true
```

#### Serialization

```dart
Employee.fromJson(Map<String, dynamic> json)
Employee.fromFirestore(DocumentSnapshot doc)
Map<String, dynamic> toJson()
Map<String, dynamic> toFirestore()
```

**Date Handling**:
- JSON: Uses ISO 8601 strings
- Firestore: Converts to/from `Timestamp` objects
- Display: DD/MM/YYYY format via date property

---

### Shift

**Location**: [lib/models/shift.dart](../lib/models/shift.dart)

Represents a scheduled shift assignment for an employee on a specific date.

#### Schema

```dart
class Shift {
  final String id;                    // Unique identifier
  final String employeeId;            // Reference to employee
  final DateTime date;                // Shift date
  final String shiftTypeId;           // Reference to shift type
  final String? notes;                // Optional notes
}
```

#### Computed Properties

```dart
// Check if shift is in the past
bool get isPast {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final shiftDate = DateTime(date.year, date.month, date.day);
  return shiftDate.isBefore(today);
}

// Check if shift is today
bool get isToday {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final shiftDate = DateTime(date.year, date.month, date.day);
  return shiftDate.isAtSameMomentAs(today);
}

// Check if shift is in the future
bool get isFuture {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final shiftDate = DateTime(date.year, date.month, date.day);
  return shiftDate.isAfter(today);
}
```

#### Business Logic

- Shifts are pre-assigned before the work day
- Cannot start work without a shift for today
- Past shifts are read-only
- Future shifts can be created/modified/deleted

---

### ShiftType

**Location**: [lib/models/shift_type.dart](../lib/models/shift_type.dart)

Defines a type of work shift with time ranges and target duration.

#### Schema

```dart
class ShiftType {
  final String id;                    // Unique identifier
  final String name;                  // Display name (e.g., "Morning", "Afternoon")
  final String colorHex;              // Display color in #RRGGBB format
  final String startTime;             // Start time in HH:mm format
  final String endTime;               // End time in HH:mm format
  final String? pauseTime;            // Optional pause start in HH:mm format
  final String? resumeTime;           // Optional pause end in HH:mm format
  final int targetTimeMinutes;        // Expected work duration in minutes (default: 480)
}
```

#### Default Shift Types

**Morning Shift**:
```dart
{
  id: "morning",
  name: "Morning",
  colorHex: "#FFA726",
  startTime: "08:00",
  endTime: "16:00",
  pauseTime: "12:00",
  resumeTime: "13:00",
  targetTimeMinutes: 480  // 8 hours
}
```

**Afternoon Shift**:
```dart
{
  id: "afternoon",
  name: "Afternoon",
  colorHex: "#42A5F5",
  startTime: "14:00",
  endTime: "22:00",
  pauseTime: "18:00",
  resumeTime: "19:00",
  targetTimeMinutes: 480  // 8 hours
}
```

**Split Shift**:
```dart
{
  id: "split",
  name: "Split",
  colorHex: "#66BB6A",
  startTime: "09:00",
  endTime: "13:00",
  pauseTime: null,
  resumeTime: null,
  targetTimeMinutes: 240  // 4 hours
}
```

#### Computed Properties

```dart
// Check if shift has defined pause/resume times
bool get hasPauseResume => pauseTime != null && resumeTime != null;
```

#### Time Format

All times use **24-hour format** (HH:mm):
- `08:00` = 8:00 AM
- `16:00` = 4:00 PM
- `22:00` = 10:00 PM

---

### AppConfig

**Location**: [lib/models/app_config.dart](../lib/models/app_config.dart)

Application-wide configuration settings for work day parameters.

#### Schema

```dart
class AppConfig {
  final int defaultTargetTimeMinutes;     // Default work duration (default: 480 = 8h)
  final int warningThresholdMinutes;      // Yellow alert threshold (default: 15)
  final int redThresholdMinutes;          // Red alert threshold (default: 60)
  final List<int> workingDays;            // Working days (1=Monday, 7=Sunday)
}
```

#### Default Configuration

```dart
{
  defaultTargetTimeMinutes: 480,      // 8 hours
  warningThresholdMinutes: 15,        // ±15 minutes = green
  redThresholdMinutes: 60,            // ±60 minutes = orange, beyond = red
  workingDays: [1, 2, 3, 4, 5]        // Monday to Friday
}
```

#### Computed Methods

```dart
// Check if a given date is a working day
bool isWorkingDay(DateTime date) {
  return workingDays.contains(date.weekday);
}
```

#### Status Thresholds

The configuration defines three status levels:

```
Time Difference     | Status
--------------------|--------
≤ 15 minutes        | Green  (On time)
15-60 minutes       | Orange (Warning)
> 60 minutes        | Red    (Error)
```

**Examples**:
- Target: 480 minutes (8h)
- Worked: 475 minutes → Difference: 5 minutes → Green
- Worked: 450 minutes → Difference: 30 minutes → Orange
- Worked: 400 minutes → Difference: 80 minutes → Red

---

## Audit Models

All audit models are located in [lib/models/audit/](../lib/models/audit/) and provide complete traceability for compliance requirements.

### Audit Enums

**Location**: [lib/models/audit/](../lib/models/audit/)

#### AuditAction

```dart
enum AuditAction {
  create,   // Entity created
  update,   // Entity modified
  delete    // Entity deleted
}
```

#### AuditSource

```dart
enum AuditSource {
  app,        // Action originated from mobile app
  dashboard   // Action originated from admin dashboard
}
```

#### ActorType

```dart
enum ActorType {
  employee,   // Action performed by employee (PIN authentication)
  user        // Action performed by admin user (login authentication)
}
```

#### LoginType

```dart
enum LoginType {
  pin,    // Employee PIN authentication (app)
  login   // User login authentication (dashboard)
}
```

#### TimeRegistrationAction

```dart
enum TimeRegistrationAction {
  start,         // Work day started
  pause,         // Work day paused
  resume,        // Work day resumed
  end,           // Work day ended
  manualUpdate   // Manual update by admin
}
```

---

### LoginAudit

**Location**: [lib/models/audit/login_audit.dart](../lib/models/audit/login_audit.dart)

Tracks all authentication attempts for security compliance.

#### Schema

```dart
class LoginAudit {
  final String id;                    // Unique identifier
  final String actorId;               // Employee or user ID
  final ActorType actorType;          // Type of actor
  final LoginType loginType;          // Type of login attempt
  final bool success;                 // Whether login succeeded
  final DateTime timestamp;           // When the attempt occurred
  final String? failureReason;        // Reason for failure (if failed)
}
```

**Firestore Collection**: `login_audit`

---

### EmployeeAudit

**Location**: [lib/models/audit/employee_audit.dart](../lib/models/audit/employee_audit.dart)

Tracks changes to employee entities.

#### Schema

```dart
class EmployeeAudit {
  final String id;                    // Unique identifier
  final String employeeId;            // Employee being modified
  final AuditAction action;           // CREATE, UPDATE, DELETE
  final AuditSource source;           // APP or DASHBOARD
  final String actorId;               // Who performed the action
  final ActorType actorType;          // Type of actor
  final DateTime timestamp;           // When the action occurred
  final Map<String, dynamic>? previousData;  // State before change
  final Map<String, dynamic>? newData;       // State after change
}
```

**Firestore Collection**: `employee_audit`

---

### TimeRegistrationAudit

**Location**: [lib/models/audit/time_registration_audit.dart](../lib/models/audit/time_registration_audit.dart)

Tracks all time registration actions for labor compliance.

#### Schema

```dart
class TimeRegistrationAudit {
  final String id;                          // Unique identifier
  final String timeRegistrationId;          // Registration being tracked
  final String employeeId;                  // Employee associated
  final TimeRegistrationAction action;      // START, PAUSE, RESUME, END, MANUAL_UPDATE
  final AuditSource source;                 // APP or DASHBOARD
  final String actorId;                     // Who performed the action
  final ActorType actorType;                // Type of actor
  final DateTime timestamp;                 // When the action occurred
  final DateTime? actionTime;               // The time recorded for the action
}
```

**Firestore Collection**: `time_registration_audit`

**Critical for**: Labor law compliance, inspection readiness

---

### ShiftAudit

**Location**: [lib/models/audit/shift_audit.dart](../lib/models/audit/shift_audit.dart)

Tracks changes to shift assignments.

#### Schema

```dart
class ShiftAudit {
  final String id;                    // Unique identifier
  final String shiftId;               // Shift being modified
  final String? assignedEmployeeId;   // Employee assigned to shift
  final AuditAction action;           // CREATE, UPDATE, DELETE
  final AuditSource source;           // APP or DASHBOARD
  final String actorId;               // Who performed the action
  final ActorType actorType;          // Type of actor
  final DateTime timestamp;           // When the action occurred
  final Map<String, dynamic>? previousData;  // State before change
  final Map<String, dynamic>? newData;       // State after change
}
```

**Firestore Collection**: `shift_audit`

---

### ShiftTypeAudit

**Location**: [lib/models/audit/shift_type_audit.dart](../lib/models/audit/shift_type_audit.dart)

Tracks changes to shift type definitions.

#### Schema

```dart
class ShiftTypeAudit {
  final String id;                    // Unique identifier
  final String shiftTypeId;           // Shift type being modified
  final AuditAction action;           // CREATE, UPDATE, DELETE
  final AuditSource source;           // APP or DASHBOARD
  final String actorId;               // Who performed the action
  final ActorType actorType;          // Type of actor
  final DateTime timestamp;           // When the action occurred
  final Map<String, dynamic>? previousData;  // State before change
  final Map<String, dynamic>? newData;       // State after change
}
```

**Firestore Collection**: `shift_type_audit`

---

### UserAudit

**Location**: [lib/models/audit/user_audit.dart](../lib/models/audit/user_audit.dart)

Tracks changes to dashboard admin users.

#### Schema

```dart
class UserAudit {
  final String id;                    // Unique identifier
  final String userId;                // User being modified
  final AuditAction action;           // CREATE, UPDATE, DELETE
  final AuditSource source;           // APP or DASHBOARD
  final String actorId;               // Who performed the action
  final ActorType actorType;          // Type of actor
  final DateTime timestamp;           // When the action occurred
  final Map<String, dynamic>? previousData;  // State before change
  final Map<String, dynamic>? newData;       // State after change
}
```

**Firestore Collection**: `user_audit`

---

## Entity Relationships

### Relationship Diagram

```
AppConfig (singleton)
    │
    └─────────────┐
                  │
Role              │
    ↑             │
    │             │
ShiftType         │
    ↑             │
    │             │
    └────────┐    │
             │    │
Shift ───────┘    │
    ↑             │
    │             │
    └──────┐      │
           │      │
Employee ──┴──────┘
    ↑      │
    │      │
    └──────┘
           │
TimeRegistration
```

### Detailed Relationships

#### AppConfig → Global

**Type**: Singleton configuration document
**Collection**: `settings` (document ID: `app_config`)

- Referenced by all shift types for default target time
- Used by time registrations for status calculation
- No foreign key references (loaded globally)

#### Role → Employee (One-to-Many)

**Type**: One Role can be assigned to many Employees
**Foreign Key**: `Employee.roleId` → `Role.id`

```dart
Role(id: "role-002-staff-uuid-002", type: RoleType.staff, displayName: "Staff")
  ├─ Employee(id: "emp1", firstName: "John", roleId: "role-002-staff-uuid-002", ...)
  ├─ Employee(id: "emp2", firstName: "Jane", roleId: "role-002-staff-uuid-002", ...)
  └─ Employee(id: "emp3", firstName: "Bob", roleId: "role-002-staff-uuid-002", ...)
```

#### ShiftType → Shift (One-to-Many)

**Type**: One ShiftType can be used by many Shifts
**Foreign Key**: `Shift.shiftTypeId` → `ShiftType.id`

```dart
ShiftType(id: "morning", name: "Morning", ...)
  ├─ Shift(id: "1", employeeId: "emp1", shiftTypeId: "morning", date: "2025-12-01")
  ├─ Shift(id: "2", employeeId: "emp2", shiftTypeId: "morning", date: "2025-12-01")
  └─ Shift(id: "3", employeeId: "emp1", shiftTypeId: "morning", date: "2025-12-02")
```

#### Employee → Shift (One-to-Many)

**Type**: One Employee can have many Shifts
**Foreign Key**: `Shift.employeeId` → `Employee.id`

```dart
Employee(id: "emp1", firstName: "John", ...)
  ├─ Shift(id: "1", employeeId: "emp1", shiftTypeId: "morning", date: "2025-12-01")
  ├─ Shift(id: "2", employeeId: "emp1", shiftTypeId: "afternoon", date: "2025-12-02")
  └─ Shift(id: "3", employeeId: "emp1", shiftTypeId: "morning", date: "2025-12-03")
```

#### Employee → TimeRegistration (One-to-Many)

**Type**: One Employee can have many TimeRegistrations
**Foreign Key**: `TimeRegistration.employeeId` → `Employee.id`

```dart
Employee(id: "emp1", firstName: "John", ...)
  ├─ TimeRegistration(id: "1", employeeId: "emp1", date: "01/12/2025", ...)
  ├─ TimeRegistration(id: "2", employeeId: "emp1", date: "02/12/2025", ...)
  └─ TimeRegistration(id: "3", employeeId: "emp1", date: "03/12/2025", ...)
```

#### Shift → TimeRegistration (One-to-One per day)

**Type**: One Shift corresponds to one TimeRegistration
**Foreign Key**: `TimeRegistration.shiftId` → `Shift.id`

```dart
Shift(id: "1", employeeId: "emp1", date: "2025-12-01", ...)
  └─ TimeRegistration(id: "reg1", employeeId: "emp1", shiftId: "1", date: "01/12/2025", ...)
```

#### Employee → Current State (Embedded References)

**Type**: Embedded references for current work day
**Properties**: `Employee.currentRegistration`, `Employee.todayShift`

```dart
Employee(
  id: "emp1",
  firstName: "John",
  currentRegistration: TimeRegistration(id: "reg1", ...),  // Today's registration
  todayShift: Shift(id: "shift1", ...)                     // Today's shift
)
```

---

## Service Architecture

### Overview

Timely uses an **abstraction-first service pattern** with three layers:

1. **Abstract Interfaces**: Define service contracts
2. **Firebase Implementations**: Production backend using Firestore
3. **Mock Implementations**: Development backend using in-memory data

Services are **swapped at runtime** via Riverpod providers based on the `Environment.isDev` flag.

### Service Hierarchy

```
Abstract Service Interfaces
    ├─ EmployeeService
    ├─ RoleService
    ├─ TimeRegistrationService
    ├─ ShiftService
    ├─ ConfigService
    └─ ShiftTypeService
         ↓
    ┌────────────────────┐
    │                    │
Firebase Impl.      Mock Impl.
(Production)        (Development)
```

---

### Abstract Service Interfaces

**Location**: [lib/services/](../lib/services/)

#### EmployeeService

**File**: [employee_service.dart](../lib/services/employee_service.dart)

```dart
abstract class EmployeeService {
  Future<List<Employee>> getEmployees();
  Future<Employee?> getEmployeeById(String id);
  Future<void> updateEmployee(Employee employee);
}
```

**Purpose**: Manage employee data (read/update operations)

#### TimeRegistrationService

**File**: [time_registration_service.dart](../lib/services/time_registration_service.dart)

```dart
abstract class TimeRegistrationService {
  Future<TimeRegistration?> getTodayRegistration(String employeeId);
  Future<void> startWorkday(String employeeId, String shiftId, DateTime startTime);
  Future<void> endWorkday(String registrationId, DateTime endTime);
  Future<void> pauseWorkday(String registrationId, DateTime pauseTime);
  Future<void> resumeWorkday(String registrationId, DateTime resumeTime);
  Future<List<TimeRegistration>> getEmployeeRegistrations(String employeeId, {int limit = 30});
  Future<List<TimeRegistration>> getMonthlyRegistrations(String employeeId, int year, int month);
}
```

**Purpose**: Manage time tracking operations (CRUD)

#### ShiftService

**File**: [shift_service.dart](../lib/services/shift_service.dart)

```dart
abstract class ShiftService {
  Future<Shift?> getTodayShift(String employeeId);
  Future<List<Shift>> getEmployeeShifts(String employeeId, {int limit = 30});
  Future<List<Shift>> getUpcomingShifts(String employeeId, {int limit = 10});
  Future<List<Shift>> getMonthlyShifts(String employeeId, int year, int month);
  Future<void> createShift(Shift shift);
  Future<void> updateShift(Shift shift);
  Future<void> deleteShift(String shiftId);
}
```

**Purpose**: Manage shift scheduling (CRUD)

#### ConfigService

**File**: [config_service.dart](../lib/services/config_service.dart)

```dart
abstract class ConfigService {
  Future<AppConfig> getConfig();
  Future<void> updateConfig(AppConfig config);
}
```

**Purpose**: Manage application configuration

#### ShiftTypeService

**File**: [shift_type_service.dart](../lib/services/shift_type_service.dart)

```dart
abstract class ShiftTypeService {
  Future<List<ShiftType>> getAllShiftTypes();
  Future<ShiftType?> getShiftTypeById(String id);
}
```

**Purpose**: Manage shift type definitions (read-only)

#### RoleService

**File**: [role_service.dart](../lib/services/role_service.dart)

```dart
abstract class RoleService {
  Future<List<Role>> getAllRoles();
  Future<Role?> getRoleById(String id);
}
```

**Purpose**: Manage role definitions (read-only)

---

### Firebase Implementations

**Location**: [lib/services/firebase/](../lib/services/firebase/)

All Firebase services use Cloud Firestore as the backend with the following collections:

| Collection | Document ID Format | Purpose |
|------------|-------------------|---------|
| `employees` | UUID | Employee records |
| `roles` | UUID | Role definitions |
| `time_registrations` | UUID | Time tracking records |
| `shifts` | UUID | Shift assignments |
| `shift_types` | Named ID | Shift type definitions |
| `settings` | `app_config` | Application configuration |
| `login_audit` | UUID | Login attempt records |
| `employee_audit` | UUID | Employee change records |
| `user_audit` | UUID | Dashboard user change records |
| `shift_type_audit` | UUID | Shift type change records |
| `shift_audit` | UUID | Shift change records |
| `time_registration_audit` | UUID | Time registration action records |

#### FirebaseEmployeeService

**File**: [firebase_employee_service.dart](../lib/services/firebase/firebase_employee_service.dart)

```dart
class FirebaseEmployeeService implements EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Employee>> getEmployees() async {
    final snapshot = await _firestore.collection('employees').get();
    return snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList();
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final doc = await _firestore.collection('employees').doc(id).get();
    return doc.exists ? Employee.fromFirestore(doc) : null;
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await _firestore
        .collection('employees')
        .doc(employee.id)
        .update(employee.toFirestore());
  }
}
```

**Query Patterns**:
- All employees: `collection('employees').get()`
- Single employee: `collection('employees').doc(id).get()`
- Update: `collection('employees').doc(id).update(data)`

#### FirebaseTimeRegistrationService

**File**: [firebase_time_registration_service.dart](../lib/services/firebase/firebase_time_registration_service.dart)

```dart
class FirebaseTimeRegistrationService implements TimeRegistrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<TimeRegistration?> getTodayRegistration(String employeeId) async {
    final today = DateTimeUtils.getTodayFormatted();
    final snapshot = await _firestore
        .collection('time_registrations')
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isEqualTo: today)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty
        ? TimeRegistration.fromFirestore(snapshot.docs.first)
        : null;
  }

  @override
  Future<void> startWorkday(String employeeId, String shiftId, DateTime startTime) async {
    final registration = TimeRegistration(
      id: const Uuid().v4(),
      employeeId: employeeId,
      shiftId: shiftId,
      startTime: startTime,
      date: DateTimeUtils.getTodayFormatted(),
    );

    await _firestore
        .collection('time_registrations')
        .doc(registration.id)
        .set(registration.toFirestore());
  }

  @override
  Future<void> endWorkday(String registrationId, DateTime endTime) async {
    await _firestore
        .collection('time_registrations')
        .doc(registrationId)
        .update({'endTime': Timestamp.fromDate(endTime)});
  }

  // ... other methods
}
```

**Query Patterns**:
- Today's registration: `where('employeeId', ==).where('date', ==).limit(1)`
- Employee history: `where('employeeId', ==).orderBy('startTime', desc).limit(n)`
- Monthly records: `where('employeeId', ==).where('startTime', >=).where('startTime', <=)`

**Indexes Required**:
```json
{
  "collectionGroup": "time_registrations",
  "fields": [
    { "fieldPath": "employeeId", "order": "ASCENDING" },
    { "fieldPath": "startTime", "order": "DESCENDING" }
  ]
}
```

#### FirebaseShiftService

**File**: [firebase_shift_service.dart](../lib/services/firebase/firebase_shift_service.dart)

```dart
class FirebaseShiftService implements ShiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Shift?> getTodayShift(String employeeId) async {
    final today = DateTime.now();
    final startOfDay = DateTimeUtils.getStartOfDay(today);
    final endOfDay = DateTimeUtils.getEndOfDay(today);

    final snapshot = await _firestore
        .collection('shifts')
        .where('employeeId', isEqualTo: employeeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty
        ? Shift.fromFirestore(snapshot.docs.first)
        : null;
  }

  // ... other methods
}
```

**Query Patterns**:
- Today's shift: `where('employeeId', ==).where('date', >=).where('date', <=).limit(1)`
- Employee shifts: `where('employeeId', ==).orderBy('date', desc).limit(n)`
- Upcoming shifts: `where('employeeId', ==).where('date', >).orderBy('date', asc).limit(n)`

---

### API Client Infrastructure

**Location**: [lib/services/api/](../lib/services/api/)

The API client provides HTTP infrastructure for future REST API backend migration.

#### ApiConfig

```dart
class ApiConfig {
  final String baseUrl;               // API base URL
  final int connectTimeout;           // Connection timeout (ms)
  final int receiveTimeout;           // Receive timeout (ms)
  final Map<String, String>? headers; // Default headers
}
```

#### ApiClient

```dart
class ApiClient {
  final Dio _dio;
  final ApiConfig config;

  // HTTP Methods
  Future<ApiResponse<T>> get<T>(String path, {Map<String, dynamic>? queryParams});
  Future<ApiResponse<T>> post<T>(String path, {dynamic data});
  Future<ApiResponse<T>> put<T>(String path, {dynamic data});
  Future<ApiResponse<T>> patch<T>(String path, {dynamic data});
  Future<ApiResponse<T>> delete<T>(String path);
}
```

#### ApiResponse

```dart
class ApiResponse<T> {
  final T? data;                      // Response data
  final int statusCode;               // HTTP status code
  final String? message;              // Response message
  final bool success;                 // Whether request succeeded
}
```

**Features**:
- Dio HTTP client with interceptors
- Token-based authentication support
- Automatic error handling
- Spanish error messages for user feedback
- Configurable timeouts

---

### Mock Implementations

**Location**: [lib/services/mock/](../lib/services/mock/)

Mock services simulate backend operations using in-memory data and JSON files.

#### MockEmployeeService

**File**: [mock_employee_service.dart](../lib/services/mock/mock_employee_service.dart)

```dart
class MockEmployeeService implements EmployeeService {
  static List<Employee>? _cachedEmployees;

  Future<List<Employee>> _loadEmployees() async {
    if (_cachedEmployees != null) return _cachedEmployees!;

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Load from assets/mock/employees.json
    final jsonString = await rootBundle.loadString('assets/mock/employees.json');
    final jsonData = json.decode(jsonString) as List;

    _cachedEmployees = jsonData
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();

    return _cachedEmployees!;
  }

  @override
  Future<List<Employee>> getEmployees() => _loadEmployees();

  @override
  Future<Employee?> getEmployeeById(String id) async {
    final employees = await _loadEmployees();
    return employees.firstWhere((e) => e.id == id, orElse: () => null);
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_cachedEmployees != null) {
      final index = _cachedEmployees!.indexWhere((e) => e.id == employee.id);
      if (index != -1) {
        _cachedEmployees![index] = employee;
      }
    }
  }
}
```

**Data Source**: [assets/mock/employees.json](../assets/mock/employees.json)

**Characteristics**:
- Cached in-memory after first load
- 2-second artificial delay for realism
- Updates modify cache (not persisted)
- Resets on app restart

#### MockTimeRegistrationService

**File**: [mock_time_registration_service.dart](../lib/services/mock/mock_time_registration_service.dart)

```dart
class MockTimeRegistrationService implements TimeRegistrationService {
  static final Map<String, TimeRegistration> _registrations = {};

  @override
  Future<TimeRegistration?> getTodayRegistration(String employeeId) async {
    await Future.delayed(const Duration(seconds: 1));

    final today = DateTimeUtils.getTodayFormatted();
    return _registrations.values.firstWhere(
      (r) => r.employeeId == employeeId && r.date == today,
      orElse: () => null,
    );
  }

  @override
  Future<void> startWorkday(String employeeId, String shiftId, DateTime startTime) async {
    await Future.delayed(const Duration(seconds: 1));

    final registration = TimeRegistration(
      id: const Uuid().v4(),
      employeeId: employeeId,
      shiftId: shiftId,
      startTime: startTime,
      date: DateTimeUtils.getTodayFormatted(),
    );

    _registrations[registration.id] = registration;
  }

  // ... other methods using in-memory map
}
```

**Data Storage**: Static in-memory map `_registrations`

**Characteristics**:
- All data in memory (no persistence)
- 1-second artificial delay
- Supports all CRUD operations
- Resets on app restart

---

## Audit Service

**Location**: [lib/services/audit_service.dart](../lib/services/audit_service.dart)

The Audit Service provides a unified interface for logging all critical actions across the application.

### Abstract Interface

```dart
abstract class AuditService {
  // Login auditing
  Future<void> logLogin(LoginAudit audit);

  // Employee auditing
  Future<void> logEmployeeChange(EmployeeAudit audit);

  // Time registration auditing
  Future<void> logTimeRegistrationAction(TimeRegistrationAudit audit);

  // Shift auditing
  Future<void> logShiftChange(ShiftAudit audit);

  // Shift type auditing
  Future<void> logShiftTypeChange(ShiftTypeAudit audit);

  // User auditing
  Future<void> logUserChange(UserAudit audit);
}
```

### Firebase Implementation

**Location**: [lib/services/firebase/firebase_audit_service.dart](../lib/services/firebase/firebase_audit_service.dart)

```dart
class FirebaseAuditService implements AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> logTimeRegistrationAction(TimeRegistrationAudit audit) async {
    await _firestore
        .collection('time_registration_audit')
        .doc(audit.id)
        .set(audit.toFirestore());
  }

  // ... other methods
}
```

### Integration with Firebase Services

All Firebase services now integrate with the AuditService for automatic logging:

```dart
class FirebaseTimeRegistrationService implements TimeRegistrationService {
  final AuditService? _auditService;

  @override
  Future<void> startWorkday(
    String employeeId,
    String shiftId,
    DateTime startTime, {
    AuditSource source = AuditSource.app,
    String? actorId,
    ActorType? actorType,
  }) async {
    // Create registration
    final registration = TimeRegistration(...);
    await _firestore.collection('time_registrations').doc(registration.id).set(...);

    // Log audit
    if (_auditService != null) {
      await _auditService!.logTimeRegistrationAction(
        TimeRegistrationAudit(
          id: const Uuid().v4(),
          timeRegistrationId: registration.id,
          employeeId: employeeId,
          action: TimeRegistrationAction.start,
          source: source,
          actorId: actorId ?? employeeId,
          actorType: actorType ?? ActorType.employee,
          timestamp: DateTime.now().toUtc(),
          actionTime: startTime,
        ),
      );
    }
  }
}
```

### Environment-Based Configuration

Audit logging is automatically configured based on environment:

```dart
final auditServiceProvider = Provider<AuditService?>((ref) {
  // Audit disabled in development mode
  if (Environment.isDev) return null;

  // Audit enabled in production
  return FirebaseAuditService();
});
```

---

## Repository Pattern

### EmployeeRepository

**Location**: [lib/repositories/employee_repository.dart](../lib/repositories/employee_repository.dart)

The repository pattern **orchestrates multiple services** to provide high-level business operations.

#### Purpose

- Combine data from multiple services (employees, shifts, registrations)
- Validate business rules before operations
- Provide simplified API for ViewModels
- Handle complex multi-step transactions

#### Implementation

```dart
class EmployeeRepository {
  final EmployeeService _employeeService;
  final TimeRegistrationService _timeRegistrationService;
  final ShiftService _shiftService;

  EmployeeRepository({
    required EmployeeService employeeService,
    required TimeRegistrationService timeRegistrationService,
    required ShiftService shiftService,
  }) : _employeeService = employeeService,
       _timeRegistrationService = timeRegistrationService,
       _shiftService = shiftService;

  // ... methods
}
```

#### Methods

**getEmployeesWithTodayRegistration()**

Fetches all employees with their current work day state.

```dart
Future<List<Employee>> getEmployeesWithTodayRegistration() async {
  final employees = await _employeeService.getEmployees();

  final enrichedEmployees = await Future.wait(
    employees.map((employee) async {
      final registration = await _timeRegistrationService.getTodayRegistration(employee.id);
      final shift = await _shiftService.getTodayShift(employee.id);

      return employee.copyWith(
        currentRegistration: registration,
        todayShift: shift,
      );
    }),
  );

  return enrichedEmployees;
}
```

**Flow**:
1. Fetch all employees
2. For each employee, fetch today's registration and shift in parallel
3. Enrich employee objects with current state
4. Return complete employee list

**getEmployeeWithRegistration(String id)**

Fetches a single employee with current state.

```dart
Future<Employee?> getEmployeeWithRegistration(String id) async {
  final employee = await _employeeService.getEmployeeById(id);
  if (employee == null) return null;

  final registration = await _timeRegistrationService.getTodayRegistration(id);
  final shift = await _shiftService.getTodayShift(id);

  return employee.copyWith(
    currentRegistration: registration,
    todayShift: shift,
  );
}
```

**startEmployeeWorkday(String employeeId)**

Starts a work day with validation.

```dart
Future<Employee> startEmployeeWorkday(String employeeId) async {
  // 1. Get employee
  final employee = await _employeeService.getEmployeeById(employeeId);
  if (employee == null) throw Exception('Employee not found');

  // 2. Validate shift exists for today
  final shift = await _shiftService.getTodayShift(employeeId);
  if (shift == null) throw Exception('No shift assigned for today');

  // 3. Validate no active registration exists
  final existingRegistration = await _timeRegistrationService.getTodayRegistration(employeeId);
  if (existingRegistration != null) {
    throw Exception('Work day already started');
  }

  // 4. Create time registration
  final now = DateTime.now();
  await _timeRegistrationService.startWorkday(employeeId, shift.id, now);

  // 5. Return updated employee
  return getEmployeeWithRegistration(employeeId);
}
```

**Validation Rules**:
- Employee must exist
- Shift must be assigned for today
- No existing active registration

**endEmployeeWorkday(String employeeId)**

Ends a work day.

```dart
Future<Employee> endEmployeeWorkday(String employeeId) async {
  final registration = await _timeRegistrationService.getTodayRegistration(employeeId);
  if (registration == null || registration.endTime != null) {
    throw Exception('No active work day');
  }

  await _timeRegistrationService.endWorkday(registration.id, DateTime.now());
  return getEmployeeWithRegistration(employeeId);
}
```

**pauseEmployeeWorkday(String employeeId)** / **resumeEmployeeWorkday(String employeeId)**

Similar pattern with validation:
- Registration must exist
- Must be in correct state (active for pause, paused for resume)

---

## Data Flow

### Data Loading Flow

```
App Initialization
    ↓
EmployeeViewModel.loadEmployees()
    ↓
EmployeeRepository.getEmployeesWithTodayRegistration()
    ↓
    ├─ EmployeeService.getEmployees()
    │   └─ Firebase: Firestore query / Mock: Load from JSON
    │
    ├─ For each employee:
    │   ├─ TimeRegistrationService.getTodayRegistration(employeeId)
    │   └─ ShiftService.getTodayShift(employeeId)
    │
    └─ Combine data into enriched Employee objects
    ↓
EmployeeViewModel updates state
    ↓
UI displays employee list
```

### Work Day Operation Flow

```
User taps "Start Work Day"
    ↓
EmployeeDetailViewModel.startWorkday()
    ↓
EmployeeRepository.startEmployeeWorkday(employeeId)
    ↓
    ├─ Validate employee exists (EmployeeService.getEmployeeById)
    ├─ Validate shift exists (ShiftService.getTodayShift)
    ├─ Validate no active registration (TimeRegistrationService.getTodayRegistration)
    └─ Create registration (TimeRegistrationService.startWorkday)
    ↓
Fetch updated employee state
    ↓
Update ViewModels (Detail + List)
    ↓
UI updates to show active state
```

### State Synchronization Flow

```
EmployeeDetailViewModel performs operation
    ↓
    ├─ Update local state (EmployeeDetailState)
    ├─ Sync to EmployeeViewModel (employee list)
    └─ Sync to EmployeeRegistrationsViewModel (history)
    ↓
All watching widgets rebuild automatically
```

---

## Data Validation

### Employee Validation

**Email Validation**:
```dart
static final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

// Valid: user@example.com, john.doe@company.co.uk
// Invalid: user@, @example.com, user@domain
```

**Phone Validation**:
```dart
static final phoneRegex = RegExp(r'^\+?34?[6-9]\d{8}$');

// Valid: 612345678, +34612345678, 34612345678
// Invalid: 512345678 (starts with 5), +1234567890 (wrong country)
```

**PIN Validation**:
```dart
// Must be exactly 6 digits
assert(pin.length == 6);
assert(RegExp(r'^\d{6}$').hasMatch(pin));

// Valid: 123456, 000000
// Invalid: 12345 (too short), abc123 (non-numeric)
```

### Time Registration Validation

**Start Work Day**:
- Shift must exist for today
- No existing active registration
- Start time cannot be in the future

**Pause Work Day**:
- Registration must be active (endTime == null)
- Must not be already paused (pauseTime == null)
- Pause time must be after start time

**Resume Work Day**:
- Registration must be paused (pauseTime != null && resumeTime == null)
- Resume time must be after pause time

**End Work Day**:
- Registration must be active (endTime == null)
- If paused, must be resumed first
- End time must be after start time

### Shift Validation

**Create Shift**:
- Employee must exist
- Shift type must exist
- Date must be in the future or today
- No duplicate shift for same employee on same date

**Delete Shift**:
- Shift must not have associated time registration
- Shift must not be in the past

---

## Summary

The Timely data architecture provides:

- **Clean Separation**: Models, services, and repositories are clearly separated
- **Environment Flexibility**: Seamless switching between Firebase, Mock, and API implementations
- **Type Safety**: Comprehensive use of Dart's type system and null safety
- **Business Logic**: Computed properties and validation in models
- **Audit Trail**: Complete logging of all critical actions for compliance
- **Scalability**: Repository pattern allows complex operations without tight coupling
- **Developer Experience**: Mock services enable offline development and testing
- **Future Ready**: API client infrastructure prepared for REST backend migration

For information on how this data layer integrates with state management, see [GLOBAL_STATE.md](./GLOBAL_STATE.md).
