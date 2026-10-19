import 'package:flutter_test/flutter_test.dart';
import 'package:regressly/models/registro_model.dart';

void main() {
  group('RegistroModel Tests', () {
    test('Should create RegistroModel from Map correctly', () {
      final map = {
        'id': 1,
        'fecha': '2023-10-27',
        'litros_manana': 10.5,
        'litros_tarde': 9.5,
        'litros_total': 20.0,
        'observaciones': 'Test obs',
        'created_at': '2023-10-27T10:00:00Z',
      };

      final registro = RegistroModel.fromMap(map);

      expect(registro.id, 1);
      expect(registro.fecha, '2023-10-27');
      expect(registro.litrosManana, 10.5);
      expect(registro.litrosTarde, 9.5);
      expect(registro.litrosTotal, 20.0);
      expect(registro.observaciones, 'Test obs');
    });

    test('Should convert RegistroModel to Map correctly', () {
      final registro = RegistroModel(
        id: 1,
        fecha: '2023-10-27',
        litrosManana: 10.0,
        litrosTarde: 5.0,
        litrosTotal: 15.0,
        observaciones: 'Obs',
        createdAt: 'Now',
      );

      final map = registro.toMap();

      expect(map['id'], 1);
      expect(map['fecha'], '2023-10-27');
      expect(map['litros_manana'], 10.0);
      expect(map['litros_total'], 15.0);
    });

    test('Should handle null values in fromMap with defaults', () {
      final map = {
        'fecha': '2023-10-27',
      };

      final registro = RegistroModel.fromMap(map);

      expect(registro.id, isNull);
      expect(registro.litrosManana, 0.0);
      expect(registro.litrosTarde, 0.0);
      expect(registro.litrosTotal, 0.0);
    });
  });
}
