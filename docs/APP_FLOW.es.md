# Flujo de la Aplicación y Navegación

Este documento describe el flujo completo de la aplicación, incluyendo enrutado, arquitectura de pantallas, layouts, configuración, theming y mecanismos de control de acceso.

## Tabla de Contenidos

-  [Visión General](#visión-general)
-  [Arquitectura de Navegación](#arquitectura-de-navegación)

   -  [Configuración del Router](#configuración-del-router)
   -  [Definición de Rutas](#definición-de-rutas)
   -  [Flujo de Navegación](#flujo-de-navegación)

-  [Pantallas](#pantallas)

   -  [SplashScreen](#splashscreen)
   -  [StaffScreen](#staffscreen)
   -  [TimeRegistrationDetailScreen](#timeregistrationdetailscreen)
   -  [EmployeeProfileScreen](#employeeprofilescreen)
   -  [EmployeeRegistrationsScreen](#employeeregistrationsscreen)
   -  [DataPrivacyScreen](#dataprivacyscreen)
   -  [ErrorScreen](#errorscreen)

-  [Layouts y Diseño Responsive](#layouts-y-diseño-responsive)

   -  [Breakpoints Responsive](#breakpoints-responsive)
   -  [Sistema de Layout](#sistema-de-layout)
   -  [Layouts Específicos por Pantalla](#layouts-específicos-por-pantalla)

-  [Configuración](#configuración)

   -  [Configuración de Entorno](#configuración-de-entorno)
   -  [Inicialización de la App](#inicialización-de-la-app)
   -  [Constantes](#constantes)

-  [Theming](#theming)

   -  [Arquitectura de Temas](#arquitectura-de-temas)
   -  [Tipos de Tema](#tipos-de-tema)
   -  [Paleta de Colores](#paleta-de-colores)
   -  [Tipografía](#tipografía)

-  [Control de Acceso](#control-de-acceso)

   -  [Verificación por PIN](#verificación-por-pin)
   -  [Tiempo de Inactividad](#tiempo-de-inactividad)

-  [Widgets y Componentes](#widgets-y-componentes)

---

## Visión General

Timely utiliza **enrutado declarativo** con GoRouter para la navegación y un **sistema de layouts responsive** que se adapta a dispositivos móviles y tablet. La aplicación sigue una jerarquía de navegación simple con propósitos de pantalla claros y transiciones predecibles.

### Características Clave

-  **Enrutado Declarativo**: Navegación basada en rutas con GoRouter
-  **Layouts Responsive**: Layouts separados para móvil y tablet por pantalla
-  **Gestión de Temas**: Temas Claro/Oscuro/Sistema con preferencias persistentes
-  **Control de Acceso**: Autenticación mediante PIN para pantallas sensibles
-  **Protección por Inactividad**: Cierre automático tras 5 minutos de inactividad

---

## Arquitectura de Navegación

### Configuración del Router

**Ubicación**: [lib/config/router.dart](../lib/config/router.dart)

El router se configura usando **GoRouter** con rutas basadas en paths y navegación tipada.

```dart
final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/staff', builder: (context, state) => const StaffScreen()),
    GoRoute(
      path: '/employee/:id',
      builder: (context, state) {
        final employeeId = state.pathParameters['id']!;
        return TimeRegistrationDetailScreen(employeeId: employeeId);
      },
    ),
    GoRoute(
      path: '/employee/:id/profile',
      builder: (context, state) {
        final employeeId = state.pathParameters['id']!;
        return EmployeeProfileScreen(employeeId: employeeId);
      },
    ),
    GoRoute(
      path: '/employee/:id/registrations',
      builder: (context, state) {
        final employeeId = state.pathParameters['id']!;
        final employeeName = state.extra as String?;
        return EmployeeRegistrationsScreen(
          employeeId: employeeId,
          employeeName: employeeName ?? 'Employee',
        );
      },
    ),
    GoRoute(
      path: '/data-privacy',
      builder: (context, state) => const DataPrivacyScreen(),
    ),
    GoRoute(
      path: '/error',
      builder: (context, state) {
        final errorMessage = state.extra as Map<String, dynamic>?;
        return ErrorScreen(
          errorMessage: errorMessage?['message'] as String? ?? 'Unknown error',
          stackTrace: errorMessage?['stackTrace'] as String?,
        );
      },
    ),
  ],
);
```

---

### Definición de Rutas

| Ruta | Path | Parámetros | Datos Extra | Propósito |
| --- | --- | --- | --- | --- |
| Splash | `/splash` | Ninguno | Ninguno | Pantalla inicial de carga |
| Staff | `/staff` | Ninguno | Ninguno | Lista principal de empleados |
| Time Detail | `/employee/:id` | `id`: ID del empleado | Ninguno | Control de jornada |
| Profile | `/employee/:id/profile` | `id`: ID del empleado | Ninguno | Perfil del empleado |
| Registrations | `/employee/:id/registrations` | `id`: ID del empleado | `employeeName`: String | Historial de registros |
| Data Privacy | `/data-privacy` | Ninguno | Ninguno | Política de privacidad |
| Error | `/error` | Ninguno | `{message, stackTrace}` | Visualización de errores |

---

### Métodos de Navegación

**Navegación Declarativa**:

```dart
context.go('/staff');
context.go('/employee/${employee.id}');
context.go('/employee/${employee.id}/profile');
context.go(
  '/employee/${employee.id}/registrations',
  extra: employee.fullName,
);
```

**Navegación Programática**:

```dart
context.push('/employee/${employee.id}');
context.pop();
context.replace('/error', extra: {'message': errorMessage});
```

---

### Flujo de Navegación

```
Inicio de la App
    ↓
SplashScreen (/splash)
    │
    ├─ Éxito → /staff
    └─ Error → /error
        ↓
    StaffScreen (/staff)
        │
        └─ Seleccionar Empleado → /employee/:id
            ↓
        TimeRegistrationDetailScreen
            │
            ├─ Tap en avatar (con PIN) → /employee/:id/profile
            │
            ├─ Enlace a registros → /employee/:id/registrations
            │
            ├─ Privacidad de datos → /data-privacy
            │
            └─ Volver → /staff
```

---

## Pantallas

## SplashScreen

**Ruta**: `/splash` **Propósito**: Pantalla inicial que inicializa datos y preferencias de tema.

### Características

-  Indicador de carga
-  Manejo de errores
-  Inicialización del tema
-  Temporizador de inactividad

---

## StaffScreen

**Ruta**: `/staff` **Propósito**: Pantalla principal con listado de empleados.

### Características

-  Lista de empleados
-  Búsqueda en tiempo real
-  Grid responsive
-  Pull to refresh
-  Temporizador de inactividad
-  Selector de tema

---

## TimeRegistrationDetailScreen

**Ruta**: `/employee/:id` **Propósito**: Interfaz de control de jornada laboral.

### Características

-  Indicador circular de tiempo
-  Botones de inicio/pausa/finalización
-  Estado de la jornada
-  Información del turno
-  Acceso al perfil mediante PIN

---

## EmployeeProfileScreen

**Ruta**: `/employee/:id/profile` **Propósito**: Visualización del perfil del empleado.

### Control de Acceso

-  Protegido por PIN de 6 dígitos

---

## EmployeeRegistrationsScreen

**Ruta**: `/employee/:id/registrations` **Propósito**: Historial de registros de jornada.

### Características

-  Listado histórico
-  Filtros por fecha y estado
-  Estadísticas de tiempo
-  Paginación

---

## DataPrivacyScreen

**Ruta**: `/data-privacy` **Propósito**: Mostrar política de privacidad y manejo de datos.

---

## ErrorScreen

**Ruta**: `/error` **Propósito**: Mostrar errores de forma amigable.

---

## Layouts y Diseño Responsive

### Breakpoints Responsive

```dart
static const double mobile = 600.0;
static const double tablet = 1024.0;
static const double desktop = 1024.0;
```

---

## Configuración

### Configuración de Entorno

```dart
flutter run --dart-define=FLAVOR=dev
flutter run --dart-define=FLAVOR=prod
```

---

## Theming

### Tipos de Tema

-  Claro
-  Oscuro
-  Sistema

### Persistencia

-  Almacenado en `SharedPreferences`
-  Clave: `'theme_preference'`

---

## Control de Acceso

### Verificación por PIN

-  PIN de 6 dígitos
-  Protege el acceso al perfil del empleado

### Tiempo de Inactividad

-  5 minutos
-  Retorno automático a `/splash`

---

## Widgets y Componentes

### Widgets Principales

-  `CustomCard`
-  `EmployeeCard`
-  `EmployeeAvatar`
-  `TimeGauge`
-  `StaffAppBar`
-  `EmployeeDetailAppBar`
-  `PinVerificationDialog`
-  `ThemeToggleButton`

---

## Resumen

La aplicación Timely proporciona:

-  Navegación clara y predecible
-  Diseño responsive optimizado
-  Theming flexible y persistente
-  Seguridad mediante PIN y tiempo de inactividad
-  Componentes reutilizables y modulares
-  Configuración diferenciada por entorno

Para conocer la integración con el estado global, consulta [GLOBAL_STATE.es.md](./GLOBAL_STATE.es.md). Para la arquitectura de datos, consulta [DATA.es.md](./DATA.es.md).
