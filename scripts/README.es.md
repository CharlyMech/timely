# Scripts de Firebase para Timely

Scripts para la configuración y población de datos en Firebase Firestore para la aplicación Timely.

## Tabla de Contenidos

- [Requisitos Previos](#requisitos-previos)
- [Configuración](#configuración)
- [Estructura de Datos](#estructura-de-datos)
- [Uso](#uso)
- [Reglas de Firestore](#reglas-de-firestore)
- [Índices de Firestore](#índices-de-firestore)
- [Datos de Prueba](#datos-de-prueba)
- [Estructura de Archivos](#estructura-de-archivos)
- [Solución de Problemas](#solución-de-problemas)

## Requisitos Previos

1. **Node.js** (v18 o superior)
2. **npm** (incluido con Node.js)
3. **Proyecto de Firebase** con Firestore habilitado
4. **Clave de Cuenta de Servicio de Firebase** (archivo JSON)
5. **Firebase CLI** (opcional, para desplegar reglas e índices)

## Configuración

### Paso 1: Instalar Dependencias

```bash
cd scripts
npm install
```

Esto instalará:
- `firebase-admin` - SDK de administración de Firebase para Node.js
- `dotenv` - Gestión de variables de entorno

### Paso 2: Obtener Credenciales de Firebase

#### Opción A: Clave de Cuenta de Servicio (Recomendada)

1. Ve a la [Consola de Firebase](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Navega a **Configuración del Proyecto** (icono de engranaje) > **Cuentas de Servicio**
4. Haz clic en **Generar Nueva Clave Privada**
5. Descarga el archivo JSON y guárdalo en la carpeta `scripts/` como `serviceAccountKey.json`

> **IMPORTANTE**: Nunca subas el archivo `serviceAccountKey.json` al control de versiones. Ya está incluido en `.gitignore`.

#### Opción B: Variables de Entorno Individuales

Alternativamente, puedes extraer los valores del JSON de la cuenta de servicio y establecerlos individualmente en el archivo `.env` (ver Paso 3).

### Paso 3: Configurar Variables de Entorno

1. Copia el archivo de ejemplo:

   ```bash
   cp .env.example .env
   ```

2. Edita `.env` con los valores de tu proyecto:

   **Opción A: Usando Archivo de Cuenta de Servicio**
   ```env
   FIREBASE_PROJECT_ID=tu-proyecto-id
   FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
   ```

   **Opción B: Usando Credenciales Individuales**
   ```env
   FIREBASE_PROJECT_ID=tu-proyecto-id
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@tu-proyecto-id.iam.gserviceaccount.com
   ```

### Paso 4: Instalar Firebase CLI (Opcional)

Firebase CLI es necesario para desplegar reglas e índices automáticamente. Si no está instalado, aún puedes desplegarlos manualmente a través de la Consola de Firebase.

```bash
npm install -g firebase-tools
firebase login
```

## Estructura de Datos

### Colecciones

Los scripts crean las siguientes colecciones en Firestore:

| Colección | Descripción |
| --- | --- |
| `settings` | Configuración de la aplicación (documento único: `app_config`) |
| `employees` | Empleados de la empresa |
| `shift_types` | Tipos de turnos disponibles (mañana, tarde, partido) |
| `shifts` | Turnos asignados a empleados |
| `time_registrations` | Registros horarios de los empleados |

### Relaciones entre Entidades

```
employees
    |
    +-- shifts (employeeId -> employee.id)
    |       |
    |       +-- shiftTypeId -> shift_types.id
    |
    +-- time_registrations (employeeId -> employee.id)
            |
            +-- shiftId -> shifts.id
```

### Modelos de Datos

#### AppConfig (settings/app_config)

```json
{
  "defaultTargetTimeMinutes": 480,
  "warningThresholdMinutes": 15,
  "redThresholdMinutes": 60,
  "workingDays": [1, 2, 3, 4, 5]
}
```

#### Employee

```json
{
  "id": "uuid",
  "firstName": "string",
  "lastName": "string",
  "avatarUrl": "string | null",
  "pin": "string (6 dígitos)",
  "status": "active | inactive | vacation | leave",
  "email": "string | null",
  "phone": "string (9 dígitos)",
  "address": "string | null"
}
```

#### ShiftType

```json
{
  "id": "uuid",
  "name": "string",
  "colorHex": "#RRGGBB",
  "startTime": "HH:mm",
  "endTime": "HH:mm",
  "pauseTime": "HH:mm | null",
  "resumeTime": "HH:mm | null",
  "targetTimeMinutes": "number"
}
```

#### Shift

```json
{
  "id": "uuid",
  "employeeId": "uuid (referencia a employee)",
  "date": "Timestamp",
  "shiftTypeId": "uuid (referencia a shift_type)",
  "notes": "string | null"
}
```

#### TimeRegistration

```json
{
  "id": "uuid",
  "employeeId": "uuid (referencia a employee)",
  "shiftId": "uuid (referencia a shift)",
  "startTime": "Timestamp",
  "endTime": "Timestamp | null",
  "pauseTime": "Timestamp | null",
  "resumeTime": "Timestamp | null",
  "date": "string (DD/MM/YYYY)"
}
```

## Uso

### Configuración Completa (Recomendado)

El script `setup.js` ejecuta todos los pasos necesarios para configurar Firebase:

```bash
node setup.js
```

O usando npm:

```bash
npm run setup
```

Este comando:
1. Verifica los requisitos previos (Node.js, npm, Firebase CLI)
2. Instala las dependencias de Node.js
3. Puebla Firestore con los datos de prueba
4. Despliega las reglas de seguridad de Firestore (si Firebase CLI está disponible)
5. Despliega los índices de Firestore (si Firebase CLI está disponible)

#### Opciones del Setup

```bash
node setup.js --clear        # Limpia datos existentes antes de poblar
node setup.js --skip-rules   # Omite el despliegue de reglas
node setup.js --skip-indexes # Omite el despliegue de índices
node setup.js --skip-seed    # Omite el poblado de datos
node setup.js --dry-run      # Muestra qué se haría sin ejecutar
node setup.js --help         # Muestra mensaje de ayuda
```

Usando scripts npm:

```bash
npm run setup             # Configuración completa
npm run setup:clear       # Configuración con limpieza de datos
npm run setup:dry-run     # Modo de prueba
```

### Poblar Solo Datos

Para poblar Firestore sin desplegar reglas o índices:

```bash
npm run seed
```

Este comando:
1. Lee los archivos JSON de la carpeta `data/`
2. Crea todas las colecciones y documentos en Firestore
3. Convierte automáticamente las cadenas de fecha ISO a Timestamps de Firestore

### Limpiar y Poblar

Para eliminar todos los datos existentes antes de poblar:

```bash
npm run seed:clear
```

> **ADVERTENCIA**: Esto eliminará todos los documentos en las colecciones antes de poblar nuevos datos.

### Modo de Prueba (Dry Run)

Para previsualizar lo que se haría sin realizar cambios reales:

```bash
npm run seed:dry-run
```

Esto es útil para:
- Probar los scripts antes de ejecutarlos
- Verificar qué datos se crearán
- Comprobar errores en los archivos JSON

## Reglas de Firestore

El archivo `firestore.rules` contiene las reglas de seguridad para Firestore:

- **settings**: Solo lectura para todos los usuarios
- **employees**: Solo lectura para todos los usuarios
- **shift_types**: Solo lectura para todos los usuarios
- **shifts**: Solo lectura para todos los usuarios
- **time_registrations**: Lectura y escritura para todos los usuarios

### Desplegar Reglas

**Automático (si Firebase CLI está instalado):**

El script `setup.js` desplegará automáticamente las reglas. También puedes desplegarlas manualmente:

```bash
# Desde el directorio raíz del proyecto
firebase deploy --only firestore:rules
```

**Manual (vía Consola de Firebase):**

1. Ve a Firestore Database > Rules en la Consola de Firebase
2. Copia el contenido de `firestore.rules`
3. Pégalo en el editor
4. Haz clic en **Publicar**

## Índices de Firestore

El archivo `firestore.indexes.json` contiene índices compuestos para consultas eficientes.

### Desplegar Índices

**Automático (si Firebase CLI está instalado):**

El script `setup.js` desplegará automáticamente los índices. También puedes desplegarlos manualmente:

```bash
# Desde el directorio raíz del proyecto
firebase deploy --only firestore:indexes
```

**Manual (vía Consola de Firebase):**

Firestore sugerirá automáticamente índices cuando ejecutes consultas que los requieran. También puedes:

1. Ve a Firestore Database > Indexes en la Consola de Firebase
2. Haz clic en **Agregar Índice**
3. Configura el índice según `firestore.indexes.json`

### Índices Incluidos

| Colección | Campos | Orden | Propósito |
| --- | --- | --- | --- |
| `shifts` | employeeId, date | ASC | Obtener turnos de empleado ordenados por fecha |
| `shifts` | employeeId, date | DESC | Obtener turnos recientes de empleado |
| `shifts` | date, shiftTypeId | ASC | Filtrar turnos por fecha y tipo |
| `time_registrations` | employeeId, startTime | DESC | Obtener registros de empleado |
| `time_registrations` | employeeId, date | ASC | Filtrar registros por empleado y fecha |
| `time_registrations` | shiftId, startTime | ASC | Obtener registros de un turno específico |

## Datos de Prueba

Los archivos JSON en `data/` contienen datos de prueba con:

- **4 empleados** con diferentes estados (activo, vacaciones, baja, inactivo)
- **3 tipos de turno**:
  - Mañana (08:00-16:00, sin pausa)
  - Tarde (15:00-23:00, sin pausa)
  - Partido (08:00-20:00, con pausa 14:00-17:00)
- **Turnos** para diciembre 2025, enero 2026 y primera quincena de febrero 2026
- **Registros horarios** completados desde diciembre 2025 hasta la fecha actual

### Archivos de Datos

- `app_config.json` - Configuración de la aplicación
- `employees.json` - Datos de empleados
- `shift_types.json` - Definiciones de tipos de turno
- `shifts.json` - Turnos asignados
- `time_registrations.json` - Registros horarios

### Personalizar Datos de Prueba

Puedes modificar el contenido dentro de los archivos JSON en la carpeta `data/` para adaptarlos a las necesidades de tu organización:

**Pautas Importantes:**
- **SÍ modifica** los valores dentro de cada archivo JSON (nombres, fechas, horas, etc.)
- **NO cambies** los nombres de archivo o la estructura
- **NO agregues ni elimines** archivos JSON de la carpeta `data/`
- **NO modifiques** los nombres de los campos o tipos de datos en los objetos JSON

**Lo que puedes personalizar:**
- Nombres de empleados, emails, teléfonos, PINs y estados
- Nombres de tipos de turno, colores y rangos horarios
- Asignaciones de turnos y fechas
- Registros de tiempo
- Valores de configuración de la aplicación (umbrales, días laborables)

**Ejemplo - Modificar un empleado:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "firstName": "Tu",             // ✅ Cambia esto
  "lastName": "Empleado",         // ✅ Cambia esto
  "email": "tu@email.com",        // ✅ Cambia esto
  "pin": "123456",                // ✅ Cambia esto
  "status": "active",             // ✅ Cambia esto
  "phone": "123456789",           // ✅ Cambia esto
  "address": "Tu Dirección",      // ✅ Cambia esto
  "avatarUrl": null               // ✅ Cambia esto o mantén null
}
```

**Lo que NO debes hacer:**
```json
{
  "employeeId": "...",     // ❌ No renombres campos
  "newField": "value",     // ❌ No agregues nuevos campos
  "firstName": 123         // ❌ No cambies tipos de datos (debe ser string)
}
```

Después de modificar los archivos de datos, ejecuta el script de seed para poblar tu Firebase:
```bash
npm run seed:clear  # Limpia datos antiguos y puebla con nuevos datos
```

## Estructura de Archivos

```
scripts/
├── data/
│   ├── app_config.json        # Configuración de la aplicación
│   ├── employees.json         # Datos de empleados
│   ├── shift_types.json       # Definiciones de tipos de turno
│   ├── shifts.json            # Turnos asignados
│   └── time_registrations.json # Registros horarios
├── .env                       # Variables de entorno (NO COMMITEAR)
├── .env.example               # Plantilla de variables de entorno
├── .gitignore                 # Archivo de ignorar de Git
├── firestore.indexes.json     # Índices de Firestore
├── firestore.rules            # Reglas de seguridad de Firestore
├── package.json               # Dependencias de Node.js
├── README.md                  # Documentación en inglés
├── README.es.md               # Esta documentación (Español)
├── seed.js                    # Script principal de seeding
├── setup.js                   # Script de configuración completa
└── serviceAccountKey.json     # Credenciales de Firebase (NO COMMITEAR)
```

## Solución de Problemas

### Error: Firebase credentials not found

**Causa**: El archivo de clave de cuenta de servicio falta o la ruta en `.env` es incorrecta.

**Solución**:
1. Verifica que `serviceAccountKey.json` exista en la carpeta `scripts/`
2. Comprueba que la ruta en `.env` sea correcta: `FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json`
3. O usa credenciales individuales (ver [Paso 3](#paso-3-configurar-variables-de-entorno))

### Error: Permission denied

**Causa**: La cuenta de servicio no tiene permisos suficientes.

**Solución**:
1. Verifica que la Cuenta de Servicio tenga el rol **Cloud Datastore User** o **Firebase Admin**
2. Comprueba que las reglas de Firestore permitan escrituras (puedes usar reglas abiertas temporalmente para pruebas)

### Las fechas no se muestran correctamente

**Causa**: El script convierte automáticamente las cadenas de fecha ISO a Timestamps de Firestore.

**Notas**:
1. Asegúrate de que las fechas en los archivos JSON estén en formato ISO 8601 (ej. `2025-01-15T10:30:00.000Z`)
2. Ten en cuenta las zonas horarias - las fechas se almacenan en UTC
3. El campo `date` en `TimeRegistration` se almacena como cadena en formato DD/MM/YYYY

### Error: Cannot find module

**Causa**: Las dependencias no están instaladas.

**Solución**:
```bash
cd scripts
npm install
```

### Los comandos de Firebase CLI no funcionan

**Causa**: Firebase CLI no está instalado o no has iniciado sesión.

**Solución**:
```bash
npm install -g firebase-tools
firebase login
```

Si Firebase CLI no está disponible, puedes desplegar reglas e índices manualmente a través de la Consola de Firebase.

### El dry run muestra lo que espero, pero no pasa nada

**Causa**: Estás en modo dry run (prueba).

**Solución**: Ejecuta sin la bandera `--dry-run`:
```bash
npm run seed  # En lugar de npm run seed:dry-run
```

---

Para más información sobre Firebase y Firestore, visita la [Documentación de Firebase](https://firebase.google.com/docs).
