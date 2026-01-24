# Plan de Migración: Riverpod a Provider (Feature Map)

Este documento detalla los pasos para migrar la gestión de estado e inyección de dependencias de la feature `map` de **Riverpod** a **Provider**.

## 🎯 Objetivo
Desacoplar la lógica interna del mapa de `flutter_riverpod` y utilizar `provider` y `ChangeNotifier` estándar, manteniendo la compatibilidad con el resto de la app.

## 📦 Estructura de Archivos Afectada

| Archivo | Cambio Requerido |
|---------|------------------|
| `map_injection.dart` | **Refactor total**. Convertir definiciones globales a un `MapDependencies` widget o lista de providers. |
| `map_provider.dart` | **Refactor**. `MapNotifier` extiende `ChangeNotifier`. Inyección por constructor. |
| `map_screen.dart` | **Refactor**. Implementar patrón "Bridge" para recibir datos externos de Riverpod y levantar el Scope de Provider. |
| `widgets/*.dart` | **Update**. Reemplazar `ConsumerWidget` y `ref` por `context.watch/read`. |

## 🚀 Pasos de Implementación

### Paso 1: Refactorizar `MapNotifier` (`map_provider.dart`)
1.  Cambiar `Notifier<MapState>` a `ChangeNotifier`.
2.  Definir `MapState _state` como propiedad privada y exponer un getter `state`.
3.  Crear un constructor que reciba todas las dependencias necesarias:
    *   `MapRepository`
    *   `GeocodingRepository` (para `ReverseGeocode`)
    *   `CreateStopFromCoordinates` (UseCase)
    *   `CreateStop` (UseCase)
    *   Etc.
4.  Reemplazar `state = ...` con `_state = ...; notifyListeners();`.

### Paso 2: Crear Configuración de Dependencias (`map_injection.dart`)
1.  Crear una clase o función que retorne la lista de `SingleChildWidget` para un `MultiProvider`.
2.  Configurar la cadena de dependencias:
    *   `Provider<DatabaseService>`
    *   `ProxyProvider<DatabaseService, MapDataSource>`
    *   `Provider<RouteRemoteDataSource>`
    *   `ProxyProvider2<..., MapRepository>`
    *   `ProxyProvider<MapRepository, GetActiveRoute>` (UseCases)
    *   `ChangeNotifierProxyProvider<Dependencies, MapNotifier>` (El Notifier consume los UseCases).

### Paso 3: Refactorizar `MapScreen` (`map_screen.dart`)
1.  **MapScreenBridge**: Widget que mantiene `ConsumerStatefulWidget` de Riverpod.
    *   Escucha `selectedRouteProvider` (Riverpod).
    *   Renderiza `MapFeatureScope`.
2.  **MapFeatureScope**: Widget que implementa `MultiProvider` con las dependencias del Paso 2.
    *   Pasa el `selectedRoute` al `MapNotifier` (mediante un `update` en el ProxyProvider o un setter en el `Init` del widget).
    *   Renderiza `MapScreenContent`.
3.  **MapScreenContent**: La UI actual de `MapScreen` pero sin referencias a Riverpod.
    *   Usa `context.read<MapNotifier>()` para eventos.
    *   Usa `context.watch<MapNotifier>()` para reconstruir UI.

### Paso 4: Actualizar Widgets Hijos
Actualizar los siguientes widgets para usar `provider`:
- `ConfirmAddStopDialog`
- `MapControlsColumn`
- `NextStopPageView` (si accede al provider)

### Paso 5: Limpieza
- Eliminar imports de `flutter_riverpod` en `lib/features/map/**`.
- Verificar que la navegación y el paso de datos entre `Routes` (Riverpod) y `Map` (Provider) funciona correctamente.

## ⚠️ Consideraciones
- **Routes Provider**: La feature `map` depende de `selectedRouteProvider` que vive en `features/routes`. El "Bridge" en `MapScreen` es crucial para sincronizar el estado entre los dos gestores.
- **Context**: Asegurar que los diálogos (`showDialog`) se invoquen con un contexto que tenga acceso a los Providers (usar `Builder` si es necesario o el contexto hijo de `MapScreenContent`).

