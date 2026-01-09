# Timely - Data Model Documentation

[Ver versión en español](./DATA_MODEL.esp.md)

## Overview

This document describes the complete data model used in the Timely application. The application uses five main entities: **Employee**, **TimeRegistration**, **Shift**, **ShiftType**, and **AppConfig**. All models are immutable and include serialization/deserialization methods for Firebase and local storage.

---

## Table of Contents

1. [Employee Model](#employee-model)
2. [TimeRegistration Model](#timeregistration-model)
3. [Shift Model](#shift-model)
4. [ShiftType Model](#shifttype-model)
5. [AppConfig Model](#appconfig-model)
6. [Entity Relationships](#entity-relationships)
7. [Firebase Collections Structure](#firebase-collections-structure)
8. [Data Flow](#data-flow)
9. [Data Validation Rules](#data-validation-rules)

---

## Employee Model

Represents an employee in the system with personal information and optional current time registration.

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | `String` | ✅ | Unique employee identifier (UUID) |
| `firstName` | `String` | ✅ | Employee's first name |
| `lastName` | `String` | ✅ | Employee's last name |
| `avatarUrl` | `String?` | ❌ | Optional URL to employee's avatar image |
| `pin` | `String` | ✅ | 6-digit PIN for secure access to employee data |
| `currentRegistration` | `TimeRegistration?` | ❌ | Active time registration if employee is currently working |

### Computed Properties

| Property | Return Type | Description |
|----------|-------------|-------------|
| `fullName` | `String` | Returns concatenation of `firstName` and `lastName` |

### Methods

#### `fromJson(Map<String, dynamic> json)`
Creates an Employee instance from JSON data.

```dart
Employee.fromJson({
  'id': 'uuid-123',
  'firstName': 'John',
  'lastName': 'Doe',
  'avatarUrl': 'https://example.com/avatar.jpg',
  'pin': '123456',
  'currentRegistration': { /* TimeRegistration JSON */ }
})
```

#### `toJson()`
Converts Employee instance to JSON map.

```dart
{
  'id': 'uuid-123',
  'firstName': 'John',
  'lastName': 'Doe',
  'avatarUrl': 'https://example.com/avatar.jpg',
  'pin': '123456',
  'currentRegistration': { /* TimeRegistration JSON */ }
}
```

#### `copyWith({...})`
Creates a modified copy of the employee with specified changes.

```dart
employee.copyWith(
  firstName: 'Jane',
  clearRegistration: true  // Sets currentRegistration to null
)
```

### Example

```dart
const employee = Employee(
  id: 'e1a2b3c4-5678-90ab-cdef-123456789abc',
  firstName: 'María',
  lastName: 'García',
  avatarUrl: 'https://example.com/maria.jpg',
  pin: '987654',
  currentRegistration: null,
);
```

---

## TimeRegistration Model

Represents a work session for an employee, tracking start time, end time, pause times, and calculating worked hours.

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | `String` | ✅ | Unique registration identifier (UUID) |
| `employeeId` | `String` | ✅ | Foreign key to Employee |
| `startTime` | `DateTime` | ✅ | Time when work session started |
| `endTime` | `DateTime?` | ❌ | Time when work session ended (null if active) |
| `pauseTime` | `DateTime?` | ❌ | Time when pause started (null if never paused) |
| `resumeTime` | `DateTime?` | ❌ | Time when pause ended (null if never resumed) |
| `date` | `String` | ✅ | Date in DD/MM/YYYY format |

### Computed Properties

| Property | Return Type | Description |
|----------|-------------|-------------|
| `totalMinutes` | `int` | Total minutes worked (excluding pause time) |
| `remainingMinutes` | `int` | Minutes remaining to reach target (from AppConfig) |
| `isActive` | `bool` | Returns `true` if `endTime` is null (session ongoing) |
| `isPaused` | `bool` | Returns `true` if currently paused |
| `status` | `TimeRegistrationStatus` | Color zone based on worked time (green/orange/red) |

### Status Calculation

The `status` property returns one of three values based on total minutes worked:

- **🟢 GREEN**: Within target range (±15 minutes)
- **🟠 ORANGE**: Approaching overtime (15-30 minutes over target)
- **🔴 RED**: Overtime threshold reached (30+ minutes over target)

### Enum: TimeRegistrationStatus

```dart
enum TimeRegistrationStatus { green, orange, red }
```

### Methods

#### `fromJson(Map<String, dynamic> json)`
Creates a TimeRegistration instance from JSON data.

```dart
TimeRegistration.fromJson({
  'id': 'reg-123',
  'employeeId': 'emp-456',
  'startTime': '2025-01-08T09:00:00.000Z',
  'endTime': '2025-01-08T17:30:00.000Z',
  'pauseTime': '2025-01-08T13:00:00.000Z',
  'resumeTime': '2025-01-08T13:30:00.000Z',
  'date': '08/01/2025'
})
```

#### `toJson()`
Converts TimeRegistration instance to JSON map.

```dart
{
  'id': 'reg-123',
  'employeeId': 'emp-456',
  'startTime': '2025-01-08T09:00:00.000Z',
  'endTime': '2025-01-08T17:30:00.000Z',
  'pauseTime': '2025-01-08T13:00:00.000Z',
  'resumeTime': '2025-01-08T13:30:00.000Z',
  'date': '08/01/2025'
}
```

#### `copyWith({...})`
Creates a modified copy of the registration with specified changes.

### Example

```dart
const registration = TimeRegistration(
  id: 'r1a2b3c4-5678-90ab-cdef-123456789abc',
  employeeId: 'e1a2b3c4-5678-90ab-cdef-123456789abc',
  startTime: DateTime(2025, 1, 8, 9, 0),
  endTime: null,  // Active session
  pauseTime: null,
  resumeTime: null,
  date: '08/01/2025',
);

print(registration.isActive);  // true
print(registration.totalMinutes);  // e.g., 240 (4 hours)
print(registration.status);  // TimeRegistrationStatus.green
```

---

## Shift Model

Represents a scheduled work shift for an employee, including time range and shift type.

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | `String` | ✅ | Unique shift identifier (UUID) |
| `employeeId` | `String` | ✅ | Foreign key to Employee |
| `date` | `DateTime` | ✅ | Date of the shift |
| `startTime` | `DateTime` | ✅ | Shift start time |
| `endTime` | `DateTime` | ✅ | Shift end time |
| `shiftTypeId` | `String` | ✅ | Foreign key to ShiftType |

### Computed Properties

| Property | Return Type | Description |
|----------|-------------|-------------|
| `duration` | `Duration` | Duration between start and end time |
| `durationInMinutes` | `int` | Duration in total minutes |
| `durationFormatted` | `String` | Human-readable duration (e.g., "8h 30m") |
| `isPast` | `bool` | Returns `true` if shift date is in the past |
| `isToday` | `bool` | Returns `true` if shift date is today |
| `isFuture` | `bool` | Returns `true` if shift date is in the future |

### Methods

#### `fromJson(Map<String, dynamic> json)`
Creates a Shift instance from JSON data.

```dart
Shift.fromJson({
  'id': 'shift-123',
  'employeeId': 'emp-456',
  'date': '2025-01-08T00:00:00.000Z',
  'startTime': '2025-01-08T09:00:00.000Z',
  'endTime': '2025-01-08T17:00:00.000Z',
  'shiftTypeId': 'type-morning'
})
```

#### `toJson()`
Converts Shift instance to JSON map.

```dart
{
  'id': 'shift-123',
  'employeeId': 'emp-456',
  'date': '2025-01-08T00:00:00.000Z',
  'startTime': '2025-01-08T09:00:00.000Z',
  'endTime': '2025-01-08T17:00:00.000Z',
  'shiftTypeId': 'type-morning'
}
```

#### `copyWith({...})`
Creates a modified copy of the shift with specified changes.

### Example

```dart
const shift = Shift(
  id: 's1a2b3c4-5678-90ab-cdef-123456789abc',
  employeeId: 'e1a2b3c4-5678-90ab-cdef-123456789abc',
  date: DateTime(2025, 1, 8),
  startTime: DateTime(2025, 1, 8, 9, 0),
  endTime: DateTime(2025, 1, 8, 17, 0),
  shiftTypeId: 'morning-shift-type',
);

print(shift.durationFormatted);  // "8h 0m"
print(shift.isToday);  // true/false depending on current date
```

---

## ShiftType Model

Represents a type of shift with classification and visual styling.

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | `String` | ✅ | Unique shift type identifier (UUID) |
| `name` | `String` | ✅ | Human-readable name of the shift type |
| `colorHex` | `String` | ✅ | Hex color code for UI representation |

### Computed Properties

| Property | Return Type | Description |
|----------|-------------|-------------|
| `color` | `Color` | Flutter Color from hex string |

### Methods

#### `fromJson(Map<String, dynamic> json)`
Creates a ShiftType instance from JSON data.

```dart
ShiftType.fromJson({
  'id': 'type-morning',
  'name': 'Mañana',
  'colorHex': '#4CAF50'
})
```

#### `toJson()`
Converts ShiftType instance to JSON map.

```dart
{
  'id': 'type-morning',
  'name': 'Mañana',
  'colorHex': '#4CAF50'
}
```

#### `copyWith({...})`
Creates a modified copy of the shift type with specified changes.

### Example

```dart
const shiftType = ShiftType(
  id: 'morning-shift-type',
  name: 'Mañana',
  colorHex: '#4CAF50',
);

print(shiftType.name);  // "Mañana"
print(shiftType.color);  // Color(0xFF4CAF50)
```

---

## AppConfig Model

Represents application-wide configuration settings.

### Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `targetTimeMinutes` | `int` | ✅ | Target daily work time in minutes (default: 480) |
| `workingDays` | `List<int>` | ✅ | Working days (1=Monday, 7=Sunday) |
| `shiftTypes` | `List<ShiftType>` | ✅ | Available shift types in the system |

### Methods

#### `fromJson(Map<String, dynamic> json)`
Creates an AppConfig instance from JSON data.

```dart
AppConfig.fromJson({
  'targetTimeMinutes': 480,
  'workingDays': [1, 2, 3, 4, 5],
  'shiftTypes': [
    { 'id': 'morning', 'name': 'Mañana', 'colorHex': '#4CAF50' },
    { 'id': 'afternoon', 'name': 'Tarde', 'colorHex': '#2196F3' }
  ]
})
```

#### `toJson()`
Converts AppConfig instance to JSON map.

```dart
{
  'targetTimeMinutes': 480,
  'workingDays': [1, 2, 3, 4, 5],
  'shiftTypes': [
    { 'id': 'morning', 'name': 'Mañana', 'colorHex': '#4CAF50' },
    { 'id': 'afternoon', 'name': 'Tarde', 'colorHex': '#2196F3' }
  ]
}
```

#### `copyWith({...})`
Creates a modified copy of the config with specified changes.

### Example

```dart
const appConfig = AppConfig(
  targetTimeMinutes: 480,
  workingDays: [1, 2, 3, 4, 5],
  shiftTypes: [
    ShiftType(id: 'morning', name: 'Mañana', colorHex: '#4CAF50'),
    ShiftType(id: 'afternoon', name: 'Tarde', colorHex: '#2196F3'),
  ],
);
```

---

## Entity Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                         EMPLOYEE                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ id: String (PK)                                       │  │
│  │ firstName: String                                     │  │
│  │ lastName: String                                      │  │
│  │ avatarUrl: String?                                    │  │
│  │ pin: String                                           │  │
│  │ currentRegistration: TimeRegistration?                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          │ Has Many
                          │
          ┌───────────────┴───────────────┐
          │                               │
          ▼                               ▼
┌─────────────────────┐          ┌─────────────────────┐
│  TIME REGISTRATION  │          │       SHIFT         │
│  ┌───────────────┐  │          │  ┌───────────────┐  │
│  │ id: String    │  │          │  │ id: String    │  │
│  │ employeeId: → │──┼──────────┼──│ employeeId: → │  │
│  │ startTime     │  │          │  │ date          │  │
│  │ endTime       │  │          │  │ startTime     │  │
│  │ pauseTime     │  │          │  │ endTime       │  │
│  │ resumeTime    │  │          │  │ shiftTypeId: →│──┼───┐
│  │ date          │  │          │  └───────────────┘  │   │
│  └───────────────┘  │          └─────────────────────┘   │
└─────────────────────┘                                      │
                                                          │
┌─────────────────────┐                                      │
│     SHIFTTYPE       │                                      │
│  ┌───────────────┐  │                                      │
│  │ id: String    │←┼──────────────────────────────────────┘
│  │ name          │  │
│  │ colorHex      │  │
│  └───────────────┘  │
└─────────────────────┘
```

### Relationship Details

#### Employee → TimeRegistration (One-to-Many)

- One employee can have **many time registrations** (historical records)
- One employee has **zero or one active registration** (`currentRegistration`)
- Foreign Key: `TimeRegistration.employeeId → Employee.id`

#### Employee → Shift (One-to-Many)

- One employee can have **many scheduled shifts**
- Shifts can be past, present, or future
- Foreign Key: `Shift.employeeId → Employee.id`

#### Shift → ShiftType (Many-to-One)

- Many shifts can belong to **one shift type**
- Shift type defines the classification and color
- Foreign Key: `Shift.shiftTypeId → ShiftType.id`

#### TimeRegistration ← → Shift (Independent)

- TimeRegistrations and Shifts are **independent entities**
- A Shift represents **planned work schedule**
- A TimeRegistration represents **actual worked time**
- They can be compared to detect schedule adherence

---

## Firebase Collections Structure

### Collection: `employees`

```
employees/
  {employeeId}/
    - id: String
    - firstName: String
    - lastName: String
    - avatarUrl: String | null
    - pin: String
    - currentRegistration: Map | null
```

**Document ID**: Uses the employee's UUID as the document ID
**Indexes**: None required for basic queries

### Collection: `time_registrations`

```
time_registrations/
  {registrationId}/
    - id: String
    - employeeId: String (indexed)
    - startTime: Timestamp
    - endTime: Timestamp | null
    - pauseTime: Timestamp | null
    - resumeTime: Timestamp | null
    - date: String (DD/MM/YYYY)
```

**Document ID**: Uses the registration's UUID as the document ID
**Indexes Required**:
- Single field: `employeeId` (Ascending)
- Composite: `employeeId` (Ascending) + `startTime` (Descending)

### Collection: `shifts`

```
shifts/
  {shiftId}/
    - id: String
    - employeeId: String (indexed)
    - date: Timestamp
    - startTime: Timestamp
    - endTime: Timestamp
    - shiftTypeId: String
```

**Document ID**: Uses the shift's UUID as the document ID
**Indexes Required**:
- Single field: `employeeId` (Ascending)
- Composite: `employeeId` (Ascending) + `date` (Ascending)

### Collection: `shift_types`

```
shift_types/
  {shiftTypeId}/
    - id: String
    - name: String
    - colorHex: String
```

**Document ID**: Uses the shift type's UUID as the document ID
**Indexes**: None required (small reference collection)

### Collection: `config`

```
config/
  {configId}/
    - targetTimeMinutes: Number
    - workingDays: Array
    - shiftTypes: Array (embedded)
```

**Document ID**: Fixed ID (e.g., "app_config")
**Indexes**: None required (single document)

### Firestore Indexes

Create these composite indexes in Firebase Console:

```yaml
# Index 1: Employee Time Registrations (ordered by most recent)
Collection: time_registrations
Fields:
  - employeeId: Ascending
  - startTime: Descending

# Index 2: Employee Shifts (ordered by date)
Collection: shifts
Fields:
  - employeeId: Ascending
  - date: Ascending
  - startTime: Ascending
```

---

## Data Flow

### 1. Clock-In Flow

```
User Action: Clock In
    ↓
1. Create TimeRegistration
   - Generate UUID
   - Set startTime = DateTime.now()
   - Set endTime = null
   - Set pauseTime = null
   - Set resumeTime = null
   - Set date = "DD/MM/YYYY"
   - Set employeeId
    ↓
2. Save to Firestore
   - Add to time_registrations collection
    ↓
3. Update Employee
   - Set currentRegistration = new registration
   - Update employees collection
    ↓
4. Update UI State
```

### 2. Clock-Out Flow

```
User Action: Clock Out
    ↓
1. Update TimeRegistration
   - Set endTime = DateTime.now()
   - Keep startTime unchanged
   - Keep pause/resume times unchanged
    ↓
2. Update Firestore
   - Update time_registrations document
    ↓
3. Update Employee
   - Set currentRegistration = null
   - Update employees collection
    ↓
4. Update UI State
```

### 3. Pause/Resume Flow

```
User Action: Pause Work
    ↓
1. Update TimeRegistration
   - Set pauseTime = DateTime.now()
   - Keep other times unchanged
    ↓
2. Update Firestore
   - Update time_registrations document
    ↓
3. Update UI State

User Action: Resume Work
    ↓
1. Update TimeRegistration
   - Set resumeTime = DateTime.now()
   - Keep other times unchanged
    ↓
2. Update Firestore
   - Update time_registrations document
    ↓
3. Update UI State
```

### 4. Load Employee Profile

```
Navigate to Profile Screen
    ↓
1. Load Employee Data
   - Fetch from employees collection
    ↓
2. Load Today's Shift (Parallel)
   - Query shifts where:
     * employeeId = current employee
     * date = today
    ↓
3. Load Today's Registration (Parallel)
   - Query time_registrations where:
     * employeeId = current employee
     * date = today
    ↓
4. Load Upcoming Shifts (Parallel)
   - Query shifts where:
     * employeeId = current employee
     * date >= today
     * Limit: 50
    ↓
5. Load Statistics (Parallel)
   - Count shifts this month
   - Count registrations this month
    ↓
6. Combine & Display
```

### 5. Load Registration History

```
Navigate to Registrations Screen
    ↓
1. Initial Load
   - Fetch first 20 registrations
   - Order by startTime DESC
    ↓
2. Pagination
   - Load more on scroll
   - Use offset + limit
    ↓
3. Display with Status Colors
```

---

## Data Validation Rules

### Employee Validation

- `id`: Must be valid UUID format
- `firstName`: Required, non-empty string, max 50 characters
- `lastName`: Required, non-empty string, max 50 characters
- `pin`: Required, exactly 6 digits (numeric string)
- `avatarUrl`: Optional, must be valid URL if provided

### TimeRegistration Validation

- `id`: Must be valid UUID format
- `employeeId`: Must reference existing employee
- `startTime`: Required, must be valid DateTime
- `endTime`: Optional, if provided must be after startTime
- `pauseTime`: Optional, if provided must be after startTime and before endTime
- `resumeTime`: Optional, if provided must be after pauseTime and before endTime
- `date`: Required, must be in DD/MM/YYYY format
- `totalMinutes`: Must be >= 0

### Shift Validation

- `id`: Must be valid UUID format
- `employeeId`: Must reference existing employee
- `date`: Required, must be valid DateTime
- `startTime`: Required, must be valid DateTime
- `endTime`: Required, must be after startTime
- `shiftTypeId`: Must reference existing shift type
- `duration`: Must be > 0 minutes

### ShiftType Validation

- `id`: Must be valid UUID format
- `name`: Required, non-empty string, max 50 characters
- `colorHex`: Required, valid hex color code (e.g., "#FF5722")

### AppConfig Validation

- `targetTimeMinutes`: Required, must be > 0, reasonable range (1-1440)
- `workingDays`: Required, array of integers 1-7, non-empty
- `shiftTypes`: Required, non-empty array of valid ShiftType objects

---

## Mock Data Location

For development mode, mock data is stored in JSON files:

- **Employees**: `assets/mock/employees.json`
- **Time Registrations**: `assets/mock/time_registrations.json`
- **Shifts**: `assets/mock/shifts.json`
- **Shift Types**: `assets/mock/shift_types.json`
- **App Config**: `assets/mock/config.json`

These files contain sample data with the same structure as Firebase documents.

---

## Immutability & State Management

All models are **immutable**:

- All properties are `final`
- Constructors are `const` when possible
- Modifications use `copyWith()` methods
- No setters or mutable state

This ensures:
- ✅ Predictable state changes
- ✅ Easy debugging with state history
- ✅ No unintended side effects
- ✅ Compatible with Riverpod state management

---

## License

This documentation is part of the Timely project, licensed under a Custom Open Source License with Commercial Restrictions.

For complete terms, see the [LICENSE](../../LICENSE) file.

---

**Last Updated:** January 2026  
**Version:** 1.0.0