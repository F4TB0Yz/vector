---
tags:
  - Feature
---
#### **Este módulo gestiona la visualización geográfica, navegación y seguimiento en tiempo real**

[[Capa de Dominio (Domain)]]
[[Capa de Datos (Data)]]
[[Capa de Presentación (Presentation)]]

---

### Descripción General
El módulo **Map** proporciona la interfaz visual principal para la navegación del repartidor. Utiliza **Mapbox** para renderizar mapas vectoriales oscuros (Neon Style) y superponer la información de la ruta activa.

Sus responsabilidades incluyen:
1.  **Renderizado**: Mostrar el mapa base y los elementos de la ruta (marcadores, polilíneas).
2.  **Interacción**: Permitir al usuario explorar la ruta, seleccionar paradas y confirmar entregas.
3.  **Geolocalización**: Seguimiento de la ubicación del usuario en tiempo real.

### Estructura de Archivos
El módulo se encuentra en: `lib/features/map/`

*   **`domain/`**:
    *   **`entities/`**: `GeoLocation`, `MapMarker`.
*   **`presentation/`**:
    *   **`screens/`**:
        *   `map_screen.dart`: Pantalla principal del mapa.
        *   `coordinate_assignment_screen.dart`: Selector de ubicación para paquetes sin GPS.
    *   **`providers/`**: `MapProvider` (Controlador del mapa Mapbox).
    *   **`widgets/`**:
        *   `MapControlsColumn`: Botones flotantes (centrar, capas).
        *   `NextStopCard`: Tarjeta inferior con info de la siguiente parada.
        *   `PackageListOverlay`: Lista desplegable rápida de paquetes.

---

### Características Clave

#### Integración con Mapbox (`MapProvider`)
*   Se utiliza `mapbox_maps_flutter` para el rendering nativo.
*   **Estilo**: Se usa un estilo personalizado "Dark/Neon" para coincidir con la estética de la app (Vector Dashboard).
*   **Gestión de Marcadores**: 
    *   Los marcadores no son widgets de Flutter estándar, sino anotaciones nativas de Mapbox para máximo rendimiento.
    *   Se diferencian por color según el estado del paquete (Pendiente: Azul/Neon, Entregado: Verde, Fallido: Rojo).

#### Navegación y UX (`MapScreen`)
*   **Next Stop Card**: Un panel deslizante en la parte inferior que muestra siempre el *siguiente* destino sugerido. Permite acciones rápidas como "Navegar" (abrir Waze/Google Maps) o "Confirmar Entrega".
*   **Package List Overlay**: Permite ver la lista completa de paradas sin salir del contexto del mapa.
*   **Interacciones**:
    *   **Tap**: Selecciona una parada y muestra detalles (`PackageDetailsDialog`).
    *   **Long Press**: Permite acciones contextuales (como crear una parada manual en ese punto).

#### Optimización de Ruta
*   El módulo incluye lógica (oa integración con servicios) para calcular el orden óptimo de las paradas, dibujando una `Polyline` que conecta los puntos en el orden sugerido.

---

### Relación con otros Módulos

*   **[[Routes]]**: El mapa *observa* activamente a `RoutesProvider`. Cuando cambia la `selectedRoute` o el estado de un paquete, el mapa se repinta o actualiza sus marcadores automáticamente.
*   **[[Packages]]**: Al tocar un marcador, se muestra la información detallada del `PackageEntity` asociado.
