import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class RegistroScreen extends StatefulWidget {
  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {

  TextEditingController litrosController = TextEditingController();
  double? litros;
  List<Map<String, dynamic>> registros = [];

  @override
  void initState() {
    super.initState();
    cargarRegistros();
  }

  Future<void> cargarRegistros() async {
    final data = await DatabaseHelper.instance.queryAll();
    setState(() {
      registros = data;
    });
  }

  double calcularPendiente() {
    int n = registros.length;
    if (n < 2) return 0;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      double x = i.toDouble();
      double y = (registros[i]['litros'] as num).toDouble();

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    return (n * sumXY - sumX * sumY) /
        (n * sumX2 - sumX * sumX);
  }

  double calcularIntercepto(double m) {
    int n = registros.length;

    double sumX = 0, sumY = 0;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += (registros[i]['litros'] as num);
    }

    return (sumY - m * sumX) / n;
  }

  double predecir() {
    if (registros.length < 2) return 0;

    double m = calcularPendiente();
    double b = calcularIntercepto(m);

    double siguienteX = registros.length.toDouble();

    return m * siguienteX + b;
  }

  String obtenerTendencia() {
    if (registros.length < 2) return "Sin datos suficientes";

    double m = calcularPendiente();

    if (m > 0) return "📈 Producción en aumento";
    if (m < 0) return "📉 Producción en disminución";

    return "➖ Producción estable";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Registro de Producción'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            Text('Ingrese la producción diaria 🐄'),

            SizedBox(height: 20),

            TextField(
              controller: litrosController,
              decoration: InputDecoration(
                labelText: 'Litros de leche',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              onPressed: () async {
                litros = double.tryParse(litrosController.text);

                if (litros != null) {
                  await DatabaseHelper.instance.insert({
                    DatabaseHelper.columnLitros: litros
                  });

                  await cargarRegistros();
                }
              },
              child: Text('Guardar'),
            ),

            SizedBox(height: 20),

            Expanded(
              child: Column(
                children: [

                  Expanded(
                    child: registros.isEmpty
                        ? Center(child: Text('No hay registros aún'))
                        : ListView.builder(
                      itemCount: registros.length,
                      itemBuilder: (context, index) {
                        final item = registros[index];

                        return Card(
                          child: ListTile(
                            title: Text('${item['litros']} litros'),
                            subtitle: Text('Registro #${item['id']}'),
                          ),
                        );
                      },
                    ),
                  ),

                  if (registros.length >= 2)
                    Text(
                      'Predicción: ${predecir().toStringAsFixed(2)} litros',
                      style: TextStyle(color: Colors.blue),
                    ),

                  if (registros.length >= 2)
                    Text(
                      obtenerTendencia(),
                      style: TextStyle(color: Colors.orange),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}