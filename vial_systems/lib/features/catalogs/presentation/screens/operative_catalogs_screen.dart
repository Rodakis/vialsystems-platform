import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/catalog_models.dart';

class OperativeCatalogsScreen extends StatefulWidget {
  const OperativeCatalogsScreen({super.key});

  @override
  State<OperativeCatalogsScreen> createState() => _OperativeCatalogsScreenState();
}

class _OperativeCatalogsScreenState extends State<OperativeCatalogsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.currentUser?.role == UserRole.administrador;

    if (!isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Acceso denegado. Se requieren permisos de administrador.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            isScrollable: true,
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Proveedores'),
              Tab(text: 'Maquinaria'),
              Tab(text: 'Control Materiales'),
              Tab(text: 'Otros Equipos'),
              Tab(text: 'Camiones Internos'),
              Tab(text: 'Personal'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCatalogTab(
                title: 'Proveedores de Servicio',
                items: catalogProvider.proveedores,
                onAdd: (nombre, [unidad]) => catalogProvider.addProveedor(nombre),
                onEdit: (item) => catalogProvider.updateProveedor(item),
                onToggle: (item) => catalogProvider.toggleProveedorStatus(item),
              ),
              _buildCatalogTab(
                title: 'Maquinaria de Obra',
                items: catalogProvider.maquinarias,
                onAdd: (nombre, [unidad]) => catalogProvider.addMaquinaria(nombre),
                onEdit: (item) => catalogProvider.updateMaquinaria(item),
                onToggle: (item) => catalogProvider.toggleMaquinariaStatus(item),
              ),
              _buildCatalogTab(
                title: 'Control de Materiales',
                items: catalogProvider.materialesControl,
                onAdd: (nombre, [unidad]) => catalogProvider.addMaterialControl(nombre, unidadDefault: unidad),
                onEdit: (item) => catalogProvider.updateMaterialControl(item),
                onToggle: (item) => catalogProvider.toggleMaterialControlStatus(item),
                isMaterial: true,
              ),
              _buildCatalogTab(
                title: 'Otros Equipos',
                items: catalogProvider.otrosEquipos,
                onAdd: (nombre, [unidad]) => catalogProvider.addOtroEquipo(nombre),
                onEdit: (item) => catalogProvider.updateOtroEquipo(item),
                onToggle: (item) => catalogProvider.toggleOtroEquipoStatus(item),
              ),
              _buildCatalogTab(
                title: 'Camiones Internos',
                items: catalogProvider.camionesInternos,
                onAdd: (nombre, [unidad]) => catalogProvider.addCamionInterno(nombre),
                onEdit: (item) => catalogProvider.updateCamionInterno(item),
                onToggle: (item) => catalogProvider.toggleCamionInternoStatus(item),
              ),
              _buildCatalogTab(
                title: 'Personal',
                items: catalogProvider.funcionesPersonal,
                onAdd: (nombre, [unidad]) => catalogProvider.addFuncionPersonal(nombre),
                onEdit: (item) => catalogProvider.updateFuncionPersonal(item),
                onToggle: (item) => catalogProvider.toggleFuncionPersonalStatus(item),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogTab({
    required String title,
    required List<OperativeCatalogItem> items,
    required Future<void> Function(String, [String?]) onAdd,
    required Future<void> Function(OperativeCatalogItem) onEdit,
    required Future<void> Function(OperativeCatalogItem) onToggle,
    bool isMaterial = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length} elementos en total',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar Item'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showAddDialog(title, onAdd, isMaterial: isMaterial),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay elementos en este catálogo',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          title: Text(
                            item.nombre,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: item.activa ? null : TextDecoration.lineThrough,
                              color: item.activa ? Colors.black87 : Colors.grey[500],
                            ),
                          ),
                          subtitle: Container(
                            margin: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  item.activa ? Icons.circle : Icons.circle_outlined,
                                  size: 10,
                                  color: item.activa ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.activa ? 'Activo' : 'Inactivo (Soft-deleted)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: item.activa ? Colors.green[700] : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isMaterial && item.unidadDefault != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '•  Unidad: ${item.unidadDefault}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                tooltip: 'Editar Nombre',
                                onPressed: () => _showEditDialog(item, onEdit, isMaterial: isMaterial),
                              ),
                              Switch(
                                value: item.activa,
                                activeThumbColor: Colors.green,
                                onChanged: (val) async {
                                  try {
                                    await onToggle(item);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error al cambiar estado: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(String catalogTitle, Future<void> Function(String, [String?]) onSave, {bool isMaterial = false}) {
    final txtController = TextEditingController();
    String? selectedUnidad = 'm³';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Nuevo elemento en $catalogTitle'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: txtController,
                    decoration: const InputDecoration(
                      hintText: 'Ej. Nombre o descripción...',
                      labelText: 'Nombre / Descripción',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    autofocus: true,
                  ),
                  if (isMaterial) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnidad,
                      decoration: const InputDecoration(
                        labelText: 'Unidad por Defecto',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'm³', child: Text('m³ (Metros Cúbicos)')),
                        DropdownMenuItem(value: 'toneladas', child: Text('toneladas (Toneladas)')),
                        DropdownMenuItem(value: 'viajes', child: Text('viajes (Viajes)')),
                        DropdownMenuItem(value: 'unidades', child: Text('unidades (Unidades)')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedUnidad = val;
                        });
                      },
                    ),
                  ],
                ],
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = txtController.text.trim();
                if (val.isNotEmpty) {
                  try {
                    if (isMaterial) {
                      await onSave(val, selectedUnidad);
                    } else {
                      await onSave(val);
                    }
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(OperativeCatalogItem item, Future<void> Function(OperativeCatalogItem) onSave, {bool isMaterial = false}) {
    final txtController = TextEditingController(text: item.nombre);
    String? selectedUnidad = item.unidadDefault ?? 'm³';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Editar Elemento'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: txtController,
                    decoration: const InputDecoration(
                      hintText: 'Editar nombre...',
                      labelText: 'Nombre / Descripción',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    autofocus: true,
                  ),
                  if (isMaterial) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedUnidad,
                      decoration: const InputDecoration(
                        labelText: 'Unidad por Defecto',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'm³', child: Text('m³ (Metros Cúbicos)')),
                        DropdownMenuItem(value: 'toneladas', child: Text('toneladas (Toneladas)')),
                        DropdownMenuItem(value: 'viajes', child: Text('viajes (Viajes)')),
                        DropdownMenuItem(value: 'unidades', child: Text('unidades (Unidades)')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedUnidad = val;
                        });
                      },
                    ),
                  ],
                ],
              );
            }
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final val = txtController.text.trim();
                if (val.isNotEmpty) {
                  try {
                    final updatedItem = OperativeCatalogItem(
                      id: item.id,
                      nombre: val,
                      activa: item.activa,
                      unidadDefault: isMaterial ? selectedUnidad : item.unidadDefault,
                    );
                    await onSave(updatedItem);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}
