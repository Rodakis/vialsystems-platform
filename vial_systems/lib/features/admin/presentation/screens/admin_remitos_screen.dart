import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../../../core/providers/remito_provider.dart';
import '../../../remito/domain/models/remito_model.dart';
import 'package:intl/intl.dart';

class AdminRemitosScreen extends StatefulWidget {
  const AdminRemitosScreen({super.key});

  @override
  State<AdminRemitosScreen> createState() => _AdminRemitosScreenState();
}

class _AdminRemitosScreenState extends State<AdminRemitosScreen> {
  String? _filterObraId;
  String? _filterMaterialId;
  String? _filterTransportistaId;
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemitoProvider>().loadAdminRemitos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RemitoProvider>();
    final catalogs = context.watch<CatalogProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Apply filters
    var filteredRemitos = provider.adminRemitos.where((r) {
      bool match = true;
      if (_filterObraId != null && _filterObraId!.isNotEmpty) {
        match = match && r.obraId == _filterObraId;
      }
      if (_filterMaterialId != null && _filterMaterialId!.isNotEmpty) {
        match = match && r.materialId == _filterMaterialId;
      }
      if (_filterTransportistaId != null && _filterTransportistaId!.isNotEmpty) {
        match = match && r.transportistaId == _filterTransportistaId;
      }
      if (_filterDate != null) {
        match = match && 
            r.fecha.year == _filterDate!.year && 
            r.fecha.month == _filterDate!.month && 
            r.fecha.day == _filterDate!.day;
      }
      return match;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(catalogs),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView(
                children: [
                  DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Remito')),
                      DataColumn(label: Text('Guía')),
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Obra')),
                      DataColumn(label: Text('Material')),
                      DataColumn(label: Text('M3')),
                      DataColumn(label: Text('Fotos')),
                    ],
                    rows: filteredRemitos.map((r) {
                      final obra = catalogs.obras.firstWhere((o) => o.id == r.obraId, orElse: () => catalogs.obras.first).nombre;
                      final material = catalogs.materiales.firstWhere((m) => m.id == r.materialId, orElse: () => catalogs.materiales.first).nombre;
                      
                      return DataRow(
                        onSelectChanged: (_) => _showRemitoDetails(context, r, catalogs),
                        cells: [
                          DataCell(Text(r.numeroRemito ?? 'S/N')),
                          DataCell(Text(r.numeroGuia)),
                          DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(r.fecha))),
                          DataCell(Text(obra)),
                          DataCell(Text(material)),
                          DataCell(Text(r.cantidadM3.toString())),
                          DataCell(Text('${r.fotos.length} fotos')),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(CatalogProvider catalogs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Obra', border: OutlineInputBorder()),
                initialValue: _filterObraId,
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todas')),
                  ...catalogs.obras.map((o) => DropdownMenuItem(value: o.id, child: Text(o.nombre)))
                ],
                onChanged: (val) => setState(() => _filterObraId = val == '' ? null : val),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Material', border: OutlineInputBorder()),
                initialValue: _filterMaterialId,
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos')),
                  ...catalogs.materiales.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nombre)))
                ],
                onChanged: (val) => setState(() => _filterMaterialId = val == '' ? null : val),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Transportista', border: OutlineInputBorder()),
                initialValue: _filterTransportistaId,
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos')),
                  ...catalogs.transportistas.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)))
                ],
                onChanged: (val) => setState(() => _filterTransportistaId = val == '' ? null : val),
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_filterDate == null ? 'Filtrar Fecha' : DateFormat('dd/MM/yyyy').format(_filterDate!)),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                setState(() => _filterDate = date);
              },
            ),
            if (_filterDate != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _filterDate = null),
                tooltip: 'Limpiar Fecha',
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              onPressed: () => context.read<RemitoProvider>().loadAdminRemitos(),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemitoDetails(BuildContext context, RemitoModel remito, CatalogProvider catalogs) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalle de Remito: ${remito.numeroRemito ?? 'S/N'}'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guía: ${remito.numeroGuia}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(remito.fecha)}'),
                  const Divider(),
                  Text('Procedencia: ${remito.procedencia}'),
                  Text('Destino: ${remito.destino}'),
                  Text('Cantidad: ${remito.cantidadM3} m3'),
                  Text('Patentes: ${remito.camionPatente ?? 'N/A'} / ${remito.acopladoPatente}'),
                  Text('Hora Descarga: ${DateFormat('HH:mm').format(remito.horaDescarga)}'),
                  if (remito.observaciones.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Observaciones: ${remito.observaciones}'),
                  ],
                  const Divider(),
                  const Text('Evidencia Fotográfica:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (remito.fotos.isEmpty)
                    const Text('No hay evidencias fotográficas registradas.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                  else
                    Column(
                      children: remito.fotos.map((foto) {
                        final dateStr = '${foto.fecha.day.toString().padLeft(2, '0')}/${foto.fecha.month.toString().padLeft(2, '0')} ${foto.fecha.hour.toString().padLeft(2, '0')}:${foto.fecha.minute.toString().padLeft(2, '0')}';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail con click para expandir
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.network(
                                              foto.path,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Text(
                                                '${foto.tipoEvidencia} - Capturado por: ${foto.usuario} ($dateStr)',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        foto.path,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Metadata
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
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
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Fecha: $dateStr',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
