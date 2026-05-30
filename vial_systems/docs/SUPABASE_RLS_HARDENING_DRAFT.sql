-- ==================================================================================
-- BORRADOR TECNICO - NO EJECUTAR COMO MIGRACION COMPLETA.
-- Este archivo mezcla SQL aplicable, propuestas, secciones pendientes y queries de
-- verificacion.
-- Debe revisarse y dividirse por fases antes de aplicar cualquier bloque en Supabase.
-- ==================================================================================

-- ==================================================================================
-- VialSystems - SUPABASE RLS HARDENING DRAFT
-- ==================================================================================
-- ESTADO: BORRADOR DE REVISION PRE-PRODUCCION
--
-- IMPORTANTE:
-- - NO ejecutar este archivo completo sin revision manual.
-- - Este archivo NO fue ejecutado contra Supabase.
-- - Las secciones aplicables estan separadas de las secciones PENDIENTES.
-- - No se incluyen claves, secretos ni configuracion del cliente Flutter.
-- - La estrategia asume que el rol publico no autenticado (`anon`) no debe recibir
--   permisos sobre datos de VialSystems.
--
-- Objetivo:
-- Endurecer RLS/policies antes de produccion, reemplazando policies permisivas de
-- desarrollo y evitando recursiones en `profiles`.
-- ==================================================================================


-- ==================================================================================
-- FASE 1 - PROFILES Y FUNCIONES AUXILIARES DE ROLES
-- ==================================================================================
-- Riesgo que resuelve:
-- - Evita recursividad infinita en policies de `public.profiles`.
-- - Centraliza checks de rol en funciones SECURITY DEFINER con search_path fijo.
-- - Bloquea roles inactivos (`activo = true`) desde la propia base.
--
-- Columnas confirmadas en `vial_systems/docs/create_profiles_table.sql`:
-- - public.profiles.id UUID
-- - public.profiles.email TEXT
-- - public.profiles.nombre TEXT
-- - public.profiles.role TEXT CHECK ('admin', 'user', 'oficina')
-- - public.profiles.activo BOOLEAN
--
-- SQL APLICABLE TRAS REVISION:
-- ==================================================================================

CREATE OR REPLACE FUNCTION public.es_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
      AND p.activo = true
  );
$$;

CREATE OR REPLACE FUNCTION public.es_oficina()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'oficina'
      AND p.activo = true
  );
$$;

CREATE OR REPLACE FUNCTION public.es_operario()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'user'
      AND p.activo = true
  );
$$;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios pueden ver su propio perfil" ON public.profiles;
DROP POLICY IF EXISTS "Administradores pueden ver todos los perfiles" ON public.profiles;
DROP POLICY IF EXISTS "Administracion exclusiva de perfiles para admins" ON public.profiles;
DROP POLICY IF EXISTS "Administración exclusiva de perfiles para admins" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_admin_oficina" ON public.profiles;
DROP POLICY IF EXISTS "profiles_write_admin" ON public.profiles;

CREATE POLICY "profiles_select_own"
ON public.profiles
FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "profiles_select_admin_oficina"
ON public.profiles
FOR SELECT
TO authenticated
USING (public.es_admin() OR public.es_oficina());

CREATE POLICY "profiles_write_admin"
ON public.profiles
FOR ALL
TO authenticated
USING (public.es_admin())
WITH CHECK (public.es_admin());

-- Rollback Fase 1:
-- - Reaplicar las policies anteriores desde `vial_systems/docs/create_profiles_table.sql`
--   solo si se acepta volver al riesgo de recursividad.
-- - Alternativamente, deshabilitar temporalmente acceso admin a perfiles y conservar
--   solo `profiles_select_own` hasta corregir la policy.
--
-- DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
-- DROP POLICY IF EXISTS "profiles_select_admin_oficina" ON public.profiles;
-- DROP POLICY IF EXISTS "profiles_write_admin" ON public.profiles;
-- DROP FUNCTION IF EXISTS public.es_admin();
-- DROP FUNCTION IF EXISTS public.es_oficina();
-- DROP FUNCTION IF EXISTS public.es_operario();


-- ==================================================================================
-- FASE 2 - REEMPLAZO DE POLICIES DE DESARROLLO POR POLICIES POR ROL
-- ==================================================================================
-- Riesgo que resuelve:
-- - Elimina `USING (true)` / `WITH CHECK (true)` en escritura.
-- - Evita que cualquier usuario autenticado pueda modificar datos sensibles.
-- - Usa solo tablas y columnas confirmadas en los archivos revisados.
--
-- NOTA SOBRE GRANTS:
-- - Estas policies controlan filas.
-- - Los GRANT de Data API deben revisarse por separado para `authenticated`.
-- - No otorgar GRANT a `anon` para estas tablas.
-- ==================================================================================


-- ----------------------------------------------------------------------------------
-- FASE 2A - personal_empleados
-- ----------------------------------------------------------------------------------
-- Columnas confirmadas en `vial_systems/supabase_migration.sql`:
-- - id, nombre, apellido, documento, telefono, identificador, activo, created_at,
--   updated_at.
--
-- Decisión de seguridad:
-- - NO permitir lectura general a cualquier authenticated porque contiene documento
--   y telefono.
-- - Admin y oficina pueden leer.
-- - Solo admin puede escribir.
-- - Si operario necesita seleccionar empleados en formularios, crear una vista limitada
--   sin documento ni telefono. Ver seccion comentada `personal_empleados_lite`.
-- ----------------------------------------------------------------------------------

ALTER TABLE public.personal_empleados ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.personal_empleados;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catalogos a autenticados" ON public.personal_empleados;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON public.personal_empleados;
DROP POLICY IF EXISTS "personal_empleados_select_admin_oficina" ON public.personal_empleados;
DROP POLICY IF EXISTS "personal_empleados_write_admin" ON public.personal_empleados;

CREATE POLICY "personal_empleados_select_admin_oficina"
ON public.personal_empleados
FOR SELECT
TO authenticated
USING (public.es_admin() OR public.es_oficina());

CREATE POLICY "personal_empleados_write_admin"
ON public.personal_empleados
FOR ALL
TO authenticated
USING (public.es_admin())
WITH CHECK (public.es_admin());

-- PENDIENTE si operario necesita leer empleados sin datos sensibles:
-- Crear una vista limitada y conceder SELECT sobre la vista, no sobre la tabla completa.
-- Revisar si PostgREST expondrá la vista según configuracion de Supabase.
--
-- CREATE OR REPLACE VIEW public.personal_empleados_lite AS
-- SELECT id, nombre, apellido, identificador, activo
-- FROM public.personal_empleados
-- WHERE activo = true;
--
-- GRANT SELECT ON public.personal_empleados_lite TO authenticated;


-- ----------------------------------------------------------------------------------
-- FASE 2B - informes_diarios
-- ----------------------------------------------------------------------------------
-- Columnas confirmadas:
-- - id, fecha, obra_id, usuario_id, usuario_name, proveedores_ids, maquinarias_ids,
--   materiales, equipos_ids, camiones_ids, observaciones, estado, fotos, created_at,
--   updated_at.
--
-- Uso confirmado en Flutter:
-- - El cliente envia `usuario_id` y `estado`.
--
-- Supuesto operativo:
-- - `usuario_id` debe guardar `auth.uid()::text`.
-- - Si actualmente Flutter guarda otro valor, esta policy bloqueara inserts/updates
--   hasta ajustar el cliente.
-- ----------------------------------------------------------------------------------

ALTER TABLE public.informes_diarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.informes_diarios;
DROP POLICY IF EXISTS "Permitir escritura de reportes a autenticados" ON public.informes_diarios;
DROP POLICY IF EXISTS "informes_diarios_select_own_or_staff" ON public.informes_diarios;
DROP POLICY IF EXISTS "informes_diarios_insert_own" ON public.informes_diarios;
DROP POLICY IF EXISTS "informes_diarios_update_own_draft" ON public.informes_diarios;
DROP POLICY IF EXISTS "informes_diarios_delete_admin" ON public.informes_diarios;

CREATE POLICY "informes_diarios_select_own_or_staff"
ON public.informes_diarios
FOR SELECT
TO authenticated
USING (
  public.es_admin()
  OR public.es_oficina()
  OR usuario_id = auth.uid()::text
);

CREATE POLICY "informes_diarios_insert_own"
ON public.informes_diarios
FOR INSERT
TO authenticated
WITH CHECK (usuario_id = auth.uid()::text);

CREATE POLICY "informes_diarios_update_own_draft"
ON public.informes_diarios
FOR UPDATE
TO authenticated
USING (
  public.es_admin()
  OR (usuario_id = auth.uid()::text AND estado = 'borrador')
)
WITH CHECK (
  public.es_admin()
  OR (usuario_id = auth.uid()::text AND estado = 'borrador')
);

CREATE POLICY "informes_diarios_delete_admin"
ON public.informes_diarios
FOR DELETE
TO authenticated
USING (public.es_admin());


-- ----------------------------------------------------------------------------------
-- FASE 2C - informes_diarios_trabajo
-- ----------------------------------------------------------------------------------
-- Columnas confirmadas:
-- - id, fecha, obra_id, usuario_id, usuario_name, tareas_realizadas,
--   horas_trabajadas, personal, maquinaria_ids, observaciones, estado, fotos,
--   created_at, updated_at.
--
-- Supuesto operativo:
-- - `usuario_id` debe guardar `auth.uid()::text`.
-- ----------------------------------------------------------------------------------

ALTER TABLE public.informes_diarios_trabajo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.informes_diarios_trabajo;
DROP POLICY IF EXISTS "Permitir escritura de reportes a autenticados" ON public.informes_diarios_trabajo;
DROP POLICY IF EXISTS "informes_trabajo_select_own_or_staff" ON public.informes_diarios_trabajo;
DROP POLICY IF EXISTS "informes_trabajo_insert_own" ON public.informes_diarios_trabajo;
DROP POLICY IF EXISTS "informes_trabajo_update_own_draft" ON public.informes_diarios_trabajo;
DROP POLICY IF EXISTS "informes_trabajo_delete_admin" ON public.informes_diarios_trabajo;

CREATE POLICY "informes_trabajo_select_own_or_staff"
ON public.informes_diarios_trabajo
FOR SELECT
TO authenticated
USING (
  public.es_admin()
  OR public.es_oficina()
  OR usuario_id = auth.uid()::text
);

CREATE POLICY "informes_trabajo_insert_own"
ON public.informes_diarios_trabajo
FOR INSERT
TO authenticated
WITH CHECK (usuario_id = auth.uid()::text);

CREATE POLICY "informes_trabajo_update_own_draft"
ON public.informes_diarios_trabajo
FOR UPDATE
TO authenticated
USING (
  public.es_admin()
  OR (usuario_id = auth.uid()::text AND estado = 'borrador')
)
WITH CHECK (
  public.es_admin()
  OR (usuario_id = auth.uid()::text AND estado = 'borrador')
);

CREATE POLICY "informes_trabajo_delete_admin"
ON public.informes_diarios_trabajo
FOR DELETE
TO authenticated
USING (public.es_admin());


-- ----------------------------------------------------------------------------------
-- FASE 2D - Funciones trigger para tablas puente
-- ----------------------------------------------------------------------------------
-- Riesgo que resuelve:
-- - Evita abrir escritura directa a `daily_report_materials` y
--   `work_daily_report_personnel`.
-- - Los triggers sincronizan datos JSONB -> tablas puente con SECURITY DEFINER.
--
-- Columnas confirmadas:
-- - daily_report_materials: daily_report_id, material_id, cantidad, unidad,
--   observacion.
-- - work_daily_report_personnel: work_daily_report_id, empleado_id, funcion_id,
--   horas_trabajadas, observacion.
-- ----------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.sync_daily_report_materials()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.daily_report_materials WHERE daily_report_id = NEW.id;

  IF NEW.materiales IS NOT NULL AND jsonb_typeof(NEW.materiales) = 'array' THEN
    INSERT INTO public.daily_report_materials
      (daily_report_id, material_id, cantidad, unidad, observacion)
    SELECT
      NEW.id,
      (elem->>'material_id')::uuid,
      (elem->>'cantidad')::numeric,
      (elem->>'unidad')::text,
      elem->>'observacion'
    FROM jsonb_array_elements(NEW.materiales) AS elem
    WHERE elem->>'material_id' IS NOT NULL
      AND elem->>'material_id' <> '';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_work_daily_report_personnel()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.work_daily_report_personnel WHERE work_daily_report_id = NEW.id;

  IF NEW.personal IS NOT NULL AND jsonb_typeof(NEW.personal) = 'array' THEN
    INSERT INTO public.work_daily_report_personnel
      (work_daily_report_id, empleado_id, funcion_id, horas_trabajadas, observacion)
    SELECT
      NEW.id,
      (elem->>'empleado_id')::uuid,
      (elem->>'funcion_id')::uuid,
      (elem->>'horas_trabajadas')::numeric,
      elem->>'observacion'
    FROM jsonb_array_elements(NEW.personal) AS elem
    WHERE elem->>'empleado_id' IS NOT NULL
      AND elem->>'empleado_id' <> ''
      AND elem->>'funcion_id' IS NOT NULL
      AND elem->>'funcion_id' <> '';
  END IF;

  RETURN NEW;
END;
$$;


-- ----------------------------------------------------------------------------------
-- FASE 2E - daily_report_materials
-- ----------------------------------------------------------------------------------
-- No se crea policy INSERT/UPDATE/DELETE para authenticated.
-- La escritura debe ocurrir mediante trigger SECURITY DEFINER.
-- ----------------------------------------------------------------------------------

ALTER TABLE public.daily_report_materials ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.daily_report_materials;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de materiales puente a autenticados" ON public.daily_report_materials;
DROP POLICY IF EXISTS "daily_report_materials_select_own_or_staff" ON public.daily_report_materials;

CREATE POLICY "daily_report_materials_select_own_or_staff"
ON public.daily_report_materials
FOR SELECT
TO authenticated
USING (
  public.es_admin()
  OR public.es_oficina()
  OR EXISTS (
    SELECT 1
    FROM public.informes_diarios i
    WHERE i.id = daily_report_id
      AND i.usuario_id = auth.uid()::text
  )
);


-- ----------------------------------------------------------------------------------
-- FASE 2F - work_daily_report_personnel
-- ----------------------------------------------------------------------------------
-- No se crea policy INSERT/UPDATE/DELETE para authenticated.
-- La escritura debe ocurrir mediante trigger SECURITY DEFINER.
-- ----------------------------------------------------------------------------------

ALTER TABLE public.work_daily_report_personnel ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.work_daily_report_personnel;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de personal puente a autenticados" ON public.work_daily_report_personnel;
DROP POLICY IF EXISTS "work_daily_report_personnel_select_own_or_staff" ON public.work_daily_report_personnel;

CREATE POLICY "work_daily_report_personnel_select_own_or_staff"
ON public.work_daily_report_personnel
FOR SELECT
TO authenticated
USING (
  public.es_admin()
  OR public.es_oficina()
  OR EXISTS (
    SELECT 1
    FROM public.informes_diarios_trabajo i
    WHERE i.id = work_daily_report_id
      AND i.usuario_id = auth.uid()::text
  )
);


-- ----------------------------------------------------------------------------------
-- FASE 2G - Catalogos operativos confirmados
-- ----------------------------------------------------------------------------------
-- Tablas confirmadas:
-- - proveedores_servicio: id, nombre, activo, created_at, updated_at.
-- - maquinaria_obra: id, nombre, activo, created_at, updated_at.
-- - control_materiales: id, nombre, unidad_default, activo, created_at, updated_at.
-- - otros_equipos: id, nombre, activo, created_at, updated_at.
-- - camiones_internos: id, nombre, activo, created_at, updated_at.
-- - funciones_personal: id, nombre, descripcion, activo, created_at, updated_at.
--
-- Patron:
-- - authenticated puede leer activos.
-- - admin/oficina pueden leer activos e inactivos.
-- - solo admin puede escribir.
-- ----------------------------------------------------------------------------------

ALTER TABLE public.proveedores_servicio ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.proveedores_servicio;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catalogos a autenticados" ON public.proveedores_servicio;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON public.proveedores_servicio;
DROP POLICY IF EXISTS "proveedores_servicio_select_authenticated" ON public.proveedores_servicio;
DROP POLICY IF EXISTS "proveedores_servicio_write_admin" ON public.proveedores_servicio;
CREATE POLICY "proveedores_servicio_select_authenticated"
ON public.proveedores_servicio FOR SELECT TO authenticated
USING (activo = true OR public.es_admin() OR public.es_oficina());
CREATE POLICY "proveedores_servicio_write_admin"
ON public.proveedores_servicio FOR ALL TO authenticated
USING (public.es_admin()) WITH CHECK (public.es_admin());

ALTER TABLE public.maquinaria_obra ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.maquinaria_obra;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catalogos a autenticados" ON public.maquinaria_obra;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON public.maquinaria_obra;
DROP POLICY IF EXISTS "maquinaria_obra_select_authenticated" ON public.maquinaria_obra;
DROP POLICY IF EXISTS "maquinaria_obra_write_admin" ON public.maquinaria_obra;
CREATE POLICY "maquinaria_obra_select_authenticated"
ON public.maquinaria_obra FOR SELECT TO authenticated
USING (activo = true OR public.es_admin() OR public.es_oficina());
CREATE POLICY "maquinaria_obra_write_admin"
ON public.maquinaria_obra FOR ALL TO authenticated
USING (public.es_admin()) WITH CHECK (public.es_admin());

ALTER TABLE public.control_materiales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.control_materiales;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catalogos a autenticados" ON public.control_materiales;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON public.control_materiales;
DROP POLICY IF EXISTS "control_materiales_select_authenticated" ON public.control_materiales;
DROP POLICY IF EXISTS "control_materiales_write_admin" ON public.control_materiales;
CREATE POLICY "control_materiales_select_authenticated"
ON public.control_materiales FOR SELECT TO authenticated
USING (activo = true OR public.es_admin() OR public.es_oficina());
CREATE POLICY "control_materiales_write_admin"
ON public.control_materiales FOR ALL TO authenticated
USING (public.es_admin()) WITH CHECK (public.es_admin());

ALTER TABLE public.otros_equipos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.otros_equipos;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catalogos a autenticados" ON public.otros_equipos;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON public.otros_equipos;
DROP POLICY IF EXISTS "otros_equipos_select_authenticated" ON public.otros_equipos;
DROP POLICY IF EXISTS "otros_equipos_write_admin" ON public.otros_equipos;
CREATE POLICY "otros_equipos_select_authenticated"
ON public.otros_equipos FOR SELECT TO authenticated
USING (activo = true OR public.es_admin() OR public.es_oficina());
CREATE POLICY "otros_equipos_write_admin"
ON public.otros_equipos FOR ALL TO authenticated
USING (public.es_admin()) WITH CHECK (public.es_admin());

ALTER TABLE public.camiones_internos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.camiones_internos;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catalogos a autenticados" ON public.camiones_internos;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON public.camiones_internos;
DROP POLICY IF EXISTS "camiones_internos_select_authenticated" ON public.camiones_internos;
DROP POLICY IF EXISTS "camiones_internos_write_admin" ON public.camiones_internos;
CREATE POLICY "camiones_internos_select_authenticated"
ON public.camiones_internos FOR SELECT TO authenticated
USING (activo = true OR public.es_admin() OR public.es_oficina());
CREATE POLICY "camiones_internos_write_admin"
ON public.camiones_internos FOR ALL TO authenticated
USING (public.es_admin()) WITH CHECK (public.es_admin());

ALTER TABLE public.funciones_personal ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Lectura permitida para autenticados" ON public.funciones_personal;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catalogos a autenticados" ON public.funciones_personal;
DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON public.funciones_personal;
DROP POLICY IF EXISTS "funciones_personal_select_authenticated" ON public.funciones_personal;
DROP POLICY IF EXISTS "funciones_personal_write_admin" ON public.funciones_personal;
CREATE POLICY "funciones_personal_select_authenticated"
ON public.funciones_personal FOR SELECT TO authenticated
USING (activo = true OR public.es_admin() OR public.es_oficina());
CREATE POLICY "funciones_personal_write_admin"
ON public.funciones_personal FOR ALL TO authenticated
USING (public.es_admin()) WITH CHECK (public.es_admin());


-- ==================================================================================
-- FASE 3 - REMITOS: PENDIENTE DE VERIFICAR
-- ==================================================================================
-- Riesgo que resuelve:
-- - Evitar lectura/escritura transversal de remitos.
-- - Controlar owner por `auth.uid()`.
-- - Bloquear edicion de remitos sincronizados por operarios.
--
-- Motivo de pendiente:
-- - La migracion completa de `public.remitos` no esta en los archivos revisados.
-- - Flutter usa `remitos`, pero no se confirmo si existe `usuario_id`,
--   `usuario_creador` u otra columna owner.
-- - No generar SQL aplicable hasta inspeccionar columnas reales.
--
-- Queries de inspeccion para ejecutar manualmente en Supabase SQL Editor:
-- ==================================================================================

-- Listar columnas reales de remitos:
-- SELECT
--   column_name,
--   data_type,
--   is_nullable,
--   column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name = 'remitos'
-- ORDER BY ordinal_position;

-- Ver constraints de remitos:
-- SELECT
--   conname,
--   pg_get_constraintdef(c.oid) AS definition
-- FROM pg_constraint c
-- JOIN pg_class t ON t.oid = c.conrelid
-- JOIN pg_namespace n ON n.oid = t.relnamespace
-- WHERE n.nspname = 'public'
--   AND t.relname = 'remitos';

-- Ver RLS y policies actuales de remitos:
-- SELECT
--   schemaname,
--   tablename,
--   policyname,
--   permissive,
--   roles,
--   cmd,
--   qual,
--   with_check
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND tablename = 'remitos'
-- ORDER BY policyname;

-- Ver secuencias relacionadas con remitos:
-- SELECT
--   sequence_schema,
--   sequence_name
-- FROM information_schema.sequences
-- WHERE sequence_schema = 'public'
--   AND sequence_name ILIKE '%remito%';

-- PENDIENTE tras confirmar owner:
-- - Si existe `usuario_id text`, usar `usuario_id = auth.uid()::text`.
-- - Si solo existe `usuario_creador text` y guarda email, considerar migrar a
--   `usuario_id uuid/text` antes de endurecer.
-- - Ajustar Flutter para enviar owner real si hoy no lo envia.


-- ==================================================================================
-- FASE 4 - STORAGE fotos_remitos PRIVADO
-- ==================================================================================
-- Riesgo que resuelve:
-- - Evita exposicion publica de fotos mediante URLs permanentes.
--
-- IMPORTANTE:
-- - REQUIERE CAMBIO FLUTTER PREVIO.
-- - El cliente actual usa `getPublicUrl()` en:
--   - lib/core/providers/remito_provider.dart
--   - lib/core/providers/informe_provider.dart
-- - Si el bucket pasa a privado sin cambiar Flutter, las fotos pueden dejar de verse.
--
-- Cambio Flutter requerido:
-- - Guardar el path interno del objeto, no una URL publica permanente.
-- - Reemplazar `getPublicUrl()` por signed URLs temporales:
--   `createSignedUrl(path, seconds)`.
-- - Alternativamente descargar bytes autenticados desde Storage.
--
-- SQL PROPUESTO, NO EJECUTAR HASTA CAMBIAR FLUTTER:
-- ==================================================================================

-- Marcar bucket como privado:
-- UPDATE storage.buckets
-- SET public = false
-- WHERE id = 'fotos_remitos';

-- Reemplazar policies previas:
-- DROP POLICY IF EXISTS "Fotos - Permitir carga a autenticados" ON storage.objects;
-- DROP POLICY IF EXISTS "Fotos - Permitir lectura a autenticados" ON storage.objects;
-- DROP POLICY IF EXISTS "Fotos - Permitir eliminacion a admins" ON storage.objects;
-- DROP POLICY IF EXISTS "Fotos - Permitir eliminación a admins" ON storage.objects;
-- DROP POLICY IF EXISTS "fotos_remitos_insert_authenticated" ON storage.objects;
-- DROP POLICY IF EXISTS "fotos_remitos_select_authenticated" ON storage.objects;
-- DROP POLICY IF EXISTS "fotos_remitos_delete_admin" ON storage.objects;

-- CREATE POLICY "fotos_remitos_insert_authenticated"
-- ON storage.objects
-- FOR INSERT
-- TO authenticated
-- WITH CHECK (bucket_id = 'fotos_remitos');

-- CREATE POLICY "fotos_remitos_select_authenticated"
-- ON storage.objects
-- FOR SELECT
-- TO authenticated
-- USING (bucket_id = 'fotos_remitos');

-- CREATE POLICY "fotos_remitos_delete_admin"
-- ON storage.objects
-- FOR DELETE
-- TO authenticated
-- USING (
--   bucket_id = 'fotos_remitos'
--   AND public.es_admin()
-- );


-- ==================================================================================
-- SECCION FINAL - QUERIES DE VERIFICACION
-- ==================================================================================
-- Estas queries son de inspeccion. Ejecutarlas manualmente despues de aplicar cambios,
-- no como parte de una migracion automatica.
-- ==================================================================================

-- 1. Listar policies por tabla relevante:
-- SELECT
--   schemaname,
--   tablename,
--   policyname,
--   permissive,
--   roles,
--   cmd,
--   qual,
--   with_check
-- FROM pg_policies
-- WHERE schemaname IN ('public', 'storage')
--   AND tablename IN (
--     'profiles',
--     'personal_empleados',
--     'informes_diarios',
--     'informes_diarios_trabajo',
--     'daily_report_materials',
--     'work_daily_report_personnel',
--     'proveedores_servicio',
--     'maquinaria_obra',
--     'control_materiales',
--     'otros_equipos',
--     'camiones_internos',
--     'funciones_personal',
--     'remitos',
--     'objects'
--   )
-- ORDER BY schemaname, tablename, policyname;

-- 2. Verificar RLS habilitado:
-- SELECT
--   n.nspname AS schema_name,
--   c.relname AS table_name,
--   c.relrowsecurity AS rls_enabled,
--   c.relforcerowsecurity AS rls_forced
-- FROM pg_class c
-- JOIN pg_namespace n ON n.oid = c.relnamespace
-- WHERE n.nspname IN ('public', 'storage')
--   AND c.relkind = 'r'
--   AND c.relname IN (
--     'profiles',
--     'personal_empleados',
--     'informes_diarios',
--     'informes_diarios_trabajo',
--     'daily_report_materials',
--     'work_daily_report_personnel',
--     'proveedores_servicio',
--     'maquinaria_obra',
--     'control_materiales',
--     'otros_equipos',
--     'camiones_internos',
--     'funciones_personal',
--     'remitos',
--     'objects'
--   )
-- ORDER BY schema_name, table_name;

-- 3. Probar funciones de rol en una sesion autenticada:
-- SELECT
--   auth.uid() AS current_auth_uid,
--   public.es_admin() AS es_admin,
--   public.es_oficina() AS es_oficina,
--   public.es_operario() AS es_operario;

-- 4. Listar buckets Storage:
-- SELECT
--   id,
--   name,
--   public,
--   file_size_limit,
--   allowed_mime_types
-- FROM storage.buckets
-- ORDER BY id;

-- 5. Ver objetos recientes de fotos_remitos sin exponer URLs:
-- SELECT
--   bucket_id,
--   name,
--   owner,
--   created_at,
--   updated_at
-- FROM storage.objects
-- WHERE bucket_id = 'fotos_remitos'
-- ORDER BY created_at DESC
-- LIMIT 20;

-- ==================================================================================
-- FIN DEL BORRADOR
-- ==================================================================================
