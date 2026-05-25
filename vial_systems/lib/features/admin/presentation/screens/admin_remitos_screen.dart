import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/catalog_provider.dart';
import '../../../../core/providers/remito_provider.dart';
import '../../../remito/domain/models/remito_model.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../utils/pdf_report_generator.dart';
import '../utils/material_resolver.dart';

class AdminRemitosScreen extends StatefulWidget {
  const AdminRemitosScreen({super.key});

  @override
  State<AdminRemitosScreen> createState() => _AdminRemitosScreenState();
}

class _AdminRemitosScreenState extends State<AdminRemitosScreen> {
  String? _filterObraId;
  String? _filterMaterialId;
  String? _filterTransportistaId;
  String? _filterUsuarioId;
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  String? _searchQuery;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemitoProvider>().loadAdminRemitos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RemitoProvider>();
    final catalogs = context.watch<CatalogProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Extract dynamic unique operators/users from photos of loaded remitos
    final uniqueUsuarios = provider.adminRemitos
        .expand((r) => r.fotos.map((f) => f.usuario))
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList();
    uniqueUsuarios.sort();

    // Apply filters
    var filteredRemitos = provider.adminRemitos.where((r) {
      final obraNombre = resolveObraName(r.obraId, catalogs);
      final materialNombre = resolveMaterialName(r, catalogs);
      final transportistaNombre = resolveTransportistaName(r.transportistaId, catalogs);

      debugPrint('--- TEMP LOG FILTER ---');
      debugPrint('selectedObra (filter): $_filterObraId');
      debugPrint('remito.obraId: ${r.obraId}');
      debugPrint('remito.obraNombre: $obraNombre');
      debugPrint('selectedMaterial (filter): $_filterMaterialId');
      debugPrint('remito.materialId: ${r.materialId}');
      debugPrint('remito.materialNombre: $materialNombre');
      debugPrint('selectedTransportista (filter): $_filterTransportistaId');
      debugPrint('remito.transportistaId: ${r.transportistaId}');
      debugPrint('remito.transportistaNombre: $transportistaNombre');
      debugPrint('------------------------');

      // 1. Obra Match
      bool matchesObra = matchesObraFilter(r, _filterObraId, catalogs);

      // 2. Material Match
      bool matchesMaterial = matchesMaterialFilter(r, _filterMaterialId, catalogs);

      // 3. Transportista Match
      bool matchesTransportista = matchesTransportistaFilter(r, _filterTransportistaId, catalogs);

      // 4. Usuario Match
      bool matchesUsuario = true;
      if (_filterUsuarioId != null && _filterUsuarioId!.isNotEmpty) {
        matchesUsuario = r.fotos.any((f) => f.usuario.toLowerCase().trim() == _filterUsuarioId!.toLowerCase().trim());
      }

      // 5. Date Match
      bool matchesDateFrom = true;
      if (_filterDateFrom != null) {
        final startOfDay = DateTime(_filterDateFrom!.year, _filterDateFrom!.month, _filterDateFrom!.day);
        matchesDateFrom = !r.fecha.isBefore(startOfDay);
      }

      bool matchesDateTo = true;
      if (_filterDateTo != null) {
        final endOfDay = DateTime(_filterDateTo!.year, _filterDateTo!.month, _filterDateTo!.day, 23, 59, 59, 999);
        matchesDateTo = !r.fecha.isAfter(endOfDay);
      }

      // 6. Search Match
      bool matchesSearch = true;
      if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
        final queryTerms = _searchQuery!
            .trim()
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((t) => t.isNotEmpty)
            .toList();

        if (queryTerms.isNotEmpty) {
          final remitoNo = (r.numeroRemito ?? '').toLowerCase();
          final guiaNo = r.numeroGuia.toLowerCase();
          final camionPat = (r.camionPatente ?? '').toLowerCase();
          final acopladoPat = r.acopladoPatente.toLowerCase();
          final proc = r.procedencia.toLowerCase();
          final dest = r.destino.toLowerCase();

          bool allTermsMatch = true;
          for (final term in queryTerms) {
            bool termMatches = remitoNo.contains(term) ||
                guiaNo.contains(term) ||
                camionPat.contains(term) ||
                acopladoPat.contains(term) ||
                proc.contains(term) ||
                dest.contains(term);
            if (!termMatches) {
              allTermsMatch = false;
              break;
            }
          }
          matchesSearch = allTermsMatch;
        }
      }

      return matchesSearch &&
          matchesObra &&
          matchesMaterial &&
          matchesTransportista &&
          matchesUsuario &&
          matchesDateFrom &&
          matchesDateTo;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(catalogs, uniqueUsuarios, filteredRemitos),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListView(
                children: [
                  DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Remito', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Guía', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Obra', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Material', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('M³', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Fotos', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: filteredRemitos.map((r) {
                      final obra = resolveObraName(r.obraId, catalogs);
                      final material = resolveMaterialName(r, catalogs);
                      
                      return DataRow(
                        onSelectChanged: (_) => _showRemitoDetails(context, r, catalogs),
                        cells: [
                          DataCell(Text(r.numeroRemito ?? 'S/N', style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(r.numeroGuia)),
                          DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(r.fecha))),
                          DataCell(Text(obra)),
                          DataCell(Text(material)),
                          DataCell(Text('${r.cantidadM3} m³')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: r.fotos.isNotEmpty ? Colors.blue.shade50 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: r.fotos.isNotEmpty ? Colors.blue.shade200 : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                '${r.fotos.length} ${r.fotos.length == 1 ? 'foto' : 'fotos'}',
                                style: TextStyle(
                                  color: r.fotos.isNotEmpty ? Colors.blue.shade800 : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(CatalogProvider catalogs, List<String> uniqueUsuarios, List<RemitoModel> filteredRemitos) {
    final hasActiveFilters = _filterObraId != null ||
        _filterMaterialId != null ||
        _filterTransportistaId != null ||
        _filterUsuarioId != null ||
        _filterDateFrom != null ||
        _filterDateTo != null ||
        (_searchQuery != null && _searchQuery!.trim().isNotEmpty);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Filtros y Búsqueda Avanzada',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Búsqueda Libre
                SizedBox(
                  width: 260,
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar remito, guía, patente, procedencia...',
                      labelStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = null);
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                // Obra Dropdown
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('obra_$_filterObraId'),
                    decoration: const InputDecoration(
                      labelText: 'Obra',
                      labelStyle: TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    initialValue: _filterObraId ?? '',
                    items: [
                      const DropdownMenuItem<String>(value: '', child: Text('Todas', style: TextStyle(fontSize: 13))),
                      ...catalogs.obras.map((o) => DropdownMenuItem<String>(value: o.id, child: Text(o.nombre, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                    ],
                    onChanged: (val) => setState(() => _filterObraId = val == '' ? null : val),
                  ),
                ),
                // Material Dropdown
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('material_$_filterMaterialId'),
                    decoration: const InputDecoration(
                      labelText: 'Material',
                      labelStyle: TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    initialValue: _filterMaterialId ?? '',
                    items: [
                      const DropdownMenuItem<String>(value: '', child: Text('Todos', style: TextStyle(fontSize: 13))),
                      ...catalogs.materiales.map((m) => DropdownMenuItem<String>(value: m.id, child: Text(m.nombre, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                    ],
                    onChanged: (val) => setState(() => _filterMaterialId = val == '' ? null : val),
                  ),
                ),
                // Transportista Dropdown
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('transportista_$_filterTransportistaId'),
                    decoration: const InputDecoration(
                      labelText: 'Transportista',
                      labelStyle: TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    initialValue: _filterTransportistaId ?? '',
                    items: [
                      const DropdownMenuItem<String>(value: '', child: Text('Todos', style: TextStyle(fontSize: 13))),
                      ...catalogs.transportistas.map((t) => DropdownMenuItem<String>(value: t.id, child: Text(t.nombre, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                    ],
                    onChanged: (val) => setState(() => _filterTransportistaId = val == '' ? null : val),
                  ),
                ),
                // Usuario/Operador Dropdown
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('usuario_$_filterUsuarioId'),
                    decoration: const InputDecoration(
                      labelText: 'Usuario / Operador',
                      labelStyle: TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    initialValue: _filterUsuarioId ?? '',
                    items: [
                      const DropdownMenuItem<String>(value: '', child: Text('Todos', style: TextStyle(fontSize: 13))),
                      ...uniqueUsuarios.map((u) => DropdownMenuItem<String>(value: u, child: Text(u, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)))
                    ],
                    onChanged: (val) => setState(() => _filterUsuarioId = val == '' ? null : val),
                  ),
                ),
                // Fecha Desde Selector Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(
                    _filterDateFrom == null
                        ? 'Fecha Desde'
                        : 'Desde: ${DateFormat('dd/MM/yyyy').format(_filterDateFrom!)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterDateFrom ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _filterDateFrom = date);
                    }
                  },
                ),
                // Fecha Hasta Selector Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(
                    _filterDateTo == null
                        ? 'Fecha Hasta'
                        : 'Hasta: ${DateFormat('dd/MM/yyyy').format(_filterDateTo!)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filterDateTo ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _filterDateTo = date);
                    }
                  },
                ),
                // Botón Limpiar Filtros
                if (hasActiveFilters)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    icon: const Icon(Icons.filter_alt_off, size: 18),
                    label: const Text('Limpiar Filtros', style: TextStyle(fontSize: 13)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _filterObraId = null;
                        _filterMaterialId = null;
                        _filterTransportistaId = null;
                        _filterUsuarioId = null;
                        _filterDateFrom = null;
                        _filterDateTo = null;
                        _searchQuery = null;
                      });
                    },
                  ),
                // Botón Actualizar
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualizar', style: TextStyle(fontSize: 13)),
                  onPressed: () => context.read<RemitoProvider>().loadAdminRemitos(),
                ),
                // Botón Generar Reporte PDF
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Generar Reporte PDF', style: TextStyle(fontSize: 13)),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (filteredRemitos.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('No hay remitos para generar el reporte.')),
                      );
                      return;
                    }
                    try {
                      final pdfBytes = await generateFilteredSummaryPdf(
                        filteredRemitos,
                        catalogs,
                        filterObra: catalogs.obras.any((o) => o.id == _filterObraId)
                            ? catalogs.obras.firstWhere((o) => o.id == _filterObraId).nombre
                            : _filterObraId,
                        filterMaterial: _filterMaterialId != null ? resolveMaterialNameFromId(_filterMaterialId, catalogs) : null,
                        filterTransportista: catalogs.transportistas.any((t) => t.id == _filterTransportistaId)
                            ? catalogs.transportistas.firstWhere((t) => t.id == _filterTransportistaId).nombre
                            : _filterTransportistaId,
                        filterUsuario: _filterUsuarioId,
                        filterDateFrom: _filterDateFrom != null ? DateFormat('dd/MM/yyyy').format(_filterDateFrom!) : null,
                        filterDateTo: _filterDateTo != null ? DateFormat('dd/MM/yyyy').format(_filterDateTo!) : null,
                        searchQuery: _searchQuery,
                      );
                      await Printing.layoutPdf(
                        name: 'Reporte_Consolidado_Remitos',
                        onLayout: (format) async => pdfBytes,
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error al generar PDF: $e')),
                      );
                    }
                  },
                ),
              ],
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
                  Text('Obra: ${resolveObraName(remito.obraId, catalogs)}'),
                  Text('Material: ${resolveMaterialName(remito, catalogs)}'),
                  Text('Transportista: ${resolveTransportistaName(remito.transportistaId, catalogs)}'),
                  Text('Chofer: ${resolveChoferName(remito.choferId, catalogs)}'),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('Exportar a PDF'),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final pdfBytes = await generateIndividualRemitoPdf(remito, catalogs);
                  await Printing.layoutPdf(
                    name: 'Remito_${remito.numeroRemito ?? remito.numeroGuia}',
                    onLayout: (format) async => pdfBytes,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error al exportar PDF: $e')),
                  );
                }
              },
            ),
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
