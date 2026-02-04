# Documentación del Módulo de Autenticación (Auth Feature)

## Descripción General
Este módulo gestiona la autenticación de usuarios contra los servicios de **J&T Express**. Sigue estrictamente los principios de **Clean Architecture**, dividiendo la lógica en capas de **Domain** (Dominio), **Data** (Datos) y **Presentation** (Presentación), asegurando desacoplamiento y testabilidad.

## Estructura de Archivos
El módulo se encuentra en: `lib/features/auth/`

*   **`domain/`**: Núcleo de la lógica de negocio. No depende de implementaciones externas.
*   **`data/`**: Implementación técnica (API Calls, Base de Datos local).
*   **`presentation/`**: Gestión de estado y componentes visuales (UI).

---

## 1. Capa de Dominio (Domain)
Define **QUÉ** hace el sistema, independientemente de **CÓMO** se implemente.

### Entidades (`entities/`)
*   **`User`** (`user.dart`): Objeto inmutable que representa al usuario autenticado. Contiene información crítica retornada por J&T:
    *   `token`: Token de sesión utilizado para peticiones autenticadas.
    *   `staffNo`: Número de empleado.
    *   `networkCode` / `networkName`: Identificación de la sucursal o red.
    *   `role` / `postName`: Cargo del usuario.

### Interfaces de Repositorio (`repositories/`)
*   **`AuthRepository`** (`auth_repository.dart`): Contrato abstracto que debe cumplir la capa de datos. Define operaciones como:
    *   `Future<Either<Failure, User>> login({required String account, required String password})`
    *   `Future<void> logout()`
    *   `Future<Option<User>> getCurrentUser()`

### Casos de Uso (`usecases/`)
Encapsulan reglas de negocio específicas y orquestan el flujo de datos hacia el repositorio.
*   **`LoginUseCase`**: Ejecuta la lógica de inicio de sesión.
*   **`GetSavedCredentials`**: Recupera credenciales almacenadas localmente para "Recordarme".
*   **`SaveCredentials`**: Guarda credenciales de forma segura.

---

## 2. Capa de Datos (Data)
Implementa **CÓMO** se obtienen y guardan los datos.

### DataSources (`datasources/`)
1.  **`JtAuthService`** (`jt_auth_service.dart`):
    *   **Función**: Cliente HTTP responsable de comunicarse con la API de J&T.
    *   **Endpoint**: `https://gw.jtexpress.co/bc/out/loginV2`
    *   **Seguridad**:
        *   Implementa hashing **MD5** para la contraseña antes del envío.
        *   Simula headers de dispositivo (`Device-Id`, `Appid`, `Signature`, `User-Agent`) para replicar el comportamiento de la app oficial de J&T y evitar bloqueos.
    *   **Manejo de Respuesta**: Valida que `code == 1` para considerar el login exitoso. Mapea el JSON de respuesta a una entidad `User`.

2.  **`AuthLocalDataSource`** (`auth_local_datasource.dart`):
    *   **Función**: Persistencia local en el dispositivo.
    *   **Implementación**: Probablemente utiliza `SharedPreferences` o almacenamiento seguro.
    *   **Datos**: Guarda el objeto `User` serializado y el token de sesión para mantener la sesión activa entre reinicios de la app.

### Implementación de Repositorio (`repositories/`)
*   **`AuthRepositoryImpl`** (`auth_repository_impl.dart`):
    *   Implementa `AuthRepository`.
    *   Orquesta la llamada a `JtAuthService` y, si es exitosa, guarda el resultado automáticamente en `AuthLocalDataSource`.
    *   Transforma excepciones (Server Exception, Network Exception) en objetos `Failure` (Domain) usando `fpdart`.

---

## 3. Capa de Presentación (Presentation)
Maneja la interacción con el usuario.

### State Management (`providers/`)
*   **`AuthProvider`** (`auth_provider.dart`):
    *   Utiliza `ChangeNotifier` (o Bloc/Riverpod según implementación) para exponer el estado de la autenticación a la UI.
    *   Estados: `Initial`, `Loading`, `Authenticated`, `Unauthenticated`, `Error`.
    *   Métodos públicos: `login()`, `logout()`, `checkAuthStatus()`.

### UI (`widgets/`)
*   **`JtLoginDialog`**: Componente visual que solicita `account` y `password`. Invoca a `AuthProvider.login()`.

---

## Flujo de Ejecución: Login

1.  **Usuario** ingresa credenciales en la UI.
2.  **`AuthProvider`** invoca `LoginUseCase.call()`.
3.  **`LoginUseCase`** invoca `AuthRepository.login()`.
4.  **`AuthRepositoryImpl`** llama a `JtAuthService.login()`.
5.  **`JtAuthService`**:
    *   Genera hash MD5 del password.
    *   Construye headers de simulación.
    *   Envía POST request a J&T.
6.  **J&T API** responde con JSON.
7.  **`JtAuthService`** convierte JSON a `User` entity.
8.  **`AuthRepositoryImpl`**:
    *   Recibe `User`.
    *   Llama a `AuthLocalDataSource.saveUser(user)`.
    *   Retorna `Right(User)`.
9.  **`AuthProvider`** recibe el resultado, actualiza el estado a `Authenticated` y notifica a la UI para navegar al Home.
