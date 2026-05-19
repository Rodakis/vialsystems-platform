# VialSystems

VialSystems es una aplicación móvil diseñada para la gestión de acarreo de materiales, reportes diarios y control de obras.

## Arquitectura y Estructura de Carpetas

Este proyecto utiliza una arquitectura limpia basada en "Features" (características):

```
lib/
├── core/             # Código base, utilidades genéricas, temas, constantes
├── features/         # Módulos de la aplicación (ej. home, auth, acarreo)
│   └── home/         # Pantalla principal placeholder
├── shared/           # Widgets reutilizables, modelos comunes
└── main.dart         # Punto de entrada principal
```

## Convenciones de Nombres

- **Archivos y Carpetas**: `snake_case` (ej. `home_screen.dart`, `user_model.dart`).
- **Clases y Enums**: `PascalCase` (ej. `HomeScreen`, `UserModel`).
- **Variables y Funciones**: `camelCase` (ej. `userName`, `getUserData()`).
- **Constantes**: `camelCase` o `SCREAMING_SNAKE_CASE` dependiendo del contexto (preferible `camelCase` por la guía de estilo oficial de Dart para constantes).

## Fase 00

Esta versión inicial (Fase 00) contiene únicamente:
- Estructura limpia de carpetas.
- Configuración inicial de la aplicación Android.
- Pantalla placeholder inicial.
- Este README con las reglas base.

No incluye ninguna funcionalidad de lógica de negocio, bases de datos o servicios externos aún.
