# VialSystems - Preparación para Producción, Mantenimiento y Escalamiento (MVP v0.1)

Este documento establece las políticas de administración de datos, estrategias de respaldo, plan de recuperación ante desastres y el roadmap tecnológico estratégico para asegurar que `VialSystems` transicione del Mínimo Producto Viable (MVP) a un entorno de producción altamente confiable y escalable.

---

## 1. Política de Retención y Ciclo de Vida de los Datos

Para optimizar costos de infraestructura en la nube (especialmente almacenamiento de base de datos y adjuntos pesados en Supabase Storage) y garantizar consultas eficientes en tiempo real, se define la siguiente política de ciclo de vida de los datos de acarreo e informes diarios:

### 📅 Resumen del Ciclo de Vida de los Datos

```
[0 a 12 meses] ──────────► [12 a 18 meses] ──────────► [18+ meses]
 Datos Activos              Histórico Comprimido        Purga Manual Confirmada
 (Lectura/Escritura)        (Solo Lectura / No Blobs)  (Procedimiento Seguro)
```

1. **Datos Activos (0 a 12 meses desde la creación)**:
   * **Alcance**: Todos los Remitos de Acarreo, Informes Diarios y Diarios de Trabajo con su metadata completa, relaciones, evidencias fotográficas y registros puente.
   * **Disponibilidad**: Lectura y escritura en caliente tanto en la app del operador móvil como en la consola web de administración.
2. **Histórico Comprimido (12 a 18 meses de antigüedad)**:
   * **Alcance**: Los registros son archivados y movidos automáticamente a las tablas de archivo histórico (`historico_remitos`, `historico_informes_diarios`, etc.).
   * **Compresión lógica**: Se mantiene intacta la metadata transaccional clave (fechas, volúmenes de material, guías, transportistas, choferes y firmas digitales) para fines de auditoría legal y análisis anual.
   * **Fotos y Binarios**: En esta versión preliminar, **no se borran archivos físicos de fotos**, pero se marca el estado del registro histórico. En futuras optimizaciones, se mantendrá la miniatura optimizada y se purgará el blob original de alta resolución.
   * **Disponibilidad**: Modo solo lectura desde el panel web administrativo y excluidos de las sincronizaciones por defecto de la aplicación móvil de los operadores para evitar sobrecargar el ancho de banda y la caché local.
3. **Purga Futura (Más de 18 meses de antigüedad)**:
   * **Alcance**: Los registros e informes con una antigüedad superior a 18 meses pasan a la cola de depuración.
   * **Regla de Seguridad**: **NO se realizan purgas automáticas ni destrucciones de registros por defecto**.
   * **Mecanismo**: La eliminación física de datos históricos requiere una **confirmación administrativa explícita y manual** por medio de una interfaz de control web cifrada o un procedimiento manual de base de datos, garantizando que ninguna información crítica se pierda por fallas de cron.

---

## 2. Estrategia de Backups y Recuperación ante Desastres (DRP)

### A. Respaldos Cloud (Supabase / PostgreSQL)
1. **Backups Diarios Automatizados**:
   * Supabase realiza de forma predeterminada copias de seguridad físicas en caliente de la base de datos PostgreSQL diariamente.
   * Ventana de retención por defecto: 7 días en planes iniciales (ampliable hasta 30 días).
2. **Point-in-Time Recovery (PITR)**:
   * **Recomendación para Producción**: Para aplicaciones con alta transaccionalidad donde los operadores envían remitos constantemente, se recomienda activar PITR en Supabase.
   * **Funcionamiento**: Permite restaurar el estado exacto de la base de datos a cualquier segundo de los últimos 7 días escribiendo de forma continua los Write-Ahead Logs (WAL) a buckets seguros de Amazon S3, minimizando la pérdida de transacciones a prácticamente cero.

### B. Respaldo Local (SQLite en Dispositivos Móviles)
* La cola de sincronización local del dispositivo actúa como un **primer respaldo físico distribuido**.
* Los archivos en SQLite persisten localmente en el sandbox del dispositivo móvil. En caso de pérdida de conexión o destrucción del servidor central, los borradores locales y elementos listos para enviar no se pierden y pueden ser recuperados mediante exportaciones locales de la caché si fuera necesario.

### C. Plan de Recuperación ante Desastres (Disaster Recovery Plan - DRP)

* **Objetivo de Punto de Recuperación (RPO - Recovery Point Objective)**: Máximo 24 horas (usando backups diarios) o 10 segundos (si se habilita PITR).
* **Objetivo de Tiempo de Recuperación (RTO - Recovery Time Objective)**: Menos de 2 horas para restablecer el servicio de lectura/escritura a través de una base de datos clonada.

#### Protocolo de Restauración ante Caídas Catastróficas:
1. **Detección**: Monitoreo reactivo de disponibilidad mediante Supabase Health Checks y reportes de errores HTTP 5xx.
2. **Contención**: Interrupción temporal de las escrituras cloud en la app móvil (activando automáticamente la cola local offline) para evitar corrupción de datos.
3. **Restauración**:
   * Ingresar a la consola de administración de Supabase Cloud.
   * Seleccionar la pestaña de Backups y elegir la versión del snapshot diario más reciente (o elegir el segundo exacto mediante PITR si está activo).
   * Confirmar la restauración de la base de datos a la instancia seleccionada.
4. **Verificación**: Comprobar conectividad y consistencia de catálogos mediante la ejecución del panel web administrativo.
5. **Re-Sincronización**: Habilitar nuevamente las transmisiones en la aplicación del operador para descargar en lote los elementos acumulados en SQLite local.

---

## 3. Checklist de QA para Lanzamiento del MVP (v0.1)

El siguiente listado de casos de prueba debe ejecutarse exhaustivamente de forma manual antes de dar de alta la versión productiva inicial:

| Módulo / Característica | Descripción del Caso de Prueba | Resultado Esperado | Estado |
| :--- | :--- | :--- | :---: |
| **Autenticación** | Login con credenciales de Operador (`user@test.com`) y Administrador (`admin@test.com`). | Acceso concedido al dashboard correspondiente; rechazo de contraseñas incorrectas con alert visual. | `[ ]` |
| **Catálogos Operativos** | Creación, modificación y desactivación (Soft-Delete) de Empleados y Roles en el panel administrativo. | Indicador gris elegante en inactivos; inclusión segura en dropdowns de informes existentes pero excluidos de nuevos. | `[ ]` |
| **Remito - Foto Obligatoria** | Guardar borrador de Remito con 0 fotos; e intentar Enviar/Sincronizar el mismo Remito sin fotos. | Guardado de borrador exitoso; bloqueo estricto en Enviar/Procesar con alerta roja en pantalla destacando la sección. | `[ ]` |
| **Remito - UUID Válido** | Carga y guardado de un nuevo Remito de acarreo desde el celular. | Consola muestra logs formateados con validaciones UUID exitosas; se evita la inserción de IDs numéricos viejos de mock. | `[ ]` |
| **Informes Diarios** | Carga de un nuevo Informe Diario y un nuevo Diario de Trabajo completando personal y horas trabajadas. | Bloqueo en horas superiores a 24 o negativas; persistencia exitosa local e inserciones a través de triggers PL/pgSQL. | `[ ]` |
| **Cola Offline** | Apagar la conexión a internet del dispositivo, completar un remito con foto y pulsar "Enviar". | Se almacena localmente en SQLite con estado `borrador` o `listoParaEnviar`; aparece badge reactivo en la campana. | `[ ]` |
| **Sincronizar Todo** | Conectar internet y presionar "Sincronizar Todo" con mezcla de borradores incompletos y remitos listos. | Sincroniza únicamente los listos; muestra barra de éxito real con conteo preciso (`Sincronizados: X / Incompletos: Y`). | `[ ]` |
| **Reportes PDF** | Exportar un Remito individual y un listado consolidado filtrado a PDF desde la web en Chrome. | Generación de archivo A4 vertical/horizontal formateado con metadata y referencias; se abre vista nativa de impresión. | `[ ]` |
| **Alertas Faltantes** | Iniciar sesión como Administrador en una fecha donde no se cargó parte diario para una obra activa. | Aparecen alertas azules informativas en el Drawer lateral con el botón "Crear"; el atajo pre-selecciona la obra en el dropdown. | `[ ]` |

---

## 4. Roadmap Tecnológico Post-MVP (Fases 12 a 15)

Una vez lograda la estabilización absoluta del MVP v0.1 en campo, se dará inicio a la expansión de funcionalidades críticas:

### 🚀 Fase 12: SaaS Multiempresa y Aislamiento de Clientes
* **Estrategia Central**: Arquitectura de **aislamiento lógico** basada en un identificador unificado `empresa_id` transversal en todas las tablas operativas.
* **Seguridad RLS (Row Level Security)**: Restricción absoluta de consultas a nivel de motor PostgreSQL de Supabase inyectando el reclamo personalizado (`claims`) de `empresa_id` desde el JWT de autenticación:
  ```sql
  CREATE POLICY "Acceso por empresa" ON remitos 
  USING (empresa_id = ((auth.jwt() -> 'user_metadata' ->> 'empresa_id')::UUID));
  ```
* **Interfaz**: Portal administrativo unificado para gestión de suscripciones de múltiples empresas independientes operando sobre la misma app.

### 💬 Fase 13: WhatsApp y Notificaciones de Alertas Críticas
* **Enfoque Inicial**: Integración prioritaria orientada a **notificaciones y alertas automáticas enviadas a capataces, inspectores y personal de oficina** (no a clientes finales en una primera instancia).
* **Casos de Uso**:
  * Envío de alertas de partes diarios faltantes al final de la jornada laboral a los encargados de obra.
  * Reportes consolidados matutinos de volúmenes de acarreo transportados por obra el día anterior.
* **Tecnología**: Uso de Webhooks y APIs oficiales de proveedores autorizados de WhatsApp Business (como Twilio o MessageBird).

### 📊 Fase 14: Reportes Avanzados, Auditorías e Integración con Excel
* **Exportación Avanzada**: Generación e importación de reportes tabulares avanzados en formato Microsoft Excel (.xlsx) con tablas dinámicas y cálculos preestablecidos de rendimiento de combustible y horas hombre.
* **Módulo de Auditoría**: Pistas de auditoría completas que registren modificaciones sobre remitos históricos (quién modificó un volumen y bajo qué justificación operativa).

### 🧠 Fase 15: Automatizaciones Inteligentes con Inteligencia Artificial (IA)
* **Dictado y Análisis de Voz en la Nube**: Transcripción y análisis semántico de observaciones de campo dictadas por voz mediante servicios avanzados de NLP (Natural Language Processing) para clasificar incidentes automáticamente.
* **Optimización de Asignaciones**: Algoritmos de sugerencia inteligente para optimizar rutas de camiones y distribución de maquinaria basándose en el historial operativo de los partes diarios anteriores.
