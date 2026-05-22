-- MIGRACIÓN FINAL UNIFICADA DE SUPABASE: FASE 08 - REESTRUCTURACIÓN DE INFORMES Y PARTES DIARIOS
-- ==================================================================================
-- 1. CREACIÓN DE TABLAS DE CATÁLOGOS OPERATIVOS (UNIFICADO EL CAMPO 'activo')
-- ==================================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- A. Proveedores de Servicio (para el operador móvil y web)
CREATE TABLE IF NOT EXISTS proveedores_servicio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- B. Maquinaria de Obra
CREATE TABLE IF NOT EXISTS maquinaria_obra (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- C. Control de Materiales (Catálogo independiente del módulo de acarreos/remitos)
CREATE TABLE IF NOT EXISTS control_materiales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    unidad_default TEXT, -- Unidad sugerida/predeterminada (m³, toneladas, etc.)
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- D. Otros Equipos
CREATE TABLE IF NOT EXISTS otros_equipos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- E. Camiones Internos (Propio de la empresa, no duplicado con camiones externos de acarreo)
CREATE TABLE IF NOT EXISTS camiones_internos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL, -- Patente, número de interno o alias
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- F. Funciones de Personal (Roles internos)
CREATE TABLE IF NOT EXISTS funciones_personal (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- G. Personal / Empleados (Personal interno de la empresa)
CREATE TABLE IF NOT EXISTS personal_empleados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    apellido TEXT NOT NULL,
    documento TEXT, -- Documento Nacional de Identidad / DNI (Opcional)
    telefono TEXT, -- Número de contacto (Opcional)
    identificador TEXT, -- Número de Legajo o Ficha Interna (Opcional)
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ==================================================================================
-- 2. CREACIÓN DE TABLAS DE REPORTES (CON CREATE TABLE IF NOT EXISTS)
-- ==================================================================================

-- A. Informes Diarios (Estructura base)
CREATE TABLE IF NOT EXISTS informes_diarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha TIMESTAMPTZ NOT NULL,
    obra_id UUID REFERENCES obras(id) ON DELETE SET NULL,
    usuario_id TEXT NOT NULL,
    usuario_name TEXT NOT NULL,
    proveedores_ids JSONB DEFAULT '[]'::jsonb,
    maquinarias_ids JSONB DEFAULT '[]'::jsonb,
    materiales JSONB DEFAULT '[]'::jsonb, -- Array de objetos [ { material_id, cantidad, unidad, observacion } ]
    equipos_ids JSONB DEFAULT '[]'::jsonb,
    camiones_ids JSONB DEFAULT '[]'::jsonb,
    observaciones TEXT,
    estado TEXT DEFAULT 'borrador', -- borrador, listoParaEnviar, sincronizado, etc.
    fotos JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- B. Partes / Diarios de Trabajo (Estructura base)
CREATE TABLE IF NOT EXISTS informes_diarios_trabajo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha TIMESTAMPTZ NOT NULL,
    obra_id UUID REFERENCES obras(id) ON DELETE SET NULL,
    usuario_id TEXT NOT NULL,
    usuario_name TEXT NOT NULL,
    tareas_realizadas TEXT DEFAULT '',
    horas_trabajadas NUMERIC DEFAULT 0.0,
    personal JSONB DEFAULT '[]'::jsonb, -- Array de objetos [ { empleado_id, funcion_id, horas_trabajadas, observacion } ]
    maquinaria_ids JSONB DEFAULT '[]'::jsonb,
    observaciones TEXT,
    estado TEXT DEFAULT 'borrador',
    fotos JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ==================================================================================
-- 3. CREACIÓN DE TABLAS PUENTE RELACIONALES (NORMALIZACIÓN PARA ANÁLISIS)
-- ==================================================================================

-- A. Desglose Relacional de Materiales en Informes Diarios
CREATE TABLE IF NOT EXISTS daily_report_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_report_id UUID NOT NULL REFERENCES informes_diarios(id) ON DELETE CASCADE,
    material_id UUID NOT NULL REFERENCES control_materiales(id) ON DELETE CASCADE,
    cantidad NUMERIC(10, 2) NOT NULL CHECK (cantidad >= 0),
    unidad TEXT NOT NULL,
    observacion TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- B. Desglose Relacional de Personal en Partes de Trabajo
CREATE TABLE IF NOT EXISTS work_daily_report_personnel (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    work_daily_report_id UUID NOT NULL REFERENCES informes_diarios_trabajo(id) ON DELETE CASCADE,
    empleado_id UUID NOT NULL REFERENCES personal_empleados(id) ON DELETE CASCADE,
    funcion_id UUID NOT NULL REFERENCES funciones_personal(id) ON DELETE CASCADE,
    horas_trabajadas NUMERIC(5, 2) NOT NULL CHECK (horas_trabajadas >= 0.0 AND horas_trabajadas <= 24.0),
    observacion TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==================================================================================
-- 4. TRIGGERS EN PL/pgSQL PARA ACTUALIZACIÓN AUTOMÁTICA EN TIEMPO REAL
-- ==================================================================================

-- A. Trigger para Materiales (JSONB -> daily_report_materials)
CREATE OR REPLACE FUNCTION sync_daily_report_materials()
RETURNS TRIGGER AS $$
BEGIN
    -- Prune de registros puente previos para este informe
    DELETE FROM daily_report_materials WHERE daily_report_id = NEW.id;

    -- Deserializar el array e insertar en la tabla normalizada
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


-- B. Trigger para Personal (JSONB -> work_daily_report_personnel)
CREATE OR REPLACE FUNCTION sync_work_daily_report_personnel()
RETURNS TRIGGER AS $$
BEGIN
    -- Prune de registros puente previos para este parte
    DELETE FROM work_daily_report_personnel WHERE work_daily_report_id = NEW.id;

    -- Deserializar el array e insertar en la tabla normalizada
    IF NEW.personal IS NOT NULL AND jsonb_typeof(NEW.personal) = 'array' THEN
        INSERT INTO work_daily_report_personnel (work_daily_report_id, empleado_id, funcion_id, horas_trabajadas, observacion)
        SELECT 
            NEW.id,
            (elem->>'empleado_id')::UUID,
            (elem->>'funcion_id')::UUID,
            (elem->>'horas_trabajadas')::NUMERIC,
            elem->>'observacion'
        FROM jsonb_array_elements(NEW.personal) AS elem
        WHERE elem->>'empleado_id' IS NOT NULL AND elem->>'empleado_id' <> '' 
          AND elem->>'funcion_id' IS NOT NULL AND elem->>'funcion_id' <> '';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_sync_work_daily_report_personnel
AFTER INSERT OR UPDATE OF personal ON informes_diarios_trabajo
FOR EACH ROW
EXECUTE FUNCTION sync_work_daily_report_personnel();

-- ==================================================================================
-- 5. DATOS SEMILLA (OPCIONALES Y COMENTADOS / SIN EMPLEADOS FICTICIOS)
-- ==================================================================================

-- A. Roles / Funciones de Personal sugeridas de arranque:
INSERT INTO funciones_personal (nombre, descripcion)
SELECT nombre, descripcion FROM (VALUES
    ('Peón', 'Tareas generales de apoyo en obra'),
    ('Chofer', 'Conducción de vehículos y utilitarios internos'),
    ('Maquinista', 'Operación de maquinaria pesada'),
    ('Técnico', 'Tareas de control y soporte de especialidad'),
    ('Capataz', 'Supervisión y control directo de cuadrilla')
) AS v(nombre, descripcion)
WHERE NOT EXISTS (SELECT 1 FROM funciones_personal WHERE funciones_personal.nombre = v.nombre);

-- B. Materiales sugeridos para Control de Materiales en Obra:
INSERT INTO control_materiales (nombre, unidad_default)
SELECT nombre, unidad_default FROM (VALUES
    ('Arena', 'm³'),
    ('Tosca', 'm³'),
    ('Piedra', 'm³'),
    ('Cemento', 'toneladas'),
    ('Hierro', 'unidades')
) AS v(nombre, unidad_default)
WHERE NOT EXISTS (SELECT 1 FROM control_materiales WHERE control_materiales.nombre = v.nombre);

-- C. Personal de la empresa:
-- Se deja completamente vacío de manera predeterminada para que el Administrador 
-- los registre de forma dinámica desde el Panel de Control en la aplicación.

-- ==================================================================================
-- 6. HABILITAR SEGURIDAD RLS (ROW LEVEL SECURITY) Y POLÍTICAS SEGURAS
-- ==================================================================================

ALTER TABLE proveedores_servicio ENABLE ROW LEVEL SECURITY;
ALTER TABLE maquinaria_obra ENABLE ROW LEVEL SECURITY;
ALTER TABLE control_materiales ENABLE ROW LEVEL SECURITY;
ALTER TABLE otros_equipos ENABLE ROW LEVEL SECURITY;
ALTER TABLE camiones_internos ENABLE ROW LEVEL SECURITY;
ALTER TABLE funciones_personal ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_empleados ENABLE ROW LEVEL SECURITY;
ALTER TABLE informes_diarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE informes_diarios_trabajo ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_report_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_daily_report_personnel ENABLE ROW LEVEL SECURITY;

-- A. Políticas de lectura (SELECT) para todos los usuarios autenticados (Operadores y Administradores)
DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON proveedores_servicio;
CREATE POLICY "Lectura permitida para autenticados" ON proveedores_servicio FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON maquinaria_obra;
CREATE POLICY "Lectura permitida para autenticados" ON maquinaria_obra FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON control_materiales;
CREATE POLICY "Lectura permitida para autenticados" ON control_materiales FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON otros_equipos;
CREATE POLICY "Lectura permitida para autenticados" ON otros_equipos FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON camiones_internos;
CREATE POLICY "Lectura permitida para autenticados" ON camiones_internos FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON funciones_personal;
CREATE POLICY "Lectura permitida para autenticados" ON funciones_personal FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON personal_empleados;
CREATE POLICY "Lectura permitida para autenticados" ON personal_empleados FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON informes_diarios;
CREATE POLICY "Lectura permitida para autenticados" ON informes_diarios FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON informes_diarios_trabajo;
CREATE POLICY "Lectura permitida para autenticados" ON informes_diarios_trabajo FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON daily_report_materials;
CREATE POLICY "Lectura permitida para autenticados" ON daily_report_materials FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON work_daily_report_personnel;
CREATE POLICY "Lectura permitida para autenticados" ON work_daily_report_personnel FOR SELECT TO authenticated USING (true);

-- B. Políticas de carga / reporte (Operadores móviles)
DROP POLICY IF EXISTS "Permitir escritura de reportes a autenticados" ON informes_diarios;
CREATE POLICY "Permitir escritura de reportes a autenticados" ON informes_diarios FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir escritura de reportes a autenticados" ON informes_diarios_trabajo;
CREATE POLICY "Permitir escritura de reportes a autenticados" ON informes_diarios_trabajo FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- C. Políticas RLS temporales de desarrollo para permitir la inserción automática vía triggers
-- Esto es sumamente importante para que las transacciones de los triggers no sean bloqueadas a nivel de fila.
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de materiales puente a autenticados" ON daily_report_materials;
CREATE POLICY "Desarrollo: Permitir escritura de materiales puente a autenticados" ON daily_report_materials FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de personal puente a autenticados" ON work_daily_report_personnel;
CREATE POLICY "Desarrollo: Permitir escritura de personal puente a autenticados" ON work_daily_report_personnel FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- D. Políticas para Catálogos Operativos (Administrador)

-- POLÍTICA DE PRODUCCIÓN RECOMENDADA (ACCESO EXCLUSIVO A ADMINISTRADORES EN PRODUCCIÓN):
-- IMPORTANTE: Al migrar a producción, se debe desactivar la política de desarrollo de abajo
-- y activar la política basada en el rol del usuario (JWT o tabla de perfiles):
--
-- DROP POLICY IF EXISTS "Administración exclusiva de catálogos para administradores" ON proveedores_servicio;
-- CREATE POLICY "Administración exclusiva de catálogos para administradores" ON proveedores_servicio
-- FOR ALL TO authenticated USING (auth.jwt() ->> 'role' = 'admin') WITH CHECK (auth.jwt() ->> 'role' = 'admin');
-- (Repetir la restricción para maquinaria_obra, control_materiales, otros_equipos, camiones_internos, funciones_personal y personal_empleados)

-- POLÍTICA DE DESARROLLO / ENTRENAMIENTO (ESCRITURA TEMPORAL PARA USUARIOS AUTENTICADOS):
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON proveedores_servicio;
CREATE POLICY "Desarrollo: Permitir escritura de catálogos a autenticados" ON proveedores_servicio FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON maquinaria_obra;
CREATE POLICY "Desarrollo: Permitir escritura de catálogos a autenticados" ON maquinaria_obra FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON control_materiales;
CREATE POLICY "Desarrollo: Permitir escritura de catálogos a autenticados" ON control_materiales FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON otros_equipos;
CREATE POLICY "Desarrollo: Permitir escritura de catálogos a autenticados" ON otros_equipos FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON camiones_internos;
CREATE POLICY "Desarrollo: Permitir escritura de catálogos a autenticados" ON camiones_internos FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON funciones_personal;
CREATE POLICY "Desarrollo: Permitir escritura de catálogos a autenticados" ON funciones_personal FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON personal_empleados;
CREATE POLICY "Desarrollo: Permitir escritura de catálogos a autenticados" ON personal_empleados FOR ALL TO authenticated USING (true) WITH CHECK (true);
