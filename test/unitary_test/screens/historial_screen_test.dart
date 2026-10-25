import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:regressly/screens/historial_screen.dart';

void main() {
  testWidgets('HistorialScreen renders correctly and shows title and filter chips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HistorialScreen(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Check AppBar title
    expect(find.text('Historial de Producción'), findsOneWidget);

    // Check search field
    expect(find.byType(TextField), findsOneWidget);

    // Check filter chips
    expect(find.text('Todo'), findsOneWidget);
    expect(find.text('Este Mes'), findsOneWidget);
    expect(find.text('Últimos 30 días'), findsOneWidget);
  });
}
