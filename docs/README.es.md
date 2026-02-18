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
   -  [Modo API](#modo-api)

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
-  **Trazabilidad de Auditoría**: Registro completo de todas las acciones críticas para cumplimiento y trazabilidad
-  **Soporte de Temas Dual**: Tema claro, oscuro y basado en el sistema
-  **Diseño Responsive**: Diseños optimizados para dispositivos móviles y tablets
-  **Múltiples Modos de Ejecución**: Modo desarrollo Mock o REST API

---

## Pila Tecnológica

### Framework y Lenguaje

-  **Flutter**: ^3.10.0
-  **Dart**: SDK ^3.10.0

### Gestión de Estado

-  **flutter_riverpod**: ^3.0.3 - Gestión de estado reactiva
-  **go_router**: ^17.0.0 - Enrutado declarativo

### Backend y API

-  **dio**: ^5.4.0 - Cliente HTTP para REST API

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

### Ejecución de la Aplicación

**Modo Desarrollo (Por Defecto):**

```bash
flutter run
# o explícitamente
flutter run --dart-define=FLAVOR=dev
```

**Modo API:**

```bash
flutter run --dart-define=FLAVOR=api --dart-define=API_URL=https://api.example.com
```

**Build para Release:**

```bash
# Android
flutter build apk --dart-define=FLAVOR=api

# iOS
flutter build ios --dart-define=FLAVOR=api
```

---

## Modos de Ejecución

Timely soporta múltiples modos de ejecución para facilitar el desarrollo y el despliegue en producción.

### Modo Desarrollo (Datos Mock)

**Propósito**: Desarrollo local y pruebas sin backend externo.

**Características:**

-  Usa datos JSON mock desde `assets/mock/employees.json`
-  Persistencia de datos en memoria (se reinicia al reiniciar la app)
-  Retardo artificial de 2 segundos para simular latencia de red
-  Sin dependencias de backend
-  Iteración de desarrollo más rápida

**Cuándo usarlo:**

-  Desarrollo local y pruebas de UI
-  Desarrollo de funcionalidades sin dependencia del backend
-  Prototipado rápido
-  Desarrollo offline

**Fuente de Datos**: Servicios mock en [lib/services/mock/](../lib/services/mock/)

### Modo API

**Propósito**: Integración con backend REST API para producción o backends personalizados.

**Características:**

-  Usa cliente HTTP Dio para comunicación con API
-  URL de API configurable mediante variable de entorno
-  Soporte para autenticación basada en tokens
-  Infraestructura preparada para futura migración

**Cuándo usarlo:**

-  Despliegue independiente de proveedor de nube
-  Integración con backend personalizado
-  Despliegues empresariales que requieren backends API específicos

**Fuente de Datos**: Servicios API en [lib/services/api/](../lib/services/api/)

### Cambio Entre Modos

La aplicación selecciona la implementación según la variable de entorno `FLAVOR` (ver [lib/config/providers.dart](../lib/config/providers.dart)): `dev` → Mock, `api` → REST API.

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
   -  Modelos de auditoría para seguimiento de cumplimiento
   -  Implementación del patrón repositorio
   -  Implementaciones de servicios Mock y API
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
