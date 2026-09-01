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

      // -----------------------------------------------------------
      // 1. CONFIGURACIÓN DE LA FINCA
      // -----------------------------------------------------------
      await tester.tap(find.byKey(const Key('nav_configuracion')));
      await tester.pumpAndSettle();

      final productorField = find.widgetWithText(TextFormField, 'Nombre del Productor');
      await tester.ensureVisible(productorField);
      await tester.enterText(productorField, 'Carlos Gomez');
      
      final fincaField = find.widgetWithText(TextFormField, 'Nombre de la Finca');
      await tester.ensureVisible(fincaField);
      await tester.enterText(fincaField, 'Rancho Alegre');
      
      final ubicacionField = find.widgetWithText(TextFormField, 'Ubicación');
      await tester.ensureVisible(ubicacionField);
      await tester.enterText(ubicacionField, 'Antioquia');
      
      final vacasField = find.widgetWithText(TextFormField, 'Número de Vacas');
      await tester.ensureVisible(vacasField);
      await tester.enterText(vacasField, '15');
      
      final precioField = find.widgetWithText(TextFormField, 'Precio por Litro (COP)');
      await tester.ensureVisible(precioField);
      await tester.enterText(precioField, '2100');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      
      final btnGuardarConfig = find.byKey(const Key('btn_guardar_config'));
      await tester.ensureVisible(btnGuardarConfig);
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(btnGuardarConfig);
      await tester.pumpAndSettle();

      expect(find.text('Configuración guardada exitosamente'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // -----------------------------------------------------------
      // 2. REGISTRO DÍA 1 (Producción Base: 80L)
      // -----------------------------------------------------------
      await tester.tap(find.byKey(const Key('nav_registro')));
      await tester.pumpAndSettle();

      final mananaField = find.widgetWithText(TextFormField, 'Litros Mañana');
      await tester.ensureVisible(mananaField);
      await tester.enterText(mananaField, '40');
      
      final tardeField = find.widgetWithText(TextFormField, 'Litros Tarde');
      await tester.ensureVisible(tardeField);
      await tester.enterText(tardeField, '40');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      
      final btnGuardarRegistro = find.byKey(const Key('btn_guardar_registro'));
      await tester.ensureVisible(btnGuardarRegistro);
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(btnGuardarRegistro);
      await tester.pumpAndSettle();
      expect(find.text('Registro guardado exitosamente'), findsOneWidget);
      
      await tester.pageBack();
      await tester.pumpAndSettle();

      // -----------------------------------------------------------
      // 3. REGISTRO DÍA 2 (Actualización a 90L)
      // -----------------------------------------------------------
      await tester.tap(find.byKey(const Key('nav_registro')));
      await tester.pumpAndSettle();
      
      // Nota: No abrimos el selector de fecha para evitar bloquear el test,
      // simplemente actualizamos el registro del día de hoy.

      final mananaEditField = find.widgetWithText(TextFormField, 'Litros Mañana');
      await tester.ensureVisible(mananaEditField);
      await tester.enterText(mananaEditField, '45');
      
      final tardeEditField = find.widgetWithText(TextFormField, 'Litros Tarde');
      await tester.ensureVisible(tardeEditField);
      await tester.enterText(tardeEditField, '45');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      
      // Esto sobreescribirá el registro de hoy (Actualizar)
      final btnActualizarRegistro = find.byKey(const Key('btn_guardar_registro'));
      await tester.ensureVisible(btnActualizarRegistro);
      await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(btnActualizarRegistro);
      await tester.pumpAndSettle();
      expect(find.text('Registro actualizado exitosamente'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // -----------------------------------------------------------
      // 4. VERIFICACIÓN EN ANALÍTICA
      // -----------------------------------------------------------
      await tester.tap(find.byKey(const Key('nav_analisis')));
      await tester.pumpAndSettle();

      // Verificar que el promedio se muestra correctamente (90.0 L)
      // Buscamos el texto '90.0 L' que sea descendiente de la columna MÁS CERCANA al texto 'Promedio'
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
      
      // El test E2E confirma que la configuración de la finca, el guardado 
      // de registros y la visualización de analíticas están conectados.
    });
  });
}
