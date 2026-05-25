-- ==================================================================================
-- SCRIPT DE AUTOMATIZACIÓN DE MANTENIMIENTO, MIGRACIÓN Y RETENCIÓN DE DATOS (FASE 11)
-- ==================================================================================
-- Proyecto: VialSystems
-- Objetivo: Conservar una base de datos activa y ligera (0-12 meses),
--           archivar datos intermedios (12-18 meses) y preparar el terreno para
--           depuraciones seguras bajo estricta confirmación administrativa.
--
-- IMPORTANTE: Este script no modifica tablas de producción activas ni realiza
--             purgas automáticas por defecto. Los cron jobs pg_cron quedan comentados.
-- ==================================================================================

-- ==================================================================================
-- 1. CREACIÓN DE TABLAS DE ARCHIVO HISTÓRICO (MODO COMPRIMIDO / LECTURA HISTÓRICA)
-- ==================================================================================

-- A. Histórico de Remitos de Acarreo
CREATE TABLE IF NOT EXISTS historico_remitos (
    id UUID PRIMARY KEY,
    numero_remito TEXT NOT NULL,
    numero_guia TEXT NOT NULL,
    fecha TIMESTAMPTZ NOT NULL,
    obra_id UUID,
    material_id UUID,
    cantidad_m3 NUMERIC(10, 2),
    procedencia TEXT,
    destino TEXT,
    transportista_id UUID,
    chofer_id UUID,
    camion_patente TEXT,
    acoplado_patente TEXT,
    hora_descarga TEXT,
    observaciones TEXT,
    estado TEXT,
    fotos JSONB DEFAULT '[]'::jsonb, -- Se conservan las referencias/URLs de fotos intactas en esta fase
    usuario_creador TEXT,
    archived_at TIMESTAMPTZ DEFAULT now(),
    original_created_at TIMESTAMPTZ
);

-- B. Histórico de Informes Diarios
CREATE TABLE IF NOT EXISTS historico_informes_diarios (
    id UUID PRIMARY KEY,
    fecha TIMESTAMPTZ NOT NULL,
    obra_id UUID,
    usuario_id TEXT NOT NULL,
    usuario_name TEXT NOT NULL,
    proveedores_ids JSONB,
    maquinarias_ids JSONB,
    materiales JSONB,
    equipos_ids JSONB,
    camiones_ids JSONB,
    observaciones TEXT,
    estado TEXT,
    fotos JSONB DEFAULT '[]'::jsonb,
    archived_at TIMESTAMPTZ DEFAULT now(),
    original_created_at TIMESTAMPTZ
);

-- C. Histórico de Diarios de Trabajo (Partes Diarios)
CREATE TABLE IF NOT EXISTS historico_informes_diarios_trabajo (
    id UUID PRIMARY KEY,
    fecha TIMESTAMPTZ NOT NULL,
    obra_id UUID,
    usuario_id TEXT NOT NULL,
    usuario_name TEXT NOT NULL,
    tareas_realizadas TEXT,
    horas_trabajadas NUMERIC,
    personal JSONB,
    maquinaria_ids JSONB,
    observaciones TEXT,
    estado TEXT,
    fotos JSONB DEFAULT '[]'::jsonb,
    archived_at TIMESTAMPTZ DEFAULT now(),
    original_created_at TIMESTAMPTZ
);

-- Habilitar RLS en las tablas históricas para mantener la seguridad intacta
ALTER TABLE historico_remitos ENABLE ROW LEVEL SECURITY;
ALTER TABLE historico_informes_diarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE historico_informes_diarios_trabajo ENABLE ROW LEVEL SECURITY;

-- Políticas de lectura de históricos permitida para usuarios autenticados
CREATE POLICY "Lectura histórica para autenticados" ON historico_remitos FOR SELECT TO authenticated USING (true);
CREATE POLICY "Lectura histórica para autenticados" ON historico_informes_diarios FOR SELECT TO authenticated USING (true);
CREATE POLICY "Lectura histórica para autenticados" ON historico_informes_diarios_trabajo FOR SELECT TO authenticated USING (true);


-- ==================================================================================
-- 2. PROCEDIMIENTOS ALMACENADOS (PL/pgSQL) PARA COMPRESIÓN Y ARCHIVO
-- ==================================================================================

-- A. Función para archivar registros que superen los 12 meses de antigüedad (12 a 18 meses)
CREATE OR REPLACE FUNCTION archive_old_records()
RETURNS void AS $$
DECLARE
    cutoff_date TIMESTAMPTZ := now() - INTERVAL '12 months';
    archived_remitos_count INT := 0;
    archived_informes_count INT := 0;
    archived_trabajo_count INT := 0;
BEGIN
    RAISE NOTICE 'Iniciando proceso de archivo. Fecha de corte: %', cutoff_date;

    -- 1. Archivar Remitos de Acarreo (Se asume que la tabla activa es 'remitos')
    -- Se incluye manejo de excepciones y verificación para evitar duplicados en la tabla histórica.
    BEGIN
        INSERT INTO historico_remitos (
            id, numero_remito, numero_guia, fecha, obra_id, material_id, cantidad_m3,
            procedencia, destino, transportista_id, chofer_id, camion_patente, acoplado_patente,
            hora_descarga, observaciones, estado, fotos, usuario_creador, original_created_at
        )
        SELECT 
            id, numero_remito, numero_guia, fecha, obra_id, material_id, cantidad_m3,
            procedencia, destino, transportista_id, chofer_id, camion_patente, acoplado_patente,
            hora_descarga, observaciones, estado, fotos, usuario_creador, created_at
        FROM remitos
        WHERE fecha < cutoff_date
          AND id NOT IN (SELECT id FROM historico_remitos);
          
        GET DIAGNOSTICS archived_remitos_count = ROW_COUNT;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'No se pudo migrar la tabla remitos. Detalle: %', SQLERRM;
    END;

    -- 2. Archivar Informes Diarios
    BEGIN
        INSERT INTO historico_informes_diarios (
            id, fecha, obra_id, usuario_id, usuario_name, proveedores_ids,
            maquinarias_ids, materiales, equipos_ids, camiones_ids, observaciones,
            estado, fotos, original_created_at
        )
        SELECT 
            id, fecha, obra_id, usuario_id, usuario_name, proveedores_ids,
            maquinarias_ids, materiales, equipos_ids, camiones_ids, observaciones,
            estado, fotos, created_at
        FROM informes_diarios
        WHERE fecha < cutoff_date
          AND id NOT IN (SELECT id FROM historico_informes_diarios);
          
        GET DIAGNOSTICS archived_informes_count = ROW_COUNT;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'No se pudo migrar la tabla informes_diarios. Detalle: %', SQLERRM;
    END;

    -- 3. Archivar Diarios de Trabajo (Informes de Trabajo)
    BEGIN
        INSERT INTO historico_informes_diarios_trabajo (
            id, fecha, obra_id, usuario_id, usuario_name, tareas_realizadas,
            horas_trabajadas, personal, maquinaria_ids, observaciones, estado,
            fotos, original_created_at
        )
        SELECT 
            id, fecha, obra_id, usuario_id, usuario_name, tareas_realizadas,
            horas_trabajadas, personal, maquinaria_ids, observaciones, estado,
            fotos, created_at
        FROM informes_diarios_trabajo
        WHERE fecha < cutoff_date
          AND id NOT IN (SELECT id FROM historico_informes_diarios_trabajo);
          
        GET DIAGNOSTICS archived_trabajo_count = ROW_COUNT;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'No se pudo migrar la tabla informes_diarios_trabajo. Detalle: %', SQLERRM;
    END;

    -- NOTA IMPORTANTE: Para mayor seguridad del MVP, en esta fase NO eliminamos físicamente
    -- los registros originales de las tablas activas. Esto se realizará mediante una purga coordinada
    -- una vez verificado que las tablas históricas retienen los datos correctamente en producción.
    
    RAISE NOTICE 'Proceso completado. Remitos archivados: %, Informes Diarios: %, Diarios de Trabajo: %', 
                 archived_remitos_count, archived_informes_count, archived_trabajo_count;
END;
$$ LANGUAGE plpgsql;


-- ==================================================================================
-- 3. PROCEDIMIENTO SEGURO DE PURGA HISTÓRICA (REQUIERE CONFIRMACIÓN ADMINISTRATIVA)
-- ==================================================================================

-- Función para purgar registros con más de 18 meses de antigüedad.
-- Requiere pasar explícitamente un código de seguridad para evitar ejecuciones accidentales.
CREATE OR REPLACE FUNCTION purge_historical_records(confirm_code TEXT)
RETURNS void AS $$
DECLARE
    cutoff_date TIMESTAMPTZ := now() - INTERVAL '18 months';
    deleted_remitos_count INT := 0;
    deleted_informes_count INT := 0;
    deleted_trabajo_count INT := 0;
BEGIN
    -- Validar código de confirmación administrativa de seguridad
    IF confirm_code IS NULL OR confirm_code <> 'CONFIRM_PURGE_18_MONTHS' THEN
        RAISE EXCEPTION 'ERROR: Código de seguridad de confirmación incorrecto o vacío. La purga de datos históricos ha sido denegada.';
    END IF;

    RAISE NOTICE '¡CONFIRMACIÓN DE PURGA ACEPTADA! Depurando registros anteriores a: %', cutoff_date;

    -- Depuración de registros en tablas históricas.
    -- Las fotos/binarios físicos en Supabase Storage NO se eliminan automáticamente 
    -- en esta fase para evitar pérdidas accidentales.
    
    DELETE FROM historico_remitos WHERE fecha < cutoff_date;
    GET DIAGNOSTICS deleted_remitos_count = ROW_COUNT;

    DELETE FROM historico_informes_diarios WHERE fecha < cutoff_date;
    GET DIAGNOSTICS deleted_informes_count = ROW_COUNT;

    DELETE FROM historico_informes_diarios_trabajo WHERE fecha < cutoff_date;
    GET DIAGNOSTICS deleted_trabajo_count = ROW_COUNT;

    RAISE NOTICE 'Purga física completada. Remitos eliminados: %, Informes Diarios: %, Diarios de Trabajo: %', 
                 deleted_remitos_count, deleted_informes_count, deleted_trabajo_count;
END;
$$ LANGUAGE plpgsql;


-- ==================================================================================
-- 4. PROGRAMACIÓN DE TAREAS PERIÓDICAS (pg_cron)
-- ==================================================================================
-- Si tu instancia de Supabase tiene habilitada la extensión "pg_cron", puedes activar
-- las siguientes tareas comentadas para programar la compresión mensual automática.
-- Para activar pg_cron en Supabase, ejecuta: CREATE EXTENSION IF NOT EXISTS pg_cron;
-- ==================================================================================

-- -- A. Programar archivado de registros el día 1 de cada mes a las 03:00 AM
-- SELECT cron.schedule(
--     'monthly-data-archiving-job',
--     '0 3 1 * *',
--     'SELECT archive_old_records();'
-- );

-- -- B. La purga definitiva NO SE PROGRAMA en cron por razones de seguridad.
-- -- Debe ser invocada de forma explícita por la consola del administrador utilizando:
-- -- SELECT purge_historical_records('CONFIRM_PURGE_18_MONTHS');
