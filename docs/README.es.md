# Timely - Documentación del Sistema de Registro de Tiempo

Bienvenido a la documentación de **Timely**. Esta es una guía completa para comprender, usar y contribuir a la aplicación de registro de tiempo Timely.

## Tabla de Contenidos

-  [Visión General](#visión-general)
-  [Pila Tecnológica](#pila-tecnológica)
-  [Primeros Pasos](#primeros-pasos)

   -  [Requisitos Previos](#requisitos-previos)
   -  [Instalación](#instalación)
   -  [Ejecución de la Aplicación](#ejecución-de-la-aplicación)

-  [Modos de Ejecución](#modos-de-ejecución)

   -  [Modo Desarrollo (Datos Mock)](#modo-desarrollo-datos-mock)
   -  [Modo Producción (Firebase)](#modo-producción-firebase)

-  [Configuración de Firebase](#configuración-de-firebase)

   -  [Carga de Datos Iniciales (Seeding)](#carga-de-datos-iniciales-seeding)
   -  [Despliegue de Reglas e Índices](#despliegue-de-reglas-e-índices)

-  [Uso de la Aplicación](#uso-de-la-aplicación)
-  [Índice de Documentación](#índice-de-documentación)
-  [Licencia](#licencia)

---

## Visión General

**Timely** es un sistema moderno de registro de tiempo y gestión de empleados diseñado para pequeñas y medianas empresas (PYME). La aplicación proporciona seguimiento en tiempo real de las horas de trabajo de los empleados, gestión de turnos y analítica completa del tiempo.

### Características Clave

-  **Seguimiento de Tiempo de Trabajo**: Iniciar, pausar, reanudar y finalizar jornadas laborales
-  **Gestión de Turnos**: Tipos de turnos predefinidos (Mañana, Tarde, Turnos partidos)
-  **Monitorización en Tiempo Real**: Indicador visual de tiempo que muestra el progreso frente a las horas objetivo
-  **Gestión de Empleados**: Gestión de perfiles con información de contacto y estado
-  **Historial de Tiempo**: Historial completo de registros con filtrado y analítica
-  **Soporte de Temas Dual**: Tema claro, oscuro y basado en el sistema
-  **Diseño Responsive**: Diseños optimizados para dispositivos móviles y tablets
-  **Modo de Ejecución Dual**: Modo producción con Firebase o modo desarrollo Mock

---

## Pila Tecnológica

### Framework y Lenguaje

-  **Flutter**: ^3.10.0
-  **Dart**: SDK ^3.10.0

### Gestión de Estado

-  **flutter_riverpod**: ^3.0.3 - Gestión de estado reactiva
-  **go_router**: ^17.0.0 - Enrutado declarativo

### Backend y Base de Datos

-  **firebase_core**: ^3.6.0 - SDK de Firebase
-  **cloud_firestore**: ^5.4.4 - Base de datos NoSQL en la nube

### UI y Diseño

-  **google_fonts**: ^6.2.1 - Tipografía personalizada (Space Grotesk, DM Sans)
-  **flutter_svg**: ^2.2.3 - Soporte de assets SVG
-  **table_calendar**: ^3.1.2 - Widget de calendario

### Utilidades

-  **uuid**: ^4.5.2 - Generación de identificadores únicos
-  **intl**: ^0.20.2 - Internacionalización y formato de fechas
-  **shared_preferences**: ^2.5.3 - Persistencia de datos local

---

## Primeros Pasos

### Requisitos Previos

**Para el Desarrollo de la Aplicación:**

-  Flutter SDK ^3.10.0 o superior
-  Dart SDK ^3.10.0 o superior
-  Un IDE (VS Code, Android Studio o IntelliJ IDEA)
-  Simulador de iOS (solo macOS) o Emulador de Android

**Para la Configuración de Firebase (Modo Producción):**

-  Node.js 18+ y npm
-  Firebase CLI (`npm install -g firebase-tools`)
-  Un proyecto de Firebase con Firestore habilitado

### Instalación

1. Clona el repositorio:

   ```bash
   git clone https://github.com/charlymech/timely.git
   cd timely
   ```

2. Instala las dependencias de Flutter:

   ```bash
   flutter pub get
   ```

3. (Opcional) Para el modo producción con Firebase, instala las dependencias de Node.js:

   ```bash
   cd scripts
   npm install
   ```

### Ejecución de la Aplicación

**Modo Desarrollo (Por Defecto):**

```bash
flutter run
# o explícitamente
flutter run --dart-define=FLAVOR=dev
```

**Modo Producción (Firebase):**

```bash
flutter run --dart-define=FLAVOR=prod
```

**Build para Release:**

```bash
# Android
flutter build apk --dart-define=FLAVOR=prod

# iOS
flutter build ios --dart-define=FLAVOR=prod
```

---

## Modos de Ejecución

Timely soporta dos modos de ejecución para facilitar el desarrollo y el despliegue en producción.

### Modo Desarrollo (Datos Mock)

**Propósito**: Desarrollo local y pruebas sin dependencia de Firebase.

**Características:**

-  Usa datos JSON mock desde `assets/mock/employees.json`
-  Persistencia de datos en memoria (se reinicia al reiniciar la app)
-  Retardo artificial de 2 segundos para simular latencia de red
-  No requiere inicialización de Firebase
-  Iteración de desarrollo más rápida

**Cuándo usarlo:**

-  Desarrollo local y pruebas de UI
-  Desarrollo de funcionalidades sin dependencia del backend
-  Prototipado rápido
-  Desarrollo offline

**Fuente de Datos**: Servicios mock en [lib/services/mock/](../lib/services/mock/)

### Modo Producción (Firebase)

**Propósito**: Despliegue en producción con base de datos en la nube en tiempo real.

**Características:**

-  Firebase Firestore como backend de base de datos
-  Sincronización de datos en tiempo real
-  Almacenamiento persistente
-  Soporte multiusuario
-  Autenticación y reglas basadas en la nube

**Cuándo usarlo:**

-  Despliegue en producción
-  Pruebas con backend real de Firebase
-  Pruebas en múltiples dispositivos
-  Pruebas de integración

**Fuente de Datos**: Servicios de Firebase en [lib/services/firebase/](../lib/services/firebase/)

### Cambio Entre Modos

La aplicación selecciona automáticamente la implementación de servicio adecuada en función de la variable de entorno `FLAVOR`:

```dart
// En lib/config/providers.dart
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return Environment.isDev
      ? MockEmployeeService()
      : FirebaseEmployeeService();
});
```

---

## Configuración de Firebase

### Requisitos Previos

1. Crea un proyecto de Firebase en [Firebase Console](https://console.firebase.google.com/)
2. Habilita Firestore Database en tu proyecto
3. Descarga el archivo de configuración de Firebase:

   -  Para Android: `google-services.json` → `android/app/`
   -  Para iOS: `GoogleService-Info.plist` → `ios/Runner/`

4. Ejecuta `flutterfire configure` para generar `lib/config/firebase_options.dart`

### Carga de Datos Iniciales (Seeding)

Timely incluye scripts en Node.js para poblar tu base de datos Firestore con datos de prueba.

**Inicio Rápido:**

```bash
cd scripts
npm run setup
```

Esto hará:

1. Comprobar los requisitos previos (Node 18+, Firebase CLI)
2. Instalar dependencias npm
3. Cargar datos en Firestore
4. Desplegar reglas de Firestore
5. Desplegar índices de Firestore

**Scripts Disponibles:**

| Comando | Descripción |
| --- | --- |
| `npm run setup` | Configuración completa: carga de datos + despliegue de reglas + despliegue de índices |
| `npm run setup:clear` | Limpia los datos existentes antes de la carga |
| `npm run setup:dry-run` | Previsualiza los cambios sin escribir en Firestore |
| `npm run seed` | Solo carga de datos |
| `npm run seed:clear` | Limpia y carga datos |
| `npm run seed:dry-run` | Previsualiza los datos de carga |

**Qué se Carga:**

-  **Configuración de la App**: Ajustes de jornada laboral, umbrales, días laborables
-  **Tipos de Turno**: Mañana, Tarde y turnos partidos con rangos horarios
-  **Empleados**: 4 empleados de prueba con información de perfil
-  **Turnos**: Turnos pre-generados desde diciembre de 2025 hasta febrero de 2026
-  **Registros de Tiempo**: Registros de trabajo de ejemplo ya completados

Para información detallada sobre la carga de datos, consulta el [README de scripts](../scripts/README.md).

### Despliegue de Reglas e Índices

**Reglas de Seguridad de Firestore:**

```bash
cd scripts
npm run deploy:rules
```

**Índices de Firestore:**

```bash
cd scripts
npm run deploy:indexes
```

**Resumen de Reglas de Seguridad:**

-  Configuración, empleados, tipos de turno y turnos: Solo lectura
-  Registros de tiempo: Acceso completo de lectura/escritura

Para más detalles, consulta [firestore.rules](../firestore.rules) y [firestore.indexes.json](../firestore.indexes.json).

---

## Uso de la Aplicación

### Primer Inicio

1. **Pantalla Splash**: La app inicializa los datos y las preferencias de tema
2. **Pantalla de Personal**: Pantalla principal que muestra la lista de empleados con búsqueda
3. **Selección de Empleado**: Toca un empleado para abrir el detalle de su registro de tiempo

### Flujo de Registro de Tiempo

1. **Comenzar Jornada**: Toca "Comenzar jornada" para iniciar el seguimiento
2. **Pausar**: Toca "Pausar jornada" para pausar el trabajo (comida, descanso, etc.)
3. **Reanudar**: Toca "Reanudar jornada" para continuar tras la pausa
4. **Finalizar Jornada**: Toca "Finalizar jornada" para completar el día laboral

### Navegación

-  **Pantalla de Personal** (`/staff`): Lista principal de empleados
-  **Detalle de Registro de Tiempo** (`/employee/:id`): Seguimiento y medidor de tiempo
-  **Perfil del Empleado** (`/employee/:id/profile`): Información del empleado (requiere PIN)
-  **Historial de Registros de Tiempo** (`/employee/:id/registrations`): Registros anteriores

### Autenticación

-  Los perfiles de empleado están protegidos por un PIN de 6 dígitos
-  Toca el avatar del empleado para acceder al perfil (PIN requerido)
-  Los PINs están definidos en el modelo de datos del empleado

### Cambio de Tema

-  Toca el botón de cambio de tema en la barra superior
-  Opciones: Claro, Oscuro, Sistema (sigue la configuración del dispositivo)
-  La preferencia se guarda localmente mediante SharedPreferences

---

## Índice de Documentación

Esta documentación está organizada en secciones especializadas para diferentes aspectos de la aplicación:

### Documentación de la Aplicación

-  **[DATA.es.md](./DATA.es.md)** - Modelos de datos, repositorios, servicios y relaciones entre entidades

   -  Esquemas de entidades y validación
   -  Implementación del patrón repositorio
   -  Implementaciones de servicios Firebase y Mock
   -  Flujo de datos y relaciones

-  **[APP_FLOW.es.md](./APP_FLOW.es.md)** - Flujo de la aplicación, rutas, pantallas y layouts

   -  Estructura de navegación y rutas
   -  Descripción y propósito de las pantallas
   -  Sistema de layout responsive
   -  Configuración y tematización
   -  Control de acceso y verificación

-  **[GLOBAL_STATE.es.md](./GLOBAL_STATE.es.md)** - Gestión de estado con Riverpod

   -  Arquitectura de providers con Riverpod
   -  Implementaciones de ViewModel
   -  Patrones de sincronización de estado
   -  Estrategias de carga y caché de datos
   -  Ciclo de vida completo de la gestión de estado

### Documentación Técnica

-  **[CONTRIBUTING.es.md](./CONTRIBUTING.es.md)** - Guía de contribución

   -  Flujo de trabajo de desarrollo
   -  Convenciones de nombres de ramas
   -  Guía para pull requests
   -  Reporte de issues
   -  Estilo de código y estándares

-  **[CONTACT.es.md](./CONTACT.es.md)** - Autor del proyecto e información de contacto

   -  Sobre el autor
   -  Enlaces a redes sociales
   -  Perfil de GitHub
   -  Sitio web del portfolio

---

## Licencia

Este proyecto está licenciado bajo la **PolyForm Noncommercial License 1.0.0**.

### Resumen de Licencia

-  **Uso no comercial**: Permitido bajo los términos del archivo [LICENSE](../LICENSE)
-  **Uso comercial**: Requiere una licencia comercial de pago independiente
-  **Contribuciones**: Al contribuir, aceptas que tu trabajo pueda ser licenciado bajo los mismos términos
-  **Sin garantía**: El software se proporciona "tal cual", sin garantía de ningún tipo

### Licenciamiento Comercial

Para uso comercial, debes obtener una licencia comercial independiente. Consulta [COMMERCIAL_LICENSE.md](../COMMERCIAL_LICENSE.md) para más detalles.

Para solicitar una licencia comercial, contacta con:

-  **Email**: [sanchezreciocarlos99@outlook.com](mailto:sanchezreciocarlos99@outlook.com)
-  **Asunto**: [Timely Commercial License Request]
-  **GitHub Issues**: [https://github.com/charlymech/timely/issues](https://github.com/charlymech/timely/issues)

**Importante**: Este proyecto es **software con código disponible**, no software de código abierto. El uso comercial sin licencia está prohibido.

Para más información sobre cómo contribuir a este proyecto respetando la licencia, consulta [CONTRIBUTING.es.md](./CONTRIBUTING.es.md).

---

## Soporte y Preguntas

-  **Documentación**: Comienza con este README y explora la documentación enlazada
-  **Issues**: Reporta errores o solicita funcionalidades mediante [GitHub Issues](https://github.com/charlymech/timely/issues)
-  **Contacto**: Para consultas de licenciamiento o uso comercial, consulta [CONTACT.es.md](./CONTACT.es.md)

---

**¡Feliz registro de tiempo!** 🕒
