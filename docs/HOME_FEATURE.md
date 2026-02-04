# Documentación del Módulo de Inicio (Home Feature)

## Descripción General
El módulo **Home** funciona como el dashboard principal de la aplicación para los repartidores. Su objetivo es proporcionar un acceso rápido a la información más crítica: la ruta activa, el progreso de entrega, estadísticas de ganancias y acciones rápidas como escanear paquetes o crear nuevas rutas.

A diferencia de otros módulos como **Auth** o **Packages**, el módulo **Home** es principalmente una **capa de presentación** que orquesta y visualiza datos provenientes de otros módulos (`Routes`, `Packages`, `Map`).

## Estructura de Archivos
El módulo se encuentra en: `lib/features/home/`

*   **`presentation/`**: Contiene toda la lógica de UI y estado específica del dashboard.
    *   **`screens/`**: Pantallas principales (`home_screen.dart`).
    *   **`providers/`**: Lógica de estado y comunicación con casos de uso (`home_provider.dart`).
    *   **`widgets/`**: Componentes reutilizables específicos del Home (`active_route_card.dart`, `home_stats_widget.dart`, etc.).

---

## Capa de Presentación (Presentation)

### State Management (`providers/`)
*   **`HomeProvider`** (`home_provider.dart`):
    *   Actúa como un **facade** o intermediario para acciones específicas del Home que requieren persistencia.
    *   **Función Principal**: `savePackageToRoute({required String routeId, required StopEntity stop})`.
    *   **Dependencia**: Utiliza el caso de uso `AddStopToRoute` (del módulo de Rutas) para persistir nuevos paquetes escaneados directamente a la ruta activa.
    *   Gestiona errores y excepciones durante el guardado.

### UI Principal (`home_screen.dart`)
La pantalla `HomeScreen` es el punto de entrada. Sus responsabilidades incluyen:
1.  **Verificación de Ruta**: Comprueba si hay una ruta seleccionada en `RoutesProvider`.
2.  **Escaneo de Paquetes**:
    *   Abre el scanner (`SharedScannerScreen`).
    *   Si se detecta un código, busca si el paquete ya existe en la lista de J&T (`PackagesProvider`).
    *   Muestra el diálogo de detalles (`AddPackageDetailsDialog`) para confirmar/editar información.
    *   **Optimistic UI**: Actualiza la interfaz inmediatamente al guardar, antes de confirmar con la base de datos, para una experiencia fluida.
3.  **Migración (Temporal)**: Incluye un acceso a `StopOrderMigrationDialog` para corregir el orden de las paradas.

### Widgets Clave (`widgets/`)
*   **`ActiveRouteCard`**:
    *   Tarjeta visual prominente que muestra la "Ruta Activa".
    *   Muestra el nombre de la ruta (o fecha) y el progreso visual (barra de progreso y contadores de entregados/total).
    *   Integra `NextStopInfo` para mostrar el siguiente destino inmediato.
*   **`HomeStatsWidget`**:
    *   Calcula y visualiza ganancias estimadas basadas en paquetes entregados.
    *   Permite al usuario configurar el "Precio por Paquete" tocando la tarjeta de ganancias.
    *   Muestra un cronómetro de tiempo transcurrido desde el inicio de la ruta (`_RouteTimeCard`).
*   **`HomeActionButtons`**:
    *   Botones de acceso rápido para "Escanear Paquete" y "Nueva Ruta".

---

## Dependencias e Integraciones
El módulo Home depende fuertemente de otros módulos:

*   **Features/Routes**:
    *   Consume `RoutesProvider` para obtener la `selectedRoute`.
    *   Usa `RouteEntity` y `StopEntity`.
    *   Usa el caso de uso `AddStopToRoute`.
*   **Features/Packages**:
    *   Consume `PackagesProvider` para pre-llenar datos de paquetes J&T al escanear.
    *   Usa `JTPackage`, `ManualPackageEntity`.
*   **Shared**:
    *   Usa `SharedScannerScreen` para la funcionalidad de cámara.

## Flujo de Trabajo: Agregar Paquete Manualmente
1.  Usuario toca **"Escanear Paquete"** en el Home.
2.  Se abre la cámara (`SharedScannerScreen`).
3.  Al detectar un QR/Barcode:
    *   Se cierra el scanner.
    *   Se busca el código en la lista de paquetes importados (J&T).
4.  Se muestra el formulario **Detalles del Paquete**.
5.  Al guardar:
    *   Se crea un `StopEntity` con un `ManualPackageEntity`.
    *   **UI Update**: Se agrega a la lista local de paradas en `RoutesProvider` (feedback inmediato).
    *   **Persistencia**: `HomeProvider` llama al caso de uso para guardar en base de datos en segundo plano.
    *   Si falla la persistencia, se revierte el cambio en la UI y se notifica el error.
