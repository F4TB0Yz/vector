Maneja la interacción con el usuario.
### State Management (`providers/`)

- **`AuthProvider`** (`auth_provider.dart`):
    - Utiliza `ChangeNotifier` (o Bloc/Riverpod según implementación) para exponer el estado de la autenticación a la UI.
    - Estados: `Initial`, `Loading`, `Authenticated`, `Unauthenticated`, `Error`.
    - Métodos públicos: `login()`, `logout()`, `checkAuthStatus()`.

### UI (`widgets/`)

- **`JtLoginDialog`**: Componente visual que solicita `account` y `password`. Invoca a `AuthProvider.login()`.

---

## Flujo de Ejecución: Login

1. **Usuario** ingresa credenciales en la UI.
2. **`AuthProvider`** invoca `LoginUseCase.call()`.
3. **`LoginUseCase`** invoca `AuthRepository.login()` de [[Capa de Datos (Data)]].
4. **`AuthRepositoryImpl`** llama a `JtAuthService.login()`.
5. **`JtAuthService`**:
    - Genera hash MD5 del password.
    - Construye headers de simulación.
    - Envía POST request a J&T.
6. **J&T API** responde con JSON.
7. **`JtAuthService`** convierte JSON a `User` entity.
8. **`AuthRepositoryImpl`**:
    - Recibe `User`.
    - Llama a `AuthLocalDataSource.saveUser(user)`. 
    - Retorna `Right(User)`.
9. **`AuthProvider`** recibe el resultado, actualiza el estado a `Authenticated` y notifica a la UI para navegar al Home.