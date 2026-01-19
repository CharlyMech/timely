# FORMATO DE DATOS - TABLAS EXCEL

## CONFIGURACIÓN DE LA APLICACIÓN

**Parámetros:**

-  `defaultTargetTimeMinutes`: Minutos de trabajo objetivo por día (número)
-  `warningThresholdMinutes`: Minutos para mostrar aviso (número)
-  `redThresholdMinutes`: Minutos para mostrar alerta crítica (número)
-  `workingDays`: Días laborables separados por coma (texto, ej: 1,2,3,4,5)

| defaultTargetTimeMinutes | warningThresholdMinutes | redThresholdMinutes | workingDays |
| --- | --- | --- | --- |
| 480 | 15 | 60 | 1,2,3,4,5 |

---

## ROLES

**Parámetros:**

-  `type`: Tipo de rol (texto: admin/manager/staff)
-  `displayName`: Nombre visible del rol (texto)

| type    | displayName   |
| ------- | ------------- |
| admin   | Administrador |
| manager | Manager       |
| staff   | Personal      |

---

## TIPOS DE TURNO

**Parámetros:**

-  `name`: Nombre del turno (texto)
-  `colorHex`: Color en formato hexadecimal (texto, ej: #FF5733)
-  `startTime`: Hora de inicio (texto, formato 24h HH:MM)
-  `endTime`: Hora de fin (texto, formato 24h HH:MM)
-  `pauseTime`: Hora de pausa (texto, formato HH:MM, vacío si no hay)
-  `resumeTime`: Hora de reanudación (texto, formato HH:MM, vacío si no hay)
-  `targetTimeMinutes`: Duración total del turno (número de minutos)

| name | colorHex | startTime | endTime | pauseTime | resumeTime | targetTimeMinutes |
| --- | --- | --- | --- | --- | --- | --- |
| Mañana | #81D4FA | 08:00 | 16:00 |  |  | 480 |
| Tarde | #FFCC80 | 15:00 | 23:00 |  |  | 480 |
| Partido | #B39DDB | 08:00 | 20:00 | 14:00 | 17:00 | 540 |

---

## EMPLEADOS

**Parámetros:**

-  `firstName`: Nombre del empleado (texto)
-  `lastName`: Apellidos del empleado (texto)
-  `personId`: DNI/NIE español (texto con formato específico)
-  `pin`: PIN de acceso (6 dígitos numéricos)
-  `phone`: Teléfono móvil (9 dígitos que empiezan con 6 o 7)
-  `email`: Correo electrónico (texto, opcional)
-  `address`: Dirección postal completa (texto, opcional)
-  `roleId`: Tipo de rol (texto: admin/manager/staff)
-  `workType`: Tipo de jornada (texto: complete/partial)
-  `status`: Estado actual (texto: active/inactive/vacation/leave)

| firstName | lastName | personId | pin | phone | email | address | roleId | workType | status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Carlos | Sanchez Recio | 12345678A | 123456 | 612345678 | carlos.sanchez@empresa.com | Calle Mayor 123, 28013 Madrid | admin | complete | active |
| Maria | Garcia Lopez | 23456789B | 234567 | 623456789 | maria.garcia@empresa.com | Avenida Constitución 45, 41001 Sevilla | staff | complete | active |
| Juan | Perez Martin | X1234567L | 345678 | 634567890 |  |  | staff | partial | active |
| Ana | Rodriguez Silva | 34567890C | 456789 | 645678901 | ana.rodriguez@empresa.com | Paseo Gracia 78, 08008 Barcelona | staff | complete | active |

---

## REGLAS DE VALIDACIÓN

### personId (DNI/NIE):

-  **DNI**: 8 números + 1 letra mayúscula (ej: 12345678A)
-  **NIE**: X/Y/Z + 7 números + 1 letra mayúscula (ej: X1234567L)

### phone:

-  9 dígitos que empiezan con 6 o 7 (ej: 612345678)

### pin:

-  Exactamente 6 dígitos numéricos (ej: 123456)

### roleId:

-  Valores válidos: `admin`, `manager`, `staff`

### workType:

-  Valores válidos: `complete` (jornada completa), `partial` (jornada parcial)

### status:

-  Valores válidos: `active` (activo), `inactive` (inactivo), `vacation` (vacaciones), `leave` (baja)

---

## EJEMPLOS POR TIPO DE NEGOCIO

### Restaurante:

| name | startTime | endTime | pauseTime | resumeTime | targetTimeMinutes |
| --- | --- | --- | --- | --- | --- |
| Mañana Restaurante | 07:00 | 15:00 |  |  | 480 |
| Tarde Restaurante | 15:00 | 23:00 |  |  | 480 |
| Noche Cierre | 22:00 | 06:00 | 02:00 | 02:30 | 480 |

### Oficina:

| name | startTime | endTime | pauseTime | resumeTime | targetTimeMinutes |
| --- | --- | --- | --- | --- | --- |
| Oficina Estándar | 08:00 | 17:00 | 13:00 | 14:00 | 480 |
| Oficina Flexible | 09:00 | 18:00 | 14:00 | 15:00 | 480 |

### Tienda:

| name | startTime | endTime | pauseTime | resumeTime | targetTimeMinutes |
| --- | --- | --- | --- | --- | --- |
| Mañana Tienda | 09:00 | 14:00 |  |  | 300 |
| Tarde Tienda | 20:00 |  |  |  | 360 |
| Completo Tienda | 09:00 | 20:00 | 13:00 | 14:00 | 540 |
