import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../../../core/providers/remito_provider.dart';
import '../../domain/models/remito_model.dart';


class RemitoFormScreen extends StatefulWidget {
  final RemitoModel? remito;

  const RemitoFormScreen({super.key, this.remito});

  @override
  State<RemitoFormScreen> createState() => _RemitoFormScreenState();
}

class _RemitoFormScreenState extends State<RemitoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _fecha;
  final _numeroGuiaController = TextEditingController();
  String? _selectedObraId;
  final _procedenciaController = TextEditingController();
  final _destinoController = TextEditingController();
  String? _selectedMaterialId;
  final _cantidadController = TextEditingController();
  String? _selectedTransportistaId;
  String? _selectedChoferId;
  String? _selectedCamionPatente;
  final _acopladoController = TextEditingController();
  late TimeOfDay _horaDescarga;
  final _observacionesController = TextEditingController();
  List<RemitoFotoModel> _fotos = [];
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.remito != null) {
      final r = widget.remito!;
      _fecha = r.fecha;
      _numeroGuiaController.text = r.numeroGuia;
      _selectedObraId = r.obraId;
      _procedenciaController.text = r.procedencia;
      _destinoController.text = r.destino;
      _selectedMaterialId = r.materialId;
      _cantidadController.text = r.cantidadM3.toString();
      _selectedTransportistaId = r.transportistaId;
      _selectedChoferId = r.choferId;
      _selectedCamionPatente = r.camionPatente;
      _acopladoController.text = r.acopladoPatente;
      _horaDescarga = TimeOfDay.fromDateTime(r.horaDescarga);
      _observacionesController.text = r.observaciones;
      _fotos = List.from(r.fotos);
    } else {
      _fecha = DateTime.now();
      _horaDescarga = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _numeroGuiaController.dispose();
    _procedenciaController.dispose();
    _destinoController.dispose();
    _cantidadController.dispose();
    _acopladoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _saveRemito(RemitoStatus estado) async {
    if (estado == RemitoStatus.listoParaEnviar && !_formKey.currentState!.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    // 1. UUID format validation
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    
    final isObraUuid = _selectedObraId == null || _selectedObraId!.isEmpty || uuidRegex.hasMatch(_selectedObraId!);
    final isMaterialUuid = _selectedMaterialId == null || _selectedMaterialId!.isEmpty || uuidRegex.hasMatch(_selectedMaterialId!);
    final isTransportistaUuid = _selectedTransportistaId == null || _selectedTransportistaId!.isEmpty || uuidRegex.hasMatch(_selectedTransportistaId!);
    final isChoferUuid = _selectedChoferId == null || _selectedChoferId!.isEmpty || uuidRegex.hasMatch(_selectedChoferId!);

    debugPrint('=== VALIDACIÓN DE UUID ANTES DE GUARDAR REMITO ===');
    debugPrint('• Obra ID: $_selectedObraId | Es UUID: $isObraUuid');
    debugPrint('• Material ID: $_selectedMaterialId | Es UUID: $isMaterialUuid');
    debugPrint('• Transportista ID: $_selectedTransportistaId | Es UUID: $isTransportistaUuid');
    debugPrint('• Chofer ID: $_selectedChoferId | Es UUID: $isChoferUuid');
    debugPrint('==================================================');

    if (!isObraUuid || !isMaterialUuid || !isTransportistaUuid || !isChoferUuid) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Error: Uno o más de los elementos seleccionados corresponden a IDs numéricos antiguos. Por favor, seleccione elementos del catálogo actual con UUIDs válidos.')),
      );
      return;
    }

    if (estado == RemitoStatus.listoParaEnviar && _fotos.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Debe adjuntar al menos 1 foto como evidencia antes de enviar el remito.')),
      );
      return;
    }

    final now = DateTime.now();
    final remito = RemitoModel(
      id: widget.remito?.id ?? const Uuid().v4(),
      fecha: _fecha,
      numeroGuia: _numeroGuiaController.text.trim(),
      obraId: _selectedObraId,
      procedencia: _procedenciaController.text.trim(),
      destino: _destinoController.text.trim(),
      materialId: _selectedMaterialId,
      cantidadM3: double.tryParse(_cantidadController.text) ?? 0.0,
      transportistaId: _selectedTransportistaId,
      choferId: _selectedChoferId,
      camionPatente: _selectedCamionPatente,
      acopladoPatente: _acopladoController.text.trim(),
      horaDescarga: DateTime(now.year, now.month, now.day, _horaDescarga.hour, _horaDescarga.minute),
      observaciones: _observacionesController.text.trim(),
      estado: estado,
      fotos: _fotos,
    );

    try {
      await context.read<RemitoProvider>().saveRemito(remito);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<String?> _showTipoEvidenciaDialog({String? initialValue}) async {
    String? selectedType = initialValue ?? 'Remito Físico';
    final types = ['Remito Físico', 'Camión / Carga', 'Descarga', 'Otros'];
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
                title: const Text('Galería de Fotos'),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaDescarga,
    );
    if (picked != null) setState(() => _horaDescarga = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = widget.remito != null && widget.remito!.estado != RemitoStatus.borrador;
    final catalogs = context.watch<CatalogProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.remito == null ? 'Nuevo Remito' : 'Detalle de Remito'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Numero de Remito
              TextFormField(
                initialValue: widget.remito?.numeroRemito ?? 'Pendiente de asignación',
                decoration: const InputDecoration(labelText: 'Número de Remito (Interno)', border: OutlineInputBorder()),
                readOnly: true,
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Fecha
              ListTile(
                title: const Text('Fecha'),
                subtitle: Text('${_fecha.day}/${_fecha.month}/${_fecha.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: isReadOnly ? null : _selectDate,
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 16),
              
              // Guia
              TextFormField(
                controller: _numeroGuiaController,
                decoration: const InputDecoration(labelText: 'Número de Guía Oficial *', border: OutlineInputBorder()),
                readOnly: isReadOnly,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Obra
              DropdownButtonFormField<String>(
                initialValue: _selectedObraId,
                decoration: const InputDecoration(labelText: 'Obra', border: OutlineInputBorder()),
                items: catalogs.obras.where((o) => o.activa).map((o) => DropdownMenuItem(value: o.id, child: Text(o.nombre))).toList(),
                onChanged: isReadOnly ? null : (val) => setState(() => _selectedObraId = val),
              ),
              const SizedBox(height: 16),

              // Procedencia y Destino
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _procedenciaController, decoration: const InputDecoration(labelText: 'Procedencia *', border: OutlineInputBorder()), readOnly: isReadOnly, validator: (v) => v!.isEmpty ? 'Req' : null)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _destinoController, decoration: const InputDecoration(labelText: 'Destino *', border: OutlineInputBorder()), readOnly: isReadOnly, validator: (v) => v!.isEmpty ? 'Req' : null)),
                ],
              ),
              const SizedBox(height: 16),

              // Material
              DropdownButtonFormField<String>(
                initialValue: _selectedMaterialId,
                decoration: const InputDecoration(labelText: 'Material *', border: OutlineInputBorder()),
                items: catalogs.materiales.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nombre))).toList(),
                onChanged: isReadOnly ? null : (val) => setState(() => _selectedMaterialId = val),
                validator: (val) => val == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),

              // Cantidad
              TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(labelText: 'Cantidad (m3) *', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                readOnly: isReadOnly,
                validator: (val) => val == null || double.tryParse(val) == null ? 'Número válido' : null,
              ),
              const SizedBox(height: 16),

              // Transportista
              DropdownButtonFormField<String>(
                initialValue: _selectedTransportistaId,
                decoration: const InputDecoration(labelText: 'Transportista', border: OutlineInputBorder()),
                items: catalogs.transportistas.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre))).toList(),
                onChanged: isReadOnly ? null : (val) => setState(() => _selectedTransportistaId = val),
              ),
              const SizedBox(height: 16),

              // Chofer
              DropdownButtonFormField<String>(
                initialValue: _selectedChoferId,
                decoration: const InputDecoration(labelText: 'Chofer', border: OutlineInputBorder()),
                items: catalogs.choferes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                onChanged: isReadOnly ? null : (val) => setState(() => _selectedChoferId = val),
              ),
              const SizedBox(height: 16),

              // Camion Patente
              DropdownButtonFormField<String>(
                initialValue: _selectedCamionPatente,
                decoration: const InputDecoration(labelText: 'Matrícula Camión', border: OutlineInputBorder()),
                items: catalogs.camiones.map((c) => DropdownMenuItem(value: c.patente, child: Text(c.patente))).toList(),
                onChanged: isReadOnly ? null : (val) => setState(() => _selectedCamionPatente = val),
              ),
              const SizedBox(height: 16),

              // Acoplado
              TextFormField(
                controller: _acopladoController,
                decoration: const InputDecoration(labelText: 'Matrícula Acoplado', border: OutlineInputBorder()),
                readOnly: isReadOnly,
              ),
              const SizedBox(height: 16),

              // Hora
              ListTile(
                title: const Text('Hora de Descarga'),
                subtitle: Text(_horaDescarga.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: isReadOnly ? null : _selectTime,
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 16),

              // Observaciones
              TextFormField(
                controller: _observacionesController,
                decoration: const InputDecoration(labelText: 'Observaciones', border: OutlineInputBorder()),
                maxLines: 3,
                readOnly: isReadOnly,
              ),
              const SizedBox(height: 16),
              
              // Evidencia fotografica
              const Text('Evidencia Fotográfica *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galería'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),

              if (!isReadOnly) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _saveRemito(RemitoStatus.borrador),
                        child: const Text('Guardar Borrador'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _saveRemito(RemitoStatus.listoParaEnviar),
                        child: const Text('Guardar y Enviar'),
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
