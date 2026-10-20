import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/models/finca_model.dart';
import 'package:regressly/services/analytics_service.dart';
import 'package:regressly/app_theme.dart';

/// [FinancieroScreen] es la pantalla principal encargada de mostrar el resumen financiero
/// y las proyecciones de ingresos para productores lecheros / rurales.
///
/// Diseñada con un enfoque altamente visual e intuitivo ("10-foot UI" / tarjetas grandes),
/// permite al productor visualizar de un vistazo:
/// - Los datos generales de su finca y el precio actual pagado por litro de leche.
/// - El dinero acumulado histórico basado en la producción registrada.
/// - Una estimación de ingresos y litros para la próxima quincena (15 días) utilizando
///   análisis estadístico de regresión lineal.
class FinancieroScreen extends StatefulWidget {
  const FinancieroScreen({super.key});

  @override
  State<FinancieroScreen> createState() => _FinancieroScreenState();
}

/// [_FinancieroScreenState] gestiona el estado interno, la comunicación con la base de datos local (SQLite)
/// a través de [DatabaseHelper], los cálculos de proyecciones mediante [AnalyticsService], y
/// la renderización de la interfaz de usuario adaptada al entorno rural.
class _FinancieroScreenState extends State<FinancieroScreen> {

  // ============================
  // 📊 VARIABLES DE ESTADO Y SERVICIOS
  // ============================

  /// Servicio encargado de ejecutar los cálculos estadísticos (regresión lineal y predicciones de series temporales).
  final AnalyticsService _analyticsService = AnalyticsService();

  /// Bandera booleana que indica si la pantalla se encuentra cargando datos desde la base de datos local.
  bool _isLoading = true;

  /// Objeto que almacena la información de configuración de la finca (nombre, precio por litro, etc.).
  FincaModel? _finca;

  /// Acumulado histórico total de litros de leche producidos registrados en la aplicación.
  double _totalLitrosHistorico = 0.0;

  /// Acumulado histórico total de dinero generado (Litros históricos * Precio por litro).
  double _totalDineroHistorico = 0.0;

  /// Proyección estimada de litros de leche para los próximos 15 días (próxima quincena).
  double _litrosProyeccion15 = 0.0;

  /// Proyección estimada de ingresos monetarios para los próximos 15 días (Litros proyectados * Precio por litro).
  double _dineroProyeccion15 = 0.0;

  @override
  void initState() {
    super.initState();
    // Al inicializar el estado, disparamos la carga asíncrona de registros y finca.
    _cargarDatos();
  }

  // ============================
  // 📥 CARGA Y PROCESAMIENTO DE DATOS
  // ============================

  /// Método asíncrono para obtener y procesar la información financiera:
  /// 1. Consulta todos los registros de producción lechera desde la base de datos SQLite.
  /// 2. Obtiene la configuración de la finca (incluyendo el precio acordado por litro).
  /// 3. Calcula el total histórico de litros y dinero acumulado.
  /// 4. Aplica [AnalyticsService] para calcular la regresión lineal y predecir la producción de los próximos 15 días.
  ///    - Si hay suficientes registros (>= 2), utiliza el modelo de regresión lineal.
  ///    - Si hay solo un registro, calcula un promedio simple.
  ///    - Si no hay registros, los valores se mantienen en cero.
  /// 5. Actualiza el estado (`setState`) para refrescar la interfaz con los resultados calculados.
  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    // Obtención de registros históricos y datos de la finca desde SQLite
    final registros = await DatabaseHelper.instance.queryAllRegistros();
    final finca = await DatabaseHelper.instance.getFinca();

    // Invertimos la lista para asegurar el orden cronológico adecuado para el análisis de tendencias
    final registrosOrdenados = registros.reversed.toList();

    // Cálculo del total histórico de litros producidos
    double totalLitros = 0.0;
    for (var r in registrosOrdenados) {
      totalLitros += r.litrosTotal;
    }

    // Precio por litro configurado en la finca (por defecto 0.0 si no está configurado)
    double precioLitro = finca?.precioLitro ?? 0.0;
    
    // Cálculo del dinero acumulado histórico
    double totalDinero = totalLitros * precioLitro;

    // =========================================================================
    // 📈 CÁLCULO DE PROYECCIÓN A 15 DÍAS (PRÓXIMA QUINCENA)
    // =========================================================================
    double litros15 = 0.0;
    if (registrosOrdenados.length >= 2) {
      // Si tenemos al menos 2 puntos de datos, aplicamos regresión lineal avanzada
      final regRes = _analyticsService.calcularRegresion(registrosOrdenados);
      final predicciones = _analyticsService.calcularPredicciones(
        registrosOrdenados,
        regRes.pendiente,
        regRes.intercepto,
        15, // Proyectar 15 días hacia adelante
      );

      // Sumamos las predicciones correspondientes al horizonte de 15 días proyectados
      int n = registrosOrdenados.length;
      for (int i = n; i < predicciones.length; i++) {
        litros15 += predicciones[i];
      }
    } else if (registrosOrdenados.isNotEmpty) {
      // Fallback: Si solo hay 1 registro, usamos promedio simple proyectado a 15 días
      double promedio = totalLitros / registrosOrdenados.length;
      litros15 = promedio * 15;
    }

    // Conversión de litros proyectados a ingresos monetarios esperados
    double dinero15 = litros15 * precioLitro;

    // Actualización del estado de la pantalla con los datos procesados
    setState(() {
      _finca = finca;
      _totalLitrosHistorico = totalLitros;
      _totalDineroHistorico = totalDinero;
      _litrosProyeccion15 = litros15;
      _dineroProyeccion15 = dinero15;
      _isLoading = false;
    });
  }

  // ============================
  // 🧱 CONSTRUCCIÓN DE LA INTERFAZ DE USUARIO (UI)
  // ============================

  @override
  Widget build(BuildContext context) {
    // Formateadores monetarios y numéricos para una presentación clara y profesional
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final numberFormat = NumberFormat('#,##0.00');

    // Si los datos siguen cargándose, mostramos un indicador de carga centrado
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resumen Financiero')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen Financiero'),
        actions: [
          // Botón manual para recargar datos y recalcular proyecciones
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================================
            // 🐄 TARJETA 1: DATOS GENERALES DE LA FINCA Y PRECIO POR LITRO
            // =================================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.home_work, color: AppTheme.primaryGreen, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _finca?.nombreFinca ?? 'Mi Finca',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pago por litro: ${currencyFormat.format(_finca?.precioLitro ?? 0.0)}',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // =================================================================
            // 💵 TARJETA HERO 2: DINERO ACUMULADO HISTÓRICO (GRADIENTE VERDE)
            // =================================================================
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.savings, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Dinero Acumulado',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyFormat.format(_totalDineroHistorico),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total producido: ${numberFormat.format(_totalLitrosHistorico)} Litros',
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // =================================================================
            // 📅 TARJETA HERO 3: PROYECCIÓN PRÓXIMA QUINCENA (GRADIENTE NARANJA)
            // =================================================================
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Próxima Quincena (15 Días)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyFormat.format(_dineroProyeccion15),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leche estimada: ${numberFormat.format(_litrosProyeccion15)} Litros',
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // =================================================================
            // 💡 TARJETA DE AYUDA / MENSAJE EDUCATIVO AMIGABLE
            // =================================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Este cálculo se actualiza solo con los litros que anotes cada día y el precio acordado por litro de leche.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
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
