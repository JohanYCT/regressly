import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:regressly/models/finca_model.dart';
import 'package:regressly/models/registro_model.dart';

/// Servicio especializado en la generación de reportes en PDF de producción lechera.
class PdfReportService {
  /// Genera un documento PDF con los datos de producción de la finca.
  ///
  /// Parámetros:
  /// - [registros]: Lista de registros de producción a incluir en el reporte.
  /// - [finca]: Información opcional de la finca y productor.
  /// - [fechaInicio]: Fecha inicial del filtro (opcional).
  /// - [fechaFin]: Fecha final del filtro (opcional).
  /// - [tituloFiltro]: Descripción del rango seleccionado (ej: "Este mes", "Historial Completo").
  static Future<Uint8List> generateProductionReport({
    required List<RegistroModel> registros,
    FincaModel? finca,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String tituloFiltro = 'Historial Completo',
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,##0.0', 'es_ES');
    final fechaGeneracion = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Ordenar registros por fecha (del más antiguo al más reciente para el reporte)
    final registrosOrdenados = List<RegistroModel>.from(registros)
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    // Cálculos estadísticos
    final totalLitros = registros.fold<double>(0.0, (sum, r) => sum + r.litrosTotal);
    final totalManana = registros.fold<double>(0.0, (sum, r) => sum + r.litrosManana);
    final totalTarde = registros.fold<double>(0.0, (sum, r) => sum + r.litrosTarde);
    final promedioDiario = registros.isNotEmpty ? totalLitros / registros.length : 0.0;

    double maxProduccion = 0.0;
    for (var r in registros) {
      if (r.litrosTotal > maxProduccion) {
        maxProduccion = r.litrosTotal;
      }
    }

    final int numVacas = finca?.numeroVacas ?? 0;
    final double promedioPorVaca = (numVacas > 0 && registros.isNotEmpty)
        ? (promedioDiario / numVacas)
        : 0.0;

    // Colores corporativos para el PDF
    final primaryColor = PdfColor.fromHex('#2E7D32'); // Verde principal
    final secondaryColor = PdfColor.fromHex('#E8F5E9'); // Verde muy claro
    final accentColor = PdfColor.fromHex('#4CAF50');
    final textDarkColor = PdfColor.fromHex('#1B5E20');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'REGRESSLY',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.Text(
                        'Reporte de Producción Lechera',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Emisión: $fechaGeneracion',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Rango: $tituloFiltro',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1.5, color: primaryColor),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Regressly - Analítica Predictiva Lechera',
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
            // ============================
            // 🏡 INFORMACIÓN DE LA FINCA
            // ============================
            if (finca != null) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: secondaryColor,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: primaryColor, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (finca.nombreProductor.isNotEmpty)
                          pw.Text('Productor: ${finca.nombreProductor}',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDarkColor)),
                        if (finca.nombreFinca.isNotEmpty)
                          pw.Text('Finca: ${finca.nombreFinca}',
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (finca.ubicacion.isNotEmpty)
                          pw.Text('Ubicación: ${finca.ubicacion}',
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                        if (finca.numeroVacas > 0)
                          pw.Text('N° Vacas: ${finca.numeroVacas}',
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
            ],

            // ============================
            // 📊 TARJETAS RESUMEN DE INDICADORES
            // ============================
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildKpiPdf('Días Registrados', '${registros.length} días', primaryColor),
                  _buildKpiPdf('Total Producido', '${numberFormat.format(totalLitros)} L', primaryColor),
                  _buildKpiPdf('Promedio Diario', '${numberFormat.format(promedioDiario)} L/día', primaryColor),
                  if (numVacas > 0)
                    _buildKpiPdf('Prom. por Vaca', '${numberFormat.format(promedioPorVaca)} L/vaca', primaryColor),
                  _buildKpiPdf('Pico Máximo', '${numberFormat.format(maxProduccion)} L', accentColor),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Título de la tabla
            pw.Text(
              'Detalle de Registros de Producción (${registros.length})',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 8),

            // ============================
            // 📋 TABLA DE REGISTROS
            // ============================
            registrosOrdenados.isEmpty
                ? pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.all(20),
                    child: pw.Text('No hay registros de producción en el rango seleccionado.',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(2.2), // Fecha
                      1: pw.FlexColumnWidth(2),   // Mañana
                      2: pw.FlexColumnWidth(2),   // Tarde
                      3: pw.FlexColumnWidth(2.2), // Total
                      4: pw.FlexColumnWidth(4),   // Observaciones
                    },
                    children: [
                      // Encabezado de la tabla
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: primaryColor),
                        children: [
                          _buildTableHeader('Fecha'),
                          _buildTableHeader('Mañana (L)', align: pw.Alignment.centerRight),
                          _buildTableHeader('Tarde (L)', align: pw.Alignment.centerRight),
                          _buildTableHeader('Total (L)', align: pw.Alignment.centerRight),
                          _buildTableHeader('Observaciones'),
                        ],
                      ),

                      // Filas de datos
                      ...List.generate(registrosOrdenados.length, (index) {
                        final r = registrosOrdenados[index];
                        final isEven = index % 2 == 0;
                        DateTime? parsedDate;
                        try {
                          parsedDate = DateTime.parse(r.fecha);
                        } catch (_) {}
                        final fechaStr = parsedDate != null ? dateFormat.format(parsedDate) : r.fecha;

                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: isEven ? PdfColors.white : PdfColors.grey100,
                          ),
                          children: [
                            _buildTableCell(fechaStr, fontWeight: pw.FontWeight.bold),
                            _buildTableCell(numberFormat.format(r.litrosManana), align: pw.Alignment.centerRight),
                            _buildTableCell(numberFormat.format(r.litrosTarde), align: pw.Alignment.centerRight),
                            _buildTableCell(numberFormat.format(r.litrosTotal), align: pw.Alignment.centerRight, fontWeight: pw.FontWeight.bold),
                            _buildTableCell(r.observaciones.isEmpty ? '-' : r.observaciones, color: PdfColors.grey800),
                          ],
                        );
                      }),

                      // Fila de Totales Generales al final de la tabla
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: secondaryColor),
                        children: [
                          _buildTableCell('TOTALES', fontWeight: pw.FontWeight.bold, color: textDarkColor),
                          _buildTableCell(numberFormat.format(totalManana), align: pw.Alignment.centerRight, fontWeight: pw.FontWeight.bold, color: textDarkColor),
                          _buildTableCell(numberFormat.format(totalTarde), align: pw.Alignment.centerRight, fontWeight: pw.FontWeight.bold, color: textDarkColor),
                          _buildTableCell(numberFormat.format(totalLitros), align: pw.Alignment.centerRight, fontWeight: pw.FontWeight.bold, color: primaryColor),
                          _buildTableCell('', color: textDarkColor),
                        ],
                      ),
                    ],
                  ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiPdf(String title, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text, {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      alignment: align,
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
    );
  }
}
