# ⏰ Timely - Time Registration App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-3.0-purple?style=for-the-badge)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange?style=for-the-badge&logo=firebase&logoColor=white)

Una aplicación móvil moderna y eficiente para el registro horario de empleados, desarrollada con Flutter y arquitectura limpia.

[Características](#-características) •
[Arquitectura](#-arquitectura) •
[Instalación](#-instalación) •
[Documentación](#-documentación) •
[Screenshots](#-screenshots)

</div>

---

## 📋 Descripción

**Timely** es una aplicación de registro horario que permite a los empleados gestionar sus jornadas laborales de manera simple, rápida e intuitiva. La aplicación implementa una arquitectura limpia con separación clara de responsabilidades y utiliza Riverpod 3.0 para el state management.

### 🎯 Problema que Resuelve

- ✅ Eliminación del registro manual en papel
- ✅ Cálculo automático de horas trabajadas
- ✅ Interfaz intuitiva sin necesidad de capacitación
- ✅ Acceso rápido desde dispositivos móviles
- ✅ Sincronización en tiempo real (modo producción)

---

## ✨ Características

### Funcionalidades Principales

- **📝 Registro Horario**
  - Check-in/Check-out con un solo tap
  - Cronómetro en tiempo real
  - Cálculo automático de horas trabajadas
  - Historial de registros diarios

- **👥 Gestión de Empleados**
  - Grid responsivo de empleados (2-5 columnas)
  - Tarjetas visuales con foto y estado
  - Pull-to-refresh para actualizar datos
  - Vista detallada por empleado

- **🎨 Experiencia de Usuario**
  - Temas claro y oscuro
  - Animaciones fluidas
  - Timeout de inactividad (5 minutos)
  - Feedback visual de estados

### Características Técnicas

- **🏗️ Arquitectura Limpia** (Clean Architecture)
- **📦 State Management** con Riverpod 3.0
- **🔥 Firebase Integration** (Firestore)
- **🧪 Mock Data** para desarrollo local
- **🎯 Type-Safe** con null-safety
- **📱 Responsive Design** multi-dispositivo
- **🚀 Performance Optimizado**

---

## 🏛️ Arquitectura

Timely implementa una **arquitectura limpia** con tres capas bien definidas:

```
┌─────────────────────────────────────┐
│       Presentation Layer            │
│  Screens • Widgets • ViewModels     │
└──────────────┬──────────────────────┘
               │ Riverpod
┌──────────────▼──────────────────────┐
│         Domain Layer                │
│  Repositories • Models • Business   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│          Data Layer                 │
│  Services • Mock • Firebase         │
└─────────────────────────────────────┘
```

### Tecnologías y Librerías

| Categoría | Tecnología | Uso |
|-----------|-----------|-----|
| **Framework** | Flutter 3.10+ | UI Framework |
| **Lenguaje** | Dart 3.10+ | Programación |
| **State Management** | Riverpod 3.0 | Gestión de estado reactivo |
| **Navegación** | GoRouter | Routing declarativo |
| **Backend** | Firebase Firestore | Base de datos en producción |
| **Storage Local** | SharedPreferences | Preferencias del usuario |
| **Assets** | flutter_svg | Imágenes vectoriales |
| **IDs** | uuid | Generación de identificadores |
| **Fechas** | intl | Formateo de fechas |

---

## 🚀 Instalación

### Prerrequisitos

- Flutter SDK 3.10 o superior
- Dart SDK 3.10 o superior
- Android Studio / VS Code
- Emulador Android o dispositivo físico

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/timely.git
cd timely
```

### Paso 2: Instalar Dependencias

```bash
flutter pub get
```

### Paso 3: Ejecutar la Aplicación

#### Modo Desarrollo (Mock Data)

```bash
# No requiere Firebase, usa datos mock locales
flutter run --dart-define=FLAVOR=dev
```

#### Modo Producción (Firebase)

```bash
# Requiere configuración de Firebase
flutter run --dart-define=FLAVOR=prod
```

### Configuración de Firebase (Opcional)

Si deseas usar Firebase en producción:

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com)
2. Agregar aplicación Android
3. Descargar `google-services.json` y colocar en `android/app/`
4. Configurar Firestore con las siguientes colecciones:
   - `employees`
   - `time_registrations`

---

## 📖 Documentación

La documentación completa del proyecto está disponible en [`assets/docs/`](./assets/docs/):

| Documento | Descripción |
|-----------|-------------|
| [**README.md**](./assets/docs/README.md) | Documentación general del proyecto |
| [**ARCHITECTURE.md**](./assets/docs/ARCHITECTURE.md) | Arquitectura del sistema en detalle |
| [**STATE_MANAGEMENT.md**](./assets/docs/STATE_MANAGEMENT.md) | Guía completa de Riverpod 3.0 |
| [**EXECUTION_FLOW.md**](./assets/docs/EXECUTION_FLOW.md) | Flujos de ejecución y casos de uso |

### Guías Rápidas

- **🆕 Nuevo en el proyecto?** → Lee [`assets/docs/README.md`](./assets/docs/README.md)
- **🏗️ Entender la arquitectura?** → Consulta [`ARCHITECTURE.md`](./assets/docs/ARCHITECTURE.md)
- **🔄 State management?** → Revisa [`STATE_MANAGEMENT.md`](./assets/docs/STATE_MANAGEMENT.md)
- **🐛 Debug de flujos?** → Usa [`EXECUTION_FLOW.md`](./assets/docs/EXECUTION_FLOW.md)

---

## 📸 Screenshots

<div align="center">

### Splash Screen
<img src="assets/screenshots/splash.png" width="250" alt="Splash Screen">

### Welcome Screen
<img src="assets/screenshots/welcome.png" width="250" alt="Welcome Screen">

### Staff Screen (Grid de Empleados)
<img src="assets/screenshots/staff.png" width="250" alt="Staff Screen">

### Employee Detail (Registro Horario)
<img src="assets/screenshots/detail.png" width="250" alt="Employee Detail">

</div>

> **Nota:** Los screenshots son ilustrativos. La aplicación incluye temas claro y oscuro.

---

## 🗂️ Estructura del Proyecto

```
timely/
├── assets/
│   ├── docs/              # 📚 Documentación completa
│   ├── images/            # 🖼️ Imágenes y logos
│   └── mock/              # 📄 Datos mock para desarrollo
│
├── lib/
│   ├── config/            # ⚙️ Configuración (router, providers, setup)
│   ├── constants/         # 📐 Constantes (temas, colores)
│   ├── models/            # 🏷️ Modelos de dominio
│   ├── repositories/      # 🗄️ Repositorios (lógica de negocio)
│   ├── services/          # 🔌 Servicios (mock, firebase)
│   ├── viewmodels/        # 🎭 ViewModels (state management)
│   ├── screens/           # 📱 Pantallas de la app
│   ├── widgets/           # 🧩 Widgets reutilizables
│   ├── utils/             # 🛠️ Utilidades
│   ├── app.dart           # 🎨 Widget principal
│   └── main.dart          # 🚀 Punto de entrada
│
├── test/                  # 🧪 Tests unitarios
├── pubspec.yaml           # 📦 Dependencias
└── README.md              # 📖 Este archivo
```

---

## 🧪 Testing

### Ejecutar Tests

```bash
# Todos los tests
flutter test

# Tests con coverage
flutter test --coverage

# Ver reporte de coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Cobertura Actual

- ✅ Unit tests de ViewModels
- ✅ Unit tests de Repositories
- ✅ Widget tests de componentes
- 🔄 Integration tests (en desarrollo)

---

## 🔧 Desarrollo

### Estructura de Branches

- `main` - Producción estable
- `develop` - Desarrollo activo
- `feature/*` - Nuevas características
- `bugfix/*` - Corrección de bugs
- `hotfix/*` - Fixes urgentes para producción

### Convenciones de Código

- **Archivos:** `snake_case.dart`
- **Clases:** `PascalCase`
- **Variables/Funciones:** `camelCase`
- **Constantes:** `camelCase` o `SCREAMING_SNAKE_CASE`
- **Privados:** prefijo `_`

### Commits Convencionales

```bash
feat: nueva funcionalidad
fix: corrección de bug
docs: cambios en documentación
style: formateo, punto y coma, etc
refactor: refactorización de código
test: añadir tests
chore: mantenimiento
```

### Añadir Nueva Feature

1. Crear branch: `git checkout -b feature/nombre-feature`
2. Crear modelo en `lib/models/`
3. Crear servicio en `lib/services/`
4. Crear repositorio en `lib/repositories/`
5. Crear ViewModel en `lib/viewmodels/`
6. Crear Screen en `lib/screens/`
7. Añadir ruta en `lib/config/router.dart`
8. Crear tests
9. Pull request a `develop`

---

## 🤝 Contribuir

Las contribuciones son bienvenidas! Por favor:

1. Fork el proyecto
2. Crea tu branch de feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Guías de Contribución

- Seguir la arquitectura existente
- Escribir tests para nuevo código
- Documentar funciones públicas
- Seguir convenciones de código
- Actualizar documentación si es necesario

---

## 📝 Roadmap

### ✅ Versión 1.0 (Actual)

- [x] Registro de entrada/salida
- [x] Grid de empleados
- [x] Detalle de empleado
- [x] Cálculo de horas
- [x] Temas claro/oscuro
- [x] Modo mock y Firebase

### 🔄 Versión 1.1 (Próxima)

- [ ] Notificaciones push
- [ ] Reportes PDF
- [ ] Gráficos de estadísticas
- [ ] Filtros avanzados
- [ ] Exportar a Excel

### 🚀 Versión 2.0 (Futuro)

- [ ] Geolocalización
- [ ] Reconocimiento facial
- [ ] Multi-empresa
- [ ] Dashboard web
- [ ] API REST

---

## 🐛 Troubleshooting

### Problema: App se queda en splash screen

**Solución:** Usar `Future.microtask` en `initState` para modificar providers.

```dart
@override
void initState() {
  super.initState();
  Future.microtask(() => ref.read(provider.notifier).load());
}
```

### Problema: Hot reload no aplica cambios

**Solución:** Hacer hot restart (R mayúscula en la consola).

### Problema: Firebase no conecta

**Verificar:**
1. `google-services.json` está en `android/app/`
2. Proyecto configurado en Firebase Console
3. Reglas de Firestore permiten lectura/escritura

### Más Ayuda

Consulta la [documentación completa](./assets/docs/README.md) o abre un [issue](https://github.com/tu-usuario/timely/issues).

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver [`LICENSE`](LICENSE) para más detalles.

---

## 👥 Autores

- **Carlos** - *Desarrollo inicial* - [@carlos](https://github.com/carlos)

---

## 🙏 Agradecimientos

- Flutter Team por el excelente framework
- Riverpod por el state management
- Firebase por los servicios backend
- Comunidad de Flutter por el apoyo

---

## 📞 Contacto

- **Email:** contacto@timely.app
- **Issues:** [GitHub Issues](https://github.com/tu-usuario/timely/issues)
- **Discussions:** [GitHub Discussions](https://github.com/tu-usuario/timely/discussions)

---

<div align="center">

**⭐ Si te gusta este proyecto, dale una estrella!**

Hecho con ❤️ y Flutter

</div>
