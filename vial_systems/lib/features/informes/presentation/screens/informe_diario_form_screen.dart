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
import '../../domain/models/informe_diario_model.dart';

class InformeDiarioFormScreen extends StatefulWidget {
  final InformeDiarioModel? informe;

  const InformeDiarioFormScreen({super.key, this.informe});

  @override
  State<InformeDiarioFormScreen> createState() => _InformeDiarioFormScreenState();
}

class _InformeDiarioFormScreenState extends State<InformeDiarioFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _fecha;
  String? _selectedObraId;
  String _clima = 'Soleado';
  String _estadoCamino = 'Transitable';
  final _observacionesController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  List<RemitoFotoModel> _fotos = [];

  final List<Map<String, dynamic>> _climaOptions = [
    {'label': 'Soleado', 'icon': Icons.wb_sunny, 'color': Colors.orange},
    {'label': 'Nublado', 'icon': Icons.cloud, 'color': Colors.blueGrey},
    {'label': 'Lluvioso', 'icon': Icons.grain, 'color': Colors.blue},
    {'label': 'Viento fuerte', 'icon': Icons.air, 'color': Colors.teal},
    {'label': 'Nieve', 'icon': Icons.ac_unit, 'color': Colors.lightBlueAccent},
  ];

  final List<Map<String, dynamic>> _caminoOptions = [
    {'label': 'Transitable', 'icon': Icons.check_circle_outline, 'color': Colors.green},
    {'label': 'Transitable con precaución', 'icon': Icons.warning_amber_rounded, 'color': Colors.orange},
    {'label': 'Intransitable', 'icon': Icons.block, 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.informe != null) {
      final inf = widget.informe!;
      _fecha = inf.fecha;
      _selectedObraId = inf.obraId;
      _clima = inf.clima;
      _estadoCamino = inf.estadoCamino;
      _observacionesController.text = inf.observaciones;
      _fotos = List.from(inf.fotos);
    } else {
      _fecha = DateTime.now();
    }
  }

  @override
  void dispose() {
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
    String? selectedType = initialValue ?? 'Clima';
    final types = ['Clima', 'Estado del Camino', 'Accesos / Obra', 'Otros'];
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

    final nuevoInforme = InformeDiarioModel(
      id: widget.informe?.id ?? const Uuid().v4(),
      fecha: _fecha,
      obraId: _selectedObraId,
      usuarioId: usuarioId,
      usuarioName: usuarioName,
      clima: _clima,
      estadoCamino: _estadoCamino,
      observaciones: _observacionesController.text.trim(),
      estado: estado,
      fotos: _fotos,
    );

    try {
      await context.read<InformeProvider>().saveInformeDiario(nuevoInforme);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(estado == RemitoStatus.borrador
                ? 'Borrador guardado localmente'
                : 'Informe listo para enviar (se sincronizará al conectar)'),
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
            ? 'Nuevo Informe Diario'
            : (isReadOnly ? 'Detalle de Informe Diario' : 'Editar Informe Diario')),
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
                          'Este informe ya ha sido guardado / enviado y no puede modificarse.',
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
                  title: const Text('Fecha del Informe', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 20),

              // Clima Selection UI
              const Text(
                'Condición del Clima *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _climaOptions.map((opt) {
                  final label = opt['label'] as String;
                  final icon = opt['icon'] as IconData;
                  final color = opt['color'] as Color;
                  final isSelected = _clima == label;

                  return GestureDetector(
                    onTap: isReadOnly ? null : () => setState(() => _clima = label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade50,
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: isSelected ? color : Colors.grey.shade600, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? (color == Colors.orange ? Colors.orange.shade900 : color) : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Camino Selection UI
              const Text(
                'Estado del Camino *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Column(
                children: _caminoOptions.map((opt) {
                  final label = opt['label'] as String;
                  final icon = opt['icon'] as IconData;
                  final color = opt['color'] as Color;
                  final isSelected = _estadoCamino == label;

                  return GestureDetector(
                    onTap: isReadOnly ? null : () => setState(() => _estadoCamino = label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 15,
                                color: isSelected ? color : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: color, size: 20)
                          else
                            const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
                  labelText: 'Observaciones / Notas adicionales',
                  hintText: 'Ingrese comentarios relevantes sobre las condiciones climáticas, del camino, incidencias, etc...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
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
