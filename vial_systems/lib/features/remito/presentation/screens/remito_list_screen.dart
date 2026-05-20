import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/remito_provider.dart';
import '../../domain/models/remito_model.dart';
import 'remito_form_screen.dart';

class RemitoListScreen extends StatelessWidget {
  const RemitoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Informes de Acarreo'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Historial'),
              Tab(text: 'Cola de Envío'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sincronizar Pendientes',
              onPressed: () => context.read<RemitoProvider>().syncQueue(),
            ),
          ],
        ),
        body: Consumer<RemitoProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final historial = provider.remitos.where((r) => r.estado == RemitoStatus.borrador || r.estado == RemitoStatus.sincronizado).toList();
            final cola = provider.remitos.where((r) => r.estado == RemitoStatus.listoParaEnviar || r.estado == RemitoStatus.error).toList();

            return TabBarView(
              children: [
                _buildList(historial, context),
                _buildList(cola, context),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RemitoFormScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildList(List<RemitoModel> remitos, BuildContext context) {
    if (remitos.isEmpty) {
      return const Center(child: Text('No hay remitos en esta lista.'));
    }

    return ListView.builder(
      itemCount: remitos.length,
      itemBuilder: (context, index) {
        final remito = remitos[index];
        IconData iconData;
        Color iconColor;

        switch (remito.estado) {
          case RemitoStatus.borrador:
            iconData = Icons.drafts;
            iconColor = Colors.grey;
            break;
          case RemitoStatus.listoParaEnviar:
            iconData = Icons.cloud_upload;
            iconColor = Colors.orange;
            break;
          case RemitoStatus.sincronizado:
            iconData = Icons.check_circle;
            iconColor = Colors.green;
            break;
          case RemitoStatus.error:
            iconData = Icons.error;
            iconColor = Colors.red;
            break;
        }

        return ListTile(
          leading: Icon(iconData, color: iconColor),
          title: Text(remito.numeroRemito != null ? 'Remito: ${remito.numeroRemito} (Guía: ${remito.numeroGuia})' : 'Guía: ${remito.numeroGuia} - ${remito.destino}'),
          subtitle: Text('${remito.fecha.day}/${remito.fecha.month}/${remito.fecha.year} - ${remito.cantidadM3} m3'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RemitoFormScreen(remito: remito)),
            );
          },
        );
      },
    );
  }
}
