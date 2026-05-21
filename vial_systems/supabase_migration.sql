-- MIGRACIÓN DE SUPABASE: FASE 08 - REESTRUCTURACIÓN DE INFORMES Y PARTES DIARIOS CON CATÁLOGOS DINÁMICOS

-- ==================================================================================
-- 1. CREACIÓN DE TABLAS DE CATÁLOGOS OPERATIVOS
-- ==================================================================================

-- A. Proveedores de Servicio
CREATE TABLE IF NOT EXISTS proveedores_servicio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- B. Maquinaria de Obra
CREATE TABLE IF NOT EXISTS maquinaria_obra (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- C. Control de Materiales
CREATE TABLE IF NOT EXISTS control_materiales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- D. Otros Equipos
CREATE TABLE IF NOT EXISTS otros_equipos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- E. Camiones Internos
CREATE TABLE IF NOT EXISTS camiones_internos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- F. Funciones de Personal
CREATE TABLE IF NOT EXISTS funciones_personal (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==================================================================================
-- 2. INSERTAR DATOS PREDETERMINADOS (FUNCIONES DE PERSONAL)
-- ==================================================================================
INSERT INTO funciones_personal (nombre) VALUES
('Peón'),
('Chofer de máquina'),
('Capataz'),
('Técnico'),
('Otros')
ON CONFLICT DO NOTHING;

-- ==================================================================================
-- 3. REESTRUCTURACIÓN DE LA TABLA 'informes_diarios'
-- ==================================================================================

-- Eliminar columnas obsoletas
ALTER TABLE informes_diarios DROP COLUMN IF EXISTS clima;
ALTER TABLE informes_diarios DROP COLUMN IF EXISTS estado_camino;

-- Agregar nuevas columnas estructuradas para guardar listas de IDs seleccionados
ALTER TABLE informes_diarios ADD COLUMN IF NOT EXISTS proveedores_ids JSONB DEFAULT '[]'::jsonb;
ALTER TABLE informes_diarios ADD COLUMN IF NOT EXISTS maquinarias_ids JSONB DEFAULT '[]'::jsonb;
ALTER TABLE informes_diarios ADD COLUMN IF NOT EXISTS materiales_ids JSONB DEFAULT '[]'::jsonb;
ALTER TABLE informes_diarios ADD COLUMN IF NOT EXISTS equipos_ids JSONB DEFAULT '[]'::jsonb;
ALTER TABLE informes_diarios ADD COLUMN IF NOT EXISTS camiones_ids JSONB DEFAULT '[]'::jsonb;

-- ==================================================================================
-- 4. REESTRUCTURACIÓN DE LA TABLA 'informes_diarios_trabajo'
-- ==================================================================================

-- Eliminar columnas obsoletas
ALTER TABLE informes_diarios_trabajo DROP COLUMN IF EXISTS personal_presente;
ALTER TABLE informes_diarios_trabajo DROP COLUMN IF EXISTS maquinaria_utilizada;

-- Agregar nuevas columnas estructuradas
-- personal_por_funcion mapea: { "id_funcion": cantidad }
ALTER TABLE informes_diarios_trabajo ADD COLUMN IF NOT EXISTS personal_por_funcion JSONB DEFAULT '{}'::jsonb;
-- maquinaria_ids es una lista de IDs de maquinarias del catálogo
ALTER TABLE informes_diarios_trabajo ADD COLUMN IF NOT EXISTS maquinaria_ids JSONB DEFAULT '[]'::jsonb;

-- ==================================================================================
-- 5. HABILITAR SEGURIDAD RLS (ROW LEVEL SECURITY) - OPCIONAL PERO RECOMENDADO
-- ==================================================================================
ALTER TABLE proveedores_servicio ENABLE ROW LEVEL SECURITY;
ALTER TABLE maquinaria_obra ENABLE ROW LEVEL SECURITY;
ALTER TABLE control_materiales ENABLE ROW LEVEL SECURITY;
ALTER TABLE otros_equipos ENABLE ROW LEVEL SECURITY;
ALTER TABLE camiones_internos ENABLE ROW LEVEL SECURITY;
ALTER TABLE funciones_personal ENABLE ROW LEVEL SECURITY;

-- Crear políticas para permitir lectura a usuarios autenticados
CREATE POLICY "Permitir lectura a autenticados" ON proveedores_servicio FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON maquinaria_obra FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON control_materiales FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON otros_equipos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON camiones_internos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON funciones_personal FOR SELECT TO authenticated USING (true);

-- Crear políticas para permitir escritura completa solo a administradores (ejemplo de rol)
-- NOTA: Adapte según el nombre de la columna de roles si aplica en su base de datos.
CREATE POLICY "Escritura completa para administradores" ON proveedores_servicio FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para administradores" ON maquinaria_obra FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para administradores" ON control_materiales FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para administradores" ON otros_equipos FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para administradores" ON camiones_internos FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para administradores" ON funciones_personal FOR ALL TO authenticated USING (true);
