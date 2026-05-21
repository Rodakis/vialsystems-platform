import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
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

  final ImagePicker _imagePicker = ImagePicker();
  List<RemitoFotoModel> _fotos = [];

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
      _fotos = List.from(inf.fotos);
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

  Future<String?> _showTipoEvidenciaDialog({String? initialValue}) async {
    String? selectedType = initialValue ?? 'Tareas';
    final types = ['Maquinaria', 'Tareas', 'Personal', 'Otros'];
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tipo de Evidencia'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: types.map((type) {
                  final isSelected = type == selectedType;
                  return ListTile(
                    title: Text(
                      type,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue.shade800 : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Colors.blue.shade800)
                        : const Icon(Icons.circle_outlined, color: Colors.grey),
                    onTap: () {
                      setDialogState(() {
                        selectedType = type;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedType),
              child: const Text('Seleccionar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final authProvider = context.read<AuthProvider>();
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      final tipo = await _showTipoEvidenciaDialog();
      if (tipo != null) {
        final usuario = authProvider.currentUser?.name ?? 'Desconocido';
        setState(() {
          _fotos.add(RemitoFotoModel(
            path: pickedFile.path,
            fecha: DateTime.now(),
            usuario: usuario,
            tipoEvidencia: tipo,
          ));
        });
      }
    }
  }

  Future<void> _replaceImage(int index, ImageSource source) async {
    final authProvider = context.read<AuthProvider>();
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      final oldFoto = _fotos[index];
      final tipo = await _showTipoEvidenciaDialog(initialValue: oldFoto.tipoEvidencia);
      if (tipo != null) {
        final usuario = authProvider.currentUser?.name ?? 'Desconocido';
        setState(() {
          _fotos[index] = RemitoFotoModel(
            path: pickedFile.path,
            fecha: DateTime.now(),
            usuario: usuario,
            tipoEvidencia: tipo,
          );
        });
      }
    }
  }

  void _onReplacePressed(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _replaceImage(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _replaceImage(index, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _fotos.removeAt(index);
    });
  }

  void _saveInforme(RemitoStatus estado) async {
    if (estado == RemitoStatus.listoParaEnviar) {
      if (_selectedObraId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar una obra antes de enviar.')),
        );
        return;
      }
      if (_fotos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidencia fotográfica obligatoria. Debe adjuntar al menos una foto para enviar el reporte.'),
            backgroundColor: Colors.red,
          ),
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
      fotos: _fotos,
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

              // Evidencia Fotográfica Section
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.camera_alt, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  const Text(
                    'Evidencia Fotográfica *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(width: 6),
                  if (!isReadOnly)
                    Text(
                      '(Mínimo 1 para enviar)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_fotos.isNotEmpty)
                Column(
                  children: List.generate(_fotos.length, (index) {
                    final foto = _fotos[index];
                    final isLocal = !foto.path.startsWith('http') && !foto.path.startsWith('blob:');
                    final dateStr = '${foto.fecha.day.toString().padLeft(2, '0')}/${foto.fecha.month.toString().padLeft(2, '0')} ${foto.fecha.hour.toString().padLeft(2, '0')}:${foto.fecha.minute.toString().padLeft(2, '0')}';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.network(foto.path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                                    : (isLocal
                                        ? Image.file(File(foto.path), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                                        : Image.network(foto.path, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Metadata & Badges
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Text(
                                      foto.tipoEvidencia,
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Usuario: ${foto.usuario}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fecha: $dateStr',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons
                            if (!isReadOnly)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.sync, color: Colors.orange, size: 22),
                                    tooltip: 'Reemplazar foto',
                                    onPressed: () => _onReplacePressed(index),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                    tooltip: 'Eliminar foto',
                                    onPressed: () => _removePhoto(index),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              if (_fotos.isEmpty && isReadOnly)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No hay fotos adjuntas.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                ),
              if (!isReadOnly) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Tomar Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade800,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galería'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade800,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

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
