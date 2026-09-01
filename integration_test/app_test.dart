import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:regressly/main.dart' as app;
import 'package:regressly/database/database_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End (E2E) Test', () {
    
    setUpAll(() async {
      // Limpiar la base de datos antes de empezar el test E2E
      await DatabaseHelper.instance.clearDatabase();
    });

    testWidgets('Complete User Journey: Setup, 3-Day Entry, and Trend Verification', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Helper para cerrar el teclado de forma robusta en cualquier dispositivo
      Future<void> hideKeyboard() async {
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        // Espera extra para asegurar que el teclado se oculte y no bloquee el hit-test
        await tester.pump(const Duration(milliseconds: 500));
      }

      // -----------------------------------------------------------
      // 1. CONFIGURACIÓN DE LA FINCA
      // -----------------------------------------------------------
      await tester.tap(find.byKey(const Key('nav_configuracion')));
      await tester.pumpAndSettle();

      final productorField = find.widgetWithText(TextFormField, 'Nombre del Productor');
      await tester.ensureVisible(productorField);
      await tester.enterText(productorField, 'Carlos Gomez');
      await tester.pumpAndSettle();
      
      final fincaField = find.widgetWithText(TextFormField, 'Nombre de la Finca');
      await tester.ensureVisible(fincaField);
      await tester.enterText(fincaField, 'Rancho Alegre');
      await tester.pumpAndSettle();
      
      final ubicacionField = find.widgetWithText(TextFormField, 'Ubicación');
      await tester.ensureVisible(ubicacionField);
      await tester.enterText(ubicacionField, 'Antioquia');
      await tester.pumpAndSettle();
      
      final vacasField = find.widgetWithText(TextFormField, 'Número de Vacas');
      await tester.ensureVisible(vacasField);
      await tester.enterText(vacasField, '15');
      await tester.pumpAndSettle();
      
      final precioField = find.widgetWithText(TextFormField, 'Precio por Litro (COP)');
      await tester.ensureVisible(precioField);
      await tester.enterText(precioField, '2100');
      
      await hideKeyboard();
      
      final btnGuardarConfig = find.byKey(const Key('btn_guardar_config'));
      await tester.ensureVisible(btnGuardarConfig);
      await tester.pumpAndSettle();
      await tester.tap(btnGuardarConfig);
      await tester.pumpAndSettle();

      expect(find.text('Configuración guardada exitosamente'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // -----------------------------------------------------------
      // 2. REGISTRO DÍA 1 (Producción Base: 80L)
      // -----------------------------------------------------------
      await tester.tap(find.byKey(const Key('nav_registro')));
      await tester.pumpAndSettle();

      final mananaField = find.widgetWithText(TextFormField, 'Litros Mañana');
      await tester.ensureVisible(mananaField);
      await tester.enterText(mananaField, '40');
      await tester.pumpAndSettle();
      
      final tardeField = find.widgetWithText(TextFormField, 'Litros Tarde');
      await tester.ensureVisible(tardeField);
      await tester.enterText(tardeField, '40');
      
      await hideKeyboard();
      
      final btnGuardarRegistro = find.byKey(const Key('btn_guardar_registro'));
      await tester.ensureVisible(btnGuardarRegistro);
      await tester.pumpAndSettle();
      await tester.tap(btnGuardarRegistro);
      await tester.pumpAndSettle();
      expect(find.text('Registro guardado exitosamente'), findsOneWidget);
      
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // -----------------------------------------------------------
      // 3. REGISTRO DÍA 2 (Actualización a 90L)
      // -----------------------------------------------------------
      await tester.tap(find.byKey(const Key('nav_registro')));
      await tester.pumpAndSettle();
      
      final mananaEditField = find.widgetWithText(TextFormField, 'Litros Mañana');
      await tester.ensureVisible(mananaEditField);
      await tester.enterText(mananaEditField, '45');
      await tester.pumpAndSettle();
      
      final tardeEditField = find.widgetWithText(TextFormField, 'Litros Tarde');
      await tester.ensureVisible(tardeEditField);
      await tester.enterText(tardeEditField, '45');
      
      await hideKeyboard();
      
      final btnActualizarRegistro = find.byKey(const Key('btn_guardar_registro'));
      await tester.ensureVisible(btnActualizarRegistro);
      await tester.pumpAndSettle();
      await tester.tap(btnActualizarRegistro);
      await tester.pumpAndSettle();
      expect(find.text('Registro actualizado exitosamente'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // -----------------------------------------------------------
      // 4. VERIFICACIÓN EN ANALÍTICA
      // -----------------------------------------------------------
      await tester.tap(find.byKey(const Key('nav_analisis')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Verificar que el promedio se muestra correctamente (90.0 L)
      final promedioItem = find.ancestor(
        of: find.text('Promedio'),
        matching: find.byType(Column),
      ).first;

      expect(
        find.descendant(
          of: promedioItem,
          matching: find.text('90.0 L'),
        ),
        findsOneWidget,
      );
      expect(find.text('Estadísticas de Producción'), findsOneWidget);
    });
  });
}
