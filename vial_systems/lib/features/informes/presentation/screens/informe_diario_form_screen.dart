import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../../../core/providers/informe_provider.dart';
import '../../../../features/catalogs/domain/models/catalog_models.dart';
import '../../../remito/domain/models/remito_model.dart';
import '../../domain/models/informe_diario_model.dart';

class InformeDiarioFormScreen extends StatefulWidget {
  final InformeDiarioModel? informe;
  final String? preselectedObraId;

  const InformeDiarioFormScreen({super.key, this.informe, this.preselectedObraId});

  @override
  State<InformeDiarioFormScreen> createState() => _InformeDiarioFormScreenState();
}

class _InformeDiarioFormScreenState extends State<InformeDiarioFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _fecha;
  String? _selectedObraId;
  final _observacionesController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  List<RemitoFotoModel> _fotos = [];

  // Listas de IDs seleccionados para los catálogos operativos
  List<String> _proveedoresIds = [];
  List<String> _maquinariasIds = [];
  List<InformeMaterialItem> _materiales = [];
  List<String> _equiposIds = [];
  List<String> _camionesIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.informe != null) {
      final inf = widget.informe!;
      _fecha = inf.fecha;
      _selectedObraId = inf.obraId;
      _observacionesController.text = inf.observaciones;
      _fotos = List.from(inf.fotos);
      _proveedoresIds = List.from(inf.proveedoresIds);
      _maquinariasIds = List.from(inf.maquinariasIds);
      _materiales = List.from(inf.materiales);
      _equiposIds = List.from(inf.equiposIds);
      _camionesIds = List.from(inf.camionesIds);
    } else {
      _fecha = DateTime.now();
      _selectedObraId = widget.preselectedObraId;
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
    String? selectedType = initialValue ?? 'Obra';
    final types = ['Obra', 'Proveedores', 'Maquinaria / Equipos', 'Materiales', 'Otros'];
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
              childTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _replaceImage(index, ImageSource.camera);
                },
              ),
              childTile(
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

  Widget childTile({required Widget leading, required Widget title, required VoidCallback onTap}) {
    return ListTile(
      leading: leading,
      title: title,
      onTap: onTap,
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
      proveedoresIds: _proveedoresIds,
      maquinariasIds: _maquinariasIds,
      materiales: _materiales,
      equiposIds: _equiposIds,
      camionesIds: _camionesIds,
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

  Future<void> _startVoiceInput(TextEditingController controller) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String transcript = '';
            bool isListening = true;
            
            // Simular transcripción de voz progresiva
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted && isListening) {
                setDialogState(() {
                  transcript = 'Se completó la excavación del sector norte';
                });
              }
            });
            
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted && isListening) {
                setDialogState(() {
                  transcript = 'Se completó la excavación del sector norte y el perfilado de banquinas';
                });
              }
            });

            Future.delayed(const Duration(milliseconds: 3500), () {
              if (context.mounted && isListening) {
                setDialogState(() {
                  transcript = 'Se completó la excavación del sector norte, el perfilado de banquinas y limpieza de calzada.';
                  isListening = false;
                });
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.mic, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Text('Reconocimiento de Voz'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isListening) ...[
                    const SizedBox(height: 8),
                    const SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(color: Colors.red, strokeWidth: 3),
                    ),
                    const SizedBox(height: 20),
                    const Text('Escuchando activamente...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ] else ...[
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 54),
                    const SizedBox(height: 16),
                    const Text('Transcripción Completada', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      transcript.isEmpty ? 'Por favor hable ahora...' : transcript,
                      style: TextStyle(
                        fontStyle: transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
                        color: transcript.isEmpty ? Colors.grey.shade600 : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    isListening = false;
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                if (!isListening)
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        controller.text += '\n$transcript';
                      } else {
                        controller.text = transcript;
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Insertar Texto'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCatalogPanel({
    required String title,
    required IconData icon,
    required List<OperativeCatalogItem> items,
    required List<String> selectedIds,
    required ValueChanged<List<String>> onChanged,
    required bool isReadOnly,
  }) {
    final activeItems = items.where((item) => item.activa || selectedIds.contains(item.id)).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: Colors.blue.shade700),
          title: Text(
            '$title (${selectedIds.length} seleccionados)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          children: [
            if (activeItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'No hay opciones activas en este catálogo.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: activeItems.length,
                  itemBuilder: (context, index) {
                    final item = activeItems[index];
                    final isChecked = selectedIds.contains(item.id);

                    return CheckboxListTile(
                      activeColor: Colors.blue.shade700,
                      dense: true,
                      title: Text(
                        item.nombre,
                        style: TextStyle(
                          color: item.activa ? Colors.black87 : Colors.grey,
                          decoration: item.activa ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      value: isChecked,
                      onChanged: isReadOnly
                          ? null
                          : (bool? value) {
                              final newSelection = List<String>.from(selectedIds);
                              if (value == true) {
                                newSelection.add(item.id);
                              } else {
                                newSelection.remove(item.id);
                              }
                              onChanged(newSelection);
                            },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialesPanel({
    required List<OperativeCatalogItem> activeCatalogItems,
    required bool isReadOnly,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _materiales.isNotEmpty,
          leading: Icon(Icons.inventory_2, color: Colors.blue.shade700),
          title: Text(
            'Control de Materiales (${_materiales.length} agregados)',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_materiales.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'No se han agregado materiales.',
                            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _materiales.length,
                      separatorBuilder: (context, index) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final item = _materiales[index];

                        // Find selected catalog item to display name if read-only
                        final catalogItem = activeCatalogItems.firstWhere(
                          (c) => c.id == item.materialId,
                          orElse: () => OperativeCatalogItem(id: '', nombre: 'Desconocido'),
                        );

                        if (isReadOnly) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    catalogItem.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${item.cantidad}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.unidad,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Form controllers or local state change
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dropdown Material
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: item.materialId.isEmpty ? null : item.materialId,
                                decoration: const InputDecoration(
                                  labelText: 'Material',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                items: activeCatalogItems.map((c) {
                                  return DropdownMenuItem<String>(
                                    value: c.id,
                                    child: Text(c.nombre, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final catItem = activeCatalogItems.firstWhere((c) => c.id == val);
                                    setState(() {
                                      _materiales[index] = InformeMaterialItem(
                                        materialId: val,
                                        cantidad: item.cantidad,
                                        unidad: catItem.unidadDefault ?? item.unidad,
                                        observacion: item.observacion,
                                      );
                                    });
                                  }
                                },
                                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Cantidad input
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: item.cantidad > 0 ? item.cantidad.toString() : '',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Cant.',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final cant = double.tryParse(val) ?? 0.0;
                                  setState(() {
                                    _materiales[index] = InformeMaterialItem(
                                      materialId: item.materialId,
                                      cantidad: cant,
                                      unidad: item.unidad,
                                      observacion: item.observacion,
                                    );
                                  });
                                },
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Requerido';
                                  final d = double.tryParse(val);
                                  if (d == null) return 'Inválido';
                                  if (d <= 0) return '> 0';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Unidad dropdown
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                initialValue: item.unidad.isEmpty ? null : item.unidad,
                                decoration: const InputDecoration(
                                  labelText: 'Unid.',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'm³', child: Text('m³')),
                                  DropdownMenuItem(value: 'toneladas', child: Text('ton')),
                                  DropdownMenuItem(value: 'viajes', child: Text('viajes')),
                                  DropdownMenuItem(value: 'unidades', child: Text('unid')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _materiales[index] = InformeMaterialItem(
                                        materialId: item.materialId,
                                        cantidad: item.cantidad,
                                        unidad: val,
                                        observacion: item.observacion,
                                      );
                                    });
                                  }
                                },
                                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _materiales.removeAt(index);
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  if (!isReadOnly) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _materiales.add(InformeMaterialItem(
                            materialId: '',
                            cantidad: 0.0,
                            unidad: 'm³',
                          ));
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar Material'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade800,
                        side: BorderSide(color: Colors.blue.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              const SizedBox(height: 24),

              // Dynamic catalog sections
              const Text(
                'Catálogos Operativos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              
              _buildCatalogPanel(
                title: 'Proveedores de Servicio',
                icon: Icons.business,
                items: catalogs.proveedores,
                selectedIds: _proveedoresIds,
                onChanged: (ids) => setState(() => _proveedoresIds = ids),
                isReadOnly: isReadOnly,
              ),

              _buildCatalogPanel(
                title: 'Maquinaria de Obra',
                icon: Icons.construction,
                items: catalogs.maquinarias,
                selectedIds: _maquinariasIds,
                onChanged: (ids) => setState(() => _maquinariasIds = ids),
                isReadOnly: isReadOnly,
              ),

              _buildMaterialesPanel(
                activeCatalogItems: catalogs.materialesControl,
                isReadOnly: isReadOnly,
              ),

              _buildCatalogPanel(
                title: 'Otros Equipos',
                icon: Icons.handyman,
                items: catalogs.otrosEquipos,
                selectedIds: _equiposIds,
                onChanged: (ids) => setState(() => _equiposIds = ids),
                isReadOnly: isReadOnly,
              ),

              _buildCatalogPanel(
                title: 'Camiones Internos',
                icon: Icons.local_shipping,
                items: catalogs.camionesInternos,
                selectedIds: _camionesIds,
                onChanged: (ids) => setState(() => _camionesIds = ids),
                isReadOnly: isReadOnly,
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

              // Observaciones (Con dictado por voz)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Observaciones / Notas adicionales',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      if (!isReadOnly)
                        IconButton(
                          icon: const Icon(Icons.mic, color: Colors.red),
                          tooltip: 'Dictar observaciones por voz',
                          onPressed: () => _startVoiceInput(_observacionesController),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _observacionesController,
                    decoration: InputDecoration(
                      hintText: 'Ingrese comentarios relevantes sobre las condiciones climáticas, del camino, incidencias, etc...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    readOnly: isReadOnly,
                  ),
                ],
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
