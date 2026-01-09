# Guía de Uso de Timely

## Visión General

Esta guía proporciona instrucciones completas para configurar, ejecutar y utilizar Timely - una aplicación móvil de registro horario para gestión de empleados.

## Tabla de Contenidos

1. [Prerrequisitos](#prerrequisitos)
2. [Instalación](#instalación)
3. [Ejecución de la Aplicación](#ejecución-de-la-aplicación)
4. [Modos de Desarrollo](#modos-de-desarrollo)
5. [Pantallas Principales](#pantallas-principales)
6. [Funcionalidades Principales](#funcionalidades-principales)
7. [Flujo de Trabajo Diario](#flujo-de-trabajo-diario)
8. [Seguridad](#seguridad)
9. [Solución de Problemas](#solución-de-problemas)

---

## Prerrequisitos

### Requisitos del Sistema

- **SO**: Android 8.0+ / iOS 12.0+
- **Almacenamiento**: Mínimo 2GB disponibles
- **Memoria RAM**: Mínimo 4GB recomendado

### Requisitos de Software

- **Flutter SDK**: 3.10+
- **Dart SDK**: 3.10+
- **Git**: Para clonar el repositorio (opcional)

### Requisitos de Hardware

- **Dispositivo Android**: Smartphone o tablet con procesador ARM64
- **Dispositivo iOS**: iPhone 6s o superior
- **Conexión a Internet**: Para modo producción con Firebase

---

## Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/your-username/timely.git
cd timely
```

### 2. Instalar Dependencias

```bash
# Instalar dependencias de Flutter
flutter pub get
```

### 3. Verificar Instalación

```bash
# Verificar que todo esté instalado correctamente
flutter doctor
```

---

## Ejecución de la Aplicación

### Modo Desarrollo

Para desarrollo y pruebas rápidas usando datos simulados:

```bash
flutter run --dart-define=FLAVOR=dev
```

**Características del modo desarrollo:**
- Usa datos mock de archivos JSON locales
- Sin necesidad de configurar Firebase
- Inicio rápido sin dependencias de red
- Simulación de latencia de red para pruebas realistas

### Modo Producción

Para uso en producción con datos reales:

```bash
flutter run --dart-define=FLAVOR=prod
```

**Requisitos para modo producción:**
- Configuración de Firebase completada
- Archivos de configuración en sus ubicaciones:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- Conexión activa a internet
- Reglas de seguridad de Firestore configuradas

---

## Modos de Desarrollo

### Cambio Entre Modos

Para cambiar entre modos sin reinstalar:

```bash
# Cambiar a modo desarrollo
flutter run --dart-define=FLAVOR=dev

# Cambiar a modo producción  
flutter run --dart-define=FLAVOR=prod
```

### Desarrollo en Dispositivos Físicos

#### Android

```bash
# Lista dispositivos conectados
flutter devices

# Ejecutar en dispositivo específico
flutter run -d <device-id> --dart-define=FLAVOR=dev
```

#### iOS

```bash
# Lista dispositivos iOS
flutter devices

# Ejecutar en dispositivo iOS específico
flutter run -d <device-id> --dart-define=FLAVOR=dev
```

### Desarrollo con Hot Reload

Para desarrollo rápido con recarga en caliente:

```bash
# Hot reload activado por defecto
flutter run --dart-define=FLAVOR=dev

# Hot reload con actualización en caliente
flutter run --dart-define=FLAVOR=dev --hot
```

---

## Pantallas Principales

### 1. Pantalla de Bienvenida (WelcomeScreen)

**Propósito:** Punto de entrada a la aplicación

**Cómo usar:**
1. La app inicia en esta pantalla después del splash
2. Presione el botón "Empezar"
3. Será redirigido automáticamente a la pantalla de personal

**Características:**
- Logo de la aplicación
- Botón de inicio principal
- Diseño limpio y profesional
- Transiciones suaves entre pantallas

### 2. Pantalla de Personal (StaffScreen)

**Propósito:** Panel principal con cuadrícula de empleados

**Características:**
- **Grid Responsivo**: Se adapta automáticamente al tamaño de pantalla:
  - 2 columnas en móviles
  - 3-4 columnas en tablets pequeñas
  - 5 columnas en tablets grandes
  - 5+ columnas en desktop
- **Búsqueda**: Encuentre empleados por nombre en tiempo real
- **Pull-to-Refresh**: Deslice hacia abajo para actualizar datos
- **Timer de Inactividad**: Refresca automáticamente después de 5 minutos sin interacción
- **Estado de Empleados**: Muestra estado actual de cada empleado (disponible, trabajando, pausado)

**Cómo usar:**
1. Deslize horizontalmente para ver más empleados
2. Toque en el campo de búsqueda para filtrar
3. Presione el botón de refresh (deslizar hacia abajo) para actualizar datos
4. Toque en la tarjeta de cualquier empleado para acceder a su gestión horaria

### 3. Pantalla de Detalle de Empleado (TimeRegistrationDetailScreen)

**Propósito:** Gestión individual de tiempo de trabajo

**Características:**
- **Información del Empleado**: Nombre, avatar, estado actual
- **Registro Horario**: 
  - Botón "Iniciar Jornada" (si no hay registro activo)
  - Cronómetro en tiempo real cuando está activo
  - Controles de pausa/reanudación
  - Botón "Finalizar Jornada" (si está activo)
- **Indicadores Visuales**: 
  - 🟢 Verde: Dentro del rango óptimo (6h 45m - 7h 15m)
  - 🟠 Naranja: Acercándose al límite de horas extra (7h 16m - 7h 59m)
  - 🔴 Roja: Límite de horas extra alcanzado (8h+)
- **Navegación**: Pestañas para perfil e historial

**Cómo usar:**
1. Inicie su jornada con "Iniciar Jornada"
2. El cronómetro comenzará a contar automáticamente
3. Use los botones de pausa/reanudar según necesite
4. Finalice con "Finalizar Jornada" cuando termine
5. Vea el tiempo total trabajado y estado de color

### 4. Pantalla de Perfil de Empleado (EmployeeProfileScreen)

**Propósito:** Información detallada y calendario de turnos

**Características:**
- **Información Personal**: Datos completos del empleado
- **Calendario de Turnos**: 
  - Vista mensual con colores por tipo de turno
  - Navegación entre meses
  - Turnos futuros y pasados
- **Estadísticas**: Resúmenes de tiempo de trabajo por mes
- **Tipos de Turno**: Códigos de color para identificación visual

### 5. Pantalla de Historial de Registros (EmployeeRegistrationsScreen)

**Propósito:** Historial completo de registros horarios

**Características:**
- **Lista Cronológica**: Todos los registros ordenados por fecha
- **Paginación**: Carga progresiva al desplazarse hacia abajo
- **Indicadores de Estado**: Colores basados en duración
- **Filtrado**: Buscar registros por período específico
- **Exportación**: Opción de compartir datos (según políticas)

---

## Funcionalidades Principales

### Sistema de Registro Horario

#### Iniciar Jornada
1. Navegue a Staff Screen
2. Seleccione su tarjeta de empleado
3. Ingrese su PIN de 6 dígitos si es requerido
4. Presione "Iniciar Jornada"
5. El registro comienza automáticamente con timestamp actual

#### Pausar Trabajo
1. Durante una jornada activa, presione "Pausar"
2. El tiempo se detiene pero no cuenta para el total
3. La pantalla mostrará estado "Pausado"
4. Presione "Reanudar" para continuar

#### Finalizar Jornada
1. Presione "Finalizar Jornada" cuando termine
2. El sistema registrará automáticamente la hora de fin
3. Calculará el tiempo total trabajado
4. Mostrará resumen del día

#### Indicadores de Tiempo

**Estado Verde** (6h 45m - 7h 15m):
- Dentro del rango óptimo de trabajo
- No se requiere acción adicional

**Estado Naranja** (7h 16m - 7h 59m):
- Acercándose al límite de horas extra
- Considere finalizar pronto para evitar overtime

**Estado Rojo** (8h+):
- Límite de horas extra alcanzado
- Requiere atención administrativa

### Autenticación por PIN

#### Sistema de Seguridad
- Cada empleado tiene un PIN único de 6 dígitos
- Requerido para acceder a registros históricos individuales
- Previente acceso no autorizado a datos de tiempo
- Máximo 3 intentos antes de bloqueo temporal

#### Verificación de Identidad

Para acceder a los registros de un empleado:
1. Toque la tarjeta del empleado en Staff Screen
2. Se le redirigirá a la pantalla de detalle
3. Si requiere autenticación, aparecerá un diálogo de PIN
4. Ingrese los 6 dígitos del PIN
5. El sistema verificará y permitirá acceso si es correcto

---

## Flujo de Trabajo Diario

### Ejemplo de Jornada Típica

**Empleado: María García - Desarrolladora**

1. **8:00 AM** - Llega a la oficina
2. Abre Timely → Staff Screen
3. Encuentra su tarjeta → Presiona
4. Ingresa PIN → Accede a su pantalla de detalle
5. Presiona "Iniciar Jornada" → El sistema registra: 08:00:00

6. **10:30 AM** - Pausa para reunión
7. Presiona "Pausar" → El timer se detiene: 2h 30m trabajados
8. Reanuda a las 10:45 AM → El timer continúa

9. **12:30 PM** - Reanuda de almuerzo
10. Presiona "Reanudar" → El timer continúa: 3h 30m trabajados

11. **1:00 PM** - Pausa para tasks administrativas
12. Presiona "Pausar" → El timer se detiene: 4h 30m trabajados

13. **1:30 PM** - Reanuda y termina tareas
14. Presiona "Reanudar" → El timer continúa: 6h total

15. **6:30 PM** - Finaliza jornada
16. Presiona "Finalizar Jornada"
17. Sistema registra fin: 6:30:00 PM
18. **Cálculo**: 10.5 horas trabajadas
19. **Estado**: Naranja (excedió límite estándar de 8h)

20. **Notificación**: El sistema muestra advertencia de overtime

---

## Seguridad

### Protección de Datos

- **Encriptación**: Todos los datos se transmiten de forma segura en producción
- **Autenticación**: Sistema de PIN para acceso individual
- **Privacidad**: Cumplimiento con reglas GDPR
- **Control de Acceso**: Solo usuarios autorizados pueden acceder a datos específicos

### Mejores Prácticas de Seguridad

1. **Para Empleados:**
   - No comparta su PIN con nadie
   - Cambie su PIN regularmente
   - Reporte si sospecha acceso no autorizado
   - Cierre sesión cuando termine de usar la app

2. **Para Administradores:**
   - Configure PINs seguros y únicos
   - Establezca políticas de contraseñas robustas
   - Revise regularmente el acceso de usuarios
   - Monitoree patrones de uso anómalos

---

## Solución de Problemas

### Problemas Comunes y Soluciones

#### Problema: "No puedo iniciar jornada"

**Causas Posibles:**
- Ya tiene una jornada activa
- Problemas de conexión a internet
- Error de autenticación
- Problemas con el servidor

**Soluciones:**
1. Verifique si ya tiene un registro activo (indicador verde/naranja/rojo)
2. Revise su conexión a internet
3. Intente reiniciar la aplicación
4. Contacte al administrador si el problema persiste

#### Problema: "Olvidé mi PIN"

**Soluciones:**
1. Contacte al administrador del sistema
2. El administrador puede resetear su PIN
3. Se le proporcionará un PIN temporal que debe cambiar en su primer inicio
4. Cambie el PIN temporal por uno permanente

#### Problema: "La app se cierra inesperadamente"

**Soluciones:**
1. Verifique el nivel de batería de su dispositivo
2. Asegúrese de tener suficiente espacio de almacenamiento
3. Cierre otras aplicaciones que consuman muchos recursos
4. Reinicie el dispositivo
5. Verifique si está usando la versión más reciente de la app

#### Problema: "Los datos no se sincronizan"

**Soluciones:**
1. Asegúrese de tener conexión a internet estable
2. Verifique que está en modo producción (no desarrollo)
3. Intente manualmente la sincronización con pull-to-refresh
4. Contacte soporte técnico si el problema continúa

---

## Licencia

Esta documentación es parte del proyecto Timely, licenciado bajo una Licencia de Código Abierto Personalizada con Restricciones Comerciales.

Para términos completos, ver el archivo [LICENSE](../../LICENSE).

---

**Última Actualización:** Enero 2026