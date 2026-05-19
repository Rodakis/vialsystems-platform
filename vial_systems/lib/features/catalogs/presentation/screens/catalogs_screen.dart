import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../domain/models/catalog_models.dart';

class CatalogsScreen extends StatelessWidget {
  const CatalogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catálogos y Obras'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Obras'),
              Tab(text: 'Materiales'),
              Tab(text: 'Transportistas'),
              Tab(text: 'Choferes'),
              Tab(text: 'Camiones'),
              Tab(text: 'Recibidores'),
            ],
          ),
        ),
        body: Consumer<CatalogProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildObrasTab(context, provider),
                _buildGenericTab<MaterialModel>(
                  context,
                  title: 'Material',
                  items: provider.materiales,
                  getTitle: (m) => m.nombre,
                  onAdd: (val) => provider.addMaterial(val),
                ),
                _buildGenericTab<TransportistaModel>(
                  context,
                  title: 'Transportista',
                  items: provider.transportistas,
                  getTitle: (t) => t.nombre,
                  onAdd: (val) => provider.addTransportista(val),
                ),
                _buildGenericTab<ChoferModel>(
                  context,
                  title: 'Chofer',
                  items: provider.choferes,
                  getTitle: (c) => c.nombre,
                  onAdd: (val) => provider.addChofer(val),
                ),
                _buildGenericTab<CamionModel>(
                  context,
                  title: 'Camión',
                  items: provider.camiones,
                  getTitle: (c) => c.patente,
                  onAdd: (val) => provider.addCamion(val),
                ),
                _buildGenericTab<RecibidorModel>(
                  context,
                  title: 'Recibidor',
                  items: provider.recibidores,
                  getTitle: (r) => r.nombre,
                  onAdd: (val) => provider.addRecibidor(val),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildObrasTab(BuildContext context, CatalogProvider provider) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: provider.obras.length,
            itemBuilder: (context, index) {
              final obra = provider.obras[index];
              return ListTile(
                title: Text(obra.nombre),
                subtitle: Text(obra.activa ? 'Activa' : 'Cerrada', style: TextStyle(color: obra.activa ? Colors.green : Colors.red)),
                trailing: Switch(
                  value: obra.activa,
                  onChanged: (_) => provider.toggleObraStatus(obra),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _showAddDialog(context, 'Obra', (val) => provider.addObra(val)),
            child: const Text('Agregar Obra'),
          ),
        ),
      ],
    );
  }

  Widget _buildGenericTab<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required String Function(T) getTitle,
    required Function(String) onAdd,
  }) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(getTitle(items[index])),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () => _showAddDialog(context, title, onAdd),
            child: Text('Agregar $title'),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, String title, Function(String) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nuevo $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Nombre o dato de $title'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final val = controller.text.trim();
                if (val.isNotEmpty) {
                  onAdd(val);
                  Navigator.pop(context);
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
