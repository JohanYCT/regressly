import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/models/registro_model.dart';
import 'package:regressly/services/analytics_service.dart';
import 'package:regressly/app_theme.dart';

/// ============================================================================
/// PANTALLA: GraficasScreen
/// ============================================================================
/// Pantalla principal encargada de mostrar el análisis de tendencias, estadísticas
/// de producción lechera y proyecciones futuras en la aplicación Regressly.
/// 
/// Diseñada con un enfoque extremadamente intuitivo, visual y sencillo para
/// productores rurales del Valle de Ubaté, evitando tecnicismos matemáticos complejos.
/// 
/// REGLA CLAVE DE FIABILIDAD:
/// Las proyecciones (línea verde de tendencia y pronóstico a 7 días) se bloquean
/// automáticamente hasta que el productor complete al menos **14 días** de registro.
class GraficasScreen extends StatefulWidget {
  const GraficasScreen({super.key});

  @override
  State<GraficasScreen> createState() => _GraficasScreenState();
}

class _GraficasScreenState extends State<GraficasScreen> {

  // ==========================================================================
  // 📊 VARIABLES DE ESTADO Y SERVICIOS
  // ==========================================================================

  /// Instancia del servicio de analítica matemática (regresión lineal y R²)
  final AnalyticsService _analyticsService = AnalyticsService();

  /// Lista que almacena los registros de producción lechera obtenidos de SQLite
  List<RegistroModel> _registros = [];

  /// Bandera booleana para controlar el indicador de carga (CircularProgressIndicator)
  bool _isLoading = true;

  /// Objeto que almacena los resultados de la regresión lineal (pendiente, intercepto, R²)
  RegressionResult? _regressionResult;

  /// Lista que almacena los valores calculados de predicción (datos reales + 7 días futuros)
  List<double> _predicciones = [];

  /// Lista de objetos DateTime convertidos a partir de las fechas de los registros
  List<DateTime> _fechas = [];

  // ==========================================================================
  // ⚙️ CICLO DE VIDA DEL WIDGET
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    // Al iniciar la pantalla, disparamos la carga de datos desde la base de datos local
    _cargarDatos();
  }

  // ==========================================================================
  // 📥 CARGA Y PROCESAMIENTO DE DATOS DESDE SQLITE
  // ==========================================================================

  /// Consulta todos los registros almacenados en la base de datos local,
  /// los ordena cronológicamente y ejecuta el análisis estadístico condicionado.
  Future<void> _cargarDatos() async {
    // 1. Activamos el estado de carga visual
    setState(() {
      _isLoading = true;
    });

    // 2. Consultamos la base de datos mediante el Singleton de DatabaseHelper
    final registros = await DatabaseHelper.instance.queryAllRegistros();

    setState(() {
      // 3. Invertimos la lista para llevar un orden cronológico (del día más antiguo al más reciente)
      _registros = registros.reversed.toList();

      // 4. Convertimos los Strings de fecha (ej. "2023-10-01") a objetos DateTime
      _fechas = _registros.map((r) {
        return DateTime.parse(r.fecha);
      }).toList();

      // 5. VALIDACIÓN DE FIABILIDAD: Verificamos si hay al menos 14 días registrados
      if (_registros.length >= 14) {
        // Si hay 14 o más días, calculamos la regresión lineal y el pronóstico a 7 días
        _regressionResult = _analyticsService.calcularRegresion(_registros);
        _predicciones = _analyticsService.calcularPredicciones(
          _registros,
          _regressionResult!.pendiente,
          _regressionResult!.intercepto,
          7, // 7 días de proyección futura
        );
      } else {
        // Si hay menos de 14 días, dejamos los resultados de regresión vacíos
        _regressionResult = null;
        _predicciones = [];
      }

      // 6. Desactivamos el indicador de carga una vez procesado todo
      _isLoading = false;
    });
  }

  // ==========================================================================
  // 📍 GENERACIÓN DE PUNTOS (COORDINADAS) PARA FL_CHART
  // ==========================================================================

  /// Convierte los registros reales de producción en puntos (FlSpot) para la gráfica.
  /// Eje X: Índice del día (0, 1, 2...). Eje Y: Litros totales producidos.
  List<FlSpot> _generarPuntos() {
    List<FlSpot> puntos = [];
    for (int i = 0; i < _registros.length; i++) {
      double x = i.toDouble();
      double y = _registros[i].litrosTotal;
      puntos.add(FlSpot(x, y));
    }
    return puntos;
  }

  /// Calcula y genera los puntos para la línea de tendencia (regresión lineal).
  /// Utiliza la ecuación de la recta: y = intercepto + pendiente * x.
  List<FlSpot> _generarLineaTendencia() {
    List<FlSpot> puntos = [];
    if (_regressionResult == null) return puntos;

    for (int i = 0; i < _registros.length; i++) {
      double x = i.toDouble();
      double y = _regressionResult!.intercepto + _regressionResult!.pendiente * i;
      // Evitamos valores negativos en la tendencia gráfica
      puntos.add(FlSpot(x, y > 0 ? y : 0));
    }
    return puntos;
  }

  /// Genera los puntos para la gráfica de pronóstico de la próxima semana (+7 días).
  List<FlSpot> _generarPredicciones() {
    List<FlSpot> puntos = [];
    int n = _registros.length;
    // Iteramos desde el día 0 hasta el total de días históricos + 7 días futuros
    for (int i = 0; i < n + 7; i++) {
      double x = i.toDouble();
      double y = _predicciones[i];
      puntos.add(FlSpot(x, y));
    }
    return puntos;
  }

  // ==========================================================================
  // 🧱 CONSTRUCCIÓN DE LA VISTA PRINCIPAL (BUILD)
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis y Tendencias'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: _isLoading
          // Muestra un círculo de carga mientras se consultan los datos de SQLite
          ? const Center(child: CircularProgressIndicator())
          // Si no hay ningún registro en la base de datos, muestra la pantalla vacía
          : _registros.isEmpty
              ? _buildEmptyState()
              // Si hay datos, muestra el contenido organizado en scroll vertical
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Tarjeta superior con estadísticas clave (Promedio, Días, Mejor Día, Tendencia)
                      _buildStatsCard(),

                      const SizedBox(height: 16),

                      // 2. Gráfica principal interactiva de producción diaria
                      _buildChartCard(),

                      const SizedBox(height: 16),

                      // 3. CONDICIONAL DE REGISTROS:
                      // Si hay menos de 14 días, muestra el aviso explicativo de días faltantes.
                      // Si ya tiene 14 días o más, muestra el pronóstico y el resumen amigable.
                      if (_registros.length < 14)
                        _buildLockedProjectionsCard()
                      else ...[
                        _buildPredictionCard(),
                        const SizedBox(height: 16),
                        _buildSimpleInsightsCard(),
                      ],
                    ],
                  ),
                ),
    );
  }

  // ==========================================================================
  // ⚠️ COMPONENTE: ESTADO VACÍO (SIN DATOS)
  // ==========================================================================

  /// Pantalla amigable que guía al usuario cuando aún no ha registrado producción.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay registros',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comienza a registrar tu producción diaria\npara ver las gráficas y tendencias.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textLight),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navega directamente a la pantalla de registro diario
                Navigator.pushNamed(context, '/registro');
              },
              child: const Text('Registrar Producción'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 🔒 COMPONENTE: TARJETA DE PROYECCIONES EN ESPERA (< 14 DÍAS)
  // ==========================================================================

  /// Explica claramente al productor por qué las proyecciones están bloqueadas
  /// y cuántos días exactos le faltan para completarlos.
  Widget _buildLockedProjectionsCard() {
    int diasFaltantes = 14 - _registros.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_clock, color: Colors.orange.shade800, size: 30),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Pronósticos y Predicciones en Espera',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Llevas ${_registros.length} de 14 días registrados.\n\n'
            'Para asegurarte un pronóstico 100% confiable y ver hacia dónde va tu producción la próxima semana, necesitamos al menos 14 días de datos.\n\n'
            '¡Te faltan $diasFaltantes ${diasFaltantes == 1 ? 'día' : 'días'} más de registro para desbloquearlo!',
            style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 📊 COMPONENTE: TARJETA DE ESTADÍSTICAS GENERALES
  // ==========================================================================

  /// Calcula métricas clave recorriendo la lista de registros:
  /// - Promedio diario en litros
  /// - Total de días registrados
  /// - Producción máxima (Día Mejor)
  /// - Estado general de la finca (Subiendo, Estable, Bajando)
  Widget _buildStatsCard() {
    double total = 0;
    double maximo = 0;
    double minimo = double.infinity;

    // Recorrido para calcular sumas y máximos/mínimos
    for (var r in _registros) {
      double litros = r.litrosTotal;
      total += litros;
      if (litros > maximo) maximo = litros;
      if (litros < minimo) minimo = litros;
    }

    double promedio = total / _registros.length;
    if (minimo == double.infinity) minimo = 0;

    // Determinamos el texto y color del estado de la finca según la pendiente
    String tendenciaTexto = 'Estable ➔';
    Color tendenciaColor = Colors.orange;
    IconData tendenciaIcon = Icons.trending_flat;

    if (_registros.length >= 14 && _regressionResult != null) {
      if (_regressionResult!.pendiente > 0) {
        tendenciaTexto = '¡Va Subiendo! 📈';
        tendenciaColor = Colors.green;
        tendenciaIcon = Icons.trending_up;
      } else if (_regressionResult!.pendiente < 0) {
        tendenciaTexto = 'Va Bajando 📉';
        tendenciaColor = Colors.red;
        tendenciaIcon = Icons.trending_down;
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de tu Producción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            // Fila con los 3 indicadores principales (Promedio, Días, Mejor Día)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Promedio Diario', '${promedio.toStringAsFixed(1)} L', Icons.water_drop, AppTheme.primaryGreen),
                _buildStatItem('Días Anotados', '${_registros.length}', Icons.calendar_today, Colors.blue),
                _buildStatItem('Día Mejor', '${maximo.toStringAsFixed(1)} L', Icons.star, Colors.amber),
              ],
            ),
            const Divider(height: 24),
            // Fila inferior con el estado actual de la tendencia
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estado actual de la finca:', style: TextStyle(fontSize: 15, color: AppTheme.textLight)),
                Row(
                  children: [
                    Icon(tendenciaIcon, color: tendenciaColor),
                    const SizedBox(width: 6),
                    Text(
                      tendenciaTexto,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tendenciaColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget auxiliar para construir cada celda individual de estadística.
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
      ],
    );
  }

  // ==========================================================================
  // 📈 COMPONENTE: GRÁFICA DE PRODUCCIÓN DIARIA
  // ==========================================================================

  /// Construye la gráfica principal de líneas (LineChart) que muestra:
  /// - Línea azul: Producción real de cada día.
  /// - Línea verde (punteada): Tendencia de regresión lineal (solo cuando hay >= 14 días).
  /// Configurada con ejes limpios y espaciado de fechas optimizado para evitar superposiciones.
  Widget _buildChartCard() {
    // Calculamos un intervalo dinámico para las fechas si hay muchos registros
    double intervalX = _registros.length > 10 ? 2 : 1;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tus Registros Día a Día',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              _registros.length >= 14
                  ? '🔵 Línea azul: Tu producción real  |  🟢 Línea verde: Hacia dónde vas'
                  : '🔵 Línea azul: Litros producidos cada día',
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    // Ocultamos títulos superiores y derechos para evitar saturación visual
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    // Eje izquierdo: Muestra los litros producidos con espacio reservado
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    // Eje inferior: Muestra las fechas formateadas (ej. 06/10)
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: intervalX,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= _fechas.length) return Container();
                          // Evitamos amontonar fechas aplicando el intervalo calculados
                          if (index % intervalX.toInt() != 0 && index != _fechas.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(_fechas[index]),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    // 1. Línea de datos reales (Azul)
                    LineChartBarData(
                      spots: _generarPuntos(),
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.blue,
                      dotData: const FlDotData(show: true),
                    ),
                    // 2. Línea de tendencia de regresión (Verde punteada - solo si hay >= 14 días)
                    if (_registros.length >= 14)
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

  // ==========================================================================
  // 🔮 COMPONENTE: GRÁFICA DE PRONÓSTICO (PRÓXIMA SEMANA)
  // ==========================================================================

  /// Muestra una segunda gráfica de líneas (Naranja) con la proyección estimada
  /// para los próximos 7 días basada en el modelo de regresión lineal.
  Widget _buildPredictionCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.orange, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pronóstico para la Próxima Semana',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Estimación de cuánta leche producirás en los próximos 7 días',
              style: TextStyle(fontSize: 12, color: AppTheme.textLight),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          int day = value.toInt();
                          int totalDays = _registros.length + 7;
                          // Omitimos el penúltimo día si está muy cerca del final para evitar solapamiento
                          if (day == totalDays - 2) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Día $day',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
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

  // ==========================================================================
  // 💡 COMPONENTE: CONCLUSIONES Y PRONÓSTICO PARA MAÑANA
  // ==========================================================================

  /// Traduce los resultados matemáticos complejos en conclusiones sencillas:
  /// - Producción estimada en litros para el día siguiente.
  /// - Porcentaje de confiabilidad del pronóstico basado en el coeficiente R².
  Widget _buildSimpleInsightsCard() {
    double r2 = _regressionResult?.r2 ?? 0;
    // Extraemos la predicción para el día siguiente (índice inmediato posterior al último registro real)
    String produccionManana = _predicciones.length > _registros.length
        ? _predicciones[_registros.length].toStringAsFixed(1)
        : '0.0';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Qué dicen tus datos?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.amber, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Producción estimada para mañana: $produccionManana Litros',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confiabilidad del pronóstico: ${(r2 * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 15, color: AppTheme.textLight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
