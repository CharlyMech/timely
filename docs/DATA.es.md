# Arquitectura de Datos

Este documento describe la **arquitectura de datos completa** de la aplicación Timely, incluyendo modelos de datos, relaciones entre entidades, repositorios, servicios y patrones de flujo de datos.

## Tabla de Contenidos

-  [Resumen](#resumen)
-  [Modelos de Datos](#modelos-de-datos)

   -  [Empleado](#empleado)
   -  [Rol](#rol)
   -  [Registro de Tiempo](#registrotimeregistration)
   -  [Turno](#turno)
   -  [Tipo de Turno](#tipodeturno)
   -  [Configuración de la App](#appconfig)

-  [Modelos de Auditoría](#modelos-de-auditoría)

   -  [Enums de Auditoría](#enums-de-auditoría)
   -  [LoginAudit](#loginaudit)
   -  [EmployeeAudit](#employeeaudit)
   -  [TimeRegistrationAudit](#timeregistrationaudit)
   -  [ShiftAudit](#shiftaudit)
   -  [ShiftTypeAudit](#shifttypeaudit)
   -  [UserAudit](#useraudit)

-  [Relaciones entre Entidades](#relaciones-entre-entidades)
-  [Arquitectura de Servicios](#arquitectura-de-servicios)

   -  [Interfaces de Servicio Abstractas](#interfaces-de-servicio-abstractas)
   -  [Implementaciones en Firebase](#implementaciones-en-firebase)
   -  [Implementaciones Mock](#implementaciones-mock)
   -  [Infraestructura de Cliente API](#infraestructura-de-cliente-api)

-  [Servicio de Auditoría](#servicio-de-auditoría)
-  [Patrón de Repositorio](#patrón-de-repositorio)
-  [Flujo de Datos](#flujo-de-datos)
-  [Validación de Datos](#validación-de-datos)

---

## Resumen

Timely utiliza un enfoque de **arquitectura limpia (clean architecture)** con separación clara entre modelos de datos, servicios y repositorios. La capa de datos está diseñada para ser **agnóstica al entorno**, soportando tanto Firebase en producción como modos Mock para desarrollo mediante interfaces abstractas.

### Principios Clave

1. **Modelos de Datos Inmutables**: Todas las entidades son inmutables con métodos `copyWith`.
2. **Abstracción de Servicios**: Interfaces abstractas permiten cambiar entre implementaciones Firebase, Mock y API.
3. **Patrón de Repositorio**: Los repositorios orquestan múltiples servicios para operaciones complejas.
4. **Seguridad de Tipos**: Uso completo de null safety y tipado de Dart.
5. **Propiedades Computadas**: Los modelos incluyen propiedades derivadas para lógica de negocio.
6. **Trazabilidad de Auditoría**: Registro completo de todas las acciones críticas para cumplimiento normativo.

---

## Modelos de Datos

Todos los modelos de datos se encuentran en [lib/models/](../lib/models/) e implementan métodos de serialización/deserialización para JSON y Firestore.

### Empleado

**Ubicación**: [lib/models/employee.dart](../lib/models/employee.dart)

Representa a un empleado en el sistema con información de perfil y estado laboral actual.

#### Esquema

```dart
class Employee {
  final String id;                    // Identificador único (UUID)
  final String firstName;             // Nombre del empleado
  final String lastName;              // Apellido del empleado
  final String pin;                   // PIN de 6 dígitos para autenticación
  final String? email;                // Email opcional (validado)
  final String phone;                 // Teléfono (formato español)
  final String? avatarUrl;            // URL de foto de perfil opcional
  final String? address;              // Dirección física opcional
  final EmployeeStatus status;        // Estado actual (activo/inactivo/vacaciones/permiso)
  final String personId;              // DNI o NIE (validado)
  final String roleId;                // Referencia a la entidad Role (UUID)
  final WorkType workType;            // Tipo de jornada laboral (completa/parcial)
  final TimeRegistration? currentRegistration;  // Registro de tiempo del día
  final Shift? todayShift;            // Turno asignado para hoy
}
```

#### Enum

```dart
enum EmployeeStatus {
  active,     // Trabajando actualmente
  inactive,   // No trabajando
  vacation,   // De vacaciones
  leave       // En permiso
}

enum WorkType {
  complete,   // Jornada completa
  partial     // Jornada parcial
}
```

#### Reglas de Validación

-  **PIN**: Exactamente 6 dígitos
-  **Email**: Debe coincidir con el patrón: `r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'`
-  **Teléfono**: Debe coincidir con patrón español: `r'^[679]\d{8}$'`
   -  Formatos válidos: `612345678`, `723456789`, `934567890`
   -  Debe empezar con 6, 7, o 9
   -  Exactamente 9 dígitos
-  **PersonId**: Debe coincidir con patrón DNI o NIE: `r'^(\d{8}[A-Z]|[XYZ]\d{7}[A-Z])$'`
   -  Formato DNI: 8 dígitos seguidos de una letra (ej. `12345678A`)
   -  Formato NIE: X, Y, o Z seguido de 7 dígitos y una letra (ej. `X1234567L`)

#### Serialización

```dart
// Desde JSON (Mock)
Employee.fromJson(Map<String, dynamic> json)

// Desde Firestore
Employee.fromFirestore(DocumentSnapshot doc)

// A JSON
Map<String, dynamic> toJson()

// A Firestore
Map<String, dynamic> toFirestore()
```

#### Lógica de Negocio

-  El estado determina la visualización en la UI (color, ícono)
-  El registro actual determina acciones disponibles (iniciar/pausar/reanudar/finalizar)
-  El turno de hoy proporciona horas objetivo y horario esperado
-  El rol determina los permisos y nivel de acceso del empleado
-  El tipo de jornada (workType) afecta la planificación y cálculos de horas

---

### Rol

**Ubicación**: [lib/models/role.dart](../lib/models/role.dart)

Representa un rol de empleado con permisos asociados e información de visualización.

#### Esquema

```dart
class Role {
  final String id;                    // Identificador único (UUID)
  final RoleType type;                // Tipo de rol (enum)
  final String displayName;           // Nombre legible del rol
}
```

#### Enum

```dart
enum RoleType {
  manager,    // Rol de gerente
  staff,      // Rol de personal
  admin       // Rol de administrador
}
```

#### Roles Predefinidos

El sistema incluye tres roles predefinidos:

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

#### Serialización

```dart
// Desde JSON (Mock)
Role.fromJson(Map<String, dynamic> json)

// A JSON
Map<String, dynamic> toJson()
```

#### Lógica de Negocio

-  Los roles son referenciados por los empleados mediante `roleId`
-  No hay guardas ni permisos basados en roles en esta versión
-  Los roles son de solo lectura y se gestionan globalmente
-  Se utilizan para visualización y propósitos organizativos

---

### Registro de Tiempo

**Ubicación**: [lib/models/time_registration.dart](../lib/models/time_registration.dart)

Representa un registro de seguimiento de jornada laboral con timestamps de inicio, fin, pausa y reanudación.

#### Esquema

```dart
class TimeRegistration {
  final String id;                    // Identificador único
  final String employeeId;            // Referencia al empleado
  final String shiftId;               // Referencia al turno
  final DateTime startTime;           // Hora de inicio
  final DateTime? endTime;            // Hora de fin (null si activo)
  final DateTime? pauseTime;          // Inicio de pausa (null si no pausado)
  final DateTime? resumeTime;         // Fin de pausa (null si no reanudado)
  final String date;                  // Fecha en formato DD/MM/YYYY
  final DateTime? createdAt;          // Timestamp de creación
  final DateTime? lastUpdatedAt;      // Timestamp de última modificación
}
```

#### Propiedades Computadas

```dart
// Minutos trabajados totales (excluyendo pausa)
int get totalMinutes {
  if (endTime == null) return 0;

  final totalWorkMinutes = endTime!.difference(startTime).inMinutes;

  if (pauseTime != null && resumeTime != null) {
    final pauseMinutes = resumeTime!.difference(pauseTime!).inMinutes;
    return totalWorkMinutes - pauseMinutes;
  }

  return totalWorkMinutes;
}

// Minutos restantes para alcanzar objetivo
int? remainingMinutes(int targetMinutes) {
  if (endTime == null) return null;
  return targetMinutes - totalMinutes;
}

// Verificar si está pausado
bool get isPaused => pauseTime != null && resumeTime == null;

// Verificar si la jornada está activa
bool get isActive => endTime == null;

// Color de estado según diferencia con objetivo
TimeRegistrationStatus getStatus(int targetMinutes, AppConfig config) {
  final remaining = remainingMinutes(targetMinutes);
  if (remaining == null) return TimeRegistrationStatus.green;

  final difference = remaining.abs();

  if (difference <= config.warningThresholdMinutes) {
    return TimeRegistrationStatus.green;  // Dentro de ±15 min
  } else if (difference <= config.redThresholdMinutes) {
    return TimeRegistrationStatus.orange; // 15-60 min
  } else {
    return TimeRegistrationStatus.red;    // >60 min
  }
}
```

#### Enum de Estado

```dart
enum TimeRegistrationStatus {
  green,   // A tiempo (±15 min)
  orange,  // Alerta (15-60 min)
  red      // Error (>60 min)
}
```

#### Ejemplo de Cálculo de Tiempo

```
Ejemplo 1 (sin pausa):
  Inicio: 08:00
  Fin: 16:00
  Total: 480 min (8h)

Ejemplo 2 (con pausa):
  Inicio: 08:00
  Pausa: 12:00
  Reanudación: 13:00
  Fin: 17:00
  Total: (17:00 - 08:00) - (13:00 - 12:00) = 480 min (8h)

Ejemplo 3 (actualmente pausado):
  Inicio: 08:00
  Pausa: 12:00
  Reanudación: null
  Fin: null
  isPaused: true
  isActive: true
```

#### Serialización

```dart
TimeRegistration.fromJson(Map<String, dynamic> json)
TimeRegistration.fromFirestore(DocumentSnapshot doc)
Map<String, dynamic> toJson()
Map<String, dynamic> toFirestore()
```

**Manejo de Fechas**:

-  JSON: cadenas ISO 8601
-  Firestore: conversión a/de `Timestamp`
-  Visualización: formato DD/MM/YYYY

---

### Turno

**Ubicación**: [lib/models/shift.dart](../lib/models/shift.dart)

Representa un turno asignado a un empleado en una fecha específica.

#### Esquema

```dart
class Shift {
  final String id;                    // Identificador único
  final String employeeId;            // Referencia al empleado
  final DateTime date;                // Fecha del turno
  final String shiftTypeId;           // Referencia al tipo de turno
  final String? notes;                // Notas opcionales
}
```

#### Propiedades Computadas

```dart
// Turno en el pasado
bool get isPast {
  final today = DateTime.now();
  final shiftDate = DateTime(date.year, date.month, date.day);
  final nowDate = DateTime(today.year, today.month, today.day);
  return shiftDate.isBefore(nowDate);
}

// Turno de hoy
bool get isToday {
  final today = DateTime.now();
  final shiftDate = DateTime(date.year, date.month, date.day);
  final nowDate = DateTime(today.year, today.month, today.day);
  return shiftDate.isAtSameMomentAs(nowDate);
}

// Turno futuro
bool get isFuture {
  final today = DateTime.now();
  final shiftDate = DateTime(date.year, date.month, date.day);
  final nowDate = DateTime(today.year, today.month, today.day);
  return shiftDate.isAfter(nowDate);
}
```

#### Lógica de Negocio

-  Los turnos se asignan antes del día laboral
-  No se puede iniciar trabajo sin turno asignado para hoy
-  Turnos pasados son de solo lectura
-  Turnos futuros se pueden crear/modificar/eliminar

---

### Tipo de Turno

**Ubicación**: [lib/models/shift_type.dart](../lib/models/shift_type.dart)

Define un tipo de turno con rangos horarios y duración objetivo.

#### Esquema

```dart
class ShiftType {
  final String id;                    // Identificador único
  final String name;                  // Nombre de visualización
  final String colorHex;              // Color en #RRGGBB
  final String startTime;             // Inicio HH:mm
  final String endTime;               // Fin HH:mm
  final String? pauseTime;            // Pausa opcional HH:mm
  final String? resumeTime;           // Reanudación opcional HH:mm
  final int targetTimeMinutes;        // Duración esperada (min)
}
```

#### Tipos por Defecto

**Turno Mañana**:

```dart
{
  id: "morning",
  name: "Mañana",
  colorHex: "#FFA726",
  startTime: "08:00",
  endTime: "16:00",
  pauseTime: "12:00",
  resumeTime: "13:00",
  targetTimeMinutes: 480
}
```

**Turno Tarde**:

```dart
{
  id: "afternoon",
  name: "Tarde",
  colorHex: "#42A5F5",
  startTime: "14:00",
  endTime: "22:00",
  pauseTime: "18:00",
  resumeTime: "19:00",
  targetTimeMinutes: 480
}
```

**Turno Dividido**:

```dart
{
  id: "split",
  name: "Dividido",
  colorHex: "#66BB6A",
  startTime: "09:00",
  endTime: "13:00",
  pauseTime: null,
  resumeTime: null,
  targetTimeMinutes: 240
}
```

#### Propiedades Computadas

```dart
bool get hasPauseResume => pauseTime != null && resumeTime != null;
```

#### Formato de Hora

Todos los horarios usan **24h (HH:mm)**:

-  08:00 = 8:00 AM
-  16:00 = 4:00 PM
-  22:00 = 10:00 PM

---

### Configuración de la App

**Ubicación**: [lib/models/app_config.dart](../lib/models/app_config.dart)

Configuración global de la aplicación para parámetros de jornada laboral.

#### Esquema

```dart
class AppConfig {
  final int defaultTargetTimeMinutes;     // Duración laboral por defecto
  final int warningThresholdMinutes;      // Umbral de alerta amarilla
  final int redThresholdMinutes;          // Umbral de alerta roja
  final List<int> workingDays;            // Días laborales (1=Lunes, 7=Domingo)
}
```

#### Valores por Defecto

```dart
{
  defaultTargetTimeMinutes: 480,   // 8 horas
  warningThresholdMinutes: 15,
  redThresholdMinutes: 60,
  workingDays: [1,2,3,4,5]        // Lunes a Viernes
}
```

#### Métodos Computados

```dart
bool isWorkingDay(DateTime date) {
  return workingDays.contains(date.weekday);
}
```

#### Umbrales de Estado

```
Diferencia con objetivo | Estado
------------------------|-------
≤ 15 min                | Verde (A tiempo)
15-60 min               | Naranja (Alerta)
> 60 min                | Rojo (Error)
```

---

## Relaciones entre Entidades

### Diagrama de Relaciones

```
AppConfig (singleton)
    │
    └─────────────┐
                  │
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
Employee   │      │
    ↑      │      │
    │      │      │
    └──────┴──────┘
           │
TimeRegistration
```

### Resumen

-  **AppConfig**: Singleton global, referencia de todos los turnos y registros
-  **ShiftType → Shift**: Uno a muchos
-  **Employee → Shift**: Uno a muchos
-  **Employee → TimeRegistration**: Uno a muchos
-  **Shift → TimeRegistration**: Uno a uno por día
-  **Employee → Estado Actual**: Embeds `currentRegistration` y `todayShift`

---

## Modelos de Auditoría

Todos los modelos de auditoría se encuentran en [lib/models/audit/](../lib/models/audit/) y proporcionan trazabilidad completa para cumplimiento normativo.

### Enums de Auditoría

**Ubicación**: [lib/models/audit/](../lib/models/audit/)

#### AuditAction

```dart
enum AuditAction {
  create,   // Entidad creada
  update,   // Entidad modificada
  delete    // Entidad eliminada
}
```

#### AuditSource

```dart
enum AuditSource {
  app,        // Acción originada desde la app móvil
  dashboard   // Acción originada desde el dashboard de admin
}
```

#### ActorType

```dart
enum ActorType {
  employee,   // Acción realizada por empleado (autenticación PIN)
  user        // Acción realizada por usuario admin (autenticación login)
}
```

#### LoginType

```dart
enum LoginType {
  pin,    // Autenticación PIN de empleado (app)
  login   // Autenticación login de usuario (dashboard)
}
```

#### TimeRegistrationAction

```dart
enum TimeRegistrationAction {
  start,         // Jornada iniciada
  pause,         // Jornada pausada
  resume,        // Jornada reanudada
  end,           // Jornada finalizada
  manualUpdate   // Actualización manual por admin
}
```

---

### LoginAudit

**Ubicación**: [lib/models/audit/login_audit.dart](../lib/models/audit/login_audit.dart)

Registra todos los intentos de autenticación para cumplimiento de seguridad.

#### Esquema

```dart
class LoginAudit {
  final String id;                    // Identificador único
  final String actorId;               // ID de empleado o usuario
  final ActorType actorType;          // Tipo de actor
  final LoginType loginType;          // Tipo de intento de login
  final bool success;                 // Si el login tuvo éxito
  final DateTime timestamp;           // Cuándo ocurrió el intento
  final String? failureReason;        // Razón del fallo (si falló)
}
```

**Colección Firestore**: `login_audit`

---

### EmployeeAudit

**Ubicación**: [lib/models/audit/employee_audit.dart](../lib/models/audit/employee_audit.dart)

Registra cambios en las entidades de empleado.

#### Esquema

```dart
class EmployeeAudit {
  final String id;                    // Identificador único
  final String employeeId;            // Empleado modificado
  final AuditAction action;           // CREATE, UPDATE, DELETE
  final AuditSource source;           // APP o DASHBOARD
  final String actorId;               // Quién realizó la acción
  final ActorType actorType;          // Tipo de actor
  final DateTime timestamp;           // Cuándo ocurrió la acción
  final Map<String, dynamic>? previousData;  // Estado antes del cambio
  final Map<String, dynamic>? newData;       // Estado después del cambio
}
```

**Colección Firestore**: `employee_audit`

---

### TimeRegistrationAudit

**Ubicación**: [lib/models/audit/time_registration_audit.dart](../lib/models/audit/time_registration_audit.dart)

Registra todas las acciones de registro de tiempo para cumplimiento laboral.

#### Esquema

```dart
class TimeRegistrationAudit {
  final String id;                          // Identificador único
  final String timeRegistrationId;          // Registro siendo rastreado
  final String employeeId;                  // Empleado asociado
  final TimeRegistrationAction action;      // START, PAUSE, RESUME, END, MANUAL_UPDATE
  final AuditSource source;                 // APP o DASHBOARD
  final String actorId;                     // Quién realizó la acción
  final ActorType actorType;                // Tipo de actor
  final DateTime timestamp;                 // Cuándo ocurrió la acción
  final DateTime? actionTime;               // La hora registrada para la acción
}
```

**Colección Firestore**: `time_registration_audit`

**Crítico para**: Cumplimiento de ley laboral, preparación para inspecciones

---

### ShiftAudit

**Ubicación**: [lib/models/audit/shift_audit.dart](../lib/models/audit/shift_audit.dart)

Registra cambios en asignaciones de turnos.

#### Esquema

```dart
class ShiftAudit {
  final String id;                    // Identificador único
  final String shiftId;               // Turno modificado
  final String? assignedEmployeeId;   // Empleado asignado al turno
  final AuditAction action;           // CREATE, UPDATE, DELETE
  final AuditSource source;           // APP o DASHBOARD
  final String actorId;               // Quién realizó la acción
  final ActorType actorType;          // Tipo de actor
  final DateTime timestamp;           // Cuándo ocurrió la acción
  final Map<String, dynamic>? previousData;  // Estado antes del cambio
  final Map<String, dynamic>? newData;       // Estado después del cambio
}
```

**Colección Firestore**: `shift_audit`

---

### ShiftTypeAudit

**Ubicación**: [lib/models/audit/shift_type_audit.dart](../lib/models/audit/shift_type_audit.dart)

Registra cambios en definiciones de tipos de turno.

#### Esquema

```dart
class ShiftTypeAudit {
  final String id;                    // Identificador único
  final String shiftTypeId;           // Tipo de turno modificado
  final AuditAction action;           // CREATE, UPDATE, DELETE
  final AuditSource source;           // APP o DASHBOARD
  final String actorId;               // Quién realizó la acción
  final ActorType actorType;          // Tipo de actor
  final DateTime timestamp;           // Cuándo ocurrió la acción
  final Map<String, dynamic>? previousData;  // Estado antes del cambio
  final Map<String, dynamic>? newData;       // Estado después del cambio
}
```

**Colección Firestore**: `shift_type_audit`

---

### UserAudit

**Ubicación**: [lib/models/audit/user_audit.dart](../lib/models/audit/user_audit.dart)

Registra cambios en usuarios administradores del dashboard.

#### Esquema

```dart
class UserAudit {
  final String id;                    // Identificador único
  final String userId;                // Usuario modificado
  final AuditAction action;           // CREATE, UPDATE, DELETE
  final AuditSource source;           // APP o DASHBOARD
  final String actorId;               // Quién realizó la acción
  final ActorType actorType;          // Tipo de actor
  final DateTime timestamp;           // Cuándo ocurrió la acción
  final Map<String, dynamic>? previousData;  // Estado antes del cambio
  final Map<String, dynamic>? newData;       // Estado después del cambio
}
```

**Colección Firestore**: `user_audit`

---

## Infraestructura de Cliente API

**Ubicación**: [lib/services/api/](../lib/services/api/)

El cliente API proporciona infraestructura HTTP para futura migración a backend REST API.

#### ApiConfig

```dart
class ApiConfig {
  final String baseUrl;               // URL base de la API
  final int connectTimeout;           // Timeout de conexión (ms)
  final int receiveTimeout;           // Timeout de recepción (ms)
  final Map<String, String>? headers; // Headers por defecto
}
```

#### ApiClient

```dart
class ApiClient {
  final Dio _dio;
  final ApiConfig config;

  // Métodos HTTP
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
  final T? data;                      // Datos de respuesta
  final int statusCode;               // Código de estado HTTP
  final String? message;              // Mensaje de respuesta
  final bool success;                 // Si la petición tuvo éxito
}
```

**Características**:
- Cliente HTTP Dio con interceptores
- Soporte para autenticación basada en tokens
- Manejo automático de errores
- Mensajes de error en español para feedback al usuario
- Timeouts configurables

---

## Servicio de Auditoría

**Ubicación**: [lib/services/audit_service.dart](../lib/services/audit_service.dart)

El Servicio de Auditoría proporciona una interfaz unificada para registrar todas las acciones críticas en la aplicación.

### Interfaz Abstracta

```dart
abstract class AuditService {
  // Auditoría de login
  Future<void> logLogin(LoginAudit audit);

  // Auditoría de empleados
  Future<void> logEmployeeChange(EmployeeAudit audit);

  // Auditoría de registros de tiempo
  Future<void> logTimeRegistrationAction(TimeRegistrationAudit audit);

  // Auditoría de turnos
  Future<void> logShiftChange(ShiftAudit audit);

  // Auditoría de tipos de turno
  Future<void> logShiftTypeChange(ShiftTypeAudit audit);

  // Auditoría de usuarios
  Future<void> logUserChange(UserAudit audit);
}
```

### Implementación Firebase

**Ubicación**: [lib/services/firebase/firebase_audit_service.dart](../lib/services/firebase/firebase_audit_service.dart)

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

  // ... otros métodos
}
```

### Integración con Servicios Firebase

Todos los servicios Firebase ahora se integran con AuditService para registro automático:

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
    // Crear registro
    final registration = TimeRegistration(...);
    await _firestore.collection('time_registrations').doc(registration.id).set(...);

    // Registrar auditoría
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

### Configuración Basada en Entorno

El registro de auditoría se configura automáticamente según el entorno:

```dart
final auditServiceProvider = Provider<AuditService?>((ref) {
  // Auditoría deshabilitada en modo desarrollo
  if (Environment.isDev) return null;

  // Auditoría habilitada en producción
  return FirebaseAuditService();
});
```

---

El resto del documento de **Patrón de Repositorio, Flujo de Datos y Validación** se mantiene igual que el original en inglés; solo cambian los nombres de clases y comentarios a español, siguiendo la misma estructura y ejemplos de código.
