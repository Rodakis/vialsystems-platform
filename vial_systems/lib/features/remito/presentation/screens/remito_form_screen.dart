import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
  List<String> _fotos = [];
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

  void _saveRemito(RemitoStatus estado) {
    if (estado == RemitoStatus.enviado && !_formKey.currentState!.validate()) {
      return;
    }

    if (estado == RemitoStatus.enviado && _fotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe adjuntar al menos 1 foto como evidencia antes de enviar el remito.')),
      );
      return;
    }

    final now = DateTime.now();
    final remito = RemitoModel(
      id: widget.remito?.id ?? now.millisecondsSinceEpoch.toString(),
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

    context.read<RemitoProvider>().saveRemito(remito);
    Navigator.pop(context);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _fotos.add(pickedFile.path);
      });
    }
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
    final isReadOnly = widget.remito?.estado == RemitoStatus.enviado;
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
                value: _selectedObraId,
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
                value: _selectedMaterialId,
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
                value: _selectedTransportistaId,
                decoration: const InputDecoration(labelText: 'Transportista', border: OutlineInputBorder()),
                items: catalogs.transportistas.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre))).toList(),
                onChanged: isReadOnly ? null : (val) => setState(() => _selectedTransportistaId = val),
              ),
              const SizedBox(height: 16),

              // Chofer
              DropdownButtonFormField<String>(
                value: _selectedChoferId,
                decoration: const InputDecoration(labelText: 'Chofer', border: OutlineInputBorder()),
                items: catalogs.choferes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                onChanged: isReadOnly ? null : (val) => setState(() => _selectedChoferId = val),
              ),
              const SizedBox(height: 16),

              // Camion Patente
              DropdownButtonFormField<String>(
                value: _selectedCamionPatente,
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
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: List.generate(_fotos.length, (index) {
                    final isLocal = !_fotos[index].startsWith('http');
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isLocal
                                ? Image.file(File(_fotos[index]), fit: BoxFit.cover)
                                : Image.network(_fotos[index], fit: BoxFit.cover),
                          ),
                        ),
                        if (!isReadOnly)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                color: Colors.black54,
                                child: const Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              if (_fotos.isEmpty && isReadOnly)
                const Text('No hay fotos adjuntas.'),
              if (!isReadOnly) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tomar Foto'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
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
                        onPressed: () => _saveRemito(RemitoStatus.enviado),
                        child: const Text('Enviar Remito'),
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
