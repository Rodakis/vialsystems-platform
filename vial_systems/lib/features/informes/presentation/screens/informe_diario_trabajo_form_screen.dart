import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../../../core/providers/informe_provider.dart';
import '../../../remito/domain/models/remito_model.dart';
import '../../domain/models/informe_diario_trabajo_model.dart';

class InformeDiarioTrabajoFormScreen extends StatefulWidget {
  final InformeDiarioTrabajoModel? informe;

  const InformeDiarioTrabajoFormScreen({super.key, this.informe});

  @override
  State<InformeDiarioTrabajoFormScreen> createState() => _InformeDiarioTrabajoFormScreenState();
}

class _InformeDiarioTrabajoFormScreenState extends State<InformeDiarioTrabajoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _fecha;
  String? _selectedObraId;
  final _tareasController = TextEditingController();
  final _horasController = TextEditingController();
  final _personalController = TextEditingController();
  final _maquinariaController = TextEditingController();
  final _observacionesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.informe != null) {
      final inf = widget.informe!;
      _fecha = inf.fecha;
      _selectedObraId = inf.obraId;
      _tareasController.text = inf.tareasRealizadas;
      _horasController.text = inf.horasTrabajadas.toString();
      _personalController.text = inf.personalPresente.toString();
      _maquinariaController.text = inf.maquinariaUtilizada;
      _observacionesController.text = inf.observaciones;
    } else {
      _fecha = DateTime.now();
    }
  }

  @override
  void dispose() {
    _tareasController.dispose();
    _horasController.dispose();
    _personalController.dispose();
    _maquinariaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _fecha = picked);
    }
  }

  void _saveInforme(RemitoStatus estado) async {
    if (estado == RemitoStatus.listoParaEnviar) {
      if (_selectedObraId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar una obra antes de enviar.')),
        );
        return;
      }
      if (!_formKey.currentState!.validate()) return;
    }

    final authProvider = context.read<AuthProvider>();
    final usuarioId = authProvider.currentUser?.id ?? '';
    final usuarioName = authProvider.currentUser?.name ?? 'Desconocido';

    final horas = double.tryParse(_horasController.text) ?? 0.0;
    final personal = int.tryParse(_personalController.text) ?? 0;

    final nuevoInforme = InformeDiarioTrabajoModel(
      id: widget.informe?.id ?? const Uuid().v4(),
      fecha: _fecha,
      obraId: _selectedObraId,
      usuarioId: usuarioId,
      usuarioName: usuarioName,
      tareasRealizadas: _tareasController.text.trim(),
      horasTrabajadas: horas,
      personalPresente: personal,
      maquinariaUtilizada: _maquinariaController.text.trim(),
      observaciones: _observacionesController.text.trim(),
      estado: estado,
    );

    try {
      await context.read<InformeProvider>().saveInformeDiarioTrabajo(nuevoInforme);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(estado == RemitoStatus.borrador
                ? 'Borrador guardado localmente'
                : 'Diario de trabajo listo para enviar (se sincronizará al conectar)'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogs = context.watch<CatalogProvider>();
    final isReadOnly = widget.informe != null && widget.informe!.estado != RemitoStatus.borrador;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.informe == null
            ? 'Nuevo Diario de Trabajo'
            : (isReadOnly ? 'Detalle de Diario de Trabajo' : 'Editar Diario de Trabajo')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner if read-only
              if (isReadOnly) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este diario de trabajo ya ha sido guardado / enviado y no puede modificarse.',
                          style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Date selector
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: const Text('Fecha de Trabajo', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${_fecha.day}/${_fecha.month}/${_fecha.year}'),
                  trailing: isReadOnly ? null : const Icon(Icons.arrow_drop_down),
                  onTap: isReadOnly ? null : _selectDate,
                ),
              ),
              const SizedBox(height: 16),

              // Obra Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedObraId,
                decoration: InputDecoration(
                  labelText: 'Obra *',
                  prefixIcon: const Icon(Icons.engineering),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: catalogs.obras.where((o) => o.activa || o.id == _selectedObraId).map((o) {
                  return DropdownMenuItem(
                    value: o.id,
                    child: Text(o.nombre),
                  );
                }).toList(),
                onChanged: isReadOnly ? null : (val) => setState(() => _selectedObraId = val),
                validator: (val) => val == null ? 'Seleccione una obra' : null,
              ),
              const SizedBox(height: 16),

              // Hours and Personal Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horas Trabajadas
                  Expanded(
                    child: TextFormField(
                      controller: _horasController,
                      decoration: InputDecoration(
                        labelText: 'Horas Trabajadas *',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'e.g. 8.5',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: isReadOnly,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        final doubleVal = double.tryParse(val);
                        if (doubleVal == null) return 'Número inválido';
                        if (doubleVal < 0 || doubleVal > 24) return 'Entre 0 y 24';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Personal Presente
                  Expanded(
                    child: TextFormField(
                      controller: _personalController,
                      decoration: InputDecoration(
                        labelText: 'Personal Presente *',
                        prefixIcon: const Icon(Icons.people),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'e.g. 5',
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: isReadOnly,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        final intVal = int.tryParse(val);
                        if (intVal == null) return 'Número entero';
                        if (intVal < 0) return 'Mayor o igual a 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tareas Realizadas
              TextFormField(
                controller: _tareasController,
                decoration: InputDecoration(
                  labelText: 'Tareas Realizadas *',
                  hintText: 'Describa de forma detallada las tareas completadas en la jornada...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                readOnly: isReadOnly,
                validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese las tareas realizadas' : null,
              ),
              const SizedBox(height: 16),

              // Maquinaria Utilizada
              TextFormField(
                controller: _maquinariaController,
                decoration: InputDecoration(
                  labelText: 'Maquinaria Utilizada',
                  hintText: 'Equipos y maquinaria pesada operando (e.g. Motoniveladora CAT-12, Excavadora, etc.)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                readOnly: isReadOnly,
              ),
              const SizedBox(height: 16),

              // Observaciones
              TextFormField(
                controller: _observacionesController,
                decoration: InputDecoration(
                  labelText: 'Observaciones generales',
                  hintText: 'Comentarios adicionales, retrasos, roturas, incidentes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                readOnly: isReadOnly,
              ),
              const SizedBox(height: 32),

              // Buttons
              if (!isReadOnly) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.drafts),
                        onPressed: () => _saveInforme(RemitoStatus.borrador),
                        label: const Text('Guardar Borrador'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.blue.shade700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        onPressed: () => _saveInforme(RemitoStatus.listoParaEnviar),
                        label: const Text('Enviar Reporte'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
