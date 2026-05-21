import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../../../core/providers/informe_provider.dart';
import '../../../remito/domain/models/remito_model.dart';
import '../../domain/models/informe_diario_model.dart';
import '../../domain/models/informe_diario_trabajo_model.dart';
import 'informe_diario_form_screen.dart';
import 'informe_diario_trabajo_form_screen.dart';

class InformeListScreen extends StatelessWidget {
  const InformeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Informes y Partes Diarios'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.wb_sunny_outlined),
                text: 'Informes Diarios',
              ),
              Tab(
                icon: Icon(Icons.assignment_outlined),
                text: 'Diarios de Trabajo',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sincronizar Pendientes',
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await context.read<InformeProvider>().syncQueue();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Sincronización completada.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error al sincronizar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: Consumer2<InformeProvider, CatalogProvider>(
          builder: (context, provider, catalogs, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildDiariosList(provider.informesDiarios, catalogs, context),
                _buildTrabajosList(provider.informesDiariosTrabajo, catalogs, context),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Nuevo Informe',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                        title: const Text('Nuevo Informe Diario'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InformeDiarioFormScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.assignment, color: Colors.blue),
                        title: const Text('Nuevo Informe de Trabajo (Tareas/Horas)'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InformeDiarioTrabajoFormScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildDiariosList(
    List<InformeDiarioModel> list,
    CatalogProvider catalogs,
    BuildContext context,
  ) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'No hay informes diarios registrados.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final inf = list[index];
        final obra = catalogs.obras.firstWhere((o) => o.id == inf.obraId, orElse: () => catalogs.obras.first).nombre;
        final dateStr = '${inf.fecha.day}/${inf.fecha.month}/${inf.fecha.year}';
        
        final iconData = _getStatusIcon(inf.estado);
        final iconColor = _getStatusColor(inf.estado);
        final totalItems = inf.proveedoresIds.length +
            inf.maquinariasIds.length +
            inf.materialesIds.length +
            inf.equiposIds.length +
            inf.camionesIds.length;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.1),
              child: Icon(iconData, color: iconColor),
            ),
            title: Text(
              'Obra: $obra',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Elementos declarados: $totalItems | Fotos: ${inf.fotos.length}'),
                Text('Fecha: $dateStr - Creado por: ${inf.usuarioName}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InformeDiarioFormScreen(informe: inf),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTrabajosList(
    List<InformeDiarioTrabajoModel> list,
    CatalogProvider catalogs,
    BuildContext context,
  ) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'No hay informes de trabajo registrados.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final inf = list[index];
        final obra = catalogs.obras.firstWhere((o) => o.id == inf.obraId, orElse: () => catalogs.obras.first).nombre;
        final dateStr = '${inf.fecha.day}/${inf.fecha.month}/${inf.fecha.year}';
        
        final iconData = _getStatusIcon(inf.estado);
        final iconColor = _getStatusColor(inf.estado);
        final totalPersonal = inf.personalPorFuncion.values.fold(0, (sum, val) => sum + val);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.1),
              child: Icon(iconData, color: iconColor),
            ),
            title: Text(
              'Obra: $obra',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Horas: ${inf.horasTrabajadas}h | Personal: $totalPersonal'),
                Text(
                  'Tareas: ${inf.tareasRealizadas}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Fecha: $dateStr - Creado por: ${inf.usuarioName}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InformeDiarioTrabajoFormScreen(informe: inf),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(RemitoStatus status) {
    switch (status) {
      case RemitoStatus.borrador:
        return Icons.drafts;
      case RemitoStatus.listoParaEnviar:
        return Icons.cloud_upload;
      case RemitoStatus.sincronizado:
        return Icons.check_circle;
      case RemitoStatus.error:
        return Icons.error;
    }
  }

  Color _getStatusColor(RemitoStatus status) {
    switch (status) {
      case RemitoStatus.borrador:
        return Colors.grey;
      case RemitoStatus.listoParaEnviar:
        return Colors.orange;
      case RemitoStatus.sincronizado:
        return Colors.green;
      case RemitoStatus.error:
        return Colors.red;
    }
  }
}
