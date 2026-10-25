import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:regressly/main.dart' as app;
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End (E2E) Test - Cobertura 100%', () {
    
    setUpAll(() async {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        try {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        } catch (_) {}
      }
      SharedPreferences.setMockInitialValues({});
      await AuthService.instance.setGuestMode();
      try {
        await DatabaseHelper.instance.clearDatabase();
      } catch (_) {}
    });

    testWidgets('Flujo Completo E2E: Configuración, Cierre de Sesión, Registro con Observaciones, Estimaciones Financieras y Gráficas', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1000));

      // Helper para cerrar el teclado de forma universal en Android/iOS/Desktop
      Future<void> hideKeyboard() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
      }

      // Si aparece la pantalla de login, hace tap en Continuar como invitado
      final btnGuest = find.byKey(const Key('btn_guest_login'));
      if (btnGuest.evaluate().isNotEmpty) {
        await tester.tap(btnGuest);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 1000));
      }

      // -----------------------------------------------------------
      // FASE 1: CONFIGURACIÓN DE LA FINCA Y PRUEBA DE DIÁLOGO DE SESIÓN
      // -----------------------------------------------------------
      final navConfig = find.byKey(const Key('nav_configuracion'));
      if (navConfig.evaluate().isNotEmpty) {
        await tester.ensureVisible(navConfig);
        await tester.tap(navConfig);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 800));
      }

      // Probar presionar Cerrar Sesión y luego Cancelar en el diálogo
      final btnCerrarSesion = find.byKey(const Key('btn_cerrar_sesion'));
      if (btnCerrarSesion.evaluate().isNotEmpty) {
        await tester.ensureVisible(btnCerrarSesion);
        await tester.tap(btnCerrarSesion);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 800));

        expect(find.text('¿Cerrar Sesión?'), findsOneWidget);

        // Toca el botón Cancelar en el diálogo
        final btnCancelar = find.text('Cancelar');
        await tester.tap(btnCancelar);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
      }

      // Diligenciamiento de los campos de la Finca
      final productorField = find.widgetWithText(TextFormField, 'Nombre del Productor');
      await tester.ensureVisible(productorField);
      await tester.enterText(productorField, 'Carlos Gomez');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      
      final fincaField = find.widgetWithText(TextFormField, 'Nombre de la Finca');
      await tester.ensureVisible(fincaField);
      await tester.enterText(fincaField, 'Rancho Alegre');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      
      final ubicacionField = find.widgetWithText(TextFormField, 'Ubicación');
      await tester.ensureVisible(ubicacionField);
      await tester.enterText(ubicacionField, 'Antioquia');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      
      final vacasField = find.widgetWithText(TextFormField, 'Número de Vacas');
      await tester.ensureVisible(vacasField);
      await tester.enterText(vacasField, '15');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      
      final precioField = find.widgetWithText(TextFormField, 'Precio por Litro (COP)');
      await tester.ensureVisible(precioField);
      await tester.enterText(precioField, '2100');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      
      await hideKeyboard();
      
      final btnGuardarConfig = find.byKey(const Key('btn_guardar_config'));
      await tester.ensureVisible(btnGuardarConfig);
      await tester.pumpAndSettle();
      await tester.tap(btnGuardarConfig);
      await tester.pumpAndSettle();
      // La pantalla de Configuración guarda y se cierra automáticamente hacia el Home
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(find.text('Configuración guardada exitosamente'), findsAtLeastNWidgets(1));

      // -----------------------------------------------------------
      // FASE 2: REGISTRO DÍA 1 CON OBSERVACIONES (Producción Base: 80L)
      // -----------------------------------------------------------
      final navRegistro = find.byKey(const Key('nav_registro'));
      await tester.ensureVisible(navRegistro);
      await tester.tap(navRegistro);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 800));

      final mananaField = find.widgetWithText(TextFormField, 'Litros Mañana');
      await tester.ensureVisible(mananaField);
      await tester.enterText(mananaField, '40');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      
      final tardeField = find.widgetWithText(TextFormField, 'Litros Tarde');
      await tester.ensureVisible(tardeField);
      await tester.enterText(tardeField, '40');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      final obsField = find.byType(TextFormField).at(2);
      if (obsField.evaluate().isNotEmpty) {
        await tester.ensureVisible(obsField);
        await tester.enterText(obsField, 'Aumento de alimento concentrado');
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));
      }
      
      await hideKeyboard();
      
      final btnGuardarRegistro = find.byKey(const Key('btn_guardar_registro'));
      await tester.ensureVisible(btnGuardarRegistro);
      await tester.pumpAndSettle();
      await tester.tap(btnGuardarRegistro);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1200));

      final snackGuardado = find.text('Registro guardado exitosamente');
      final snackActualizado = find.text('Registro actualizado exitosamente');
      expect(snackGuardado.evaluate().isNotEmpty || snackActualizado.evaluate().isNotEmpty, isTrue);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 800));

      // -----------------------------------------------------------
      // FASE 3: REGISTRO DÍA 2 (Edición a 90L)
      // -----------------------------------------------------------
      final navRegistro2 = find.byKey(const Key('nav_registro'));
      await tester.ensureVisible(navRegistro2);
      await tester.tap(navRegistro2);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 800));
      
      final mananaEditField = find.widgetWithText(TextFormField, 'Litros Mañana');
      await tester.ensureVisible(mananaEditField);
      await tester.enterText(mananaEditField, '45');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      
      final tardeEditField = find.widgetWithText(TextFormField, 'Litros Tarde');
      await tester.ensureVisible(tardeEditField);
      await tester.enterText(tardeEditField, '45');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      
      await hideKeyboard();
      
      final btnActualizarRegistro = find.byKey(const Key('btn_guardar_registro'));
      await tester.ensureVisible(btnActualizarRegistro);
      await tester.pumpAndSettle();
      await tester.tap(btnActualizarRegistro);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1200));

      final snackActualizado2 = find.text('Registro actualizado exitosamente');
      final snackGuardado2 = find.text('Registro guardado exitosamente');
      expect(snackActualizado2.evaluate().isNotEmpty || snackGuardado2.evaluate().isNotEmpty, isTrue);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 800));

      // -----------------------------------------------------------
      // FASE 4: VERIFICACIÓN MÓDULO ESTIMACIONES FINANCIERAS
      // -----------------------------------------------------------
      final navEstimaciones = find.byKey(const Key('nav_estimaciones'));
      await tester.ensureVisible(navEstimaciones);
      await tester.tap(navEstimaciones);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('Resumen Financiero'), findsOneWidget);
      expect(find.text('Rancho Alegre'), findsOneWidget);
      expect(find.textContaining('Dinero Acumulado'), findsOneWidget);
      expect(find.textContaining('Próxima Quincena'), findsOneWidget);

      final btnRefrescar = find.byIcon(Icons.refresh);
      if (btnRefrescar.evaluate().isNotEmpty) {
        await tester.tap(btnRefrescar);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 800));
      }

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 800));

      // -----------------------------------------------------------
      // FASE 5: VERIFICACIÓN EN ANALÍTICA Y ALERTA DE FIABILIDAD (< 14 DÍAS)
      // -----------------------------------------------------------
      final navAnalisis = find.byKey(const Key('nav_analisis'));
      await tester.ensureVisible(navAnalisis);
      await tester.tap(navAnalisis);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 2000));

      final promedioItem = find.ancestor(
        of: find.text('Promedio Diario'),
        matching: find.byType(Column),
      ).first;

      expect(
        find.descendant(
          of: promedioItem,
          matching: find.text('90.0 L'),
        ),
        findsOneWidget,
      );
      expect(find.text('Resumen de tu Producción'), findsOneWidget);
      expect(find.text('Pronósticos y Predicciones en Espera'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2000));
    });
  });
}
