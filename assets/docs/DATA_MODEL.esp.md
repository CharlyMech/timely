# Timely - Documentación del Modelo de Datos

## Visión General

Este documento describe el modelo de datos completo utilizado en la aplicación Timely. La aplicación utiliza cinco entidades principales: **Employee**, **TimeRegistration**, **Shift**, **ShiftType** y **AppConfig**. Todos los modelos son inmutables e incluyen métodos de serialización/deserialización para Firebase y almacenamiento local.

---

## Tabla de Contenidos

1. [Modelo Employee](#modelo-employee)
2. [Modelo TimeRegistration](#modelo-timeregistration)
3. [Modelo Shift](#modelo-shift)
4. [Modelo ShiftType](#modelo-shifttype)
5. [Modelo AppConfig](#modelo-appconfig)
6. [Relaciones de Entidades](#relaciones-de-entidades)
7. [Estructura de Colecciones Firebase](#estructura-de-colecciones-firebase)
8. [Flujo de Datos](#flujo-de-datos)
9. [Reglas de Validación de Datos](#reglas-de-validación-de-datos)

---

## Modelo Employee

Representa un empleado en el sistema con información personal y registro de tiempo opcional actual.

### Propiedades

| Propiedad | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `id` | `String` | ✅ | Identificador único del empleado (UUID) |
| `firstName` | `String` | ✅ | Nombre del empleado |
| `lastName` | `String` | ✅ | Apellido del empleado |
| `avatarUrl` | `String?` | ❌ | URL opcional del avatar del empleado |
| `pin` | `String` | ✅ | PIN de 6 dígitos para acceso seguro a datos del empleado |
| `currentRegistration` | `TimeRegistration?` | ❌ | Registro de tiempo activo si el empleado está trabajando actualmente |

### Propiedades Calculadas

| Propiedad | Tipo de Retorno | Descripción |
|-----------|------------------|-------------|
| `fullName` | `String` | Retorna concatenación de `firstName` y `lastName` |

### Métodos

#### `fromJson(Map<String, dynamic> json)`
Crea una instancia Employee desde datos JSON.

```dart
Employee.fromJson({
  'id': 'uuid-123',
  'firstName': 'John',
  'lastName': 'Doe',
  'avatarUrl': 'https://example.com/avatar.jpg',
  'pin': '123456',
  'currentRegistration': { /* JSON TimeRegistration */ }
})
```

#### `toJson()`
Convierte instancia Employee a mapa JSON.

```dart
{
  'id': 'uuid-123',
  'firstName': 'John',
  'lastName': 'Doe',
  'avatarUrl': 'https://example.com/avatar.jpg',
  'pin': '123456',
  'currentRegistration': { /* JSON TimeRegistration */ }
}
```

#### `copyWith({...})`
Crea una copia modificada del empleado con cambios especificados.

```dart
employee.copyWith(
  firstName: 'Jane',
  clearRegistration: true  // Establece currentRegistration a null
)
```

### Ejemplo

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

## Modelo TimeRegistration

Representa una sesión de trabajo para un empleado, registrando hora de inicio, hora de fin, tiempos de pausa y calculando horas trabajadas.

### Propiedades

| Propiedad | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `id` | `String` | ✅ | Identificador único del registro (UUID) |
| `employeeId` | `String` | ✅ | Clave foránea a Employee |
| `startTime` | `DateTime` | ✅ | Hora de inicio de la sesión de trabajo |
| `endTime` | `DateTime?` | ❌ | Hora de fin de la sesión (null si está activa) |
| `pauseTime` | `DateTime?` | ❌ | Hora de inicio de pausa (null si nunca se pausó) |
| `resumeTime` | `DateTime?` | ❌ | Hora de fin de pausa (null si nunca se reanudó) |
| `date` | `String` | ✅ | Fecha en formato DD/MM/YYYY |

### Propiedades Calculadas

| Propiedad | Tipo de Retorno | Descripción |
|-----------|------------------|-------------|
| `totalMinutes` | `int` | Total de minutos trabajados (excluyendo tiempo de pausa) |
| `remainingMinutes` | `int` | Minutos restantes para alcanzar objetivo (desde AppConfig) |
| `isActive` | `bool` | Retorna `true` si `endTime` es null (sesión en curso) |
| `isPaused` | `bool` | Retorna `true` si está actualmente en pausa |
| `status` | `TimeRegistrationStatus` | Zona de color basada en tiempo trabajado (verde/naranja/rojo) |

### Cálculo de Estado

La propiedad `status` retorna uno de tres valores basados en los minutos trabajados totales:

- **🟢 GREEN**: Dentro del rango objetivo (±15 minutos)
- **🟠 ORANGE**: Acercándose a horas extra (15-30 minutos sobre objetivo)
- **🔴 RED**: Umbral de horas extra alcanzado (30+ minutos sobre objetivo)

### Enum: TimeRegistrationStatus

```dart
enum TimeRegistrationStatus { green, orange, red }
```

### Métodos

#### `fromJson(Map<String, dynamic> json)`
Crea una instancia TimeRegistration desde datos JSON.

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
Convierte instancia TimeRegistration a mapa JSON.

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
Crea una copia modificada del registro con cambios especificados.

### Ejemplo

```dart
const registration = TimeRegistration(
  id: 'r1a2b3c4-5678-90ab-cdef-123456789abc',
  employeeId: 'e1a2b3c4-5678-90ab-cdef-123456789abc',
  startTime: DateTime(2025, 1, 8, 9, 0),
  endTime: null,  // Sesión activa
  pauseTime: null,
  resumeTime: null,
  date: '08/01/2025',
);

print(registration.isActive);  // true
print(registration.totalMinutes);  // ej. 240 (4 horas)
print(registration.status);  // TimeRegistrationStatus.green
```

---

## Modelo Shift

Representa un turno de trabajo programado para un empleado, incluyendo rango de tiempo y tipo de turno.

### Propiedades

| Propiedad | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `id` | `String` | ✅ | Identificador único del turno (UUID) |
| `employeeId` | `String` | ✅ | Clave foránea a Employee |
| `date` | `DateTime` | ✅ | Fecha del turno |
| `startTime` | `DateTime` | ✅ | Hora de inicio del turno |
| `endTime` | `DateTime` | ✅ | Hora de fin del turno |
| `shiftTypeId` | `String` | ✅ | Clave foránea a ShiftType |

### Propiedades Calculadas

| Propiedad | Tipo de Retorno | Descripción |
|-----------|------------------|-------------|
| `duration` | `Duration` | Duración entre hora de inicio y fin |
| `durationInMinutes` | `int` | Duración en minutos totales |
| `durationFormatted` | `String` | Duración legible (ej. "8h 30m") |
| `isPast` | `bool` | Retorna `true` si la fecha del turno está en el pasado |
| `isToday` | `bool` | Retorna `true` si la fecha del turno es hoy |
| `isFuture` | `bool` | Retorna `true` si la fecha del turno está en el futuro |

### Métodos

#### `fromJson(Map<String, dynamic> json)`
Crea una instancia Shift desde datos JSON.

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
Convierte instancia Shift a mapa JSON.

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
Crea una copia modificada del turno con cambios especificados.

### Ejemplo

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
print(shift.isToday);  // true/false dependiendo de la fecha actual
```

---

## Modelo ShiftType

Representa un tipo de turno con clasificación y estilo visual.

### Propiedades

| Propiedad | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `id` | `String` | ✅ | Identificador único del tipo de turno (UUID) |
| `name` | `String` | ✅ | Nombre legible del tipo de turno |
| `colorHex` | `String` | ✅ | Código de color hex para representación visual |

### Propiedades Calculadas

| Propiedad | Tipo de Retorno | Descripción |
|-----------|------------------|-------------|
| `color` | `Color` | Color Flutter desde cadena hex |

### Métodos

#### `fromJson(Map<String, dynamic> json)`
Crea una instancia ShiftType desde datos JSON.

```dart
ShiftType.fromJson({
  'id': 'type-morning',
  'name': 'Mañana',
  'colorHex': '#4CAF50'
})
```

#### `toJson()`
Convierte instancia ShiftType a mapa JSON.

```dart
{
  'id': 'type-morning',
  'name': 'Mañana',
  'colorHex': '#4CAF50'
}
```

#### `copyWith({...})`
Crea una copia modificada del tipo de turno con cambios especificados.

### Ejemplo

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

## Modelo AppConfig

Representa configuraciones de toda la aplicación.

### Propiedades

| Propiedad | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `targetTimeMinutes` | `int` | ✅ | Tiempo de trabajo diario objetivo en minutos (default: 480) |
| `workingDays` | `List<int>` | ✅ | Días laborables (1=Lunes, 7=Domingo) |
| `shiftTypes` | `List<ShiftType>` | ✅ | Tipos de turno disponibles en el sistema |

### Métodos

#### `fromJson(Map<String, dynamic> json)`
Crea una instancia AppConfig desde datos JSON.

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
Convierte instancia AppConfig a mapa JSON.

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
Crea una copia modificada de la configuración con cambios especificados.

### Ejemplo

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

## Relaciones de Entidades

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
└─────────────────────────┬──────────────────────────────────┘
                          │
                          │ Tiene Muchos
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

### Detalles de Relaciones

#### Employee → TimeRegistration (Uno-a-Muchos)

- Un empleado puede tener **muchos registros de tiempo** (registros históricos)
- Un empleado tiene **cero o un registro activo** (`currentRegistration`)
- Clave Foránea: `TimeRegistration.employeeId → Employee.id`

#### Employee → Shift (Uno-a-Muchos)

- Un empleado puede tener **muchos turnos programados**
- Los turnos pueden ser pasados, presentes o futuros
- Clave Foránea: `Shift.employeeId → Employee.id`

#### Shift → ShiftType (Muchos-a-Uno)

- Muchos turnos pueden pertenecer a **un tipo de turno**
- El tipo de turno define la clasificación y color
- Clave Foránea: `Shift.shiftTypeId → ShiftType.id`

#### TimeRegistration ← → Shift (Independientes)

- TimeRegistrations y Shifts son **entidades independientes**
- Un Shift representa **horario de trabajo planificado**
- Un TimeRegistration representa **tiempo de trabajo real**
- Pueden compararse para detectar adherencia al horario

---

## Estructura de Colecciones Firebase

### Colección: `employees`

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

**ID de Documento**: Usa el UUID del empleado como ID del documento
**Índices**: No se requieren para consultas básicas

### Colección: `time_registrations`

```
time_registrations/
  {registrationId}/
    - id: String
    - employeeId: String (indexado)
    - startTime: Timestamp
    - endTime: Timestamp | null
    - pauseTime: Timestamp | null
    - resumeTime: Timestamp | null
    - date: String (DD/MM/YYYY)
```

**ID de Documento**: Usa el UUID del registro como ID del documento
**Índices Requeridos**:
- Campo simple: `employeeId` (Ascendente)
- Compuesto: `employeeId` (Ascendente) + `startTime` (Descendente)

### Colección: `shifts`

```
shifts/
  {shiftId}/
    - id: String
    - employeeId: String (indexado)
    - date: Timestamp
    - startTime: Timestamp
    - endTime: Timestamp
    - shiftTypeId: String
```

**ID de Documento**: Usa el UUID del turno como ID del documento
**Índices Requeridos**:
- Campo simple: `employeeId` (Ascendente)
- Compuesto: `employeeId` (Ascendente) + `date` (Ascendente)

### Colección: `shift_types`

```
shift_types/
  {shiftTypeId}/
    - id: String
    - name: String
    - colorHex: String
```

**ID de Documento**: Usa el UUID del tipo de turno como ID del documento
**Índices**: No se requieren (colección de referencia pequeña)

### Colección: `config`

```
config/
  {configId}/
    - targetTimeMinutes: Number
    - workingDays: Array
    - shiftTypes: Array (embebido)
```

**ID de Documento**: ID fijo (ej. "app_config")
**Índices**: No se requieren (documento único)

### Índices Firestore

Crea estos índices compuestos en Firebase Console:

```yaml
# Índice 1: Registros de Tiempo de Empleado (ordenados por más reciente)
Colección: time_registrations
Campos:
  - employeeId: Ascendente
  - startTime: Descendente

# Índice 2: Turnos de Empleado (ordenados por fecha)
Colección: shifts
Campos:
  - employeeId: Ascendente
  - date: Ascendente
  - startTime: Ascendente
```

---

## Flujo de Datos

### 1. Flujo de Entrada (Clock-In)

```
Acción Usuario: Entrada
    ↓
1. Crear TimeRegistration
   - Generar UUID
   - Establecer startTime = DateTime.now()
   - Establecer endTime = null
   - Establecer pauseTime = null
   - Establecer resumeTime = null
   - Establecer date = "DD/MM/YYYY"
   - Establecer employeeId
    ↓
2. Guardar en Firestore
   - Añadir a colección time_registrations
    ↓
3. Actualizar Employee
   - Establecer currentRegistration = nuevo registro
   - Actualizar colección employees
    ↓
4. Actualizar Estado UI
```

### 2. Flujo de Salida (Clock-Out)

```
Acción Usuario: Salida
    ↓
1. Actualizar TimeRegistration
   - Establecer endTime = DateTime.now()
   - Mantener startTime sin cambios
   - Mantener tiempos de pausa/reanudación sin cambios
    ↓
2. Actualizar Firestore
   - Actualizar documento time_registrations
    ↓
3. Actualizar Employee
   - Establecer currentRegistration = null
   - Actualizar colección employees
    ↓
4. Actualizar Estado UI
```

### 3. Flujo de Pausa/Reanudación

```
Acción Usuario: Pausar Trabajo
    ↓
1. Actualizar TimeRegistration
   - Establecer pauseTime = DateTime.now()
   - Mantener otros tiempos sin cambios
    ↓
2. Actualizar Firestore
   - Actualizar documento time_registrations
    ↓
3. Actualizar Estado UI

Acción Usuario: Reanudar Trabajo
    ↓
1. Actualizar TimeRegistration
   - Establecer resumeTime = DateTime.now()
   - Mantener otros tiempos sin cambios
    ↓
2. Actualizar Firestore
   - Actualizar documento time_registrations
    ↓
3. Actualizar Estado UI
```

### 4. Cargar Perfil de Empleado

```
Navegar a Pantalla de Perfil
    ↓
1. Cargar Datos de Empleado
   - Obtener de colección employees
    ↓
2. Cargar Turno de Hoy (Paralelo)
   - Consultar shifts donde:
     * employeeId = empleado actual
     * date = hoy
    ↓
3. Cargar Registro de Hoy (Paralelo)
   - Consultar time_registrations donde:
     * employeeId = empleado actual
     * date = hoy
    ↓
4. Cargar Próximos Turnos (Paralelo)
   - Consultar shifts donde:
     * employeeId = empleado actual
     * date >= hoy
     * Límite: 50
    ↓
5. Cargar Estadísticas (Paralelo)
   - Contar turnos este mes
   - Contar registros este mes
    ↓
6. Combinar y Mostrar
```

### 5. Cargar Historial de Registros

```
Navegar a Pantalla de Registros
    ↓
1. Carga Inicial
   - Obtener primeros 20 registros
   - Ordenar por startTime DESC
    ↓
2. Paginación
   - Cargar más al hacer scroll
   - Usar offset + limit
    ↓
3. Mostrar con Colores de Estado
```

---

## Reglas de Validación de Datos

### Validación Employee

- `id`: Debe ser formato UUID válido
- `firstName`: Requerido, string no vacío, máx 50 caracteres
- `lastName`: Requerido, string no vacío, máx 50 caracteres
- `pin`: Requerido, exactamente 6 dígitos (string numérico)
- `avatarUrl`: Opcional, debe ser URL válida si se proporciona

### Validación TimeRegistration

- `id`: Debe ser formato UUID válido
- `employeeId`: Debe referenciar empleado existente
- `startTime`: Requerido, debe ser DateTime válido
- `endTime`: Opcional, si se proporciona debe ser después de startTime
- `pauseTime`: Opcional, si se proporciona debe ser después de startTime y antes de endTime
- `resumeTime`: Opcional, si se proporciona debe ser después de pauseTime y antes de endTime
- `date`: Requerido, debe estar en formato DD/MM/YYYY
- `totalMinutes`: Debe ser >= 0

### Validación Shift

- `id`: Debe ser formato UUID válido
- `employeeId`: Debe referenciar empleado existente
- `date`: Requerido, debe ser DateTime válido
- `startTime`: Requerido, debe ser DateTime válido
- `endTime`: Requerido, debe ser después de startTime
- `shiftTypeId`: Debe referenciar tipo de turno existente
- `duration`: Debe ser > 0 minutos

### Validación ShiftType

- `id`: Debe ser formato UUID válido
- `name`: Requerido, string no vacío, máx 50 caracteres
- `colorHex`: Requerido, código de color hex válido (ej. "#FF5722")

### Validación AppConfig

- `targetTimeMinutes`: Requerido, debe ser > 0, rango razonable (1-1440)
- `workingDays`: Requerido, array de enteros 1-7, no vacío
- `shiftTypes`: Requerido, array no vacío de objetos ShiftType válidos

---

## Ubicación de Datos Mock

Para modo desarrollo, los datos mock se almacenan en archivos JSON:

- **Employees**: `assets/mock/employees.json`
- **Time Registrations**: `assets/mock/time_registrations.json`
- **Shifts**: `assets/mock/shifts.json`
- **Shift Types**: `assets/mock/shift_types.json`
- **App Config**: `assets/mock/config.json`

Estos archivos contienen datos de muestra con la misma estructura que los documentos Firebase.

---

## Inmutabilidad y Gestión de Estado

Todos los modelos son **inmutables**:

- Todas las propiedades son `final`
- Los constructores son `const` cuando es posible
- Las modificaciones usan métodos `copyWith()`
- No hay setters o estado mutable

Esto asegura:
- ✅ Cambios de estado predecibles
- ✅ Fácil debugging con historial de estado
- ✅ Sin side effects no deseados
- ✅ Compatibilidad con gestión de estado Riverpod

---

## Licencia

Esta documentación es parte del proyecto Timely, licenciado bajo una Licencia de Código Abierto Personalizada con Restricciones Comerciales.

Para términos completos, ver el archivo [LICENSE](../../LICENSE).

---

**Última Actualización:** Enero 2026  
**Versión:** 1.0.0