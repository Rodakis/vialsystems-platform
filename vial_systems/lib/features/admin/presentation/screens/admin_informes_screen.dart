import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../../../core/providers/informe_provider.dart';
import '../../../informes/domain/models/informe_diario_model.dart';
import '../../../informes/domain/models/informe_diario_trabajo_model.dart';

class AdminInformesScreen extends StatefulWidget {
  const AdminInformesScreen({super.key});

  @override
  State<AdminInformesScreen> createState() => _AdminInformesScreenState();
}

class _AdminInformesScreenState extends State<AdminInformesScreen> {
  String? _filterObraId;
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InformeProvider>().loadAdminInformes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InformeProvider>();
    final catalogs = context.watch<CatalogProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter Informes Diarios
    var filteredDiarios = provider.adminInformesDiarios.where((inf) {
      bool match = true;
      if (_filterObraId != null && _filterObraId!.isNotEmpty) {
        match = match && inf.obraId == _filterObraId;
      }
      if (_filterDate != null) {
        match = match &&
            inf.fecha.year == _filterDate!.year &&
            inf.fecha.month == _filterDate!.month &&
            inf.fecha.day == _filterDate!.day;
      }
      return match;
    }).toList();

    // Filter Diarios de Trabajo
    var filteredTrabajos = provider.adminInformesDiariosTrabajo.where((inf) {
      bool match = true;
      if (_filterObraId != null && _filterObraId!.isNotEmpty) {
        match = match && inf.obraId == _filterObraId;
      }
      if (_filterDate != null) {
        match = match &&
            inf.fecha.year == _filterDate!.year &&
            inf.fecha.month == _filterDate!.month &&
            inf.fecha.day == _filterDate!.day;
      }
      return match;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Screen Header & Filter Bar
            Row(
              children: [
                const Icon(Icons.assignment, size: 28, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Text(
                  'Historial de Informes y Partes Diarios',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refrescar datos',
                  onPressed: () {
                    context.read<InformeProvider>().loadAdminInformes();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFilters(catalogs),
            const SizedBox(height: 16),

            // TabBar to switch between kinds of reports
            const TabBar(
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
              tabs: [
                Tab(
                  icon: Icon(Icons.wb_sunny_outlined),
                  text: 'Informes Diarios (Clima/Acceso)',
                ),
                Tab(
                  icon: Icon(Icons.engineering_outlined),
                  text: 'Diarios de Trabajo (Tareas/Recursos)',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // TabBarView Content
            Expanded(
              child: TabBarView(
                children: [
                  _buildDiariosTable(filteredDiarios, catalogs),
                  _buildTrabajosTable(filteredTrabajos, catalogs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(CatalogProvider catalogs) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Obra',
                  prefixIcon: Icon(Icons.engineering),
                  border: OutlineInputBorder(),
                ),
                initialValue: _filterObraId,
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todas las Obras')),
                  ...catalogs.obras.map((o) => DropdownMenuItem(value: o.id, child: Text(o.nombre)))
                ],
                onChanged: (val) => setState(() => _filterObraId = val == '' ? null : val),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _filterDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _filterDate = picked);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(_filterDate == null
                  ? 'Filtrar por Fecha'
                  : 'Fecha: ${DateFormat('dd/MM/yyyy').format(_filterDate!)}'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_filterObraId != null || _filterDate != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _filterObraId = null;
                    _filterDate = null;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar Filtros'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiariosTable(List<InformeDiarioModel> list, CatalogProvider catalogs) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No se encontraron informes diarios con los filtros seleccionados.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: ListView(
        children: [
          DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Obra', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Operador', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Clima', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Camino', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: list.map((inf) {
              final obra = catalogs.obras
                  .firstWhere((o) => o.id == inf.obraId, orElse: () => catalogs.obras.first)
                  .nombre;
              return DataRow(
                onSelectChanged: (_) => _showDiarioDetailDialog(context, inf, obra),
                cells: [
                  DataCell(Text(DateFormat('dd/MM/yyyy').format(inf.fecha))),
                  DataCell(Text(obra)),
                  DataCell(Text(inf.usuarioName)),
                  DataCell(Text(inf.clima)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCaminoColor(inf.estadoCamino).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _getCaminoColor(inf.estadoCamino).withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        inf.estadoCamino,
                        style: TextStyle(
                          color: _getCaminoColor(inf.estadoCamino),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrabajosTable(List<InformeDiarioTrabajoModel> list, CatalogProvider catalogs) {
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No se encontraron diarios de trabajo con los filtros seleccionados.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: ListView(
        children: [
          DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Obra', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Operador', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Horas', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Personal', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tareas Realizadas', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: list.map((inf) {
              final obra = catalogs.obras
                  .firstWhere((o) => o.id == inf.obraId, orElse: () => catalogs.obras.first)
                  .nombre;
              return DataRow(
                onSelectChanged: (_) => _showTrabajoDetailDialog(context, inf, obra),
                cells: [
                  DataCell(Text(DateFormat('dd/MM/yyyy').format(inf.fecha))),
                  DataCell(Text(obra)),
                  DataCell(Text(inf.usuarioName)),
                  DataCell(Text('${inf.horasTrabajadas}h')),
                  DataCell(Text('${inf.personalPresente} p.')),
                  DataCell(
                    Text(
                      inf.tareasRealizadas,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getCaminoColor(String state) {
    if (state == 'Transitable') return Colors.green;
    if (state == 'Transitable con precaución') return Colors.orange;
    return Colors.red;
  }

  void _showDiarioDetailDialog(BuildContext context, InformeDiarioModel inf, String obraName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Detalle de Informe Diario'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Obra:', obraName),
                  _buildDetailRow('Fecha:', DateFormat('dd/MM/yyyy').format(inf.fecha)),
                  _buildDetailRow('Operador:', '${inf.usuarioName} (ID: ${inf.usuarioId})'),
                  _buildDetailRow('Clima:', inf.clima),
                  _buildDetailRow('Estado del Camino:', inf.estadoCamino),
                  const SizedBox(height: 12),
                  const Text(
                    'Observaciones / Notas:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      inf.observaciones.isNotEmpty ? inf.observaciones : 'Sin observaciones.',
                      style: const TextStyle(fontSize: 14),
                    ),
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

  void _showTrabajoDetailDialog(BuildContext context, InformeDiarioTrabajoModel inf, String obraName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.engineering, color: Colors.blueAccent),
              const SizedBox(width: 8),
              const Text('Detalle de Diario de Trabajo'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Obra:', obraName),
                  _buildDetailRow('Fecha:', DateFormat('dd/MM/yyyy').format(inf.fecha)),
                  _buildDetailRow('Operador:', '${inf.usuarioName} (ID: ${inf.usuarioId})'),
                  _buildDetailRow('Horas Trabajadas:', '${inf.horasTrabajadas} horas'),
                  _buildDetailRow('Personal Presente:', '${inf.personalPresente} personas'),
                  const SizedBox(height: 12),
                  const Text(
                    'Tareas Realizadas:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(inf.tareasRealizadas, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Maquinaria Utilizada:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      inf.maquinariaUtilizada.isNotEmpty ? inf.maquinariaUtilizada : 'Ninguna declarada.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Observaciones:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      inf.observaciones.isNotEmpty ? inf.observaciones : 'Sin observaciones.',
                      style: const TextStyle(fontSize: 14),
                    ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
