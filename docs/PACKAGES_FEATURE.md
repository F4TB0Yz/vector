# Documentación del Módulo de Paquetes (Packages Feature)

## Descripción General
El módulo **Packages** gestiona la información detallada de los envíos. Su rol es dual:
1.  **Fuente de Datos**: Actúa como puente con el sistema externo de J&T para importar paquetes asignados al repartidor.
2.  **Gestión de Entidades**: Define las estructuras de datos fundamentales (`PackageEntity`, `JTPackage`, `ManualPackageEntity`) que son utilizadas por otros módulos como **Routes** y **Map**.

Aunque la visualización principal de "paradas" ocurre en el contexto de una Rutas, el módulo Packages provee las herramientas para crear, importar y corregir la información de los paquetes individuales.

## Estructura de Archivos
El módulo se encuentra en: `lib/features/packages/`

*   **`domain/`**:
    *   **`entities/`**: Definiciones base del negocio (`package_entity.dart`).
    *   **`usecases/`**: Lógica de negocio atómica (`update_package_coordinates.dart`).
*   **`data/`**:
    *   **`repositories/`**: Implementación de la comunicación con APIs externas (J&T).
*   **`presentation/`**:
    *   **`screens/`**: Pantalla de listado y gestión (`packages_screen.dart`).
    *   **`providers/`**: Lógica de importación y estado (`jt_package_providers.dart`).
    *   **`widgets/`**: Componentes visuales de las tarjetas de paquete.

---

## Capa de Dominio (Domain)

### Entidades (`entities/`)
El sistema utiliza un diseño polimórfico para manejar diferentes orígenes de datos:

*   **`PackageEntity`** (Abstract): Clase base que define los campos comunes (ID, receptor, dirección, teléfono, coordenadas, estado).
*   **`JTPackage`**: Extiende `PackageEntity`. Representa paquetes importados del sistema J&T. Incluye campos extra como `waybillNo`, `taskStatus`, `scanTime`, etc.
*   **`ManualPackageEntity`**: Extiende `PackageEntity`. Representa paquetes ingresados manualmente por el repartidor (ej. recogidas no registradas o errores de sistema).

### Casos de Uso (`usecases/`)
*   **`UpdatePackageCoordinates`**:
    *   Permite corregir o asignar coordenadas GPS a un paquete.
    *   **Validación**: Incluye lógica para asegurar que las coordenadas estén dentro del área operativa (Fusagasugá).

---

## Capa de Presentación (Presentation)

### State Management (`providers/`)
*   **`PackagesProvider`** (`jt_package_providers.dart`):
    *   Encargado de **Importar Paquetes** desde el repositorio de J&T.
    *   **Integración con Routes**: No solo descarga los datos, sino que automáticamente los convierte en `StopEntity` y trata de agregarlos a la ruta actualmente seleccionada en `RoutesProvider`.
    *   Maneja errores de sesión (token vencido).

### UI Principal (`packages_screen.dart`)
Esta pantalla es híbrida: visualmente pertenece a "Paquetes", pero funcionalmente muestra el contenido de la **Ruta Activa**.

1.  **Visualización**:
    *   Consume `RoutesProvider` para listar las paradas (`StopEntity`).
    *   Permite filtrar y cambiar entre vista de lista (`PackageCard`) o cuadrícula comprimida.
2.  **Acciones**:
    *   **Escanear/Agregar**: Usa `FloatingScanButton` para abrir el scanner.
    *   **Asignar Coordenadas**: Permite abrir el mapa para fijar la ubicación de un paquete sin coordenadas.
    *   **Cambio de Estado**: Permite marcar como `Delivered` o `Failed` (delegando la acción a `RoutesProvider`).

---

## Flujos Clave

### 1. Importación masiva (Desde J&T)
1.  El usuario solicita "Importar Paquetes" (generalmente desde Home o al inicio).
2.  `PackagesProvider` llama a `JTPackageRepository.getJTPackages()`.
3.  Si la API responde exitosamente:
    *   Se obtiene una lista de `JTPackage`.
    *   Se itera sobre la lista y se convierte cada paquete en un `StopEntity`.
    *   Se invoca el caso de uso `AddStopToRoute` para persistirlos en la base de datos local asociada a la ruta actual.

### 2. Creación Manual (Scanner)
1.  Usuario abre scanner en `packages_screen.dart`.
2.  Al detectar un código:
    *   El sistema intenta buscar si ya existe en la memoria de paquetes J&T descargados (para pre-llenar datos).
    *   Abre `AddPackageDetailsDialog` para confirmar datos.
3.  Al guardar:
    *   Crea un `ManualPackageEntity`.
    *   Lo agrega inmediatamente a la ruta activa mediante `RoutesProvider.addStop()`.

### 3. Corrección de Coordenadas
1.  Si un paquete no tiene coordenadas, aparece un botón "Asignar Ubicación".
2.  Se abre `CoordinateAssignmentScreen` (mapa).
3.  Al confirmar la ubicación, se invoca `UpdatePackageCoordinates`.
4.  Esto actualiza la entidad del paquete y permite que sea visible en el módulo de Mapas.

---

## Relación con otros Módulos

*   **Routes**: Packages es un "proveedor" de datos para Routes. Una vez un paquete es parte de una ruta (convertido en `StopEntity`), su ciclo de vida (Estado: Pendiente -> Entregado) se gestiona principalmente a través de la lógica de Routes.
*   **Map**: Los paquetes solo aparecen en el mapa si tienen coordenadas válidas (`Position`). El módulo Packages provee la herramienta para arreglar esto.
