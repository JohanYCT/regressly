import 'package:flutter_test/flutter_test.dart';
import 'package:regressly/models/registro_model.dart';
import 'package:regressly/services/analytics_service.dart';

void main() {
  final analyticsService = AnalyticsService();

  group('AnalyticsService - Regression Tests', () {
    test('Should return zero regression for less than 2 points', () {
      final registros = [
        RegistroModel(
          fecha: '2023-10-01',
          litrosManana: 10,
          litrosTarde: 10,
          litrosTotal: 20,
          observaciones: '',
          createdAt: '',
        )
      ];

      final result = analyticsService.calcularRegresion(registros);

      expect(result.pendiente, 0);
      expect(result.intercepto, 0);
      expect(result.r2, 0);
    });

    test('Should calculate positive linear growth correctly', () {
      // y = 10x + 100
      final registros = [
        RegistroModel(fecha: 'D1', litrosManana: 50, litrosTarde: 50, litrosTotal: 100, observaciones: '', createdAt: ''),
        RegistroModel(fecha: 'D2', litrosManana: 55, litrosTarde: 55, litrosTotal: 110, observaciones: '', createdAt: ''),
        RegistroModel(fecha: 'D3', litrosManana: 60, litrosTarde: 60, litrosTotal: 120, observaciones: '', createdAt: ''),
      ];

      final result = analyticsService.calcularRegresion(registros);

      expect(result.pendiente, closeTo(10, 0.001));
      expect(result.intercepto, closeTo(100, 0.001));
      expect(result.r2, closeTo(1.0, 0.001));
    });

    test('Should calculate perfect negative trend', () {
      // y = -5x + 50
      final registros = [
        RegistroModel(fecha: 'D1', litrosManana: 25, litrosTarde: 25, litrosTotal: 50, observaciones: '', createdAt: ''),
        RegistroModel(fecha: 'D2', litrosManana: 22.5, litrosTarde: 22.5, litrosTotal: 45, observaciones: '', createdAt: ''),
        RegistroModel(fecha: 'D3', litrosManana: 20, litrosTarde: 20, litrosTotal: 40, observaciones: '', createdAt: ''),
      ];

      final result = analyticsService.calcularRegresion(registros);

      expect(result.pendiente, closeTo(-5, 0.001));
      expect(result.intercepto, closeTo(50, 0.001));
      expect(result.r2, closeTo(1.0, 0.001));
    });
  });

  group('AnalyticsService - Prediction Tests', () {
    test('Should predict future values based on trend', () {
      // y = 2x + 10
      final registros = [
        RegistroModel(fecha: 'D1', litrosManana: 5, litrosTarde: 5, litrosTotal: 10, observaciones: '', createdAt: ''),
        RegistroModel(fecha: 'D2', litrosManana: 6, litrosTarde: 6, litrosTotal: 12, observaciones: '', createdAt: ''),
      ];

      final slope = 2.0;
      final intercept = 10.0;

      final predictions = analyticsService.calcularPredicciones(registros, slope, intercept, 2);

      // Expected: 10, 12 (real) + 14, 16 (future)
      expect(predictions.length, 4);
      expect(predictions[0], 10);
      expect(predictions[1], 12);
      expect(predictions[2], 14);
      expect(predictions[3], 16);
    });

    test('Predictions should never be negative', () {
      // y = -10x + 5
      final registrations = [
        RegistroModel(fecha: 'D1', litrosManana: 2.5, litrosTarde: 2.5, litrosTotal: 5, observaciones: '', createdAt: ''),
        RegistroModel(fecha: 'D2', litrosManana: -2.5, litrosTarde: -2.5, litrosTotal: -5, observaciones: '', createdAt: ''),
      ];

      final predictions = analyticsService.calcularPredicciones(registrations, -10, 5, 1);

      for (var p in predictions) {
        expect(p, greaterThanOrEqualTo(0));
      }
    });
  });
}
