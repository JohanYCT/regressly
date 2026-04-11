import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:regressly/database/database_helper.dart';

class GraficasScreen extends StatefulWidget {
  const GraficasScreen({super.key});

  @override
  State<GraficasScreen> createState() => _GraficasScreenState();
}

class _GraficasScreenState extends State<GraficasScreen> {
  List<Map<String, dynamic>> _registros = [];
  bool _isLoading = true;
  double _pendiente = 0;
  double _intercepto = 0;
  List<double> _predicciones = [];
  List<DateTime> _fechas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    final registros = await DatabaseHelper.instance.queryAllRegistros();
    setState(() {
      _registros = registros.reversed.toList();
      _fechas = _registros.map((r) {
        return DateTime.parse(r['fecha']);
      }).toList();
      _calcularRegresion();
      _calcularPredicciones();
      _isLoading = false;
    });
  }

  void _calcularRegresion() {
    if (_registros.length < 2) {
      _pendiente = 0;
      _intercepto = 0;
      return;
    }

    int n = _registros.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      double x = i.toDouble();
      double y = (_registros[i]['litros_total'] ?? 0).toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    double denominador = (n * sumX2 - sumX * sumX);
    if (denominador != 0) {
      _pendiente = (n * sumXY - sumX * sumY) / denominador;
      _intercepto = (sumY - _pendiente * sumX) / n;
    }
  }

  void _calcularPredicciones() {
    _predicciones.clear();
    int n = _registros.length;
    for (int i = 0; i < n + 7; i++) {
      double prediccion = _intercepto + _pendiente * i;
      _predicciones.add(prediccion > 0 ? prediccion : 0);
    }
  }

  double _getR2() {
    if (_registros.length < 2) return 0;

    double sumY = 0;
    for (var r in _registros) {
      sumY += r['litros_total'] as double;
    }
    double meanY = sumY / _registros.length;

    double ssRes = 0;
    double ssTot = 0;

    for (int i = 0; i < _registros.length; i++) {
      double yReal = _registros[i]['litros_total'] as double;
      double yPred = _intercepto + _pendiente * i;
      ssRes += (yReal - yPred) * (yReal - yPred);
      ssTot += (yReal - meanY) * (yReal - meanY);
    }

    return ssTot == 0 ? 0 : 1 - (ssRes / ssTot);
  }

  List<FlSpot> _generarPuntos() {
    List<FlSpot> puntos = [];
    for (int i = 0; i < _registros.length; i++) {
      double x = i.toDouble();
      double y = _registros[i]['litros_total'] as double;
      puntos.add(FlSpot(x, y));
    }
    return puntos;
  }

  List<FlSpot> _generarLineaTendencia() {
    List<FlSpot> puntos = [];
    for (int i = 0; i < _registros.length; i++) {
      double x = i.toDouble();
      double y = _intercepto + _pendiente * i;
      puntos.add(FlSpot(x, y > 0 ? y : 0));
    }
    return puntos;
  }

  List<FlSpot> _generarPredicciones() {
    List<FlSpot> puntos = [];
    int n = _registros.length;
    for (int i = 0; i < n + 7; i++) {
      double x = i.toDouble();
      double y = _predicciones[i];
      puntos.add(FlSpot(x, y));
    }
    return puntos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis y Gráficas'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _registros.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildChartCard(),
            const SizedBox(height: 16),
            _buildPredictionCard(),
            const SizedBox(height: 16),
            _buildRegressionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay datos suficientes',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra al menos 2 días de producción\npara ver análisis y gráficas',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/registro');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Ir a Registro'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    double total = 0;
    double maximo = 0;
    double minimo = double.infinity;

    for (var r in _registros) {
      double litros = r['litros_total'] as double;
      total += litros;
      if (litros > maximo) maximo = litros;
      if (litros < minimo) minimo = litros;
    }

    double promedio = total / _registros.length;
    if (minimo == double.infinity) minimo = 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas de Producción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', '${total.toStringAsFixed(1)} L', Icons.production_quantity_limits),
                _buildStatItem('Promedio', '${promedio.toStringAsFixed(1)} L', Icons.trending_up),
                _buildStatItem('Días', '${_registros.length}', Icons.calendar_today),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Máximo', '${maximo.toStringAsFixed(1)} L', Icons.arrow_upward),
                _buildStatItem('Mínimo', '${minimo.toStringAsFixed(1)} L', Icons.arrow_downward),
                _buildStatItem(
                  'Tendencia',
                  _pendiente > 0 ? '↑ Positiva' : (_pendiente < 0 ? '↓ Negativa' : '→ Estable'),
                  _pendiente > 0 ? Icons.trending_up : (_pendiente < 0 ? Icons.trending_down : Icons.trending_flat),
                  color: _pendiente > 0 ? Colors.green : (_pendiente < 0 ? Colors.red : Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color color = Colors.green}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Producción Diaria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Línea azul: Producción real | Línea verde: Tendencia',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();

                          if (index < 0 || index >= _fechas.length) {
                            return Container();
                          }

                          String fecha = DateFormat('dd/MM').format(_fechas[index]);

                          return Text(
                            fecha,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generarPuntos(),
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.blue,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: _generarLineaTendencia(),
                      isCurved: false,
                      barWidth: 2,
                      color: Colors.green,
                      dotData: const FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proyección a 7 Días',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimación de producción basada en tendencia histórica',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generarPredicciones(),
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.orange,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegressionInfo() {
    double r2 = _getR2();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Regresión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Pendiente:', _pendiente.toStringAsFixed(3)),
            const SizedBox(height: 8),
            _buildInfoRow('Intercepto:', _intercepto.toStringAsFixed(1)),
            const SizedBox(height: 8),
            _buildInfoRow('R² (Coef. Determinación):', '${(r2 * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 12),
            if (_pendiente > 0)
              const Text('📈 La producción está en aumento', style: TextStyle(color: Colors.green))
            else if (_pendiente < 0)
              const Text('📉 La producción está en disminución', style: TextStyle(color: Colors.red))
            else
              const Text('📊 La producción se mantiene estable', style: TextStyle(color: Colors.orange)),
            const SizedBox(height: 8),
            if (_predicciones.length > _registros.length)
              Text(
                '📅 Producción estimada para mañana: ${_predicciones[_registros.length].toStringAsFixed(1)} litros',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}