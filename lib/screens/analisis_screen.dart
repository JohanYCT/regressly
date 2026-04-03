import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';

class AnalisisScreen extends StatefulWidget {
  @override
  _AnalisisScreenState createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> {

  // Lista de datos de la BD
  List<Map<String, dynamic>> registros = [];

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  // Cargar datos desde SQLite
  Future<void> cargarDatos() async {
    final data = await DatabaseHelper.instance.queryAll();

    setState(() {
      registros = data;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Análisis'),
      ),

      body: registros.isEmpty
          ? Center(child: Text('No hay datos para graficar'))
          : Padding(
        padding: EdgeInsets.all(16),

        child: LineChart(

          LineChartData(

            // CONFIGURACIÓN GENERAL
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(show: true),

            borderData: FlBorderData(show: true),

            // DATOS DE LA GRÁFICA
            lineBarsData: [

              LineChartBarData(

                spots: generarPuntos(),

                isCurved: true, // línea suave
                barWidth: 4,
                dotData: FlDotData(show: true),

              ),
            ],
          ),
        ),
      ),
    );
  }

  // Convierte los datos en puntos para la gráfica
  List<FlSpot> generarPuntos() {

    List<FlSpot> puntos = [];

    for (int i = 0; i < registros.length; i++) {

      double x = i.toDouble();
      double y = (registros[i]['litros'] as num).toDouble();

      puntos.add(FlSpot(x, y));
    }

    return puntos;
  }
}