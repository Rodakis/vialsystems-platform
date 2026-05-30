# SUPABASE SECURITY FIX PLAN - PLAN PROCTOR DE SEGURIDAD Y PERMISOS (VialSystems)

Este documento es una propuesta técnica detallada para corregir y optimizar la seguridad, el acceso a datos (Data API) y las políticas RLS (Row Level Security) en el proyecto **VialSystems**. 

> [!NOTE]
> **ESTATUS DEL PLAN: PROPUESTA TÉCNICA REVISABLE**
> Este plan no realiza modificaciones en la base de datos de producción, no ejecuta sentencias SQL ni altera archivos de migración existentes. Se presenta como una guía de ingeniería de software estructurada para ser revisada y aprobada antes de su implementación en los scripts de migración.

---

## A. Resumen Ejecutivo

### ¿Por qué es necesario este plan?
El análisis del esquema actual de Supabase para VialSystems (ver [SUPABASE_DATA_API_GRANTS_REVIEW.md](file:///c:/DevSrc/vialSystem/SUPABASE_DATA_API_GRANTS_REVIEW.md)) reveló que el proyecto depende de comportamientos heredados de Supabase que están siendo deprecados progresivamente (Data API Exposure). Adicionalmente, se identificaron brechas críticas en las políticas RLS y un error lógico de recursión infinita que impediría el funcionamiento de la aplicación en producción.

### Riesgos que se resuelven con esta propuesta:
1. **Incompatibilidad con nuevos entornos de Supabase**: Garantizar que si la base de datos se despliega en un nuevo servidor de desarrollo, staging o producción, el cliente móvil y web no se bloqueen con errores `403 Forbidden` / `permission denied`.
2. **Bucle de Recursión en Perfiles**: Eliminar el bug lógico en la RLS de la tabla `profiles` que bloquea la consulta de perfiles para administradores debido a desbordamiento de pila en PostgreSQL.
3. **Fugas de Información Sensible**: Restringir el acceso de escritura y lectura global de datos personales de trabajadores (DNI, Teléfono) y catálogos en la tabla `personal_empleados`, que actualmente están expuestos a cualquier usuario autenticado debido a políticas de desarrollo.
4. **Integridad de Reportes y Remitos**: Asegurar que los operadores móviles no puedan editar ni eliminar reportes o remitos que ya han sido sincronizados (es decir, cuyo estado no sea `'borrador'`).
5. **Robustez Transaccional**: Asegurar que las inserciones automatizadas a través de triggers no fallen por falta de permisos en el rol API, encapsulando las transacciones de forma segura.

---

## B. Cambios Propuestos para GRANT (Exposición de Data API)

Con la entrada en vigor de las restricciones de **Data API Exposure** de Supabase, debemos otorgar permisos explícitos de manera estructurada al rol `authenticated` (utilizado por el SDK móvil y web tras el inicio de sesión).

> [!WARNING]
> **POLÍTICA DE PRIVACIDAD SOBRE EL ROL ANON**:
> **No se otorgará ningún permiso (GRANT) ni acceso de lectura/escritura al rol `anon`** (público no autenticado). Dado que VialSystems es una aplicación de circuito cerrado corporativo que requiere inicio de sesión obligatorio para visualizar o reportar información, exponer tablas al rol anónimo viola el principio de mínimo privilegio.

### SQL Propuesto para el Script de Permisos (Data API Grants)

Este bloque de comandos debe colocarse al final de las migraciones para asegurar que todas las tablas y secuencias sean accesibles para el SDK:

```sql
-- 1. Asegurar uso del esquema public por parte del rol authenticated
GRANT USAGE ON SCHEMA public TO authenticated;

-- 2. Otorgar permisos sobre secuencias (vital para remitos autoincrementales 'numero_remito_seq')
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 3. Permisos de lectura en catálogos y perfiles para la app móvil
GRANT SELECT ON public.profiles TO authenticated;
GRANT SELECT ON public.obras TO authenticated;
GRANT SELECT ON public.materiales TO authenticated;
GRANT SELECT ON public.transportistas TO authenticated;
GRANT SELECT ON public.choferes TO authenticated;
GRANT SELECT ON public.camiones TO authenticated;
GRANT SELECT ON public.recibidores TO authenticated;
GRANT SELECT ON public.proveedores_servicio TO authenticated;
GRANT SELECT ON public.maquinaria_obra TO authenticated;
GRANT SELECT ON public.control_materiales TO authenticated;
GRANT SELECT ON public.otros_equipos TO authenticated;
GRANT SELECT ON public.camiones_internos TO authenticated;
GRANT SELECT ON public.funciones_personal TO authenticated;
GRANT SELECT ON public.personal_empleados TO authenticated;

-- 4. Permisos de lectura/escritura en tablas operativas y transaccionales
GRANT SELECT, INSERT, UPDATE, DELETE ON public.remitos TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.informes_diarios TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.informes_diarios_trabajo TO authenticated;

-- 5. Permisos sobre tablas relacionales puente (necesarios para la app y triggers de sincronización)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.daily_report_materials TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.work_daily_report_personnel TO authenticated;

-- 6. Permisos de lectura sobre el archivo histórico (exclusivo para visualización web y auditoría)
GRANT SELECT ON public.historico_remitos TO authenticated;
GRANT SELECT ON public.historico_informes_diarios TO authenticated;
GRANT SELECT ON public.historico_informes_diarios_trabajo TO authenticated;
```

---

## C. Cambios Propuestos para RLS (Endurecimiento de Políticas por Rol)

Las políticas de desarrollo temporales que utilizan `FOR ALL TO authenticated USING (true) WITH CHECK (true)` deben reemplazarse por políticas granulares basadas en los roles del negocio: **Operador**, **Oficina** y **Admin**.

### 1. Rol: Operador (Mobile App)
* **Objetivo**: Permitir ingresar remitos e informes diarios en campo, ver catálogos y registrar datos nuevos solo cuando el estado sea borrador.
* **Políticas Propuestas**:
  * **Catálogos (obras, materiales, choferes, etc.)**: Solo lectura (`SELECT`) de registros activos.
  * **Remitos e Informes**:
    * `SELECT`: Solo registros creados por el propio operador (`usuario_id = auth.uid()::text`).
    * `INSERT`: Permitido para todos los usuarios autenticados.
    * `UPDATE`: Solo permitido si el registro pertenece al operador **y** su estado es `'borrador'`.
    * `DELETE`: Denegado por defecto.

### 2. Rol: Oficina (Web Auditor)
* **Objetivo**: Visualizar todo el mapa operativo del sistema, auditar remitos y exportar reportes, sin privilegios de alteración de catálogos maestros o eliminación física de informes.
* **Políticas Propuestas**:
  * **Catálogos y Transaccionales**: Permiso exclusivo de `SELECT` total sobre todas las tablas del esquema `public` y las tablas históricas.
  * **Escritura (INSERT/UPDATE/DELETE)**: Denegada en todas las tablas operativas.

### 3. Rol: Administrador (Admin Web)
* **Objetivo**: Control absoluto del ecosistema: alta y baja de empleados, asignación de obras, modificación de parámetros maestros y purga de históricos comprimidos.
* **Políticas Propuestas**:
  * Acceso completo (`ALL` - SELECT, INSERT, UPDATE, DELETE) en todas las tablas del esquema `public`.

---

## D. Corrección Propuesta para `profiles` (Evitar Recursión Infinita)

### Diagnóstico del Problema de Recursión
La política de administradores realizaba un `EXISTS` sobre `public.profiles` para validar si el `auth.uid()` tenía rol de admin. Dado que esa misma validación se disparaba recursivamente en cada acceso a la tabla `profiles`, PostgreSQL cancelaba la consulta con un desbordamiento de pila.

### Soluciones Recomendadas

Proponemos **dos alternativas viables** para solucionar este bug de forma definitiva:

---

### Opción A (Recomendada): Usar una Función con `SECURITY DEFINER`
Esta opción crea una función en PostgreSQL que consulta directamente la tabla de perfiles esquivando las políticas de RLS, gracias al modificador `SECURITY DEFINER` (que ejecuta la consulta con privilegios de superusuario/postgres).

```sql
-- 1. Crear función segura para comprobar rol de Administrador
CREATE OR REPLACE FUNCTION public.es_administrador(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id AND role = 'admin' AND activo = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Crear función segura para comprobar rol de Oficina
CREATE OR REPLACE FUNCTION public.es_oficina(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id AND role = 'oficina' AND activo = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

#### Políticas RLS de `profiles` optimizadas con esta Opción:
```sql
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Política 1: Cualquier usuario autenticado puede ver su propio perfil
CREATE POLICY "Profiles - Lectura propia" 
ON public.profiles FOR SELECT 
TO authenticated 
USING (auth.uid() = id);

-- Política 2: Los administradores y personal de oficina pueden ver todos los perfiles
CREATE POLICY "Profiles - Lectura administrativa/oficina" 
ON public.profiles FOR SELECT 
TO authenticated 
USING (public.es_administrador(auth.uid()) OR public.es_oficina(auth.uid()));

-- Política 3: Solo los administradores pueden crear, modificar o borrar perfiles
CREATE POLICY "Profiles - Escritura exclusiva de administradores" 
ON public.profiles FOR ALL 
TO authenticated 
USING (public.es_administrador(auth.uid()))
WITH CHECK (public.es_administrador(auth.uid()));
```
> [!TIP]
> **VENTAJAS DE LA OPCIÓN A**:
> * Es 100% segura e interna de la base de datos.
> * Evita dependencias externas en metadatos del cliente.
> * Se actualiza inmediatamente en tiempo real si el administrador cambia el rol de un usuario en la tabla.

---

### Opción B: Sincronizar el Rol en `app_metadata` del JWT (Máximo Rendimiento)
En Supabase, los reclamos (`claims`) del JWT de sesión de un usuario son de lectura extremadamente rápida. El rol del usuario puede inyectarse directamente en `app_metadata` mediante un trigger automático en la base de datos. 

> [!CAUTION]
> **ADVERTENCIA CRÍTICA DE SEGURIDAD**:
> **No utilizar `user_metadata`** para la asignación de roles. Los usuarios pueden actualizar su propia metadata de usuario directamente desde el SDK del cliente (ej. `supabase.auth.updateUser()`), lo que permitiría escalamiento de privilegios por parte de un usuario malintencionado. En cambio, `app_metadata` es de solo lectura para el cliente y solo puede modificarse mediante llamadas con la clave de servicio (`service_role`) o triggers internos.

#### Implementación de la Sincronización en `app_metadata`:
```sql
-- 1. Función para replicar el rol de profile a auth.users (app_metadata)
CREATE OR REPLACE FUNCTION public.sync_profile_role_to_app_metadata()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object('role', NEW.role)
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Crear Trigger
CREATE OR REPLACE TRIGGER trg_sync_profile_role
AFTER INSERT OR UPDATE OF role ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_profile_role_to_app_metadata();
```

#### Políticas RLS de `profiles` optimizadas con esta Opción:
```sql
-- Los administradores se leen directamente del JWT decodificado en memoria por PostgreSQL (Cero consultas)
CREATE POLICY "Profiles - Lectura administrativa via JWT" 
ON public.profiles FOR SELECT 
TO authenticated 
USING (
  auth.uid() = id OR 
  (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
);
```

---

## E. Revisión y Endurecimiento de Tablas Sensibles

A continuación, se detalla la estrategia de protección propuesta para las tablas identificadas como críticas:

### 1. `profiles`
* **Acción**: Aplicar la **Opción A** (función `es_administrador`) para romper la recursión de lectura, y limitar estrictamente la creación/modificación al rol `admin`.

### 2. `personal_empleados`
* **Riesgo Actual**: Datos de identificación (DNI, Teléfonos) legibles por todos y editables por todos los autenticados.
* **Propuesta RLS**:
  ```sql
  -- Lectura permitida para Operadores (para seleccionar su equipo en partes diarios)
  CREATE POLICY "Empleados - Lectura general" ON public.personal_empleados 
  FOR SELECT TO authenticated USING (activo = true);

  -- Escritura restringida únicamente a administradores
  CREATE POLICY "Empleados - Gestión exclusiva de admins" ON public.personal_empleados 
  FOR ALL TO authenticated 
  USING (public.es_administrador(auth.uid()))
  WITH CHECK (public.es_administrador(auth.uid()));
  ```

### 3. `remitos`
* **Riesgo Actual**: Sin control de edición post-sincronización.
* **Propuesta RLS**:
  ```sql
  -- Operadores: Solo ven e insertan sus remitos
  CREATE POLICY "Remitos - Operador" ON public.remitos 
  FOR SELECT TO authenticated 
  USING (usuario_creador = (SELECT email FROM public.profiles WHERE id = auth.uid()));

  CREATE POLICY "Remitos - Inserción" ON public.remitos 
  FOR INSERT TO authenticated 
  WITH CHECK (usuario_creador = (SELECT email FROM public.profiles WHERE id = auth.uid()));

  -- Administradores y Oficina: Lectura total
  CREATE POLICY "Remitos - Lectura Admin/Oficina" ON public.remitos 
  FOR SELECT TO authenticated 
  USING (public.es_administrador(auth.uid()) OR public.es_oficina(auth.uid()));

  -- Administradores: Modificación de auditoría
  CREATE POLICY "Remitos - Control total Admin" ON public.remitos 
  FOR ALL TO authenticated 
  USING (public.es_administrador(auth.uid()))
  WITH CHECK (public.es_administrador(auth.uid()));
  ```

### 4. `informes_diarios` e `informes_diarios_trabajo`
* **Riesgo Actual**: Modificaciones libres entre operarios y manipulación de partes cerrados.
* **Propuesta RLS**:
  ```sql
  -- Permiso de insertar y leer informes propios
  CREATE POLICY "Informes - Operador lectura y carga" ON public.informes_diarios 
  FOR ALL TO authenticated 
  USING (usuario_id = auth.uid()::text)
  WITH CHECK (usuario_id = auth.uid()::text AND estado = 'borrador');
  ```
  *(Esta política bloquea automáticamente cualquier intento del celular de modificar un informe si el `estado` en la base de datos pasó a `'sincronizado'` o `'listoParaEnviar'`)*.

### 5. Triggers de Materiales y Personal (`daily_report_materials` y `work_daily_report_personnel`)
* **Riesgo Actual**: Pérdida de transacciones y crash de la app al insertar informes si el rol `authenticated` no tiene permisos globales directos sobre estas tablas relacionales secundarias.
* **Propuesta Técnica**:
  Redefinir las funciones de trigger en [supabase_migration.sql](file:///c:/DevSrc/vialSystem/vial_systems/supabase_migration.sql#L149-L207) con el modificador `SECURITY DEFINER` y un `search_path` seguro:
  ```sql
  CREATE OR REPLACE FUNCTION sync_daily_report_materials()
  RETURNS TRIGGER AS $$
  BEGIN
      DELETE FROM daily_report_materials WHERE daily_report_id = NEW.id;
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
  $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
  ```
  *(Al usar `SECURITY DEFINER`, PostgreSQL ejecuta la inserción/borrado puente con privilegios de superusuario, eliminando el riesgo de que la transacción falle debido a restricciones del rol API)*.

---

## F. Propuesta de Revisión y Políticas para Storage

Las evidencias fotográficas de los remitos de acarreo se cargan mediante el cliente móvil al bucket `fotos_remitos` en Supabase Storage. La configuración por defecto del bucket debe endurecerse.

### Diagnóstico Actual
Actualmente, el bucket de almacenamiento está expuesto o corre el riesgo de configurarse en modo "Público" para facilitar el renderizado de imágenes mediante URL directas. Esto permite que cualquier persona con el enlace acceda a las fotografías de obras corporativas y remitos oficiales.

### Acciones Propuestas para el Bucket `fotos_remitos`:

1. **Configurar el Bucket como "Privado"**:
   Las fotos no deben ser accesibles públicamente sin un token firmado temporal.
2. **Definir Políticas RLS para Storage**:
   Las políticas de acceso sobre el bucket deben definirse en el esquema `storage.objects`:
   
   ```sql
   -- A. Permitir la carga de imágenes únicamente a usuarios autenticados
   CREATE POLICY "Fotos - Permitir carga a autenticados" 
   ON storage.objects FOR INSERT 
   TO authenticated 
   WITH CHECK (bucket_id = 'fotos_remitos');

   -- B. Permitir la lectura de imágenes únicamente a usuarios con sesión activa (authenticated)
   CREATE POLICY "Fotos - Permitir lectura a autenticados" 
   ON storage.objects FOR SELECT 
   TO authenticated 
   USING (bucket_id = 'fotos_remitos');

   -- C. Permitir borrado exclusivo a administradores
   CREATE POLICY "Fotos - Permitir eliminación a admins" 
   ON storage.objects FOR DELETE 
   TO authenticated 
   USING (bucket_id = 'fotos_remitos' AND public.es_administrador(auth.uid()));
   ```

---

## G. Orden Recomendado de Implementación

Para llevar a cabo estas correcciones sin afectar la disponibilidad del servicio, se sugiere el siguiente orden cronológico de trabajo en fases controladas:

### 1. Urgente (Antes de Producción / Go-Live)
* **Objetivo**: Asegurar la conectividad de la app y corregir crashes del sistema.
* **Tareas**:
  1. Crear las funciones auxiliares `es_administrador(user_id)` y `es_oficina(user_id)` con `SECURITY DEFINER`.
  2. Implementar la corrección de RLS de `profiles` para disolver el bucle infinito de recursión.
  3. Redefinir las funciones de trigger de `informes_diarios` y `informes_diarios_trabajo` con `SECURITY DEFINER` para evitar fallos de transacción en las tablas puente.
  4. Aplicar el script unificado de `GRANT` para abrir la Data API en el rol `authenticated`.

### 2. Necesario (Antes de Pruebas de Campo con Usuarios Reales)
* **Objetivo**: Limitar la exposición de información sensible y proteger la base de datos contra alteraciones.
* **Tareas**:
  1. Reemplazar las políticas temporales de desarrollo en `personal_empleados` para proteger nombres, DNI y números de contacto.
  2. Endurecer RLS de los catálogos operativos (`proveedores_servicio`, `maquinaria_obra`, `control_materiales`, `otros_equipos`, `camiones_internos`, `funciones_personal`) bloqueando la escritura para operadores e implementándola solo para administradores.
  3. Aplicar RLS en tablas operativas para evitar manipulaciones de informes sincronizados.
  4. Aplicar las políticas del bucket de Storage `fotos_remitos` marcándolo como Privado.

### 3. Mantenimiento Futuro y Monitoreo (Post-Lanzamiento)
* **Objetivo**: Garantizar el crecimiento limpio y escalable del ecosistema.
* **Tareas**:
  1. Monitoreo reactivo de tokens expirados.
  2. Habilitar backups en Point-in-Time Recovery (PITR) y activar automatizaciones pg_cron para la compresión de históricos de remitos de más de 12 meses.
  3. Revisión semestral de permisos para auditorías de cumplimiento normativo de protección de datos.
