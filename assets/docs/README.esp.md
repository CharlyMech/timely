# Timely - Documentación Técnica

## Índice

1. [Visión General](#visión-general)
2. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
3. [Gestión de Estado](#gestión-de-estado)
4. [Modelo de Datos](#modelo-de-datos)
5. [Flujo de Ejecución](#flujo-de-ejecución)
6. [Estructura de Carpetas](#estructura-de-carpetas)
7. [Guía de Desarrollo](#guía-de-desarrollo)
8. [Contribuir](#contribuir)

## Visión General

**Timely** es una aplicación móvil de registro horario desarrollada en Flutter que permite a los empleados gestionar sus jornadas laborales de manera simple y eficiente.

### Características Principales

- ✅ Registro de entrada y salida de empleados
- ✅ Vista de empleados en grid responsivo con funcionalidad de búsqueda
- ✅ Detalle de registros horarios por empleado con seguimiento en tiempo real
- ✅ Cálculo automático de horas trabajadas con indicadores de estado (verde/naranja/rojo)
- ✅ Panel de perfil de empleado con integración de calendario de turnos
- ✅ Sistema completo de gestión de turnos (mañana, tarde, noche, nocturno)
- ✅ Historial completo de registros con paginación
- ✅ Acceso a datos de empleado protegido por PIN (seguridad de 6 dígitos)
- ✅ Pantalla de información de privacidad de datos (cumplimiento GDPR)
- ✅ Soporte dual de entorno: Desarrollo (Mock) y Producción (Firebase)
- ✅ Temas claro y oscuro con detección de preferencias del sistema
- ✅ Timeout de inactividad (5 minutos) con retorno automático a pantalla de personal
- ✅ Funcionalidad de pull-to-refresh en todas las pantallas de datos
- ✅ Diseño responsivo landscape/portrait

### Tecnologías Utilizadas

- **Flutter 3.10+** - Framework UI multiplataforma
- **Dart 3.10+** - Lenguaje de programación
- **Riverpod 3.0.3** - Gestión de estado con Notifiers
- **GoRouter 17.0.0** - Navegación declarativa con rutas type-safe
- **Firebase Core 3.6.0** & **Cloud Firestore 5.4.4** - Base de datos NoSQL en la nube para producción
- **SharedPreferences 2.5.3** - Persistencia local para preferencias de usuario
- **table_calendar 3.1.2** - Widget de calendario interactivo para visualización de turnos
- **Google Fonts 6.2.1** - Tipografía (Space Grotesk + DM Sans)
- **Flutter SVG 2.2.3** - Soporte SVG para iconos y gráficos
- **intl** - Internacionalización y formateo de fechas (localización española)

---

## Arquitectura del Proyecto

La aplicación sigue una **arquitectura limpia (Clean Architecture)** con separación clara de responsabilidades:

```
┌─────────────────────────────────────────────────┐
│                   UI Layer                      │
│  (Screens, Widgets, ViewModels)                 │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│              Repository Layer                   │
│  (Business Logic, Data Orchestration)           │
└─────────────────┬───────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────┐
│               Service Layer                     │
│  (Data Sources: Firebase, Mock)                 │
└─────────────────────────────────────────────────┘
```

### Capas de la Arquitectura

#### 1. **UI Layer (Presentación)**

- **Screens**: Pantallas completas de la aplicación con enrutamiento
- **Widgets**: Componentes de UI reutilizables
- **ViewModels**: Gestión del estado de UI usando Riverpod Notifiers

#### 2. **Repository Layer (Dominio)**

- Orquesta múltiples servicios
- Implementa lógica de negocio compleja
- Combina y transforma datos de diferentes fuentes
- Proporciona operaciones de alto nivel a la capa UI

#### 3. **Service Layer (Datos)**

- Abstracción de fuentes de datos
- Implementaciones específicas (Firebase, Mock)
- Operaciones CRUD con manejo de errores
- Cambio basado en entorno

#### 4. **Models (Entidades)**

- Modelos de dominio inmutables con serialización JSON
- Métodos de lógica de negocio (getters, propiedades calculadas)
- Modelos principales: Employee, TimeRegistration, Shift, ShiftType, AppConfig

---

## Gestión de Estado

### Arquitectura Riverpod 3.0

Timely utiliza **Riverpod 3.0** con la nueva API de `Notifier` para gestión de estado reactiva.

#### Providers Principales

```dart
// Provider de pantalla de personal
final employeeViewModelProvider =
    NotifierProvider<EmployeeViewModel, EmployeeState>(
        EmployeeViewModel.new
    );

// Provider de detalle de empleado (family - parametrizado por ID de empleado)
final employeeDetailViewModelProvider =
    NotifierProvider.family<EmployeeDetailViewModel, EmployeeDetailState, String>(
        EmployeeDetailViewModel.new
    );

// Provider de perfil de empleado (family)
final employeeProfileViewModelProvider =
    NotifierProvider.family<EmployeeProfileViewModel, EmployeeProfileState, String>(
        EmployeeProfileViewModel.new
    );

// Provider de registros de empleado (family)
final employeeRegistrationsViewModelProvider =
    NotifierProvider.family<EmployeeRegistrationsViewModel, EmployeeRegistrationsState, String>(
        EmployeeRegistrationsViewModel.new
    );

// Provider de tema
final themeViewModelProvider =
    NotifierProvider<ThemeViewModel, ThemeState>(
        ThemeViewModel.new
    );

// Provider de configuración de la app
final appConfigProvider =
    FutureProvider<AppConfig>((ref) async {
      final configService = ref.read(configServiceProvider);
      return await configService.getAppConfig();
    });
```

### Mejores Prácticas de Gestión de Estado

1. **Nunca modificar providers en `initState`**
   ```dart
   @override
   void initState() {
     super.initState();
     // ✅ BIEN:
     Future.microtask(() => ref.read(provider.notifier).load());
   }
   ```

2. **Usar `ref.watch` en build, `ref.read` en callbacks**

3. **Estados siempre inmutables**
   - Usar `final` en todas las propiedades
   - Implementar `copyWith` para actualizaciones
   - No usar setters

4. **Manejo de errores en ViewModels**
   - Capturar excepciones y convertirlas a mensajes amigables para el usuario
   - Actualizar estado con información de error
   - Mantener estados de carga apropiadamente

---

## Modelo de Datos

### Modelos Principales

#### Modelo Employee
```dart
class Employee {
  final String id;                    // UUID
  final String firstName;             // Nombre
  final String lastName;              // Apellido
  final String? avatarUrl;            // URL de avatar opcional
  final String pin;                   // PIN de 6 dígitos
  final TimeRegistration? currentRegistration; // Sesión activa
  
  String get fullName => '$firstName $lastName';
}
```

#### Modelo TimeRegistration
```dart
class TimeRegistration {
  final String id;                    // UUID
  final String employeeId;            // Clave foránea
  final DateTime startTime;           // Hora de entrada
  final DateTime? endTime;            // Hora de salida (null si está activo)
  final DateTime? pauseTime;          // Hora de inicio de pausa
  final DateTime? resumeTime;         // Hora de fin de pausa
  final String date;                  // Formato DD/MM/YYYY
  
  int get totalMinutes;               // Tiempo de trabajo calculado
  bool get isActive;                  // true si endTime es null
  bool get isPaused;                  // true si está en pausa actualmente
  TimeRegistrationStatus get status; // verde/naranja/rojo basado en duración
}
```

#### Modelo Shift
```dart
class Shift {
  final String id;                    // UUID
  final String employeeId;            // Clave foránea
  final DateTime date;                // Fecha del turno
  final DateTime startTime;           // Inicio del turno
  final DateTime endTime;             // Fin del turno
  final String shiftTypeId;           // Referencia a tipo de turno
  
  Duration get duration;              // Duración calculada
  bool get isToday;                   // Comparación de fecha
  bool get isPast;                    // Comparación de fecha
  bool get isFuture;                  // Comparación de fecha
}
```

#### Modelo ShiftType
```dart
class ShiftType {
  final String id;                    // UUID
  final String name;                  // Nombre del tipo (ej. "Mañana")
  final String colorHex;              // Color para UI
  
  Color get color;                    // Conversión de hex a Color
}
```

### Relaciones de Entidades

```
Employee (1) ←→ (Muchos) TimeRegistration
Employee (1) ←→ (Muchos) Shift
Shift (Muchos) ←→ (1) ShiftType
```

Para documentación detallada del modelo de datos, ver [DATA_MODEL.esp.md](./DATA_MODEL.esp.md).

---

## Flujo de Ejecución

### Flujo de Inicio de la Aplicación

```mermaid
graph TD
    A[main.dart] --> B[AppSetup.initialize]
    B --> C[Inicialización SharedPreferences]
    B --> D[Inicialización Firebase (solo prod)]
    B --> E[ProviderScope con overrides de entorno]
    E --> F[App Widget con GoRouter]
    F --> G[SplashScreen]
    G --> H[Cargar datos iniciales]
    H --> I[WelcomeScreen]
    I --> J[Usuario presiona "Empezar"]
    J --> K[StaffScreen]
```

### Flujo de Navegación Clave

1. **SplashScreen** (`/splash`) - Inicialización de app y precarga de datos
2. **WelcomeScreen** (`/welcome`) - Pantalla de bienvenida con botón de entrada
3. **StaffScreen** (`/staff`) - Grid principal de empleados con búsqueda
4. **TimeRegistrationDetailScreen** (`/employee/:id`) - Seguimiento horario de empleado
5. **EmployeeProfileScreen** (`/employee/:id/profile`) - Perfil y calendario
6. **EmployeeRegistrationsScreen** (`/employee/:id/registrations`) - Historial
7. **DataPrivacyScreen** (`/data-privacy`) - Política de privacidad
8. **ErrorScreen** (`/error`) - Manejo global de errores

### Patrones de Flujo de Datos

#### Operaciones de Lectura
```
Acción UI → ViewModel → Repository → Service → Fuente de Datos
UI ← Actualización Estado ← Repository ← Service ← Modelos
```

#### Operaciones de Escritura
```
Acción UI → ViewModel → Repository → Reglas de Negocio → Service → Fuente de Datos
UI ← Éxito/Error ← Actualización Estado ← Repository ← Service ← Resultado
```

Para documentación detallada del flujo de ejecución, ver [EXECUTION_FLOW.esp.md](./EXECUTION_FLOW.esp.md).

---

## Estructura de Carpetas

```
lib/
├── main.dart                      # Punto de entrada
├── app.dart                       # Widget principal de la app
│
├── config/                        # Configuración
│   ├── environment.dart           # Variables de entorno (dev/prod)
│   ├── providers.dart             # Providers de Riverpod
│   ├── router.dart                # Configuración de GoRouter
│   ├── setup.dart                 # Inicialización de la app
│   ├── theme.dart                 # Extensión de tema
│   └── firebase_options.dart      # Configuración de Firebase
│
├── constants/                     # Constantes
│   └── themes.dart                # Definiciones de temas (light/dark)
│
├── models/                        # Modelos de dominio
│   ├── app_config.dart            # Modelo de configuración de la app
│   ├── employee.dart              # Modelo de empleado
│   ├── shift_type.dart            # Modelo de tipo de turno
│   ├── shift.dart                 # Modelo de turno
│   └── time_registration.dart     # Modelo de registro horario
│
├── repositories/                  # Capa de repositorio
│   └── employee_repository.dart   # Repositorio de empleados con lógica de negocio
│
├── services/                      # Capa de servicios
│   ├── config_service.dart        # Interfaz de servicio de configuración
│   ├── employee_service.dart      # Interfaz de servicio de empleados
│   ├── shift_service.dart         # Interfaz de servicio de turnos
│   ├── time_registration_service.dart # Interfaz de servicio de registros horarios
│   ├── mock/                      # Implementaciones mock
│   │   ├── mock_config_service.dart
│   │   ├── mock_employee_service.dart
│   │   ├── mock_shift_service.dart
│   │   └── mock_time_registration_service.dart
│   └── firebase/                  # Implementaciones Firebase
│       ├── firebase_config_service.dart
│       ├── firebase_employee_service.dart
│       ├── firebase_shift_service.dart
│       └── firebase_time_registration_service.dart
│
├── viewmodels/                    # ViewModels (Gestión de Estado)
│   ├── employee_detail_viewmodel.dart
│   ├── employee_profile_viewmodel.dart
│   ├── employee_registrations_viewmodel.dart
│   ├── employee_viewmodel.dart
│   └── theme_viewmodel.dart
│
├── screens/                       # Pantallas
│   ├── data_privacy_screen.dart
│   ├── employee_profile_screen.dart
│   ├── employee_registrations_screen.dart
│   ├── error_screen.dart
│   ├── splash_screen.dart
│   ├── staff_screen.dart
│   └── time_registration_detail_screen.dart
│
├── widgets/                       # Widgets reutilizables
│   ├── custom_card.dart
│   ├── custom_text.dart
│   ├── data_info_button.dart
│   ├── employee_avatar.dart
│   ├── employee_card.dart
│   ├── employee_detail_appbar.dart
│   ├── pin_verification_dialog.dart
│   ├── staff_appbar.dart
│   ├── theme_toggle_button.dart
│   └── time_gauge.dart
│
└── utils/                         # Utilidades
    └── date_utils.dart            # Funciones de fecha/hora
```

---

## Guía de Desarrollo

### Configuración del Entorno

#### Prerrequisitos

- Flutter SDK 3.10+
- Dart SDK 3.10+
- Android Studio / VS Code
- Emulador Android o dispositivo físico
- (Opcional) Cuenta Firebase para modo producción

#### Instalación

```bash
# 1. Clonar repositorio
git clone <repository-url>
cd timely

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar en modo desarrollo (datos mock)
flutter run --dart-define=FLAVOR=dev

# 4. Ejecutar en modo producción (Firebase)
flutter run --dart-define=FLAVOR=prod
```

### Modos de Ejecución

#### Modo Desarrollo (Mock)

Usa datos mock de archivos JSON `assets/mock/`:

```bash
flutter run --dart-define=FLAVOR=dev
```

**Características:**
- No requiere Firebase
- Datos de prueba predefinidos
- Rápido para desarrollo local
- Retrasos de red simulados para testing realista

#### Modo Producción (Firebase)

Usa Firebase Firestore:

```bash
flutter run --dart-define=FLAVOR=prod
```

**Configuración Requerida:**
- Proyecto Firebase creado
- `google-services.json` (Android) en `android/app/`
- `GoogleService-Info.plist` (iOS) en `ios/Runner/`
- Reglas de seguridad de Firestore configuradas
- Índices apropiados para consultas

### Calidad de Código

#### Linting y Type Checking

```bash
# Ejecutar linting
flutter analyze

# Ejecutar type checking
dart analyze --fatal-infos
```

#### Testing

```bash
# Ejecutar tests unitarios
flutter test

# Ejecutar tests de integración
flutter test integration_test/

# Generar cobertura de tests
flutter test --coverage
```

---

## Contribuir

¡Bienvenimos las contribuciones a Timely! Por favor lee nuestra [Guía de Contribución](./CONTRIBUTING.esp.md) para información detallada sobre:

- Prácticas de desarrollo y estándares de código
- Convenciones de nombrado de branches
- Proceso de pull requests
- Guías de code review
- Requisitos de testing
- Estándares de documentación

### Inicio Rápido para Contribuidores

1. Fork del repositorio
2. Crear una rama de feature: `git checkout -b feature/nombre-de-tu-feature`
3. Realizar tus cambios siguiendo nuestros estándares de código
4. Añadir tests para nueva funcionalidad
5. Actualizar documentación según sea necesario
6. Enviar un pull request con descripción clara

---

## Documentación Adicional

- [**Arquitectura**](./ARCHITECTURE.esp.md) - Arquitectura técnica detallada
- [**Modelo de Datos**](./DATA_MODEL.esp.md) - Documentación completa del modelo de datos
- [**Flujo de Ejecución**](./EXECUTION_FLOW.esp.md) - Flujo detallado de la aplicación
- [**Gestión de Estado**](./STATE_MANAGEMENT.esp.md) - Detalles de implementación de Riverpod
- [**Contribuir**](./CONTRIBUTING.esp.md) - Guías de desarrollo y contribución

---

## Recursos

- [Documentación de Flutter](https://docs.flutter.dev)
- [Documentación de Riverpod](https://riverpod.dev)
- [Documentación de GoRouter](https://pub.dev/packages/go_router)
- [Firebase Flutter](https://firebase.flutter.dev)

---

## Licencia

Esta documentación es parte del proyecto Timely, licenciado bajo una Licencia de Código Abierto Personalizada con Restricciones Comerciales.

Para términos completos, ver el archivo [LICENSE](../../LICENSE).

---

**Última Actualización:** Enero 2026  
**Versión:** 1.0.0