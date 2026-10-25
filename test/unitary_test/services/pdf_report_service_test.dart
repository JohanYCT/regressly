import 'package:flutter_test/flutter_test.dart';
import 'package:regressly/models/finca_model.dart';
import 'package:regressly/models/registro_model.dart';
import 'package:regressly/services/pdf_report_service.dart';

void main() {
  group('PdfReportService Tests', () {
    test('Should generate production report PDF bytes successfully', () async {
      final registros = [
        RegistroModel(
          id: 1,
          fecha: '2023-10-01',
          litrosManana: 15.0,
          litrosTarde: 15.0,
          litrosTotal: 30.0,
          observaciones: 'Normal',
          createdAt: '2023-10-01T10:00:00Z',
        ),
        RegistroModel(
          id: 2,
          fecha: '2023-10-02',
          litrosManana: 20.0,
          litrosTarde: 18.0,
          litrosTotal: 38.0,
          observaciones: 'Buen día',
          createdAt: '2023-10-02T10:00:00Z',
        ),
      ];

      final finca = FincaModel(
        id: 1,
        nombreProductor: 'Juan Pérez',
        nombreFinca: 'La Esperanza',
        ubicacion: 'Bogotá',
        numeroVacas: 10,
        precioLitro: 2000.0,
      );

      final pdfBytes = await PdfReportService.generateProductionReport(
        registros: registros,
        finca: finca,
        tituloFiltro: 'Octubre 2023',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('Should generate PDF successfully even with empty registros and null finca', () async {
      final pdfBytes = await PdfReportService.generateProductionReport(
        registros: [],
        finca: null,
        tituloFiltro: 'Historial Vacío',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });
}
