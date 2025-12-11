# Contribuir a Timely

[View English version](./CONTRIBUTING.md)

Gracias por tu interés en contribuir a Timely! Este documento proporciona guías para contribuir al proyecto a través de issues y pull requests.

## Tabla de Contenidos

- [Código de Conducta](#código-de-conducta)
- [Primeros Pasos](#primeros-pasos)
- [Cómo Contribuir](#cómo-contribuir)
  - [Reportar Bugs](#reportar-bugs)
  - [Sugerir Funcionalidades](#sugerir-funcionalidades)
  - [Enviar Pull Requests](#enviar-pull-requests)
- [Guías de Desarrollo](#guías-de-desarrollo)
- [Estándares de Código](#estándares-de-código)
- [Mensajes de Commit](#mensajes-de-commit)
- [Licencia](#licencia)

---

## Código de Conducta

Al participar en este proyecto, aceptas mantener un entorno respetuoso y colaborativo. Por favor:

- Sé respetuoso y constructivo en las discusiones.
- Enfócate en los aspectos técnicos de las contribuciones.
- Acepta la crítica constructiva con gracia.
- Ayuda a otros a aprender y crecer.

---

## Primeros Pasos

Antes de contribuir, asegúrate de:

1. **Leer la documentación**
   - [README.esp.md](../../README.esp.md) - Visión general del proyecto.
   - [ARCHITECTURE.esp.md](./ARCHITECTURE.esp.md) - Arquitectura del sistema.
   - [USAGE.md](./USAGE.md) - Cómo usar el proyecto.

2. **Configurar tu entorno de desarrollo**
   ```bash
   git clone https://github.com/your-username/timely.git
   cd timely
   flutter pub get
   flutter run --dart-define=FLAVOR=dev
   ```

3. **Entender la estructura del proyecto**
   - Revisar la organización del código.
   - Familiarizarte con la arquitectura.
   - Entender la gestión de estado con Riverpod 3.0.

---

## Cómo Contribuir

### Reportar Bugs

¿Encontraste un bug? Ayúdanos a solucionarlo creando un issue detallado.

#### Antes de Enviar un Reporte de Bug

- Verifica si el bug ya ha sido reportado.
- Confirma que el bug existe en la última versión.
- Intenta reproducir el bug de manera consistente.

#### Plantilla de Reporte de Bug

```markdown
**Descripción**
Una descripción clara del bug.

**Pasos para Reproducir**
1. Ir a '...'
2. Hacer clic en '...'
3. Desplazarse hacia '...'
4. Ver error

**Comportamiento Esperado**
Lo que esperabas que sucediera.

**Comportamiento Actual**
Lo que realmente sucedió.

**Capturas de Pantalla**
Si aplica, añade capturas de pantalla.

**Entorno**
- Dispositivo: [ej., Pixel 6]
- OS: [ej., Android 13]
- Versión de Flutter: [ej., 3.10.0]
- Versión de la app: [ej., 1.0.0]
- Modo: [dev/prod]

**Contexto Adicional**
Cualquier otra información relevante.

**Logs**
```
Pegar logs relevantes aquí
```
```

### Sugerir Funcionalidades

¿Tienes una idea para mejorar Timely? Nos encantaría escucharla!

#### Plantilla de Solicitud de Funcionalidad

```markdown
**Descripción de la Funcionalidad**
Una descripción clara de la funcionalidad.

**Problema que Resuelve**
Explica el problema que esta funcionalidad resolvería.

**Solución Propuesta**
Describe cómo imaginas que funcionaría esta funcionalidad.

**Alternativas Consideradas**
Otras soluciones que has considerado.

**Contexto Adicional**
Mockups, ejemplos o referencias.

**Complejidad de Implementación**
Tu estimación: Baja / Media / Alta / Desconocida
```

### Enviar Pull Requests

¿Listo para contribuir con código? Sigue estos pasos:

#### 1. Fork y Clone

```bash
# Hacer fork del repositorio en GitHub
# Clonar tu fork
git clone https://github.com/TU-USUARIO/timely.git
cd timely

# Añadir upstream remote
git remote add upstream https://github.com/original-owner/timely.git
```

#### 2. Crear una Rama

```bash
# Actualizar rama main
git checkout main
git pull upstream main

# Crear rama de feature
git checkout -b feature/tu-funcionalidad

# O para correcciones de bugs
git checkout -b fix/descripcion-bug
```

#### 3. Hacer tus Cambios

- Seguir los [estándares de código](#estándares-de-código).
- Escribir tests para nueva funcionalidad.
- Actualizar documentación si es necesario.
- Asegurar que todos los tests pasen.

```bash
# Ejecutar tests
flutter test

# Ejecutar análisis de código
flutter analyze

# Formatear código
flutter format .
```

#### 4. Hacer Commit de tus Cambios

Sigue nuestras [guías de mensajes de commit](#mensajes-de-commit):

```bash
git add .
git commit -m "feat: añadir toggle de modo oscuro a configuración"
```

#### 5. Push y Crear Pull Request

```bash
# Push a tu fork
git push origin feature/tu-funcionalidad
```

Luego crea un pull request en GitHub con:

- **Título claro** siguiendo el formato de conventional commits.
- **Descripción detallada** de los cambios.
- **Referencia a issues relacionados** (ej., "Closes #123").
- **Capturas/videos** si aplica.
- **Instrucciones de testing** para revisores.

#### Plantilla de Pull Request

```markdown
**Descripción**
Breve descripción de los cambios.

**Issues Relacionados**
Closes #123
Related to #456

**Tipo de Cambio**
- [ ] Corrección de bug
- [ ] Nueva funcionalidad
- [ ] Breaking change
- [ ] Actualización de documentación

**Testing**
- [ ] Todos los tests existentes pasan
- [ ] Se añadieron nuevos tests para los cambios
- [ ] Se probó manualmente en dispositivo/emulador

**Capturas/Videos**
Si aplica.

**Checklist**
- [ ] El código sigue las guías de estilo del proyecto
- [ ] He revisado mi propio código
- [ ] He comentado la lógica compleja
- [ ] He actualizado la documentación
- [ ] No hay nuevas advertencias
```

---

## Guías de Desarrollo

### Arquitectura

Timely sigue los principios de Clean Architecture:

```
Presentación (UI) → ViewModels → Repositorios → Servicios
```

Al añadir funcionalidades:

1. **Crear modelos** en `lib/models/`.
2. **Definir interfaz de servicio** en `lib/services/`.
3. **Implementar servicio mock** en `lib/services/mock/`.
4. **Implementar servicio Firebase** (opcional) en `lib/services/firebase/`.
5. **Crear repositorio** en `lib/repositories/`.
6. **Crear ViewModel** en `lib/viewmodels/`.
7. **Crear UI** en `lib/screens/` y `lib/widgets/`.
8. **Añadir rutas** en `lib/config/router.dart`.
9. **Escribir tests** en `test/`.

### Gestión de Estado

- Usar **Riverpod 3.0** con API de `Notifier`.
- Mantener el estado inmutable.
- Usar `copyWith` para actualizaciones de estado.
- Evitar modificar providers en `initState` (usar `Future.microtask`).

### Testing

- Escribir unit tests para ViewModels y Repositories.
- Escribir widget tests para componentes UI complejos.
- Apuntar a alta cobertura de código.
- Probar casos límite y escenarios de error.

---

## Estándares de Código

### Estilo Dart/Flutter

Seguir la [guía oficial de estilo de Dart](https://dart.dev/guides/language/effective-dart/style):

- Usar `lowerCamelCase` para variables y funciones.
- Usar `UpperCamelCase` para clases.
- Usar `lowercase_with_underscores` para nombres de archivos.
- Prefijo `_` para miembros privados.

### Organización de Código

```dart
// 1. Imports (ordenados)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee.dart';
import '../repositories/employee_repository.dart';

// 2. Definiciones de Provider
final employeeProvider = ...;

// 3. Definición de Clase
class EmployeeViewModel extends Notifier<EmployeeState> {
  // 3.1. Miembros estáticos
  static const maxRetries = 3;

  // 3.2. Variables de instancia
  late EmployeeRepository _repository;

  // 3.3. Constructor
  EmployeeViewModel();

  // 3.4. Overrides
  @override
  EmployeeState build() => const EmployeeState();

  // 3.5. Métodos públicos
  Future<void> loadEmployees() async { }

  // 3.6. Métodos privados
  void _handleError(Object error) { }
}
```

### Documentación

- Documentar APIs públicas con comentarios dartdoc.
- Añadir comentarios inline solo para lógica compleja.
- Mantener los comentarios actualizados con el código.

```dart
/// Carga empleados con su registro del día.
///
/// Retorna una lista de empleados ordenados por nombre.
/// Lanza [EmployeeException] si la carga falla.
Future<List<Employee>> loadEmployees() async {
  // La lógica compleja merece un comentario
  final registrations = await _getActiveRegistrations();
  return _combineEmployeesAndRegistrations(registrations);
}
```

---

## Mensajes de Commit

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

### Formato

```
<tipo>(<scope>): <asunto>

<cuerpo>

<pie>
```

### Tipos

- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `style`: Cambios de estilo de código (formateo, punto y coma, etc.)
- `refactor`: Refactorización de código
- `test`: Añadir o actualizar tests
- `chore`: Tareas de mantenimiento
- `perf`: Mejoras de rendimiento

### Ejemplos

```bash
feat(auth): añadir autenticación biométrica

fix(timer): corregir cálculo de horas trabajadas

docs(readme): actualizar instrucciones de instalación

refactor(viewmodel): simplificar lógica de carga de empleados

test(repository): añadir tests para casos límite

chore(deps): actualizar dependencias a últimas versiones
```

### Mejores Prácticas

- Usar modo imperativo ("añadir" no "añadido").
- Mantener línea de asunto bajo 50 caracteres.
- Capitalizar línea de asunto.
- No terminar asunto con punto.
- Separar asunto del cuerpo con línea en blanco.
- Envolver cuerpo a 72 caracteres.
- Explicar qué y por qué, no cómo.

---

## Licencia

Al contribuir a Timely, aceptas que tus contribuciones estarán licenciadas bajo la Licencia Open Source Personalizada con Restricciones Comerciales del proyecto.

### Puntos Clave

- Retienes el copyright de tus contribuciones.
- Otorgas al propietario del proyecto (Carlos) derechos para usar tus contribuciones.
- Otorgas al propietario del proyecto derechos de distribución comercial.
- Tus contribuciones estarán disponibles para otros bajo los mismos términos de licencia.

Ver el archivo [LICENSE](../../LICENSE) para detalles completos.

---

## ¿Preguntas?

Si tienes preguntas sobre cómo contribuir:

- Abre una [GitHub Discussion](https://github.com/your-username/timely/discussions).
- Email: sanchezreciocarlos99@outlook.com.
- Consulta la documentación existente en `assets/docs/`.

---

¡Gracias por contribuir a Timely! 🎉

---

**Última Actualización:** Diciembre 2025
