import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/models/registro_model.dart';
import 'package:regressly/services/analytics_service.dart';

/// Pantalla encargada de mostrar análisis y visualización de datos
/// mediante gráficas y modelos de regresión.
///
/// Funcionalidades principales:
/// - Visualización de producción diaria en gráfico de líneas
/// - Cálculo de regresión lineal (tendencia)
/// - Predicción de producción futura (7 días)
/// - Métricas estadísticas (R², promedio, etc.)
///
/// Utiliza:
/// - fl_chart → para renderizar gráficas
/// - intl → para formateo de fechas
/// - DatabaseHelper → para obtener datos almacenados
class GraficasScreen extends StatefulWidget {
  const GraficasScreen({super.key});

  @override
  State<GraficasScreen> createState() => _GraficasScreenState();
}

/// Estado de la pantalla GraficasScreen.
///
/// Aquí se maneja:
/// - Carga de datos desde SQLite
/// - Procesamiento estadístico
/// - Generación de datos para gráficas
class _GraficasScreenState extends State<GraficasScreen> {

  // ============================
  // 📊 VARIABLES DE ESTADO
  // ============================

  /// Servicio de analítica para cálculos estadísticos
  final AnalyticsService _analyticsService = AnalyticsService();

  /// Lista de registros obtenidos desde la base de datos
  List<RegistroModel> _registros = [];

  /// Control de carga (loader)
  bool _isLoading = true;

  /// Resultado de la regresión lineal
  RegressionResult? _regressionResult;

  /// Lista de valores predichos (incluye días futuros)
  List<double> _predicciones = [];

  /// Lista de fechas correspondientes a los registros
  List<DateTime> _fechas = [];

  @override
  void initState() {
    super.initState();

    /// Al iniciar la pantalla se cargan los datos
    _cargarDatos();
  }

  // ============================
  // 📥 CARGA DE DATOS
  // ============================

  /// Obtiene todos los registros desde la base de datos
  /// y prepara la información para análisis.
  ///
  /// Flujo:
  /// 1. Activa loading
  /// 2. Consulta datos en SQLite
  /// 3. Ordena registros (más antiguos → más recientes)
  /// 4. Convierte fechas
  /// 5. Calcula regresión
  /// 6. Calcula predicciones
  Future<void> _cargarDatos() async {

    setState(() {
      _isLoading = true;
    });

    final registros = await DatabaseHelper.instance.queryAllRegistros();

    setState(() {

      /// Se invierte la lista para mantener orden cronológico
      _registros = registros.reversed.toList();

      /// Conversión de fechas String → DateTime
      _fechas = _registros.map((r) {
        return DateTime.parse(r.fecha);
      }).toList();

      /// Procesamiento de datos mediante el servicio
      _regressionResult = _analyticsService.calcularRegresion(_registros);
      _predicciones = _analyticsService.calcularPredicciones(
        _registros,
        _regressionResult!.pendiente,
        _regressionResult!.intercepto,
        7,
      );

      _isLoading = false;
    });
  }

  // ============================
  // 📈 MÉTODOS ELIMINADOS (Movidos al Servicio)
  // ============================
  // _calcularRegresion()
  // _calcularPredicciones()
  // _getR2()

  // ============================
  // 📍 GENERACIÓN DE PUNTOS (GRÁFICAS)
  // ============================

  /// Genera los puntos reales de producción para la gráfica principal.
  ///
  /// Cada punto representa:
  /// - X → índice del día (tiempo)
  /// - Y → litros producidos ese día
  ///
  /// Se utiliza en la línea azul (datos reales).
  List<FlSpot> _generarPuntos() {

    List<FlSpot> puntos = [];

    for (int i = 0; i < _registros.length; i++) {

      double x = i.toDouble();
      double y = _registros[i].litrosTotal;

      puntos.add(FlSpot(x, y));
    }

    return puntos;
  }

  /// Genera los puntos de la línea de tendencia (regresión lineal).
  List<FlSpot> _generarLineaTendencia() {

    List<FlSpot> puntos = [];

    if (_regressionResult == null) return puntos;

    for (int i = 0; i < _registros.length; i++) {

      double x = i.toDouble();

      /// Aplicación de la ecuación de regresión
      double y = _regressionResult!.intercepto + _regressionResult!.pendiente * i;

      /// Se evita mostrar valores negativos
      puntos.add(FlSpot(x, y > 0 ? y : 0));
    }

    return puntos;
  }

  /// Genera los puntos de predicción futura.
  ///
  /// Incluye:
  /// - Datos actuales
  /// - +7 días proyectados
  ///
  /// Se utiliza en la gráfica de proyección.
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

  // ============================
  // 🧱 UI PRINCIPAL
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // ============================
      // 📌 APP BAR
      // ============================

      /// Barra superior de la pantalla
      appBar: AppBar(
        title: const Text('Análisis y Gráficas'),
        backgroundColor: Colors.green,
      ),

      // ============================
      // 🎯 MANEJO DE ESTADOS
      // ============================

      body: _isLoading

      /// Estado de carga (mientras se consultan datos)
          ? const Center(
        child: CircularProgressIndicator(),
      )

          : _registros.isEmpty

      /// Estado vacío (sin datos suficientes)
          ? _buildEmptyState()

      /// Estado con datos → muestra contenido completo
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Tarjeta de estadísticas generales
            _buildStatsCard(),

            const SizedBox(height: 16),

            /// Gráfica principal (producción + tendencia)
            _buildChartCard(),

            const SizedBox(height: 16),

            /// Gráfica de predicciones futuras
            _buildPredictionCard(),

            const SizedBox(height: 16),

            /// Información detallada de regresión
            _buildRegressionInfo(),
          ],
        ),
      ),
    );
  }

  // ============================
  // ⚠️ ESTADO VACÍO
  // ============================

  /// Widget que se muestra cuando no hay suficientes datos
  /// para generar análisis o gráficas.
  ///
  /// Requiere mínimo 2 registros para calcular regresión.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          /// Ícono representativo
          Icon(
            Icons.show_chart,
            size: 80,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 16),

          /// Mensaje principal
          Text(
            'No hay datos suficientes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 8),

          /// Mensaje secundario
          Text(
            'Registra al menos 2 días de producción\npara ver análisis y gráficas',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),

          const SizedBox(height: 24),

          // ============================
          // 🔁 BOTÓN DE NAVEGACIÓN
          // ============================

          /// Botón que redirige al módulo de registro
          ElevatedButton(
            onPressed: () {

              /// Navega a la pantalla de registro
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
  // ============================
  // 📊 TARJETA DE ESTADÍSTICAS
  // ============================

  /// Calcula y muestra métricas generales de producción:
  /// - Total acumulado
  /// - Promedio
  /// - Número de días registrados
  /// - Máximo y mínimo
  /// - Tendencia (según la pendiente)
  Widget _buildStatsCard() {

    double total = 0;
    double maximo = 0;
    double minimo = double.infinity;

    /// Recorrido para calcular métricas
    for (var r in _registros) {
      double litros = r.litrosTotal;
      total += litros;

      if (litros > maximo) maximo = litros;
      if (litros < minimo) minimo = litros;
    }

    double promedio = total / _registros.length;

    /// Ajuste si no hay datos válidos
    if (minimo == double.infinity) minimo = 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Título de la sección
            const Text(
              'Estadísticas de Producción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // ============================
            // 📌 FILA 1: TOTAL / PROMEDIO / DÍAS
            // ============================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                _buildStatItem(
                  'Total',
                  '${total.toStringAsFixed(1)} L',
                  Icons.production_quantity_limits,
                ),

                _buildStatItem(
                  'Promedio',
                  '${promedio.toStringAsFixed(1)} L',
                  Icons.trending_up,
                ),

                _buildStatItem(
                  'Días',
                  '${_registros.length}',
                  Icons.calendar_today,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ============================
            // 📌 FILA 2: MAX / MIN / TENDENCIA
            // ============================

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [

                _buildStatItem(
                  'Máximo',
                  '${maximo.toStringAsFixed(1)} L',
                  Icons.arrow_upward,
                ),

                _buildStatItem(
                  'Mínimo',
                  '${minimo.toStringAsFixed(1)} L',
                  Icons.arrow_downward,
                ),

                /// Indicador de tendencia basado en la pendiente
                _buildStatItem(
                  'Tendencia',

                  (_regressionResult?.pendiente ?? 0) > 0
                      ? '↑ Positiva'
                      : ((_regressionResult?.pendiente ?? 0) < 0 ? '↓ Negativa' : '→ Estable'),

                  (_regressionResult?.pendiente ?? 0) > 0
                      ? Icons.trending_up
                      : ((_regressionResult?.pendiente ?? 0) < 0
                      ? Icons.trending_down
                      : Icons.trending_flat),

                  color: (_regressionResult?.pendiente ?? 0) > 0
                      ? Colors.green
                      : ((_regressionResult?.pendiente ?? 0) < 0 ? Colors.red : Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // 🧩 ITEM DE ESTADÍSTICA
  // ============================

  /// Componente reutilizable para mostrar una métrica individual.
  ///
  /// Parámetros:
  /// - label → nombre del indicador
  /// - value → valor calculado
  /// - icon → ícono representativo
  /// - color → color opcional
  Widget _buildStatItem(
      String label,
      String value,
      IconData icon, {
        Color color = Colors.green,
      }) {
    return Column(
      children: [

        Icon(icon, color: color, size: 28),

        const SizedBox(height: 8),

        /// Valor principal
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        /// Etiqueta
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ============================
  // 📈 GRÁFICA PRINCIPAL
  // ============================

  /// Muestra:
  /// - Línea azul → datos reales
  /// - Línea verde → tendencia (regresión)
  Widget _buildChartCard() {

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

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

            /// Leyenda de la gráfica
            Text(
              'Línea azul: Producción real | Línea verde: Tendencia',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 300,

              child: LineChart(
                LineChartData(

                  /// Cuadrícula
                  gridData: const FlGridData(show: true),

                  // ============================
                  // 📅 EJE X (FECHAS)
                  // ============================

                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,

                        /// Formato de fechas en el eje X
                        getTitlesWidget: (value, meta) {

                          int index = value.toInt();

                          if (index < 0 || index >= _fechas.length) {
                            return Container();
                          }

                          String fecha = DateFormat('dd/MM')
                              .format(_fechas[index]);

                          return Text(
                            fecha,
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),

                  borderData: FlBorderData(show: true),

                  // ============================
                  // 📊 LÍNEAS DE LA GRÁFICA
                  // ============================

                  lineBarsData: [

                    /// Línea de datos reales
                    LineChartBarData(
                      spots: _generarPuntos(),
                      isCurved: true,
                      barWidth: 3,
                      color: Colors.blue,
                      dotData: const FlDotData(show: true),
                    ),

                    /// Línea de tendencia (regresión)
                    LineChartBarData(
                      spots: _generarLineaTendencia(),
                      isCurved: false,
                      barWidth: 2,
                      color: Colors.green,
                      dotData: const FlDotData(show: false),

                      /// Línea punteada
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

  // ============================
  // 🔮 GRÁFICA DE PREDICCIÓN
  // ============================

  /// Muestra la proyección de producción a 7 días
  /// basada en la regresión lineal.
  Widget _buildPredictionCard() {

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

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

                    /// Línea de predicción
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

  // ============================
  // 🧠 INFORMACIÓN DE REGRESIÓN
  // ============================

  /// Muestra información matemática del modelo:
  Widget _buildRegressionInfo() {

    double pendiente = _regressionResult?.pendiente ?? 0;
    double intercepto = _regressionResult?.intercepto ?? 0;
    double r2 = _regressionResult?.r2 ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

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

            _buildInfoRow('Pendiente:', pendiente.toStringAsFixed(3)),

            const SizedBox(height: 8),

            _buildInfoRow('Intercepto:', intercepto.toStringAsFixed(1)),

            const SizedBox(height: 8),

            _buildInfoRow(
              'R² (Coef. Determinación):',
              '${(r2 * 100).toStringAsFixed(1)}%',
            ),

            const SizedBox(height: 12),

            // ============================
            // 📊 INTERPRETACIÓN
            // ============================

            if (pendiente > 0)
              const Text(
                '📈 La producción está en aumento',
                style: TextStyle(color: Colors.green),
              )
            else if (pendiente < 0)
              const Text(
                '📉 La producción está en disminución',
                style: TextStyle(color: Colors.red),
              )
            else
              const Text(
                '📊 La producción se mantiene estable',
                style: TextStyle(color: Colors.orange),
              ),

            const SizedBox(height: 8),

            /// Predicción del siguiente día
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

  // ============================
  // 📄 FILA DE INFORMACIÓN
  // ============================

  /// Componente reutilizable para mostrar pares clave-valor.
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}