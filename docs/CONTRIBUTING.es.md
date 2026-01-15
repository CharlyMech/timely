# Contribuyendo a Timely

¡Gracias por tu interés en contribuir a Timely! Este documento proporciona pautas e instrucciones para contribuir al proyecto.

## Tabla de Contenidos

-  [Antes de Comenzar](#antes-de-comenzar)
-  [Reconocimiento de Licencia](#reconocimiento-de-licencia)
-  [Comenzando](#comenzando)

   -  [Configuración de Desarrollo](#configuración-de-desarrollo)
   -  [Ejecutando la Aplicación](#ejecutando-la-aplicación)

-  [Flujo de Desarrollo](#flujo-de-desarrollo)

   -  [Convenciones de Nombres de Ramas](#convenciones-de-nombres-de-ramas)
   -  [Guías para Mensajes de Commit](#guías-para-mensajes-de-commit)

-  [Estándares de Código](#estándares-de-código)

   -  [Guía de Estilo Flutter](#guía-de-estilo-flutter)
   -  [Formateo de Código](#formateo-de-código)
   -  [Linting](#linting)

-  [Proceso de Pull Request](#proceso-de-pull-request)

   -  [Antes de Enviar](#antes-de-enviar)
   -  [Plantilla de PR](#plantilla-de-pr)
   -  [Proceso de Revisión](#proceso-de-revisión)

-  [Reporte de Issues](#reporte-de-issues)

   -  [Reportes de Errores](#reportes-de-errores)
   -  [Solicitudes de Funcionalidad](#solicitudes-de-funcionalidad)
   -  [Etiquetas de Issues](#etiquetas-de-issues)

-  [Guías de Testing](#guías-de-testing)
-  [Documentación](#documentación)

---

## Antes de Comenzar

### Notas Importantes

1. **Leer la Documentación**: Familiarízate con el proyecto leyendo:

   -  [README.es.md](./README.es.md) - Resumen del proyecto y configuración
   -  [DATA.es.md](./DATA.es.md) - Arquitectura de datos
   -  [APP_FLOW.es.md](./APP_FLOW.es.md) - Flujo de la aplicación y navegación
   -  [GLOBAL_STATE.es.md](./GLOBAL_STATE.es.md) - Gestión de estado

2. **Revisar Issues Existentes**: Antes de empezar, verifica si ya existe un issue para el cambio que deseas realizar.

3. **Discutir Cambios Mayores**: Para características importantes o cambios de arquitectura, abre un issue para discutir el enfoque antes de implementarlo.

---

## Reconocimiento de Licencia

**IMPORTANTE**: Timely está licenciado bajo la **PolyForm Noncommercial License 1.0.0**, que es una licencia **disponible con código fuente**, NO una licencia de código abierto.

### Qué Significa Esto para los Contribuidores

Al contribuir a Timely, reconoces y aceptas que:

1. **Tus contribuciones estarán licenciadas bajo los mismos términos** que el proyecto (PolyForm Noncommercial License 1.0.0)
2. **Concedes al mantenedor del proyecto** (Carlos Sánchez Recio) el derecho de incorporar tus contribuciones al proyecto
3. **No se otorgan derechos adicionales** a los contribuyentes más allá de los especificados en la licencia
4. **El uso comercial** del proyecto (incluyendo tus contribuciones) requiere una licencia comercial separada del propietario del proyecto
5. **Retienes los derechos de autor** sobre tus contribuciones originales, pero las licencias al proyecto bajo la PolyForm Noncommercial License

### Acuerdo de Contribución

Al enviar un pull request, aceptas que:

-  Tienes derecho a enviar la contribución
-  Tu contribución no viola derechos de terceros
-  Tu contribución puede ser usada, modificada y distribuida como parte de Timely bajo la PolyForm Noncommercial License
-  El mantenedor del proyecto puede incluir tu contribución en versiones comerciales bajo una licencia comercial

### Referencias de Licencia

-  **Licencia Principal**: [LICENSE](../LICENSE)
-  **Información sobre Licencia Comercial**: [COMMERCIAL_LICENSE.md](../COMMERCIAL_LICENSE.md)

Si tienes preguntas sobre la licencia o los términos de contribución, contacta al mantenedor antes de enviar contribuciones.

---

## Comenzando

### Configuración de Desarrollo

1. **Fork del Repositorio**:

```bash
# Hacer fork en GitHub y clonar tu fork
git clone https://github.com/YOUR_USERNAME/timely.git
cd timely
```

2. **Agregar Remote Upstream**:

```bash
git remote add upstream https://github.com/charlymech/timely.git
```

3. **Instalar Dependencias**:

```bash
# Dependencias de Flutter
flutter pub get

# (Opcional) Dependencias Node.js para scripts de Firebase
cd scripts
npm install
cd ..
```

4. **Verificar Configuración**:

```bash
flutter doctor
flutter analyze
```

### Ejecutando la Aplicación

**Modo Desarrollo** (datos simulados):

```bash
flutter run --dart-define=FLAVOR=dev
```

**Modo Producción** (Firebase):

```bash
# Asegúrate de configurar Firebase primero
flutter run --dart-define=FLAVOR=prod
```

**Ejecutar Tests**:

```bash
flutter test
```

**Ejecutar Linter**:

```bash
flutter analyze
```

---

## Flujo de Desarrollo

### Convenciones de Nombres de Ramas

Crea una rama nueva para cada característica o corrección usando el siguiente formato:

```
<tipo>/<descripcion-corta>
```

**Tipos de Ramas**:

| Tipo        | Descripción                | Ejemplo                          |
| ----------- | -------------------------- | -------------------------------- |
| `feat/`     | Nueva funcionalidad        | `feat/shift-calendar-view`       |
| `fix/`      | Corrección de bug          | `fix/time-calculation-error`     |
| `chore/`    | Tareas de mantenimiento    | `chore/update-dependencies`      |
| `docs/`     | Solo documentación         | `docs/update-contributing-guide` |
| `refactor/` | Refactorización de código  | `refactor/employee-viewmodel`    |
| `test/`     | Añadir tests               | `test/time-registration-service` |
| `style/`    | Estilo o formato de código | `style/fix-linting-errors`       |
| `perf/`     | Mejoras de rendimiento     | `perf/optimize-employee-list`    |

**Ejemplos**:

```bash
git checkout -b feat/export-registrations
git checkout -b fix/pin-verification-dialog
git checkout -b chore/upgrade-flutter-3.11
git checkout -b docs/add-api-documentation
```

### Pasos del Flujo de Trabajo

1. **Sincronizar con Upstream**:

```bash
git fetch upstream
git checkout main
git merge upstream/main
```

2. **Crear Rama Nueva**:

```bash
git checkout -b feat/tu-nueva-caracteristica
```

3. **Realizar Cambios**:

-  Escribir código siguiendo los [Estándares de Código](#estándares-de-código)
-  Probar los cambios exhaustivamente
-  Actualizar documentación si es necesario

4. **Hacer Commit**:

```bash
git add .
git commit -m "feat: add export to CSV functionality"
```

5. **Subir al Fork**:

```bash
git push origin feat/tu-nueva-caracteristica
```

6. **Crear Pull Request**:

-  Ve a GitHub y crea un PR desde tu fork hacia el repositorio principal
-  Completa la plantilla de PR
-  Espera la revisión

---

### Guías para Mensajes de Commit

Sigue la especificación **Conventional Commits**:

```
<tipo>(<ámbito>): <descripción corta>

<cuerpo opcional>

<footer opcional>
```

**Tipos**:

-  `feat`: Nueva funcionalidad
-  `fix`: Corrección de bug
-  `docs`: Cambios en documentación
-  `style`: Cambios de estilo de código (formato, punto y coma, etc.)
-  `refactor`: Refactorización de código
-  `test`: Añadir o actualizar tests
-  `chore`: Tareas de mantenimiento (dependencias, configuración, etc.)
-  `perf`: Mejoras de rendimiento

**Ejemplos**:

```bash
feat: add monthly registration report
feat(registrations): implement CSV export functionality
fix: correct time calculation when pause spans midnight
fix(gauge): prevent division by zero in progress calculation
docs: update installation instructions for Firebase setup
chore: upgrade Riverpod to version 3.0.4
test: add unit tests for TimeRegistration model
refactor(viewmodels): extract common loading logic
```

**Pautas**:

-  Usa tiempo presente ("add", no "added")
-  Usa modo imperativo ("move", no "moves")
-  Primera línea ≤ 50 caracteres
-  Separa subject del body con línea en blanco
-  Ajusta body a 72 caracteres por línea
-  Explica qué y por qué, no cómo

---

## Estándares de Código

### Guía de Estilo Flutter

Sigue la [guía oficial de Flutter](https://dart.dev/guides/language/effective-dart/style) y estas convenciones del proyecto:

1. **Organización de Archivos**:

```
lib/
├── models/          # Modelos de datos
├── services/        # Lógica de negocio
├── repositories/    # Orquestación de datos
├── viewmodels/      # Gestión de estado
├── screens/         # Pantallas de UI
├── widgets/         # Componentes reutilizables
├── layouts/         # Layouts responsive
├── utils/           # Funciones auxiliares
├── config/          # Configuración de la app
└── constants/       # Constantes
```

2. **Convenciones de Nombres**:

-  **Archivos**: `snake_case.dart` (ej. `employee_service.dart`)
-  **Clases**: `PascalCase` (ej. `EmployeeService`)
-  **Variables/Métodos**: `camelCase` (ej. `loadEmployees`)
-  **Constantes**: `camelCase` (ej. `primaryColor`)
-  **Miembros privados**: `_leadingUnderscore` (ej. `_loadData`)

3. **Organización de Imports**:

```dart
// Dart imports
import 'dart:async';
import 'dart:convert';

// Flutter imports
import 'package:flutter/material.dart';

// Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Project imports
import 'package:timely/models/employee.dart';
import 'package:timely/services/employee_service.dart';
```

4. **Estructura de Código**:

-  Longitud máxima de línea: 80 caracteres
-  Usar trailing commas para mejores diffs
-  Preferir `const` siempre que sea posible
-  Usar parámetros nombrados para claridad
-  Evitar anidamiento profundo (máx. 3–4 niveles)

---

### Formateo de Código

**Auto-formatear Antes de Commit**:

```bash
flutter format .
```

**Configuración Recomendada VS Code**:

```json
{
	"editor.formatOnSave": true,
	"dart.lineLength": 80,
	"[dart]": {
		"editor.rulers": [80],
		"editor.selectionHighlight": false,
		"editor.suggest.snippetsPreventQuickSuggestions": false,
		"editor.suggestSelection": "first",
		"editor.tabCompletion": "onlySnippets",
		"editor.wordBasedSuggestions": false
	}
}
```

### Linting

El proyecto utiliza `flutter_lints` para análisis estático.

**Ejecutar Linter**:

```bash
flutter analyze
```

**Corregir problemas automáticos**:

```bash
dart fix --apply
```

**Reglas de Lint Comunes**:

-  No imports sin usar
-  Preferir `const`
-  Evitar `print()` (usar logging adecuado)
-  Siempre usar llaves en control de flujo
-  Preferir comillas simples para strings
-  Evitar tipos dinámicos implícitos

---

## Proceso de Pull Request

### Antes de Enviar

Asegúrate de que tu PR cumpla con:

-  [ ] Código sigue los [Estándares de Código](#estándares-de-código)
-  [ ] Todos los tests pasan (`flutter test`)
-  [ ] Sin errores de lint (`flutter analyze`)
-  [ ] Código formateado (`flutter format .`)
-  [ ] Documentación actualizada (si aplica)
-  [ ] Mensajes de commit siguen [guías](#guías-para-mensajes-de-commit)
-  [ ] Rama actualizada con `main`

### Plantilla de PR

```markdown
## Descripción

Breve descripción de lo que hace este PR y por qué.

## Tipo de Cambio

-  [ ] Bug fix (cambio no disruptivo que corrige un problema)
-  [ ] Nueva funcionalidad (cambio no disruptivo que añade funcionalidad)
-  [ ] Cambio disruptivo (fix o feature que rompe funcionalidad existente)
-  [ ] Actualización de documentación

## Issues Relacionados

Cierra #[número de issue]

## Cambios Realizados

-  Cambio 1
-  Cambio 2
-  Cambio 3

## Testing

Describe cómo probaste los cambios:

-  Escenario de prueba 1
-  Escenario de prueba 2

## Capturas de Pantalla (si aplica)

Agrega capturas para cambios en UI.

## Checklist

-  [ ] Mi código sigue el estilo del proyecto
-  [ ] He realizado auto-revisión del código
-  [ ] He comentado el código en áreas difíciles de entender
-  [ ] He actualizado la documentación
-  [ ] Mis cambios no generan nuevas advertencias
-  [ ] He agregado tests que demuestran que mi fix/feature funciona
-  [ ] Todos los tests pasan localmente

## Notas Adicionales

Información adicional para los revisores.
```

### Proceso de Revisión

1. **Checks Automáticos**: GitHub Actions ejecutará tests y linting
2. **Revisión de Código**: El mantenedor revisará tu código
3. **Feedback**: Atender cambios solicitados
4. **Aprobación**: Una vez aprobado, el mantenedor hace merge

**Tiempo de Respuesta**:

-  Revisión inicial: ≤ 1 semana
-  Revisiones siguientes: 3–5 días

**Criterios de Revisión**:

-  Calidad y legibilidad del código
-  Cumplimiento de la arquitectura del proyecto
-  Cobertura de tests
-  Completitud de documentación
-  Impacto en performance

---

## Reporte de Issues

### Reportes de Errores

Usa la plantilla de bug report:

```markdown
**Descripción del Bug** Descripción clara y concisa del bug.

**Cómo Reproducir** Pasos para reproducir el comportamiento:

1. Ir a '...'
2. Clic en '...'
3. Desplazarse hasta '...'
4. Ver error

**Comportamiento Esperado** Qué esperabas que sucediera.

**Capturas** Si aplica, agrega capturas.

**Entorno**

-  Dispositivo: [ej., iPhone 12, Pixel 5]
-  OS: [ej., iOS 15.0, Android 12]
-  Versión App: [ej., 1.0.0]
-  Modo: [Dev/Prod]

**Contexto Adicional** Cualquier otro detalle relevante.

**Logs**
```

Pega aquí logs relevantes

```

```

### Solicitudes de Funcionalidad

Usa la plantilla de feature request:

```markdown
**Descripción de la Funcionalidad** Descripción clara de la funcionalidad que quieres.

**Problema que Resuelve** Explica el problema que esta funcionalidad resolvería.

**Solución Propuesta** Describe cómo imaginas que funcionaría.

**Alternativas Consideradas** Otras soluciones que has pensado.

**Contexto Adicional** Contexto adicional, mockups o ejemplos.
```

### Etiquetas de Issues

| Etiqueta           | Descripción                      |
| ------------------ | -------------------------------- |
| `bug`              | Algo no funciona                 |
| `enhancement`      | Nueva funcionalidad o request    |
| `documentation`    | Mejoras en documentación         |
| `good first issue` | Bueno para nuevos contribuidores |
| `help wanted`      | Se necesita atención extra       |
| `question`         | Se requiere más información      |
| `duplicate`        | Ya existe                        |
| `wontfix`          | No se trabajará                  |
| `priority: high`   | Alta prioridad                   |
| `priority: medium` | Prioridad media                  |
| `priority: low`    | Baja prioridad                   |

---

## Guías de Testing

### Unit Tests

Escribir tests unitarios para:

-  Modelos de datos (serialización, validación, propiedades calculadas)
-  Métodos de servicios (Firebase y Mock)
-  ViewModels (cambios de estado, lógica de negocio)
-  Funciones auxiliares

**Ejemplo**:

```dart
// test/models/time_registration_test.dart
void main() {
  group('TimeRegistration', () {
    test('calculates total minutes correctly', () {
      final registration = TimeRegistration(
        id: '1',
        employeeId: 'emp1',
        shiftId: 'shift1',
        startTime: DateTime(2025, 1, 1, 8, 0),
        endTime: DateTime(2025, 1, 1, 16, 0),
        date: '01/01/2025',
      );

      expect(registration.totalMinutes, 480);
    });

    test('subtracts pause time from total', () {
      final registration = TimeRegistration(
        id: '1',
        employeeId: 'emp1',
        shiftId: 'shift1',
        startTime: DateTime(2025, 1, 1, 8, 0),
        endTime: DateTime(2025, 1, 1, 17, 0),
        pauseTime: DateTime(2025, 1, 1, 12, 0),
        resumeTime: DateTime(2025, 1, 1, 13, 0),
        date: '01/01/2025',
      );

      expect(registration.totalMinutes, 480); // 9h - 1h pausa = 8h
    });
  });
}
```

### Widget Tests

Escribir tests de widgets para:

-  Widgets personalizados
-  Layouts de pantallas
-  Interacciones de usuario

**Ejemplo**:

```dart
// test/widgets/employee_card_test.dart
void main
```

() { testWidgets('EmployeeCard displays employee name', (tester) async { final employee = Employee( id: '1', firstName: 'John', lastName: 'Doe', pin: '123456', status: EmployeeStatus.active, );

```
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: EmployeeCard(
        employee: employee,
        onTap: () {},
      ),
    ),
  ),
);

expect(find.text('John Doe'), findsOneWidget);
```

}); }

````

### Integration Tests

Escribir tests de integración para:
- Flujos completos de usuario
- Navegación entre pantallas
- Sincronización de estado

**Ejecutar Tests**:
```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widgets/

# Integration tests
flutter test integration_test/
````

---

## Documentación

### Cuándo Actualizar Documentación

Actualiza documentación cuando:

-  Añadas o modifiques funcionalidades
-  Cambies arquitectura o patrones
-  Añadas nuevas dependencias
-  Cambies configuración o pasos de setup
-  Añadas o modifiques APIs

### Archivos de Documentación

| Archivo | Propósito |
| --- | --- |
| [README.es.md](./README.es.md) | Resumen del proyecto, setup, uso |
| [DATA.es.md](./DATA.es.md) | Modelos de datos, servicios, repositorios |
| [APP_FLOW.es.md](./APP_FLOW.es.md) | Navegación, pantallas, layouts, theming |
| [GLOBAL_STATE.es.md](./GLOBAL_STATE.es.md) | Gestión de estado, ViewModels |
| [CONTRIBUTING.es.md](./CONTRIBUTING.es.md) | Este archivo |
| [CONTACT.es.md](./CONTACT.es.md) | Información de autor y contacto |

### Comentarios en Código

**Usa comentarios para**:

-  Algoritmos complejos o lógica de negocio
-  Decisiones de diseño no obvias
-  Workarounds o soluciones temporales
-  APIs públicas e interfaces

**No comentar**:

-  Código autoexplicativo
-  Información redundante
-  Código comentado (bórralo)

**Ejemplo**:

```dart
// ✅ Bueno - explica el por qué
// Redondeamos al múltiplo de 5 minutos según política de la empresa
final roundedMinutes = (minutes / 5).round() * 5;

// ❌ Malo - obvio
// Incrementar contador en 1
counter = counter + 1;
```

---

## Obtener Ayuda

Si necesitas ayuda:

1. **Revisar Documentación**: Leer docs en la carpeta `/docs`
2. **Buscar Issues**: Verifica issues existentes en GitHub
3. **Hacer Preguntas**: Abrir un issue con etiqueta `question`
4. **Contactar al Mantenedor**: Ver [CONTACT.es.md](./CONTACT.es.md)

---

## Código de Conducta

### Comportamiento Esperado

-  Ser respetuoso y considerado
-  Dar la bienvenida a nuevos contribuyentes
-  Aceptar críticas constructivas
-  Priorizar lo mejor para el proyecto
-  Mostrar empatía hacia otros

### Comportamiento Inaceptable

-  Acoso o discriminación
-  Trolling, insultos o comentarios despectivos
-  Publicar información privada de otros
-  Conducta inapropiada en un entorno profesional

### Aplicación

Las violaciones pueden resultar en:

1. Advertencia
2. Prohibición temporal del proyecto
3. Prohibición permanente del proyecto

Reportar violaciones a: [sanchezreciocarlos99@outlook.com](mailto:sanchezreciocarlos99@outlook.com)

---

## Reconocimiento

Los contribuyentes serán reconocidos en:

-  Lista de contribuidores en GitHub
-  Notas de lanzamiento por contribuciones significativas
-  README del proyecto (para funciones importantes)

---

## ¡Gracias!

¡Gracias por contribuir a Timely! Tu esfuerzo hace que el proyecto sea mejor para todos.

Para preguntas sobre contribución, abre un issue o contacta al mantenedor vía [CONTACT.es.md](./CONTACT.es.md).

---

**Mantenedor del Proyecto**: Carlos Sánchez Recio (CharlyMech)

**Repositorio**: [https://github.com/charlymech/timely](https://github.com/charlymech/timely)

**Licencia**: PolyForm Noncommercial License 1.0.0 (ver [LICENSE](../LICENSE))
