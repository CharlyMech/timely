# Documentación del Flujo CI/CD

[View English version](./CI_CD_WORKFLOW.md)

## Visión General

Timely utiliza **GitHub Actions** para Integración Continua y Despliegue Continuo (CI/CD). El workflow automatiza la gestión de versiones, construcción, testing y liberación de la aplicación.

## Archivos de Workflow

### 1. **Workflow de Release** (`.github/workflows/release.yml`)

Se activa cuando se hace merge de código a la rama `main`.

**Propósito:**
- Hacer bump de versión automáticamente basado en los mensajes de commit.
- Crear git tags.
- Construir artifacts listos para producción (APK, AAB, IPA).
- Crear GitHub Release con artifacts descargables.

### 2. **Workflow de Checks en PR** (`.github/workflows/pr-checks.yml`)

Se activa en pull requests a las ramas `dev` o `main`.

**Propósito:**
- Lint y formatear código.
- Ejecutar análisis estático.
- Ejecutar tests.
- Verificar builds.
- Validar mensajes de commit.

---

## Workflow de Release (Detallado)

### Trigger

```yaml
on:
  push:
    branches:
      - main
```

Se activa cuando:
- Un pull request se mergea a `main`.
- Se hace un push directo a `main` (no recomendado).

### Jobs

#### Job 1: Version Bump and Release

**Ejecuta en:** `ubuntu-latest`

**Pasos:**

1. **Checkout Code**
   - Obtiene el historial completo de git.
   - Requerido para que semantic-release analice commits.

2. **Setup Node.js**
   - Instala Node.js 20.
   - Requerido para herramientas de semantic-release.

3. **Install semantic-release**
   - Instala semantic-release y plugins:
     - `@semantic-release/commit-analyzer` - Analiza commits.
     - `@semantic-release/release-notes-generator` - Genera changelog.
     - `@semantic-release/changelog` - Actualiza CHANGELOG.md.
     - `@semantic-release/exec` - Ejecuta script de actualización de versión.
     - `@semantic-release/git` - Commitea cambios de versión.
     - `@semantic-release/github` - Crea GitHub Release.

4. **Create Configuration**
   - Genera `.releaserc.json` con reglas de release:

```json
{
  "releaseRules": [
    {"type": "feat", "release": "minor"},      // 0.x.0
    {"type": "fix", "release": "patch"},       // 0.0.x
    {"type": "chore", "release": "patch"},     // 0.0.x
    {"type": "perf", "release": "patch"},      // 0.0.x
    {"type": "docs", "release": false},        // Sin release
    {"type": "style", "release": false},       // Sin release
    {"type": "refactor", "release": false},    // Sin release
    {"type": "test", "release": false}         // Sin release
  ]
}
```

5. **Create Version Update Script**
   - Genera `scripts/update-version.sh`.
   - Actualiza versión en múltiples archivos:
     - `pubspec.yaml` - Versión de Flutter.
     - `android/app/build.gradle` - Versión de Android.
     - `ios/Runner/Info.plist` - Versión de iOS.

6. **Run semantic-release**
   - Analiza commits desde el último release.
   - Determina nueva versión.
   - Actualiza archivos de versión.
   - Crea git tag.
   - Commitea cambios.
   - Crea GitHub Release.

**Outputs:**
- `version`: Nuevo número de versión (ej., "1.2.3").
- `released`: Boolean, true si se liberó nueva versión.

#### Job 2: Build Android

**Ejecuta en:** `ubuntu-latest`
**Depende de:** Version Bump
**Condición:** Solo si se liberó nueva versión.

**Pasos:**

1. **Checkout Code**
   - Obtiene el último código de `main`.

2. **Setup Java 17**
   - Requerido para builds de Android.

3. **Setup Flutter**
   - Instala Flutter 3.10.0 stable.

4. **Install Dependencies**
   ```bash
   flutter pub get
   ```

5. **Run Tests**
   ```bash
   flutter test
   ```

6. **Build APK**
   ```bash
   flutter build apk --release --dart-define=FLAVOR=prod
   ```
   - Genera: `app-release.apk`.
   - Para testing y sideloading.

7. **Build App Bundle (AAB)**
   ```bash
   flutter build appbundle --release --dart-define=FLAVOR=prod
   ```
   - Genera: `app-release.aab`.
   - Para distribución en Google Play Store.

8. **Rename Artifacts**
   - Renombra para incluir versión:
     - `timely-v1.2.3.apk`
     - `timely-v1.2.3.aab`

9. **Upload Artifacts**
   - Almacena en artifacts de GitHub Actions (90 días).
   - Sube a GitHub Release.

**Artifacts:**
- `timely-v{version}.apk` - ~50-100 MB
- `timely-v{version}.aab` - ~30-50 MB

#### Job 3: Build iOS

**Ejecuta en:** `macos-latest`
**Depende de:** Version Bump
**Condición:** Solo si se liberó nueva versión.

**Pasos:**

1. **Checkout Code**

2. **Setup Flutter**

3. **Install Dependencies**

4. **Run Tests**

5. **Build iOS**
   ```bash
   flutter build ios --release --dart-define=FLAVOR=prod --no-codesign
   ```
   - Construye sin code signing.
   - Para desarrollo y testing.

6. **Create IPA Archive**
   ```bash
   cd build/ios/iphoneos
   mkdir Payload
   cp -r Runner.app Payload/
   zip -r app-release.ipa Payload
   ```

7. **Rename and Upload**
   - Renombra a: `timely-v{version}.ipa`.
   - Sube a GitHub Release.

**Nota:** Para distribución en App Store, necesitarás:
- Configurar certificados de code signing.
- Configurar provisioning profiles.
- Usar Fastlane o Xcode Cloud.

**Artifacts:**
- `timely-v{version}.ipa` - ~50-100 MB

#### Job 4: Notify Completion

**Ejecuta en:** `ubuntu-latest`
**Depende de:** Todos los jobs anteriores
**Condición:** Siempre se ejecuta si se liberó versión.

**Propósito:**
- Crea resumen de build en la UI de GitHub Actions.
- Muestra estado de todos los builds.
- Proporciona enlace a la página de release.

---

## Workflow de Checks en PR (Detallado)

### Trigger

```yaml
on:
  pull_request:
    branches:
      - dev
      - main
```

### Jobs

#### Job 1: Lint and Test

**Pasos:**

1. **Format Check**
   ```bash
   flutter format --set-exit-if-changed .
   ```
   - Asegura que el código sigue el formato de Dart.

2. **Static Analysis**
   ```bash
   flutter analyze
   ```
   - Verifica errores y warnings potenciales.

3. **Run Tests with Coverage**
   ```bash
   flutter test --coverage
   ```
   - Ejecuta todos los tests unitarios y de widgets.
   - Genera reporte de cobertura.

4. **Upload Coverage**
   - Envía cobertura a Codecov (opcional).

#### Job 2: Build Check

**Propósito:**
- Verifica que la app se construye exitosamente.
- Usa flavor dev para acelerar builds.

```bash
flutter build apk --debug --dart-define=FLAVOR=dev
```

#### Job 3: Commit Message Check

**Propósito:**
- Valida que los mensajes de commit siguen Conventional Commits.

**Tipos válidos:**
- `feat:` - Nuevas funcionalidades.
- `fix:` - Correcciones de bugs.
- `docs:` - Documentación.
- `style:` - Estilo de código.
- `refactor:` - Refactorización de código.
- `perf:` - Mejoras de rendimiento.
- `test:` - Tests.
- `chore:` - Mantenimiento.

**Ejemplo de validación:**
```bash
✓ feat(auth): añadir login biométrico
✓ fix(timer): resolver error de cálculo
✗ updated readme  # Falta tipo
✗ Fixed bug       # Formato incorrecto
```

---

## Gestión de Versiones

### Versionado Semántico

Timely sigue [SemVer](https://semver.org/): `MAJOR.MINOR.PATCH`

**Bumps de versión automáticos:**

| Tipo de Commit | Cambio de Versión | Ejemplo |
|----------------|-------------------|---------|
| `feat:` | MINOR (0.x.0) | 1.2.0 → 1.3.0 |
| `fix:` | PATCH (0.0.x) | 1.2.0 → 1.2.1 |
| `chore:` | PATCH (0.0.x) | 1.2.0 → 1.2.1 |
| `perf:` | PATCH (0.0.x) | 1.2.0 → 1.2.1 |
| `feat!:` o `BREAKING CHANGE:` | MAJOR (x.0.0) | 1.2.0 → 2.0.0 |

### Archivos de Versión Actualizados

1. **`pubspec.yaml`**
   ```yaml
   version: 1.2.3+45
   ```
   - Formato: `version+build`
   - Número de build auto-incrementa.

2. **`android/app/build.gradle`**
   ```gradle
   versionName "1.2.3"
   versionCode 45
   ```
   - `versionName`: Mostrado a usuarios.
   - `versionCode`: Interno, debe incrementar.

3. **`ios/Runner/Info.plist`**
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>1.2.3</string>
   <key>CFBundleVersion</key>
   <string>45</string>
   ```
   - `CFBundleShortVersionString`: Versión mostrada.
   - `CFBundleVersion`: Número de build.

---

## Artifacts de Build

### Android

**APK (Android Package)**
- **Archivo:** `timely-v{version}.apk`
- **Tamaño:** ~50-100 MB
- **Caso de uso:**
  - Instalación directa en dispositivos.
  - Testing y QA.
  - Distribución fuera de Play Store.

**AAB (Android App Bundle)**
- **Archivo:** `timely-v{version}.aab`
- **Tamaño:** ~30-50 MB
- **Caso de uso:**
  - **Google Play Store** (formato requerido).
  - Optimizado para configuraciones de dispositivo.
  - Entrega dinámica.

### iOS

**IPA (iOS App Store Package)**
- **Archivo:** `timely-v{version}.ipa`
- **Tamaño:** ~50-100 MB
- **Caso de uso:**
  - Testing en dispositivos.
  - Distribución por TestFlight.
  - Distribución en App Store (con signing).

---

## Publicación en Stores

### Google Play Store

1. **Preparar AAB**
   - Descargar `timely-v{version}.aab` desde GitHub Release.

2. **Subir a Play Console**
   - Ir a [Google Play Console](https://play.google.com/console).
   - Seleccionar tu app.
   - Producción → Crear nuevo release.
   - Subir archivo AAB.

3. **Configurar Release**
   - Añadir notas de release.
   - Establecer porcentaje de rollout.
   - Enviar para revisión.

**Automatización (Futuro):**
```yaml
# Se puede automatizar con:
- Fastlane + plugin Supply
- API de Google Play Developer
```

### Apple App Store

1. **Firmar IPA con Code Signing**
   - Requiere cuenta de Apple Developer.
   - Configurar certificados y provisioning profiles.
   - Usar Xcode o Fastlane.

2. **Subir a App Store Connect**
   - Usar app Xcode o Transporter.
   - Enviar para TestFlight o revisión.

3. **Revisión de App Store**
   - Añadir capturas de pantalla, descripción.
   - Enviar para revisión.

**Automatización (Futuro):**
```yaml
# Se puede automatizar con:
- Fastlane + plugin Deliver
- Xcode Cloud
```

---

## Diagrama de Workflow

```
┌─────────────────────────────────────────┐
│   Desarrollador crea PR a dev          │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│    Workflow de Checks en PR ejecuta     │
│  - Lint & Format                        │
│  - Analyze                              │
│  - Test                                 │
│  - Build check                          │
│  - Validación de mensaje de commit      │
└────────────────┬────────────────────────┘
                 │
                 ↓ (Todos los checks pasan)
┌─────────────────────────────────────────┐
│     PR mergeado a dev                   │
│     (Sin deployment, solo tests)        │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│     Crear PR de dev a main              │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│    Checks de PR ejecutan de nuevo       │
└────────────────┬────────────────────────┘
                 │
                 ↓ (Todos los checks pasan)
┌─────────────────────────────────────────┐
│     PR mergeado a main                  │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│   Workflow de Release se activa         │
└────────────────┬────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────┐
│   semantic-release analiza commits      │
│   - Determina bump de versión           │
│   - Actualiza archivos de versión       │
│   - Crea CHANGELOG.md                   │
│   - Crea git tag                        │
│   - Commitea cambios [skip ci]          │
└────────────────┬────────────────────────┘
                 │
                 ├─────────────┬─────────────┐
                 ↓             ↓             ↓
        ┌────────────┐ ┌──────────┐ ┌──────────┐
        │Build Android│ │Build iOS │ │ Notify   │
        │  APK + AAB  │ │   IPA    │ │          │
        └──────┬──────┘ └────┬─────┘ └────┬─────┘
               │             │            │
               └─────────────┴────────────┘
                            │
                            ↓
               ┌────────────────────────┐
               │  GitHub Release Creado │
               │  - Tag: v1.2.3         │
               │  - Changelog           │
               │  - Descarga APK        │
               │  - Descarga AAB        │
               │  - Descarga IPA        │
               └────────────────────────┘
```

---

## Configuración

### Secrets Requeridos

Ninguno requerido para workflow básico. Opcionales:

- `CODECOV_TOKEN` - Para reportes de cobertura de código.
- `SLACK_WEBHOOK` - Para notificaciones de build.
- `FIREBASE_TOKEN` - Para Firebase App Distribution.

### Reglas de Protección de Ramas

**Rama `main`:**
- ✅ Requerir revisión de pull request.
- ✅ Requerir que pasen checks de estado:
  - `Lint and Test`
  - `Build Check`
  - `Commit Message Check`
- ✅ Requerir resolución de conversaciones.
- ❌ Permitir force pushes.

**Rama `dev`:**
- ✅ Requerir revisión de pull request.
- ✅ Requerir que pasen checks de estado.
- ❌ Permitir force pushes.

---

## Solución de Problemas

### Build Falla

**Verificar:**
1. Compatibilidad de versión de Flutter.
2. Problemas con dependencias (`flutter pub get`).
3. Fallos en tests (`flutter test`).
4. Configuración de build.

**Ver logs:**
- GitHub Actions → Workflow fallido → Logs del job.

### Versión No Hace Bump

**Causas posibles:**
1. No hay commits con tipos que hacen bump de versión (`feat`, `fix`, etc.).
2. Solo commits de `docs` o `style`.
3. Error de configuración de semantic-release.

**Solución:**
- Asegurar que los commits siguen formato de Conventional Commits.
- Verificar configuración de `.releaserc.json`.

### Artifacts No Suben

**Verificar:**
1. Build completado exitosamente.
2. Artifacts existen en rutas esperadas.
3. Permisos del token de GitHub.

---

## Mejores Prácticas

### 1. Commits Significativos

```bash
# Bueno
feat(auth): añadir autenticación con huella
fix(timer): resolver error de redondeo en cálculo

# Malo
código actualizado
arreglado bug
```

### 2. Test Antes de PR

```bash
# Ejecutar localmente antes de crear PR
flutter format .
flutter analyze
flutter test
flutter build apk --debug --dart-define=FLAVOR=dev
```

### 3. PRs Pequeños y Enfocados

- Una funcionalidad por PR.
- Más fácil de revisar.
- Ejecución de CI/CD más rápida.

### 4. Monitorear Ejecuciones de Workflow

- Verificar pestaña de GitHub Actions.
- Revisar logs de build.
- Verificar artifacts.

---

## Licencia

Esta documentación es parte del proyecto Timely, licenciado bajo una Licencia Open Source Personalizada con Restricciones Comerciales.

Para términos completos, ver el archivo [LICENSE](../../LICENSE).

---

**Última Actualización:** Diciembre 2025
