# Timely - Aplicación de Registro Horario

![Timely Banner](./assets/screenshots/banner.png)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?style=for-the-badge&logo=dart&logoColor=white) ![Riverpod](https://img.shields.io/badge/Riverpod-3.0-purple?style=for-the-badge)

Una aplicación móvil moderna y eficiente para el registro horario de empleados, desarrollada con Flutter y arquitectura limpia.

[Ver versión en inglés](./README.md)

</div>

---

## Tabla de Contenidos

-  [Descripción](#descripción)
-  [Características](#características)
-  [Stack Tecnológico](#stack-tecnológico)
-  [Documentación](#documentación)
-  [Screenshots](#screenshots)
-  [Licencia](#licencia)
-  [Contacto](#contacto)

---

## Descripción

**Timely** es una aplicación de registro horario que permite a los empleados gestionar sus jornadas laborales de manera simple, rápida e intuitiva. La aplicación implementa una arquitectura limpia con separación clara de responsabilidades y utiliza Riverpod 3.0 para el state management.

### Beneficios Clave

-  Eliminación del registro manual en papel.
-  Cálculo automático de horas trabajadas.
-  Interfaz intuitiva sin necesidad de capacitación.
-  Acceso rápido desde dispositivos móviles.
-  Sincronización en tiempo real (modo producción).

---

## Características

### Funcionalidades de Usuario

-  Registro horario de empleados (entrada/salida).
-  Cálculo automático de horas trabajadas.
-  Lista de empleados con grid responsivo.
-  Visualización de tiempo en tiempo real.
-  Soporte para temas claro y oscuro.
-  Trazabilidad de auditoría completa para cumplimiento normativo.

### Arquitectura y Técnicas

-  Arquitectura Limpia con patrón MVVM.
-  Riverpod 3.0 para gestión de estado.
-  Capa de abstracción de servicios (soporta Mock y API REST).
-  Implementación con datos mock para desarrollo.
-  Cliente REST API para producción.
-  Sistema de auditoría para registro de acciones críticas.

---

## Stack Tecnológico

| Categoría            | Tecnología         | Uso                            |
| -------------------- | ------------------ | ------------------------------ |
| **Framework**        | Flutter 3.10+      | UI Framework.                  |
| **Lenguaje**         | Dart 3.10+         | Programación.                  |
| **State Management** | Riverpod 3.0       | Gestión de estado reactivo.    |
| **Navegación**       | GoRouter           | Routing declarativo.           |
| **Backend**          | REST API (Dio)     | Producción.                    |
| **HTTP Client**      | Dio                | Cliente REST API.              |
| **Storage Local**    | SharedPreferences  | Preferencias del usuario.      |
| **Assets**           | flutter_svg        | Imágenes vectoriales.          |
| **IDs**              | uuid               | Generación de identificadores. |
| **Fechas**           | intl               | Formateo de fechas.            |
| **Auditoría**        | AuditService       | Trazabilidad y cumplimiento.   |

---

## Documentación

La documentación completa del proyecto está disponible en [`assets/docs/`](./assets/docs/):

| Documento | Descripción |
| --- | --- |
| [**README.esp.md**](./assets/docs/README.esp.md) | Visión general de la documentación técnica. |
| [**ARCHITECTURE.esp.md**](./assets/docs/ARCHITECTURE.esp.md) | Arquitectura del sistema en detalle. |
| [**STATE_MANAGEMENT.esp.md**](./assets/docs/STATE_MANAGEMENT.esp.md) | Guía completa de Riverpod 3.0. |
| [**EXECUTION_FLOW.esp.md**](./assets/docs/EXECUTION_FLOW.esp.md) | Flujos de ejecución y casos de uso. |
| [**USAGE.md**](./assets/docs/USAGE.md) | Cómo usar este proyecto. |
| [**CONTRIBUTING.md**](./assets/docs/CONTRIBUTING.md) | Cómo contribuir al proyecto. |

---

## Screenshots

<div align="center">

### Splash Screen

<img src="assets/screenshots/splash.png" alt="Splash Screen">

### Welcome Screen

<img src="assets/screenshots/welcome.png" alt="Welcome Screen">

### Staff Screen (Grid de Empleados)

<img src="assets/screenshots/staff.png" alt="Staff Screen">

### Employee Detail (Registro Horario)

<img src="assets/screenshots/time_resgistration_detail.png" alt="Employee Detail">

</div>

> **Nota:** Los screenshots son ilustrativos. La aplicación incluye temas claro y oscuro.

---

## Licencia

Este proyecto está bajo una **Licencia Open Source Personalizada con Restricciones Comerciales**.

### Resumen

-  **Código Abierto**: El código fuente está disponible públicamente.
-  **Contribuciones**: Los issues y pull requests son bienvenidos.
-  **Uso Comercial**: Solo el autor original está autorizado para distribuir este software comercialmente.
-  **Uso No Comercial**: Libre uso para propósitos personales y no comerciales.

Ver el archivo [LICENSE](LICENSE) para los términos y condiciones completos.

---

## Contacto

Si estás interesado en este proyecto para propósitos comerciales o tienes preguntas:

-  **Email**: [sanchezreciocarlos99@outlook.com](mailto:sanchezreciocarlos99@outlook.com).
-  **Issues**: [GitHub Issues](https://github.com/tu-usuario/timely/issues).
-  **Discussions**: [GitHub Discussions](https://github.com/tu-usuario/timely/discussions).

---

<div align="center">

Hecho con 💙 y Flutter.

</div>
