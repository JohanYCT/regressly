# Regressly

**Analítica Predictiva Offline para Productores Lecheros**

Una aplicación móvil multiplataforma desarrollada con Flutter que permite a los productores lecheros registrar, gestionar y analizar la producción de leche de sus fincas de forma offline.

## 📋 Descripción

Regressly es una herramienta diseñada para productores lecheros que necesitan:

- **Registrar producción diaria** de leche (mañana y tarde)
- **Gestionar múltiples fincas** con sus datos y ubicaciones
- **Visualizar tendencias** mediante gráficas analíticas
- **Trabajar sin conexión** a internet (funcionalidad offline)
- **Configurar parámetros** específicos de sus operaciones

## ✨ Características

- ✅ Registro de producción de leche por turno (mañana/tarde)
- ✅ Gestión de múltiples fincas
- ✅ Base de datos local con SQLite
- ✅ Gráficas interactivas para visualizar datos
- ✅ Funcionalidad completamente offline
- ✅ Interfaz intuitiva y fácil de usar
- ✅ Cálculo automático de producción total

## 🛠️ Tecnologías

- **Framework**: Flutter 3.0+
- **Base de datos**: SQLite (sqflite)
- **Gráficas**: fl_chart
- **Plataformas**: Android, iOS, Web, Linux, Windows, macOS

## 🚀 Requisitos

- Flutter SDK 3.0.0 o superior
- Dart 3.0.0 o superior
- Android SDK (para Android)
- Xcode (para iOS)

## � Versión Beta

La versión beta de Regressly ya está disponible para descarga directa desde GitHub Releases.

👉 [Descargar versión beta](https://github.com/JohanYCT/regressly/releases/latest/download/regressly-beta.apk)

## �📦 Instalación

1. Clona el repositorio:
```bash
git clone <repository-url>
cd regressly
```

2. Obtén las dependencias:
```bash
flutter pub get
```

3. Ejecuta la aplicación:
```bash
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada de la aplicación
├── app_theme.dart              # Tema y estilos globales
├── models/
│   ├── finca_model.dart         # Modelo de datos de fincas
│   └── registro_model.dart      # Modelo de registros de producción
├── screens/
│   ├── home_screen.dart         # Pantalla principal
│   ├── registro_screen.dart     # Pantalla de registro de producción
│   ├── graficas_screen.dart     # Pantalla de gráficas
│   └── configuracion_screen.dart # Pantalla de configuración
├── database/
│   └── database_helper.dart     # Gestión de la base de datos SQLite
└── services/
    └── analytics_service.dart   # Servicios de análisis de datos
```

## 💡 Uso

1. **Crear una finca**: Configura los datos de tu finca (nombre, ubicación, número de vacas, precio por litro)
2. **Registrar producción**: Ingresa los litros de leche obtenidos cada mañana y tarde
3. **Ver gráficas**: Visualiza las tendencias de producción en gráficas interactivas
4. **Configurar parámetros**: Ajusta los valores según tus necesidades

## 📝 Licencia

Este proyecto es parte de un trabajo académico.

## 📧 Contacto

Para preguntas o sugerencias, contacta al equipo de desarrollo.
