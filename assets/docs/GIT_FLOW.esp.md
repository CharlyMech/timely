# Estrategia de Git Flow

[View English version](./GIT_FLOW.md)

## Visión General

Timely utiliza **Git Flow** como estrategia de ramificación. Este enfoque proporciona un marco robusto para gestionar releases, features y hotfixes de manera estructurada.

Git Flow es un conjunto de extensiones de git que proporcionan operaciones de alto nivel en el repositorio basadas en el [modelo de ramificación de Vincent Driessen](https://nvie.com/posts/a-successful-git-branching-model/). Utiliza una solución basada en merge que no hace rebase de las ramas de features.

### Instalar Git Flow

**macOS:**
```bash
# Usando Homebrew
brew install git-flow-avh

# Usando Macports
port install git-flow-avh
```

**Linux:**
```bash
apt-get install git-flow
```

**Windows (Cygwin):**
Instalación mediante script bash (requiere wget y util-linux).

### Inicializar Git Flow

```bash
git flow init
```

Este comando personaliza la configuración de tu proyecto con convenciones de nombres de ramas. Recomendamos usar la configuración por defecto, que se alinea con la estructura de Timely (`main` para producción, `dev` para desarrollo).

## Estructura de Ramas

```
main (producción)
  ↑
  └─ dev (desarrollo)
       ↑
       ├─ feature/nombre-funcionalidad
       ├─ feature/otra-funcionalidad
       └─ bugfix/descripcion-bug
```

### Ramas Principales

#### `main`
- **Propósito**: Código listo para producción.
- **Protección**: Rama protegida, requiere pull request y revisiones.
- **Despliegue**: Activa automáticamente bump de versión y builds de release.
- **Commits directos**: ❌ Nunca hacer commit directamente a main.
- **Merges desde**: Solo desde rama `dev` (vía pull request).

#### `dev`
- **Propósito**: Rama de integración para desarrollo continuo.
- **Protección**: Rama protegida, requiere pull request.
- **Commits directos**: ❌ Nunca hacer commit directamente a dev.
- **Merges desde**: Ramas `feature/*`, `bugfix/*`, `hotfix/*`.

### Ramas de Soporte

#### `feature/*`
- **Propósito**: Desarrollar nuevas funcionalidades.
- **Nomenclatura**: `feature/descripcion-corta` (ej., `feature/modo-oscuro`).
- **Rama desde**: `dev`.
- **Merge hacia**: `dev`.
- **Duración**: Hasta que la funcionalidad esté completa y mergeada.

#### `bugfix/*`
- **Propósito**: Corregir bugs encontrados durante desarrollo.
- **Nomenclatura**: `bugfix/descripcion-corta` (ej., `bugfix/calculo-timer`).
- **Rama desde**: `dev`.
- **Merge hacia**: `dev`.
- **Duración**: Hasta que la corrección esté completa y mergeada.

#### `hotfix/*`
- **Propósito**: Correcciones de emergencia para problemas en producción.
- **Nomenclatura**: `hotfix/descripcion-corta` (ej., `hotfix/crash-inicio`).
- **Rama desde**: `main`.
- **Merge hacia**: Tanto `main` como `dev`.
- **Duración**: Hasta que el hotfix esté desplegado.

---

## Flujos de Trabajo

### 1. Trabajar con Features

#### Iniciar una Nueva Funcionalidad

**Usando git-flow:**
```bash
# Iniciar nueva feature (crea rama desde dev y cambia a ella)
git flow feature start autenticacion-usuario

# Trabajar en la funcionalidad
git add .
git commit -m "feat(auth): añadir pantalla de login"

# Publicar feature en remoto (para colaboración)
git flow feature publish autenticacion-usuario
```

**Usando git estándar:**
```bash
# 1. Asegurar que dev está actualizado
git checkout dev
git pull origin dev

# 2. Crear rama de feature
git checkout -b feature/autenticacion-usuario

# 3. Trabajar en la funcionalidad
git add .
git commit -m "feat(auth): añadir pantalla de login"

# 4. Push de la rama feature
git push origin feature/autenticacion-usuario
```

#### Colaborar en Features

```bash
# Obtener feature remota para trackearla localmente
git flow feature track autenticacion-usuario

# Obtener últimos cambios de feature remota
git flow feature pull origin autenticacion-usuario
```

#### Completar una Funcionalidad

**Usando git-flow:**
```bash
# Finalizar feature (mergea a dev, elimina rama, cambia a dev)
git flow feature finish autenticacion-usuario

# Push de rama dev actualizada
git push origin dev

# Eliminar rama feature remota
git push origin --delete feature/autenticacion-usuario
```

**Usando git estándar:**
```bash
# 1. Actualizar rama feature con último dev
git checkout feature/autenticacion-usuario
git pull origin dev

# 2. Resolver cualquier conflicto
# Si existen conflictos, resolverlos y hacer commit

# 3. Push de la rama actualizada
git push origin feature/autenticacion-usuario

# 4. Merge vía Pull Request
# Completar PR en GitHub después de revisión y aprobación

# 5. Eliminar rama feature (después del merge)
git checkout dev
git pull origin dev
git branch -d feature/autenticacion-usuario
git push origin --delete feature/autenticacion-usuario
```

### 2. Trabajar con Releases

#### Iniciar un Release

**Usando git-flow:**
```bash
# Iniciar rama de release (crea desde dev)
git flow release start 1.2.0

# Opcionalmente especificar commit base
git flow release start 1.2.0 [BASE]

# Publicar release para colaboración del equipo
git flow release publish 1.2.0
```

**Usando git estándar:**
```bash
# 1. Asegurar que dev está estable y probado
git checkout dev
git pull origin dev

# 2. Crear rama de release
git checkout -b release/1.2.0

# 3. Actualizar números de versión y preparar release
# Hacer ajustes finales

# 4. Push de rama release
git push origin release/1.2.0
```

#### Finalizar un Release

**Usando git-flow:**
```bash
# Finalizar release (mergea a main, etiqueta, back-merge a dev, elimina rama)
git flow release finish 1.2.0

# Push de todo incluyendo tags
git push origin main
git push origin dev
git push origin --tags
```

**Usando git estándar (workflow de GitHub de Timely):**
```bash
# 1. Crear Pull Request
# Ir a GitHub y crear PR: dev → main
# Título: "Release v1.2.0" o similar

# 2. Revisar y aprobar PR
# Asegurar que todos los checks de CI pasen
# Revisar changelog y bump de versión

# 3. Merge a main
# Usar "Squash and merge" o "Create a merge commit"
# GitHub Actions automáticamente:
#   - Hace bump de versión basado en commits
#   - Crea git tag
#   - Construye APK y AAB para Android
#   - Construye IPA para iOS
#   - Crea GitHub Release con artifacts

# 4. Actualizar dev con main
git checkout dev
git pull origin main
git push origin dev
```

### 3. Trabajar con Hotfixes

#### Iniciar un Hotfix

**Usando git-flow:**
```bash
# Iniciar hotfix desde main (producción)
git flow hotfix start 1.2.1

# Opcionalmente especificar versión base
git flow hotfix start 1.2.1 [BASENAME]

# Corregir el problema
git add .
git commit -m "fix(critical): resolver crash al iniciar app"
```

**Usando git estándar:**
```bash
# 1. Crear rama hotfix desde main
git checkout main
git pull origin main
git checkout -b hotfix/crash-critico

# 2. Corregir el problema
git add .
git commit -m "fix(critical): resolver crash al iniciar app"

# 3. Push de rama hotfix
git push origin hotfix/crash-critico
```

#### Finalizar un Hotfix

**Usando git-flow:**
```bash
# Finalizar hotfix (mergea a main y dev, etiqueta, elimina rama)
git flow hotfix finish 1.2.1

# Push de todo
git push origin main
git push origin dev
git push origin --tags
```

**Usando git estándar:**
```bash
# 1. Crear PR a main
# Ir a GitHub y crear PR: hotfix/crash-critico → main

# 2. Después del merge a main, también merge a dev
git checkout dev
git pull origin main
git push origin dev

# 3. Eliminar rama hotfix
git branch -d hotfix/crash-critico
git push origin --delete hotfix/crash-critico
```

---

## Convención de Mensajes de Commit

Seguir [Conventional Commits](https://www.conventionalcommits.org/) para todos los commits.

### Formato

```
<tipo>(<scope>): <asunto>

[cuerpo opcional]

[pie opcional]
```

### Tipos e Impacto en Versión

| Tipo | Descripción | Bump de Versión | Ejemplo |
|------|-------------|-----------------|---------|
| `feat` | Nueva funcionalidad | **MINOR** (0.x.0) | `feat(auth): añadir login biométrico` |
| `fix` | Corrección de bug | **PATCH** (0.0.x) | `fix(timer): corregir cálculo de horas` |
| `chore` | Mantenimiento | **PATCH** (0.0.x) | `chore(deps): actualizar dependencias` |
| `docs` | Documentación | Sin bump de versión | `docs(readme): actualizar pasos instalación` |
| `style` | Estilo de código | Sin bump de versión | `style: formatear código con prettier` |
| `refactor` | Refactorización | Sin bump de versión | `refactor(auth): simplificar lógica login` |
| `test` | Tests | Sin bump de versión | `test(auth): añadir tests unitarios login` |
| `perf` | Rendimiento | **PATCH** (0.0.x) | `perf(list): optimizar renderizado` |

### Cambios Breaking

Para cambios breaking, añadir `BREAKING CHANGE:` en el pie del commit o usar `!` después del tipo:

```bash
feat(auth)!: rediseñar flujo de autenticación

BREAKING CHANGE: Los tokens de autenticación antiguos ya no son válidos
```

Esto activará un bump de versión **MAJOR** (x.0.0).

### Ejemplos

```bash
# Bump de versión minor (nueva funcionalidad)
git commit -m "feat(notifications): añadir soporte push notifications"

# Bump de versión patch (corrección bug)
git commit -m "fix(registration): resolver error cálculo zona horaria"

# Bump de versión patch (mantenimiento)
git commit -m "chore(deps): actualizar riverpod a 3.1.0"

# Sin bump de versión (documentación)
git commit -m "docs(api): documentar endpoints autenticación"

# Bump de versión major (cambio breaking)
git commit -m "feat(api)!: migrar a REST API v2

BREAKING CHANGE: Endpoints de API v1 están deprecados y eliminados"
```

---

## Reglas de Protección de Ramas

### Rama `main`

- ✅ Requerir pull request antes de merge
- ✅ Requerir aprobaciones (mínimo 1 revisor)
- ✅ Requerir que pasen los checks de estado
- ✅ Requerir resolución de conversaciones
- ❌ Permitir force pushes
- ❌ Permitir eliminaciones

### Rama `dev`

- ✅ Requerir pull request antes de merge
- ✅ Requerir que pasen los checks de estado
- ✅ Requerir resolución de conversaciones
- ❌ Permitir force pushes
- ❌ Permitir eliminaciones

---

## Estrategia de Versionado

Timely sigue [Semantic Versioning](https://semver.org/) (SemVer):

```
MAJOR.MINOR.PATCH

Ejemplo: 1.2.3
```

- **MAJOR** (1.x.x): Cambios breaking, cambios incompatibles en API
- **MINOR** (x.2.x): Nuevas funcionalidades, compatible hacia atrás
- **PATCH** (x.x.3): Correcciones de bugs, compatible hacia atrás

### Fuentes de Versión

La versión se gestiona en múltiples archivos:
- `pubspec.yaml` - Versión del proyecto Flutter
- Android: `android/app/build.gradle` - `versionCode` y `versionName`
- iOS: `ios/Runner/Info.plist` - `CFBundleShortVersionString` y `CFBundleVersion`

GitHub Actions actualiza automáticamente todos los archivos de versión al mergear a `main`.

---

## Mejores Prácticas

### 1. Leer la Ayuda de Comandos

Siempre lee cuidadosamente la salida de ayuda de los comandos git flow antes de ejecutarlos:
```bash
git flow feature help
git flow release help
git flow hotfix help
```

### 2. Git Flow y Git Estándar Funcionan Juntos

Git Flow es simplemente un wrapper alrededor de comandos git estándar. Puedes usar comandos git regulares junto con comandos git flow:
```bash
# Estos funcionan juntos sin problemas
git flow feature start mi-feature
git add .
git commit -m "feat: añadir nueva funcionalidad"
git push origin feature/mi-feature
```

### 3. Mantener Ramas de Corta Duración

- Las ramas feature deben mergearse en pocos días.
- No dejar que las ramas diverjan mucho de dev.
- Sincronizar regularmente con dev para evitar conflictos.

### 4. Mensajes de Commit Significativos

- Escribir mensajes claros y descriptivos.
- Seguir formato de conventional commits.
- Explicar el "por qué" no solo el "qué".

### 5. Pull Requests Pequeños y Enfocados

- Una funcionalidad o fix por PR.
- Más fácil de revisar y probar.
- Reduce conflictos de merge.

### 6. Actualizaciones Regulares

```bash
# Diario: actualizar tu rama feature con dev
git checkout feature/mi-feature
git pull origin dev

# Resolver conflictos temprano y frecuentemente
```

### 7. Historial de Commits Limpio

```bash
# Antes de crear PR, considerar squash de commits
git rebase -i dev

# O usar opción "Squash and merge" en GitHub
```

### 8. Herramientas GUI

Para desarrolladores que prefieren herramientas GUI, considerar usar:
- **Sourcetree** (macOS/Windows) - Tiene soporte integrado para git flow.
- **GitKraken** - Interfaz visual de git flow.
- **SourceTree** - GUI Git gratuita con integración de git flow.

---

## Solución de Problemas

### Conflictos de Merge

```bash
# 1. Actualizar rama con último dev
git checkout feature/mi-feature
git pull origin dev

# 2. Resolver conflictos en el editor
# Buscar marcadores de conflicto: <<<<<<<, =======, >>>>>>>

# 3. Marcar como resuelto
git add .
git commit -m "resolve: conflictos de merge con dev"

# 4. Push
git push origin feature/mi-feature
```

### Commit Accidental en Rama Incorrecta

```bash
# Si hiciste commit a dev en lugar de una rama feature

# 1. Crear rama feature desde estado actual
git branch feature/mi-feature

# 2. Resetear dev al estado anterior
git checkout dev
git reset --hard origin/dev

# 3. Cambiar a rama feature
git checkout feature/mi-feature

# 4. Push rama feature
git push origin feature/mi-feature
```

### Necesidad de Actualizar Dev desde Main

```bash
# Después de un hotfix o cambio manual en main

git checkout dev
git pull origin main
git push origin dev
```

---

## Integración CI/CD

Timely usa GitHub Actions para integración y despliegue continuos:

- **En PR a dev**: Ejecutar tests, linting, análisis de código
- **En merge a dev**: Ejecutar suite completa de tests
- **En merge a main**:
  - Bump de versión automático
  - Crear git tag
  - Construir Android APK/AAB
  - Construir iOS IPA
  - Crear GitHub Release
  - Adjuntar artifacts de build

Ver [CI_CD_WORKFLOW.md](./CI_CD_WORKFLOW.md) para documentación detallada del workflow.

---

## Referencia Rápida

### Comandos de Git Flow

#### Workflow de Features
```bash
# Iniciar feature
git flow feature start <nombre>

# Publicar feature
git flow feature publish <nombre>

# Obtener feature remota
git flow feature track <nombre>

# Finalizar feature
git flow feature finish <nombre>
```

#### Workflow de Releases
```bash
# Iniciar release
git flow release start <version>

# Publicar release
git flow release publish <version>

# Finalizar release
git flow release finish <version>
```

#### Workflow de Hotfixes
```bash
# Iniciar hotfix
git flow hotfix start <version>

# Finalizar hotfix
git flow hotfix finish <version>
```

### Comandos Git Estándar

#### Crear Rama Feature
```bash
git checkout dev && git pull origin dev
git checkout -b feature/nombre-feature
```

#### Push Rama Feature
```bash
git push origin feature/nombre-feature
```

#### Eliminar Rama Local
```bash
git branch -d feature/nombre-feature
```

#### Eliminar Rama Remota
```bash
git push origin --delete feature/nombre-feature
```

#### Actualizar Feature con Dev
```bash
git checkout feature/nombre-feature
git pull origin dev
```

#### Listar Todas las Ramas
```bash
git branch -a
```

---

## Licencia

Esta documentación es parte del proyecto Timely, licenciado bajo una Licencia Open Source Personalizada con Restricciones Comerciales.

Para términos completos, ver el archivo [LICENSE](../../LICENSE).

---

**Última Actualización:** Diciembre 2025
