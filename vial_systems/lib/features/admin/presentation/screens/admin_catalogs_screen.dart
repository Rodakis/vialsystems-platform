import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../catalogs/domain/models/catalog_models.dart';

class AdminCatalogsScreen extends StatefulWidget {
  const AdminCatalogsScreen({super.key});

  @override
  State<AdminCatalogsScreen> createState() => _AdminCatalogsScreenState();
}

class _AdminCatalogsScreenState extends State<AdminCatalogsScreen> with SingleTickerProviderStateMixin {
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

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Obras'),
            Tab(text: 'Materiales'),
            Tab(text: 'Transportistas'),
            Tab(text: 'Choferes'),
            Tab(text: 'Camiones'),
            Tab(text: 'Recibidores'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildObrasTab(catalogProvider, isAdmin),
              _buildSimpleTab(catalogProvider, 'Materiales', catalogProvider.materiales.map((e) => e.nombre).toList(), (val) => catalogProvider.addMaterial(val), isAdmin),
              _buildSimpleTab(catalogProvider, 'Transportistas', catalogProvider.transportistas.map((e) => e.nombre).toList(), (val) => catalogProvider.addTransportista(val), isAdmin),
              _buildSimpleTab(catalogProvider, 'Choferes', catalogProvider.choferes.map((e) => e.nombre).toList(), (val) => catalogProvider.addChofer(val), isAdmin),
              _buildSimpleTab(catalogProvider, 'Camiones (Patentes)', catalogProvider.camiones.map((e) => e.patente).toList(), (val) => catalogProvider.addCamion(val), isAdmin),
              _buildSimpleTab(catalogProvider, 'Recibidores', catalogProvider.recibidores.map((e) => e.nombre).toList(), (val) => catalogProvider.addRecibidor(val), isAdmin),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildObrasTab(CatalogProvider provider, bool isAdmin) {
    return _buildListLayout(
      title: 'Obras Activas',
      items: provider.obras,
      onAdd: isAdmin ? () => _showAddDialog('Nueva Obra', (val) => provider.addObra(val)) : null,
      itemBuilder: (context, dynamic obra) {
        final o = obra as ObraModel;
        return ListTile(
          title: Text(o.nombre),
          trailing: Switch(
            value: o.activa,
            onChanged: isAdmin
                ? (val) async {
                    try {
                      await provider.toggleObraStatus(o);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al actualizar obra: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSimpleTab(CatalogProvider provider, String title, List<String> items, Future<void> Function(String) onAdd, bool isAdmin) {
    return _buildListLayout(
      title: title,
      items: items,
      onAdd: isAdmin ? () => _showAddDialog('Nuevo $title', onAdd) : null,
      itemBuilder: (context, dynamic item) {
        return ListTile(
          title: Text(item.toString()),
          trailing: const Icon(Icons.check, color: Colors.green),
        );
      },
    );
  }

  Widget _buildListLayout({required String title, required List<dynamic> items, required VoidCallback? onAdd, required Widget Function(BuildContext, dynamic) itemBuilder}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (onAdd != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: onAdd,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => itemBuilder(context, items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(String title, Future<void> Function(String) onSave) {
    final txtController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: txtController,
            decoration: const InputDecoration(hintText: 'Ingresar valor...'),
            autofocus: true,
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
                    await onSave(val);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar: $e'),
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

