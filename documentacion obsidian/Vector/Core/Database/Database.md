---
tags:
  - Core
---
# Base de Datos y Persistencia

### Estrategia: Local-First
La aplicación sigue una arquitectura **Local-First**, lo que significa que todas las lecturas y escrituras ocurren primariamente en una base de datos local en el dispositivo del usuario. Esto garantiza que la app funcione perfectamente sin conexión a internet (Offline-First).

### Tecnologías

#### 1. PowerSync + Supabase (Sincronización)
*   **Supabase (PostgreSQL)**: Actúa como la fuente de verdad en la nube. Almacena todos los datos de usuarios, rutas, paquetes y trazas de auditoría.
*   **PowerSync**: Es el motor de sincronización bidireccional. Mantiene una réplica local de SQLite en el dispositivo que se sincroniza automáticamente con Supabase cuando hay conexión.

#### 2. Almacenamiento Key-Value (Preferencias)
*   Para configuraciones simples, tokens de sesión y estados de UI efímeros (como la selección de la última ruta), se utiliza un almacenamiento ligero (como `SharedPreferences` o `Hive`).

### Modelado de Datos
Las entidades principales se definen en la Capa de Datos (`data/models`) y se mapean tanto a las tablas de SQLite (para PowerSync) como a los objetos de dominio.

*   **Rutas**: Almacenadas localmente para acceso rápido.
*   **Paquetes**: Sincronizados con J&T y enriquecidos localmente (fotos, firmas).
