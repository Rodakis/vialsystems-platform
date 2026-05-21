-- MIGRACIÓN DE SUPABASE: FASE 08 - REESTRUCTURACIÓN DE INFORMES Y PARTES DIARIOS CON CATÁLOGOS DINÁMICOS Y TABLAS PUENTE
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
    unidad_default TEXT, -- m³, toneladas, viajes, unidades
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
-- 2. INSERTAR DATOS PREDETERMINADOS (FUNCIONES DE PERSONAL Y MATERIALES)
-- ==================================================================================
INSERT INTO funciones_personal (nombre) VALUES
('Peón'),
('Chofer de máquina'),
('Capataz'),
('Técnico'),
('Otros')
ON CONFLICT DO NOTHING;

INSERT INTO control_materiales (nombre, unidad_default) VALUES
('Arena', 'm³'),
('Tosca', 'm³'),
('Piedra', 'm³'),
('Cemento', 'toneladas'),
('Hierro', 'unidades')
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
ALTER TABLE informes_diarios ADD COLUMN IF NOT EXISTS materiales JSONB DEFAULT '[]'::jsonb; -- Arreglo estructurado de InformeMaterialItem
ALTER TABLE informes_diarios ADD COLUMN IF NOT EXISTS equipos_ids JSONB DEFAULT '[]'::jsonb;
ALTER TABLE informes_diarios ADD COLUMN IF NOT EXISTS camiones_ids JSONB DEFAULT '[]'::jsonb;

-- ==================================================================================
-- 4. REESTRUCTURACIÓN DE LA TABLA 'informes_diarios_trabajo'
-- ==================================================================================

-- Eliminar columnas obsoletas
ALTER TABLE informes_diarios_trabajo DROP COLUMN IF EXISTS personal_presente;
ALTER TABLE informes_diarios_trabajo DROP COLUMN IF EXISTS maquinaria_utilizada;

-- Agregar nuevas columnas estructuradas
ALTER TABLE informes_diarios_trabajo ADD COLUMN IF NOT EXISTS personal JSONB DEFAULT '[]'::jsonb; -- Arreglo estructurado de InformePersonalItem
ALTER TABLE informes_diarios_trabajo ADD COLUMN IF NOT EXISTS maquinaria_ids JSONB DEFAULT '[]'::jsonb;

-- ==================================================================================
-- 5. CREACIÓN DE TABLAS PUENTE NORMALIZADAS PARA ANÁLISIS
-- ==================================================================================

-- A. Tabla puente para Materiales de Informes Diarios
CREATE TABLE IF NOT EXISTS daily_report_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_report_id UUID NOT NULL REFERENCES informes_diarios(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES control_materiales(id) ON DELETE CASCADE,
    cantidad NUMERIC(10, 2) NOT NULL CHECK (cantidad >= 0),
    unidad TEXT NOT NULL,
    observacion TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- B. Tabla puente para Personal de Partes Diarios de Trabajo
CREATE TABLE IF NOT EXISTS work_daily_report_personnel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    work_daily_report_id UUID NOT NULL REFERENCES informes_diarios_trabajo(id) ON DELETE CASCADE,
    personal_role_id UUID NOT NULL REFERENCES funciones_personal(id) ON DELETE CASCADE,
    horas_trabajadas NUMERIC(5, 2) NOT NULL CHECK (horas_trabajadas >= 0 AND horas_trabajadas <= 24),
    observacion TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==================================================================================
-- 6. TRIGGERS DE BASE DE DATOS PARA NORMALIZACIÓN EN TIEMPO REAL
-- ==================================================================================

-- A. Función Trigger para informes_diarios (Materiales JSONB -> daily_report_materials)
CREATE OR REPLACE FUNCTION sync_daily_report_materials()
RETURNS TRIGGER AS $$
BEGIN
    -- Eliminar registros puente antiguos para este informe
    DELETE FROM daily_report_materials WHERE daily_report_id = NEW.id;

    -- Deserializar el JSONB e insertar las filas puente normalizadas
    IF NEW.materiales IS NOT NULL AND jsonb_typeof(NEW.materiales) = 'array' THEN
        INSERT INTO daily_report_materials (daily_report_id, material_id, cantidad, unidad, observacion)
        SELECT 
            NEW.id,
            (elem->>'material_id')::UUID,
            (elem->>'cantidad')::NUMERIC,
            (elem->>'unidad')::TEXT,
            elem->>'observacion'
        FROM jsonb_array_elements(NEW.materiales) AS elem
        WHERE elem->>'material_id' IS NOT NULL AND elem->>'material_id' <> '';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_sync_daily_report_materials
AFTER INSERT OR UPDATE OF materiales ON informes_diarios
FOR EACH ROW
EXECUTE FUNCTION sync_daily_report_materials();


-- B. Función Trigger para informes_diarios_trabajo (Personal JSONB -> work_daily_report_personnel)
CREATE OR REPLACE FUNCTION sync_work_daily_report_personnel()
RETURNS TRIGGER AS $$
BEGIN
    -- Eliminar registros puente antiguos para este parte de trabajo
    DELETE FROM work_daily_report_personnel WHERE work_daily_report_id = NEW.id;

    -- Deserializar el JSONB e insertar las filas puente normalizadas
    IF NEW.personal IS NOT NULL AND jsonb_typeof(NEW.personal) = 'array' THEN
        INSERT INTO work_daily_report_personnel (work_daily_report_id, personal_role_id, horas_trabajadas, observacion)
        SELECT 
            NEW.id,
            (elem->>'personal_role_id')::UUID,
            (elem->>'horas_trabajadas')::NUMERIC,
            elem->>'observacion'
        FROM jsonb_array_elements(NEW.personal) AS elem
        WHERE elem->>'personal_role_id' IS NOT NULL AND elem->>'personal_role_id' <> '';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_sync_work_daily_report_personnel
AFTER INSERT OR UPDATE OF personal ON informes_diarios_trabajo
FOR EACH ROW
EXECUTE FUNCTION sync_work_daily_report_personnel();


-- ==================================================================================
-- 7. HABILITAR SEGURIDAD RLS (ROW LEVEL SECURITY)
-- ==================================================================================
ALTER TABLE proveedores_servicio ENABLE ROW LEVEL SECURITY;
ALTER TABLE maquinaria_obra ENABLE ROW LEVEL SECURITY;
ALTER TABLE control_materiales ENABLE ROW LEVEL SECURITY;
ALTER TABLE otros_equipos ENABLE ROW LEVEL SECURITY;
ALTER TABLE camiones_internos ENABLE ROW LEVEL SECURITY;
ALTER TABLE funciones_personal ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_report_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_daily_report_personnel ENABLE ROW LEVEL SECURITY;

-- Políticas de lectura para autenticados
CREATE POLICY "Permitir lectura a autenticados" ON proveedores_servicio FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON maquinaria_obra FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON control_materiales FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON otros_equipos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON camiones_internos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON funciones_personal FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON daily_report_materials FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permitir lectura a autenticados" ON work_daily_report_personnel FOR SELECT TO authenticated USING (true);

-- Políticas de escritura completa (Administrador / Operador)
CREATE POLICY "Escritura completa para autenticados" ON proveedores_servicio FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para autenticados" ON maquinaria_obra FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para autenticados" ON control_materiales FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para autenticados" ON otros_equipos FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para autenticados" ON camiones_internos FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para autenticados" ON funciones_personal FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para autenticados" ON daily_report_materials FOR ALL TO authenticated USING (true);
CREATE POLICY "Escritura completa para autenticados" ON work_daily_report_personnel FOR ALL TO authenticated USING (true);
