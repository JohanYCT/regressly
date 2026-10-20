import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/models/finca_model.dart';
import 'package:regressly/services/analytics_service.dart';
import 'package:regressly/app_theme.dart';

/// Pantalla Financiera simplificada y diseñada para productores rurales.
/// Presenta de forma muy visual, intuitiva y con números grandes el dinero
/// acumulado y la estimación de ingresos para la próxima quincena.
class FinancieroScreen extends StatefulWidget {
  const FinancieroScreen({super.key});

  @override
  State<FinancieroScreen> createState() => _FinancieroScreenState();
}

/// Estado de la pantalla FinancieroScreen.
///
/// Gestiona la carga de datos y cálculos automáticos de producción e ingresos.
class _FinancieroScreenState extends State<FinancieroScreen> {

  // ============================
  // 📊 VARIABLES DE ESTADO
  // ============================

  /// Servicio para calcular proyecciones basadas en producción
  final AnalyticsService _analyticsService = AnalyticsService();

  /// Indicador de carga
  bool _isLoading = true;

  /// Datos de la finca del usuario
  FincaModel? _finca;

  /// Métricas financieras
  double _totalLitrosHistorico = 0.0;
  double _totalDineroHistorico = 0.0;
  double _litrosProyeccion15 = 0.0;
  double _dineroProyeccion15 = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ============================
  // 📥 CARGA DE DATOS
  // ============================

  /// Obtiene los registros y finca de SQLite y calcula totales e ingresos.
  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
    });

    final registros = await DatabaseHelper.instance.queryAllRegistros();
    final finca = await DatabaseHelper.instance.getFinca();

    final registrosOrdenados = registros.reversed.toList();

    double totalLitros = 0.0;
    for (var r in registrosOrdenados) {
      totalLitros += r.litrosTotal;
    }

    double precioLitro = finca?.precioLitro ?? 0.0;
    double totalDinero = totalLitros * precioLitro;

    // Cálculo de proyección a 15 días (próxima quincena)
    double litros15 = 0.0;
    if (registrosOrdenados.length >= 2) {
      final regRes = _analyticsService.calcularRegresion(registrosOrdenados);
      final predicciones = _analyticsService.calcularPredicciones(
        registrosOrdenados,
        regRes.pendiente,
        regRes.intercepto,
        15,
      );

      int n = registrosOrdenados.length;
      for (int i = n; i < predicciones.length; i++) {
        litros15 += predicciones[i];
      }
    } else if (registrosOrdenados.isNotEmpty) {
      double promedio = totalLitros / registrosOrdenados.length;
      litros15 = promedio * 15;
    }

    double dinero15 = litros15 * precioLitro;

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
  // 🧱 UI PRINCIPAL (ENFOQUE RURAL / INTUITIVO)
  // ============================

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final numberFormat = NumberFormat('#,##0.00');

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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================
            // 🐄 TARJETA: DATOS DE LA FINCA
            // ============================
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

            // ============================
            // 💵 TARJETA HERO: DINERO ACUMULADO
            // ============================
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

            // ============================
            // 📅 TARJETA HERO: PRÓXIMA QUINCENA
            // ============================
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

            // ============================
            // 💡 MENSAJE DE AYUDA AMIGABLE
            // ============================
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
