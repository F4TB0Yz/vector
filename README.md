# Vector - App de Delivery

Aplicación de delivery construida con Flutter siguiendo Clean Architecture.

## 🚀 Configuración Inicial

### 1. Clonar el repositorio

```bash
git clone <repository-url>
cd vector
```

### 2. Configurar Variables de Entorno

Copia el archivo `.env.example` a `.env`:

```bash
cp .env.example .env
```

Luego edita el archivo `.env` con tus credenciales reales:

```env
# Supabase Configuration
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui

# Mapbox Configuration
MAPBOX_ACCESS_TOKEN=tu_mapbox_token_aqui
```

### 3. Instalar Dependencias

```bash
flutter pub get
```

### 4. Ejecutar la Aplicación

```bash
flutter run
```

## 📁 Estructura del Proyecto

El proyecto sigue Clean Architecture con la siguiente estructura:

```
lib/
├── src/
│   ├── core/                 # Funcionalidades compartidas
│   │   ├── config/          # Configuraciones (EnvConfig)
│   │   ├── router/          # Navegación (GoRouter)
│   │   └── service_locator/ # Inyección de dependencias (GetIt)
│   └── features/            # Features por módulo
│       └── auth/            # Módulo de autenticación
│           ├── domain/      # Entidades y casos de uso
│           ├── data/        # Implementaciones y fuentes de datos
│           └── presentation/# UI y estado (BLoC)
└── main.dart
```

## 🔐 Seguridad

- **NUNCA** subas el archivo `.env` al repositorio
- El archivo `.env` está incluido en `.gitignore`
- Usa `.env.example` como plantilla para otros desarrolladores

## 🛠️ Tecnologías

- **Flutter** - Framework de UI
- **Supabase** - Backend y autenticación
- **GetIt** - Inyección de dependencias
- **BLoC** - Gestión de estado
- **GoRouter** - Navegación
- **flutter_dotenv** - Variables de entorno

## 📝 Notas

- Asegúrate de tener configuradas las credenciales de Supabase antes de ejecutar la app
- El token de Mapbox será necesario cuando se implemente la funcionalidad de mapas
