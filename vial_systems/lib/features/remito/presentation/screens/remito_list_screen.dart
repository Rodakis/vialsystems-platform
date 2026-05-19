import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/remito_provider.dart';
import '../../domain/models/remito_model.dart';
import 'remito_form_screen.dart';

class RemitoListScreen extends StatelessWidget {
  const RemitoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informes de Acarreo'),
      ),
      body: Consumer<RemitoProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.remitos.isEmpty) {
            return const Center(child: Text('No hay remitos creados.'));
          }

          return ListView.builder(
            itemCount: provider.remitos.length,
            itemBuilder: (context, index) {
              final remito = provider.remitos[index];
              return ListTile(
                leading: Icon(
                  remito.estado == RemitoStatus.enviado ? Icons.check_circle : Icons.drafts,
                  color: remito.estado == RemitoStatus.enviado ? Colors.green : Colors.grey,
                ),
                title: Text('Guía: ${remito.numeroGuia} - ${remito.destino}'),
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
    );
  }
}
