-- ==================================================================================
-- CREACIÓN DE TABLA DE PERFILES (PROFILES) Y ASIGNACIÓN DE ROLES (FASE 11B)
-- ==================================================================================
-- Proyecto: VialSystems
-- Objetivo: Vincular los usuarios de Supabase Auth con roles de negocio y estado activo/inactivo.
-- ==================================================================================

-- 1. CREACIÓN DE LA TABLA DE PERFILES
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'user', 'oficina')),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. HABILITAR SEGURIDAD RLS (ROW LEVEL SECURITY)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. CREACIÓN DE POLÍTICAS DE ACCESO SEGURO RLS

-- A. Lectura permitida para cualquier usuario autenticado sobre su propio perfil
DROP POLICY IF EXISTS "Usuarios pueden ver su propio perfil" ON public.profiles;
CREATE POLICY "Usuarios pueden ver su propio perfil" 
ON public.profiles FOR SELECT 
TO authenticated 
USING (auth.uid() = id);

-- B. Lectura general permitida a administradores sobre todos los perfiles
DROP POLICY IF EXISTS "Administradores pueden ver todos los perfiles" ON public.profiles;
CREATE POLICY "Administradores pueden ver todos los perfiles" 
ON public.profiles FOR SELECT 
TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE public.profiles.id = auth.uid() 
          AND public.profiles.role = 'admin'
    )
);

-- C. Escritura y administración de perfiles reservada exclusivamente para administradores
DROP POLICY IF EXISTS "Administración exclusiva de perfiles para admins" ON public.profiles;
CREATE POLICY "Administración exclusiva de perfiles para admins" 
ON public.profiles FOR ALL 
TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE public.profiles.id = auth.uid() 
          AND public.profiles.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE public.profiles.id = auth.uid() 
          AND public.profiles.role = 'admin'
    )
);

-- 4. FUNCIÓN TRIGGER AUTOMÁTICA (OPCIONAL)
-- Esta función crea automáticamente un perfil básico de tipo 'user' al registrar un
-- nuevo usuario mediante Supabase Auth.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nombre, role, activo)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    'user',
    true
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crear el trigger en auth.users
-- (Descomentar para habilitar creación automática al registrarse desde el SDK)
-- DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
-- CREATE TRIGGER on_auth_user_created
--   AFTER INSERT ON auth.users
--   FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==================================================================================
-- 5. USUARIOS SEMILLA / EJEMPLOS DE TESTING
-- ==================================================================================
-- Nota: Para registrar los usuarios semilla en Supabase Auth, primero debes crearlos
-- en el módulo "Authentication" de tu panel de control de Supabase con password "123".
-- Una vez creados en Auth, ejecuta las siguientes inserciones reemplazando el UUID
-- de ejemplo por los UUID reales asignados por Supabase.
-- ==================================================================================

-- INSERT INTO public.profiles (id, email, nombre, role, activo)
-- VALUES 
--     ('REEMPLAZAR_CON_UUID_DE_admin@test.com', 'admin@test.com', 'Administrador Principal', 'admin', true),
--     ('REEMPLAZAR_CON_UUID_DE_operador1@test.com', 'operador1@test.com', 'Operador en Obra 1', 'user', true),
--     ('REEMPLAZAR_CON_UUID_DE_operador2@test.com', 'operador2@test.com', 'Operador en Obra 2', 'user', true)
-- ON CONFLICT (id) DO UPDATE 
-- SET role = EXCLUDED.role, activo = EXCLUDED.activo;
