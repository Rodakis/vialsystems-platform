# SUPABASE DATA API GRANTS REVIEW - AUDITORÍA DE SEGURIDAD Y PERMISOS (VialSystems)

Este documento presenta una auditoría exhaustiva de la estructura de base de datos de **VialSystems** en Supabase, realizada en respuesta a las recientes directivas de Supabase sobre **Data API Exposure**.

> [!IMPORTANT]
> **ESTATUS DE LA TAREA: ÚNICAMENTE AUDITORÍA / REVISIÓN**
> De acuerdo con las instrucciones estrictas del proyecto, **no se ha modificado ninguna tabla, no se han ejecutado sentencias ALTER TABLE o GRANT, ni se han alterado políticas RLS o datos**. Este documento sirve como diagnóstico técnico y plan de remediación antes del pase a producción.

---

## 1. Resumen del Cambio de Supabase (Data API Exposure)

Históricamente, las instancias de Supabase exponían de forma automática todas las tablas creadas en el esquema `public` a las APIs REST (PostgREST) y GraphQL. Esto se lograba mediante la concesión automática de privilegios globales:
```sql
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
```

### El Cambio de Políticas de Supabase (Línea de Tiempo 2026)
* **Proyectos Nuevos (Desde el 30 de Mayo de 2026)**: Los nuevos proyectos ya **no** exponen automáticamente las tablas del esquema `public` a la Data API. Los roles `anon` y `authenticated` no tienen acceso por defecto.
* **Proyectos Existentes (Desde el 30 de Octubre de 2026)**: Cualquier nueva tabla creada a partir de esta fecha requerirá sentencias `GRANT` explícitas para ser accesible mediante clientes `supabase-js`, `supabase_flutter` o consultas directas HTTP REST/GraphQL.

Para garantizar el funcionamiento de la aplicación en cualquier entorno (incluyendo nuevos servidores de staging o producción creados para el lanzamiento), **VialSystems debe declarar explícitamente los privilegios sobre cada tabla expuesta**.

---

## 2. Impacto Posible en VialSystems

Si VialSystems se despliega en un nuevo proyecto de Supabase (por ejemplo, para producción o una nueva empresa cliente) sin adaptar su esquema a este cambio, ocurrirá lo siguiente:

1. **Fallo Catastrófico de Inicialización**: La aplicación móvil y el panel web administrativo experimentarán errores `401 Unauthorized` o `403 Forbidden` inmediatamente al intentar consultar o modificar cualquier catálogo, perfil o informe.
2. **Fallas Silenciosas en Procesos Transaccionales (Triggers)**: Las tablas relacionales puente como `daily_report_materials` y `work_daily_report_personnel` son escritas mediante triggers PL/pgSQL que se ejecutan bajo los privilegios del usuario activo. Al no contar con privilegios explícitos sobre estas tablas secundarias, las inserciones principales de reportes fallarán.
3. **Bloqueo en la Generación de Secuencias**: Los remitos autoincrementales utilizan secuencias internas para generar su identificador visual (`numero_remito_seq`). Si el rol `authenticated` no tiene privilegios explícitos sobre estas secuencias, el proceso de sincronización móvil arrojará un error.

---

## 3. Tabla de Revisión por Tabla Encontrada

A continuación se presenta el inventario completo de las **22 tablas** identificadas en la base de datos de VialSystems, clasificadas según su uso, políticas RLS y estado de seguridad:

| # | Nombre de la Tabla | ¿Usada por App Móvil? | ¿Usada por Panel Web? | ¿RLS Activo? | Permisos Rol `anon` | Permisos Rol `authenticated` | ¿Requiere Revisión antes de Producción? |
| :--- | :--- | :---: | :---: | :---: | :--- | :--- | :---: |
| 1 | `profiles` | **Sí** (Login) | **Sí** | **Sí** | Ninguno | SELECT (Propio), ALL (Admins) | **Sí (CRÍTICO - RLS Recursivo)** |
| 2 | `remitos` | **Sí** (Acarreos) | **Sí** | **Sí** | Ninguno | SELECT, INSERT, UPDATE | **Sí (Alto - Requiere GRANT)** |
| 3 | `obras` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, INSERT/UPDATE (Admin) | **Sí (Medio - Requiere GRANT)** |
| 4 | `materiales` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, INSERT (Admin) | **Sí (Medio - Requiere GRANT)** |
| 5 | `transportistas` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, INSERT (Admin) | **Sí (Medio - Requiere GRANT)** |
| 6 | `choferes` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, INSERT (Admin) | **Sí (Medio - Requiere GRANT)** |
| 7 | `camiones` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, INSERT (Admin) | **Sí (Medio - Requiere GRANT)** |
| 8 | `recibidores` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, INSERT (Admin) | **Sí (Medio - Requiere GRANT)** |
| 9 | `proveedores_servicio` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Dev/ALL) | **Sí (Alto - RLS Vulnerable)** |
| 10 | `maquinaria_obra` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Dev/ALL) | **Sí (Alto - RLS Vulnerable)** |
| 11 | `control_materiales` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Dev/ALL) | **Sí (Alto - RLS Vulnerable)** |
| 12 | `otros_equipos` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Dev/ALL) | **Sí (Alto - RLS Vulnerable)** |
| 13 | `camiones_internos` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Dev/ALL) | **Sí (Alto - RLS Vulnerable)** |
| 14 | `funciones_personal` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Dev/ALL) | **Sí (Alto - RLS Vulnerable)** |
| 15 | `personal_empleados` | **Sí** (Catálogo) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Dev/ALL) | **Sí (CRÍTICO - Datos Sensibles)** |
| 16 | `informes_diarios` | **Sí** (Reportes) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Operador/Admin) | **Sí (Alto - RLS Permisivo)** |
| 17 | `informes_diarios_trabajo` | **Sí** (Reportes) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Operador/Admin) | **Sí (Alto - RLS Permisivo)** |
| 18 | `daily_report_materials` | No directo (Trigger) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Dev) | **Sí (CRÍTICO - Fallo de Trigger)** |
| 19 | `work_daily_report_personnel` | No directo (Trigger) | **Sí** | **Sí** | Ninguno | SELECT, ALL (Dev) | **Sí (CRÍTICO - Fallo de Trigger)** |
| 20 | `historico_remitos` | No | **Sí** | **Sí** | Ninguno | SELECT (Histórico) | **Sí (Medio - Requiere GRANT)** |
| 21 | `historico_informes_diarios` | No | **Sí** | **Sí** | Ninguno | SELECT (Histórico) | **Sí (Medio - Requiere GRANT)** |
| 22 | `historico_informes_diarios_trabajo`| No | **Sí** | **Sí** | Ninguno | SELECT (Histórico) | **Sí (Medio - Requiere GRANT)** |

---

## 4. Análisis de Tablas Sensibles y de Privacidad

La auditoría identificó varias tablas con requerimientos estrictos de seguridad de datos:

### A. `profiles`
* **Definición**: Vincula usuarios de `auth.users` con su nombre, correo y rol de negocio (`admin`, `user`, `oficina`).
* **Estado de Privacidad**: El rol `anon` no tiene permisos, lo cual es correcto. Sin embargo, existe una **vulnerabilidad técnica crítica en su RLS** (ver Sección 5).

### B. `personal_empleados`
* **Definición**: Contiene datos reales identificatorios de los trabajadores internos (nombre, apellido, documento, teléfono, identificador/legajo).
* **Estado de Privacidad**: Actualmente se encuentra bajo una política temporal de desarrollo que permite **escritura, edición y lectura global a cualquier usuario autenticado**. Cualquier operador con acceso a la app móvil podría realizar consultas masivas de documentos y teléfonos, o modificarlos maliciosamente. **Debe ser restringida de inmediato antes de producción.**

### C. `remitos`, `informes_diarios` e `informes_diarios_trabajo`
* **Definición**: Contienen datos operativos, volúmenes de tierra/tosca acarreados, y horas hombre trabajadas en obras activas.
* **Estado de Privacidad**: Las políticas de RLS de desarrollo permiten `ALL` (todas las operaciones) para todos los usuarios autenticados. En producción, un operador no debería tener capacidad de editar o borrar remitos o informes ya sincronizados e integrados en la base histórica.

### D. Gestión de Fotos (`fotos`)
* **Clarificación**: No existe una tabla `fotos` en la base de datos de VialSystems. La aplicación gestiona las imágenes a través de **Supabase Storage** en el bucket `fotos_remitos`, y almacena las URL absolutas en formato `JSONB` dentro de las tablas `remitos`, `informes_diarios` y `informes_diarios_trabajo`. 
* **Riesgo**: El bucket de almacenamiento `fotos_remitos` debe ser auditado de forma independiente para asegurar que las políticas de Storage restrinjan la lectura únicamente a usuarios con sesión activa (`authenticated`).

---

## 5. Riesgos Críticos Detectados

### 🚨 RIESGO 1: Bloqueo Total de la App por Falta de GRANTs Explícitos
* **Descripción**: Los archivos SQL actuales ([supabase_migration.sql](file:///c:/DevSrc/vialSystem/vial_systems/supabase_migration.sql) y [create_profiles_table.sql](file:///c:/DevSrc/vialSystem/vial_systems/docs/create_profiles_table.sql)) carecen de sentencias `GRANT` explícitas.
* **Consecuencia**: Al desplegar en un entorno de Supabase nuevo para producción (creado después de Mayo de 2026), todas las peticiones desde el cliente móvil o web fallarán con errores de autorización (`403 Forbidden` / `permission denied`), impidiendo el funcionamiento completo del sistema.

### 🚨 RIESGO 2: Fallo Silencioso de Sincronización en Triggers de Materiales y Personal
* **Descripción**: Los triggers `trg_sync_daily_report_materials` y `trg_sync_work_daily_report_personnel` ejecutan funciones PL/pgSQL que no están marcadas como `SECURITY DEFINER`. Por defecto, se ejecutan con los privilegios del usuario conectado (`authenticated`).
* **Consecuencia**: Si el usuario no tiene permisos directos de escritura en las tablas puente relacionales `daily_report_materials` y `work_daily_report_personnel`, el motor de base de datos rechazará la transacción completa. Al insertar un `informe_diario`, la app móvil recibirá un error y fallará la sincronización, a pesar de que el usuario tenga privilegios en la tabla padre.

### 🚨 RIESGO 3: Bucle de Recursión Infinita (Stack Overflow) en la RLS de `profiles`
* **Descripción**: La política de RLS para administradores sobre `profiles` se define así:
  ```sql
  CREATE POLICY "Administradores pueden ver todos los perfiles" 
  ON public.profiles FOR SELECT TO authenticated 
  USING (
      EXISTS (
          SELECT 1 FROM public.profiles 
          WHERE public.profiles.id = auth.uid() 
            AND public.profiles.role = 'admin'
      )
  );
  ```
* **Consecuencia**: Cuando un usuario administrador realiza una consulta sobre `profiles`, el motor de base de datos evalúa la política, que realiza una subconsulta en `profiles` para verificar el rol. Esto dispara nuevamente la evaluación de la misma política de forma infinita, resultando en un error de desbordamiento de pila o cancelación de la consulta por parte de PostgreSQL. **Ningún administrador podrá ver la lista de usuarios.**

### 🚨 RIESGO 4: Políticas de Desarrollo con Control Total Activas por Defecto
* **Descripción**: Múltiples catálogos y tablas operativas poseen políticas RLS marcadas como `"Desarrollo: Permitir escritura de..."` que utilizan la cláusula `FOR ALL TO authenticated USING (true) WITH CHECK (true)`.
* **Consecuencia**: Cualquier usuario registrado de la aplicación (incluso operadores en obra) posee privilegios totales para editar o eliminar catálogos maestros como maquinaria, proveedores, o empleados, destruyendo la integridad y trazabilidad de los datos de la empresa.

---

## 6. Recomendaciones y Plan de Acción

Para garantizar un pase a producción seguro, robusto y alineado con los estándares actuales de Supabase, se proponen las siguientes acciones clasificadas por urgencia:

### A. Acción Urgente
1. **Crear un Script de Exposición de Data API (Grants)**:
   Añadir un bloque de sentencias explícitas de permisos al final del script de migración para garantizar la comunicación con PostgREST en nuevos entornos:
   ```sql
   -- Otorgar uso de esquemas y secuencias
   GRANT USAGE ON SCHEMA public TO authenticated;
   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

   -- Permisos de lectura en catálogos y perfiles para la app móvil
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

   -- Permisos de escritura y lectura en tablas transaccionales
   GRANT SELECT, INSERT, UPDATE, DELETE ON public.remitos TO authenticated;
   GRANT SELECT, INSERT, UPDATE, DELETE ON public.informes_diarios TO authenticated;
   GRANT SELECT, INSERT, UPDATE, DELETE ON public.informes_diarios_trabajo TO authenticated;
   
   -- Permisos para tablas relacionales modificadas por triggers
   GRANT SELECT, INSERT, UPDATE, DELETE ON public.daily_report_materials TO authenticated;
   GRANT SELECT, INSERT, UPDATE, DELETE ON public.work_daily_report_personnel TO authenticated;
   GRANT SELECT ON public.historico_remitos TO authenticated;
   GRANT SELECT ON public.historico_informes_diarios TO authenticated;
   GRANT SELECT ON public.historico_informes_diarios_trabajo TO authenticated;
   ```

2. **Declarar Triggers con SECURITY DEFINER**:
   Modificar las funciones de los triggers para asegurar que se ejecuten bajo privilegios administrativos seguros, independientemente de los grants otorgados al rol API:
   ```sql
   CREATE OR REPLACE FUNCTION sync_daily_report_materials()
   RETURNS TRIGGER AS $$
   BEGIN
       -- Lógica de sincronización...
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
   ```

3. **Corregir Recursión Infinita en Perfiles**:
   Utilizar la información contenida en el JWT (inyectada por el trigger de login en la metadata del usuario de Supabase Auth) para evitar la subconsulta cíclica:
   ```sql
   DROP POLICY IF EXISTS "Administradores pueden ver todos los perfiles" ON public.profiles;
   CREATE POLICY "Administradores pueden ver todos los perfiles" 
   ON public.profiles FOR SELECT 
   TO authenticated 
   USING (
       (auth.jwt() ->> 'role' = 'service_role') OR
       (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin') OR
       (auth.uid() = id) -- Permite ver su propio perfil
   );
   ```

---

### B. Acción Antes de Producción
1. **Endurecer Políticas RLS de Catálogos (Admins vs. Operadores)**:
   Reemplazar las políticas de desarrollo permisivas por restricciones basadas en roles reales. Por ejemplo, para `proveedores_servicio`:
   ```sql
   -- Solo lectura para operadores normales
   DROP POLICY IF EXISTS "Desarrollo: Permitir escritura de catálogos a autenticados" ON proveedores_servicio;
   
   -- Permitir select general
   CREATE POLICY "Lectura permitida para autenticados" ON proveedores_servicio FOR SELECT TO authenticated USING (true);
   
   -- Restringir inserción, actualización y borrado exclusivo a administradores
   CREATE POLICY "Escritura exclusiva para administradores" ON proveedores_servicio 
   FOR ALL TO authenticated 
   USING (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin') 
   WITH CHECK (auth.jwt() -> 'user_metadata' ->> 'role' = 'admin');
   ```
   *(Aplicar esta misma lógica de endurecimiento a maquinaria_obra, control_materiales, otros_equipos, camiones_internos, funciones_personal y personal_empleados)*.

2. **Restringir Operaciones en Reportes Sincronizados**:
   Asegurar que los operadores móviles no puedan editar ni eliminar informes que ya han sido sincronizados (es decir, cuyo estado no sea `'borrador'`).
   ```sql
   DROP POLICY IF EXISTS "Permitir escritura de reportes a autenticados" ON informes_diarios;
   
   CREATE POLICY "Permitir inserción de reportes" ON informes_diarios 
   FOR INSERT TO authenticated 
   WITH CHECK (usuario_id = auth.uid()::text);
   
   CREATE POLICY "Permitir edición de borradores propios" ON informes_diarios 
   FOR UPDATE TO authenticated 
   USING (usuario_id = auth.uid()::text AND estado = 'borrador')
   WITH CHECK (usuario_id = auth.uid()::text AND estado = 'borrador');
   ```

3. **Verificar RLS en Tablas Heredadas**:
   Garantizar que las tablas `remitos`, `obras`, `materiales`, `transportistas`, `choferes`, `camiones` y `recibidores` tengan explícitamente activada la seguridad de fila (`ENABLE ROW LEVEL SECURITY`) y políticas de select correspondientes.

4. **Blindar el Rol Anon**:
   Asegurar que ninguna tabla sensible sea expuesta al rol `anon`. El rol `anon` no debe tener privilegios `GRANT` ni políticas RLS que expongan información transaccional u operativa.

---

### C. Acción Futura / Mantenimiento
1. **Activar Point-in-Time Recovery (PITR)**:
   Activar PITR en la consola de Supabase de producción para habilitar recuperaciones ante desastres al segundo exacto, lo cual es vital para el flujo constante de sincronización de remitos de los choferes.
2. **Automatización pg_cron**:
   Cuando la base de datos se estabilice en producción, descomentar y habilitar los cron jobs en [retention_backup_jobs.sql](file:///c:/DevSrc/vialSystem/vial_systems/docs/retention_backup_jobs.sql) para automatizar el archivado mensual de remitos antiguos e informes hacia el archivo histórico.
3. **Auditoría de Logs en Storage**:
   Implementar políticas de seguridad restrictivas en Supabase Storage para evitar el acceso público no autorizado a las imágenes almacenadas en el bucket `fotos_remitos`.
