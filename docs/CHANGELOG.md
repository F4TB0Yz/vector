# Changelog

## 2026-01-15

### `FEATURE` - Mejoras de UI Neon-Glassmorphism
- **UI**: Creado el widget `NeonButton`, un botón reutilizable con efecto de cristal y brillo neón, para estandarizar las acciones principales.
- **UI**: Refinado el `CustomTextField` para mejorar el efecto de brillo (`glow`) en los estados de foco y error, alineándose mejor con la skill de UI-Neon.
- **UI**: Actualizadas las pantallas `LoginPage` y `HomeScreen` para utilizar el nuevo `NeonButton`, reemplazando los botones estándar.

### `FIX` - Corregido el `AuthGuard` de GoRouter
- **Navigation**: Eliminada la llamada inicial a `notifyListeners()` en `GoRouterRefreshStream` para prevenir errores de inicialización y asegurar que la redirección se active únicamente por cambios de estado en `AuthBloc`.

### `FEATURE` - Navegación y Rutas Protegidas
- **Core**: Implementada la inyección de dependencias con `get_it` para registrar `SupabaseClient`, `AuthBloc` y todas las capas intermedias.
- **Navigation**: Configurado `GoRouter` con rutas para `/login` y `/home`. Se ha implementado un `AuthGuard` que redirige al login si el usuario no está autenticado, basándose en el estado de `AuthBloc`.
- **UI**: Creada una `LoginPage` y una `HomeScreen` básicas para probar el flujo de autenticación y navegación.
- **App**: Actualizado `main.dart` para inicializar dependencias y usar `MaterialApp.router`.

### `FIX` - Completada la lógica de `AuthBloc`
- **Domain**: Añadido `LogoutUseCase` y actualizado el `AuthRepository`.
- **Data**: Implementada la funcionalidad de `logout` en `SupabaseAuthDataSource` y `AuthRepositoryImpl`.
- **Presentation**: Actualizado `AuthBloc` para manejar el evento `LogoutRequested`, corrigiendo la implementación pendiente.

### `FEATURE` - Auth con Supabase (Data & Presentation)
- **Data**: Implementado `SupabaseAuthDataSource` para la comunicación con Supabase. Creado `AuthRepositoryImpl` que maneja las excepciones de Supabase y las convierte en `AuthFailure`. Añadido `UserModel` con mappers JSON.
- **Presentation**: Creado `AuthBloc` con los eventos `LoginRequested` y `LogoutRequested` y los estados correspondientes para gestionar el ciclo de vida de la autenticación.
- **Docs**: Verificado y confirmado el esquema de la tabla `profiles` en `DATABASE_SCHEMA.md`.

### `FEATURE` - Auth con Supabase
- **Domain**: Creada la entidad `UserEntity` y el contrato `AuthRepository`. Se define `AuthFailure` para un manejo de errores robusto con `fpdart`.
- **TDD**: Añadido el test unitario para `LoginUseCase` utilizando `mocktail`.
- **UI**: Implementado el widget `CustomTextField` con el estilo Neon-Glassmorphism, siguiendo las directrices de la skill UI-Neon.

### `INITIAL`
- **Proyecto Inicializado**: Se inicializa el proyecto VECTOR.
- **Arquitectura**: Se establece una arquitectura limpia (Clean Architecture) con un enfoque "Feature-First". La estructura de carpetas se divide en `domain`, `data` y `presentation` para cada funcionalidad.
- **Gestión de Estado**: Se selecciona `bloc` para el manejo de estado, `equatable` para la comparación de objetos.
- **Navegación**: Se utilizará `go_router` para la gestión de rutas.
- **Backend**: Se integra con Supabase para la base de datos y autenticación, y PowerSync para la sincronización de datos local-first.
- **Utilidades**: Se añaden `fpdart` para programación funcional y manejo de errores, `lucide_icons` para iconografía y `google_fonts` para tipografías.
- **Metodología**: Se adopta Test-Driven Development (TDD) como práctica estándar para todo el desarrollo de funcionalidades.
