# VialSystems - Prompts por Fase para Antigravity

Usar un archivo por fase. No pegar todas las fases juntas.

## Fase 00 - Preparacion y reglas del proyecto

```text
Actua como arquitecto senior Flutter. Crea solamente la base inicial del proyecto VialSystems para Android. Debe incluir estructura limpia de carpetas, README, convenciones de nombres y pantalla inicial placeholder. No implementes formularios, dashboard web, PDFs, notificaciones, IA, GPS ni sincronizacion avanzada. El objetivo es dejar una base estable para trabajar por fases.
```

## Fase 01 - Autenticacion y roles basicos

```text
Implementa en VialSystems un modulo de autenticacion basico con login individual por usuario y password. Crea modelos simples de usuario y roles: operador, oficina y administrador. Guarda la sesion localmente para pruebas. No implementes multiempresa, SSO, MFA ni permisos complejos. Mantener codigo modular y facil de reemplazar luego por Supabase o Firebase.
```

## Fase 02 - Gestion base de obras y catalogos

```text
Implementa la gestion base de obras y catalogos compartidos para VialSystems. Crear modelos y pantallas simples para Obras, Materiales, Transportistas, Choferes, Camiones y Recibidores. Las obras deben poder estar activas o cerradas. Los catalogos deben estar disponibles para los formularios y permitir agregar nuevas opciones. No implementes reportes, costos avanzados ni integraciones externas.
```

## Fase 03 - Modulo principal: Informe de Acarreo de Materiales

```text
Implementa solamente el modulo Informe de Acarreo de Materiales de VialSystems. Regla central: un remito corresponde a un viaje. Campos requeridos: fecha, numero de guia oficial, obra, procedencia del material, destino, tipo de material, cantidad en m3, empresa transportista, chofer, matricula camion, matricula acoplado, hora de descarga y observaciones opcionales. Debe permitir guardar borrador y enviar. Validar obligatorios antes de enviar. Usar dropdowns con opcion Agregar. No implementes otros formularios, dashboard web ni PDFs todavia.
```

## Fase 04 - Evidencia fotografica obligatoria

```text
Agrega al modulo Informe de Acarreo de Materiales una capa de evidencia fotografica obligatoria. Cada remito debe tener al menos 1 foto valida asociada al numero de guia/remito antes de poder enviarse. Permitir tomar o adjuntar foto, ver miniaturas, eliminar o reemplazar antes del envio y guardar metadatos: remito, fecha, usuario y tipo de evidencia. Comprimir imagen para uso movil. No implementar IA visual, GPS ni almacenamiento cloud avanzado todavia.
```

## Fase 05 - Offline parcial y cola de sincronizacion

```text
Implementa offline parcial para VialSystems. Los formularios de acarreo y sus fotos deben guardarse localmente si no hay conexion. Crear una cola de sincronizacion con estados: borrador, listo para enviar, sincronizado y error. Mostrar pantalla de pendientes y permitir reintento manual. Evitar duplicados por numero de guia oficial. No implementes conflictos avanzados ni replicacion compleja.
```

## Fase 06 - Backend cloud y sincronizacion basica

```text
Conecta VialSystems a un backend cloud, preferentemente Supabase o Firebase. Crear estructura para usuarios, obras, catalogos, remitos de acarreo y fotos. Sincronizar remitos enviados desde la cola local, subir fotos y guardar su referencia. Agregar timestamps y usuario creador. Incluir reglas basicas de seguridad. No implementar SaaS multiempresa, dashboards avanzados, WhatsApp ni Excel todavia.
```

## Fase 07 - Panel web administrativo inicial

```text
Implementa el panel web administrativo inicial para VialSystems. Debe permitir login simple, ver dashboard operacional basico, listar remitos enviados, filtrar por obra, fecha, material y transportista, abrir detalle del remito y ver fotos asociadas. Separar vista oficina/admin. No implementar analytics avanzados, SaaS multiempresa ni integracion Excel todavia.
```

## Fase 08 - Informes diario y diario de trabajo

```text
Agrega los modulos Informe Diario e Informe Diario de Trabajo como formularios independientes dentro de VialSystems. Deben asociarse a una obra activa, usuario responsable y fecha. Reutilizar componentes ya creados para validaciones, guardado local y sincronizacion. No mezclar estos formularios con el Informe de Acarreo de Materiales. Mantener cada documento independiente.
```

## Fase 09 - Reportes PDF simples y busqueda avanzada

```text
Implementa reportes PDF simples en el panel web de VialSystems. Crear PDF individual de remito y PDF filtrado por obra/fecha. Incluir datos principales y fotos o referencias a fotos si corresponde. Agregar busqueda avanzada por obra, fecha, usuario, material y transportista. No crear plantillas complejas, facturacion ni reportes financieros avanzados.
```

## Fase 10 - Alertas, notificaciones y control de pendientes

```text
Agrega alertas y notificaciones basicas a VialSystems para reducir perdida de informacion. Alertar cuando existan borradores sin enviar, remitos sin foto obligatoria, errores de sincronizacion o documentos pendientes por obra/usuario. Si el backend lo permite, implementar push notifications simples. No crear automatizaciones IA complejas ni saturar al usuario con mensajes.
```

## Fase 11 - Retencion, backups y preparacion para escalar

```text
Prepara VialSystems para cierre de MVP profesional. Documenta politica de retencion: 12 meses almacenamiento normal, 6 meses comprimido y eliminacion programada posterior. Configura backups iniciales, checklist de QA y roadmap post-MVP. No implementar SaaS multiempresa, IA avanzada, WhatsApp, Excel ni APIs externas hasta que el MVP este estable.
```
