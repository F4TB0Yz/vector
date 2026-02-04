Define **QUÉ** hace el sistema, independientemente de **CÓMO** se implemente.

### Entidades (`entities/`)

- **`User`** (`user.dart`): Objeto inmutable que representa al usuario autenticado. Contiene información crítica retornada por J&T:
    - `token`: Token de sesión utilizado para peticiones autenticadas.
    - `staffNo`: Número de empleado.
    - `networkCode` / `networkName`: Identificación de la sucursal o red.
    - `role` / `postName`: Cargo del usuario.

### Interfaces de Repositorio (`repositories/`)

- **`AuthRepository`** (`auth_repository.dart`): Contrato abstracto que debe cumplir la capa de datos. Define operaciones como:
    - `Future<Either<Failure, User>> login({required String account, required String password})`
    - `Future<void> logout()`
    - `Future<Option<User>> getCurrentUser()`

### Casos de Uso (`usecases/`)

Encapsulan reglas de negocio específicas y orquestan el flujo de datos hacia el repositorio.

- **`LoginUseCase`**: Ejecuta la lógica de inicio de sesión.
- **`GetSavedCredentials`**: Recupera credenciales almacenadas localmente para "Recordarme".
- **`SaveCredentials`**: Guarda credenciales de forma segura.