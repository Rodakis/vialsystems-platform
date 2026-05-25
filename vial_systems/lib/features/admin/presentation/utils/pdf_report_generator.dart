import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../remito/domain/models/remito_model.dart';
import '../../../../core/providers/catalog_provider.dart';
import 'material_resolver.dart';

/// Top-level private helper to build details table rows in individual PDFs.
pw.TableRow _buildTableRow(String label, String value) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ),
    ],
  );
}

/// Generates a Portrait PDF with complete details for a single Remito.
Future<Uint8List> generateIndividualRemitoPdf(
  RemitoModel remito,
  CatalogProvider catalogs,
) async {
  final pdf = pw.Document();

  // Resolve names from catalog UUIDs safely
  final obra = resolveObraName(remito.obraId, catalogs);
  final material = resolveMaterialName(remito, catalogs);
  final transportista = resolveTransportistaName(remito.transportistaId, catalogs);
  final chofer = resolveChoferName(remito.choferId, catalogs);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company branding header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'VialSystems',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800,
                    ),
                  ),
                  pw.Text(
                    'Remito de Acarreo',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.blueGrey800),
              pw.SizedBox(height: 16),

              // Title and sequence codes
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Nº Remito: ${remito.numeroRemito ?? 'S/N'}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Nº Guía Oficial: ${remito.numeroGuia}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Fecha y Hora: ${DateFormat('dd/MM/yyyy HH:mm').format(remito.fecha)}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 24),

              // Main Details
              pw.Text(
                'DETALLE DEL ACARREO',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  _buildTableRow('Obra', obra),
                  _buildTableRow('Material', material),
                  _buildTableRow('Cantidad', '${remito.cantidadM3} m³'),
                  _buildTableRow('Procedencia', remito.procedencia.isNotEmpty ? remito.procedencia : 'N/A'),
                  _buildTableRow('Destino', remito.destino.isNotEmpty ? remito.destino : 'N/A'),
                  _buildTableRow('Transportista', transportista),
                  _buildTableRow('Chofer', chofer),
                  _buildTableRow('Patente Camión', remito.camionPatente ?? 'N/A'),
                  _buildTableRow('Patente Acoplado', remito.acopladoPatente.isNotEmpty ? remito.acopladoPatente : 'N/A'),
                  _buildTableRow('Hora Descarga', DateFormat('HH:mm').format(remito.horaDescarga)),
                  _buildTableRow('Observaciones', remito.observaciones.isNotEmpty ? remito.observaciones : 'Sin observaciones'),
                ],
              ),
              pw.SizedBox(height: 24),

              // Photographic evidence list
              pw.Text(
                'EVIDENCIA FOTOGRÁFICA',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Cantidad de fotos adjuntas: ${remito.fotos.length}'),
              pw.SizedBox(height: 8),
              if (remito.fotos.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: remito.fotos.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final foto = entry.value;
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(foto.fecha);
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Text(
                        'Foto $idx: ${foto.tipoEvidencia} - Registrada por: ${foto.usuario} ($dateStr)\nReferencia/URL: ${foto.path}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue800),
                      ),
                    );
                  }).toList(),
                )
              else
                pw.Text(
                  'No hay evidencias fotográficas registradas.',
                  style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                ),
              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Documento generado digitalmente por la plataforma VialSystems.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}

/// Generates a Landscape multi-page PDF summary based on the current filtered list.
Future<Uint8List> generateFilteredSummaryPdf(
  List<RemitoModel> filteredRemitos,
  CatalogProvider catalogs, {
  String? filterObra,
  String? filterMaterial,
  String? filterTransportista,
  String? filterUsuario,
  String? filterDateFrom,
  String? filterDateTo,
  String? searchQuery,
}) async {
  final pdf = pw.Document();

  // Accumulate total cubic meters volume safely (ignores non-m3 items or nulls implicitly via double logic)
  double totalM3 = 0.0;
  for (var r in filteredRemitos) {
    totalM3 += r.cantidadM3;
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      orientation: pw.PageOrientation.landscape,
      margin: const pw.EdgeInsets.all(24),
      header: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'VialSystems',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.Text(
                  'Reporte Consolidado de Remitos',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 1.5, color: PdfColors.blueGrey800),
            pw.SizedBox(height: 8),
          ],
        );
      },
      footer: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Fecha de generación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        );
      },
      build: (pw.Context context) {
        return [
          // Filter meta and totals summary
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Filtros Aplicados:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('• Obra: ${filterObra ?? 'Todas'}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('• Material: ${filterMaterial ?? 'Todos'}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('• Transportista: ${filterTransportista ?? 'Todos'}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('• Usuario/Operador: ${filterUsuario ?? 'Todos'}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 14),
                    pw.Text('• Rango Fechas: Desde ${filterDateFrom ?? 'Inicio'} Hasta ${filterDateTo ?? 'Fin'}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('• Búsqueda libre: ${searchQuery ?? 'Ninguna'}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Resumen:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Remitos Incluidos: ${filteredRemitos.length}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Total m³ Acumulado: ${totalM3.toStringAsFixed(2)} m³', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Consolidated list table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.0), // Fecha
              1: pw.FlexColumnWidth(1.2), // Remito
              2: pw.FlexColumnWidth(1.2), // Guía
              3: pw.FlexColumnWidth(2.2), // Obra
              4: pw.FlexColumnWidth(2.2), // Material
              5: pw.FlexColumnWidth(1.0), // m³
              6: pw.FlexColumnWidth(2.2), // Transportista
              7: pw.FlexColumnWidth(0.8), // Fotos
            },
            children: [
              // Column Headers
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Remito', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Guía', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Obra', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Material', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('m³', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Transportista', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Fotos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                ],
              ),
              // Map Remitos to Rows
              ...filteredRemitos.map((r) {
                final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(r.fecha);
                final obra = resolveObraName(r.obraId, catalogs);
                final material = resolveMaterialName(r, catalogs);
                final transportista = resolveTransportistaName(r.transportistaId, catalogs);

                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(r.numeroRemito ?? 'S/N', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(r.numeroGuia, style: const pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(obra, style: const pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(material, style: const pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${r.cantidadM3} m³', style: const pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(transportista, style: const pw.TextStyle(fontSize: 7))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${r.fotos.length}', style: const pw.TextStyle(fontSize: 7))),
                  ],
                );
              }),
            ],
          ),
        ];
      },
    ),
  );

  return pdf.save();
}
