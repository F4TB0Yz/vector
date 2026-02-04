Implementa **CÓMO** se obtienen y guardan los datos.

### DataSources (`datasources/`)

1. **JtAuthService** (`jt_auth_service.dart`):    
    - **Función**: Cliente HTTP responsable de comunicarse con la API de J&T.
    - **Endpoint**: `https://gw.jtexpress.co/bc/out/loginV2`
    - **Seguridad**:
        - Implementa hashing **MD5** para la contraseña antes del envío.
        - Simula headers de dispositivo (`Device-Id`, `Appid`, `Signature`, `User-Agent`) para replicar el comportamiento de la app oficial de J&T y evitar bloqueos.
    - **Manejo de Respuesta**: Valida que `code == 1` para considerar el login exitoso. Mapea el JSON de respuesta a una entidad `User`.
    
2. **AuthLocalDataSource** (`auth_local_datasource.dart`):
    - **Función**: Persistencia local en el dispositivo.
    - **Implementación**: Probablemente utiliza `SharedPreferences` o almacenamiento seguro.
    - **Datos**: Guarda el objeto `User` serializado y el token de sesión para mantener la sesión activa entre reinicios de la app.

### Implementación de Repositorio (`repositories/`)

- **AuthRepositoryImpl** (`auth_repository_impl.dart`):
    - Implementa `AuthRepository` de [[Capa de Dominio (Domain)]].
    - Orquesta la llamada a `JtAuthService` y, si es exitosa, guarda el resultado automáticamente en `AuthLocalDataSource`.
    - Transforma excepciones (Server Exception, Network Exception) en objetos `Failure` (Domain) usando `fpdart`.