# Esquema de Base de Datos (SQL)

Este documento define el esquema de la base de datos PostgreSQL en Supabase.

---

## Tabla: `profiles`
Almacena información pública de los usuarios.

```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Políticas de RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los usuarios pueden ver todos los perfiles"
ON public.profiles FOR SELECT
USING (true);

CREATE POLICY "Los usuarios pueden insertar su propio perfil"
ON public.profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Los usuarios pueden actualizar su propio perfil"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);
```

---

## Tabla: `routes`
Contiene las rutas de entrega asignadas a los repartidores.

```sql
CREATE TABLE public.routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, in_progress, completed, cancelled
  date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Políticas de RLS
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los repartidores pueden ver sus propias rutas"
ON public.routes FOR SELECT
USING (auth.uid() = driver_id);

CREATE POLICY "Los repartidores pueden actualizar sus propias rutas"
ON public.routes FOR UPDATE
USING (auth.uid() = driver_id);
```

---

## Tabla: `packages`
Define los paquetes que deben ser entregados en cada ruta.

```sql
CREATE TABLE public.packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  tracking_number TEXT UNIQUE NOT NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT,
  address TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, delivered, failed
  delivery_attempts INT DEFAULT 0,
  photo_url TEXT,
  recipient_name TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Políticas de RLS
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Los repartidores pueden ver los paquetes de sus rutas"
ON public.packages FOR SELECT
USING (
  route_id IN (
    SELECT id FROM public.routes WHERE driver_id = auth.uid()
  )
);

CREATE POLICY "Los repartidores pueden insertar paquetes en sus rutas"
ON public.packages FOR INSERT
WITH CHECK (
  route_id IN (
    SELECT id FROM public.routes WHERE driver_id = auth.uid()
  )
);

CREATE POLICY "Los repartidores pueden actualizar los paquetes de sus rutas"
ON public.packages FOR UPDATE
USING (
  route_id IN (
    SELECT id FROM public.routes WHERE driver_id = auth.uid()
  )
);

-- Índices para optimización
CREATE INDEX idx_packages_route_id ON public.packages(route_id);
CREATE INDEX idx_packages_status ON public.packages(status);

```
