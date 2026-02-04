---
tags:
  - Feature
---
#### **Este módulo gestiona la creación, selección y seguimiento de rutas de reparto**

[[Capa de Dominio (Domain)]]
[[Capa de Datos (Data)]]
[[Capa de Presentación (Presentation)]]

---

### Descripción General
El módulo **Routes** es el núcleo operativo de la jornada del repartidor. Gestiona el concepto de "Ruta" como una colección ordenada de paradas (`StopEntity`) asociadas a una fecha específica.

Es responsable de:
1.  **Agrupación**: Organizar paquetes en rutas lógicas (por día o zona).
2.  **Estado Global**: Mantener cuál es la "Ruta Activa" que se muestra en el Home y en el Mapa.
3.  **Progreso**: Calcular el porcentaje de completitud de la jornada.

### Estructura de Archivos
El módulo se encuentra en: `lib/features/routes/`

*   **`domain/`**:
    *   **`entities/`**: `RouteEntity`, `StopEntity`.
    *   **`usecases/`**: `CreateRoute`, `GetRoutes`, `AddStopToRoute`.
*   **`data/`**:
    *   **`datasources/`**: Persistencia local (Isar/Hive) de las rutas y preferencias.
*   **`presentation/`**:
    *   **`providers/`**: `RoutesProvider` (Logic central).
    *   **`screens/`**: Pantallas de historial y selección de rutas.

---

### Capa de Dominio (Domain)

#### Entidades Principales
*   **`RouteEntity`**:
    *   Representa una jornada de trabajo o lista de reparto.
    *   Propiedades: `id`, `name`, `date`, `progress` (0.0 - 1.0), `stops`.
    *   Calcula su estado (Activa, En espera, Completada) basado en el progreso.

*   **`StopEntity`**:
    *   Representa una parada individual dentro de una ruta.
    *   Contiene un `PackageEntity` (polimórfico).
    *   Propiedad `stopOrder` para definir la secuencia de entrega.

---

### Capa de Presentación (Presentation)

#### State Management (`RoutesProvider`)
El `RoutesProvider` es uno de los providers más críticos de la app.

*   **Selección de Ruta (`selectedRoute`)**:
    *   Mantiene la referencia a la ruta que el usuario está trabajando actualmente.
    *   Persiste la selección en preferencias locales para restaurarla al reiniciar la app (solo si es del día actual).
    
*   **Filtrado**:
    *   Permite filtrar rutas por estado (Activa, En espera).
    *   Permite filtrar paradas dentro de una ruta (Pendientes, Entregados, Fallidos).

*   **Optimistic UI**:
    *   Al agregar paradas (`addStop`) o cambiar estados de paquetes (`updatePackageStatus`), actualiza la UI inmediatamente antes de confirmar con la base de datos/API para una experiencia fluida.

---

### Relación con otros Módulos

*   **[[Home]]**: El Home escucha `RoutesProvider.selectedRoute` para mostrar la tarjeta de progreso y habilitar el escaneo.
*   **[[Packages]]**: Cuando se escanea un paquete, se convierte en un `StopEntity` y se agrega a la ruta activa gestionada por este módulo.
*   **[[Map]]**: El mapa dibuja las paradas de la `selectedRoute`.
