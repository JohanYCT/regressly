import 'package:flutter/material.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/models/finca_model.dart';

/// Pantalla encargada de gestionar la configuración de la finca.
///
/// Permite al usuario:
/// - Registrar información del productor
/// - Definir datos de la finca
/// - Guardar configuración en base de datos local
///
/// Esta información puede ser utilizada posteriormente para:
/// - Análisis
/// - Reportes
/// - Personalización de la app
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

/// Estado de la pantalla ConfiguracionScreen.
///
/// Maneja:
/// - Carga de datos desde SQLite
/// - Validación de formulario
/// - Guardado de configuración
class _ConfiguracionScreenState extends State<ConfiguracionScreen> {

  /// Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // ============================
  // 🎛️ CONTROLADORES DE INPUT
  // ============================

  final _nombreProductorController = TextEditingController();
  final _nombreFincaController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _numeroVacasController = TextEditingController();
  final _precioLitroController = TextEditingController();

  // ============================
  // 🔄 ESTADOS DE CONTROL
  // ============================

  /// Indica si se están cargando los datos iniciales
  bool _isLoading = true;

  /// Indica si se está guardando la información
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    /// Carga la configuración existente al iniciar
    _cargarConfiguracion();
  }

  // ============================
  // 📥 CARGAR CONFIGURACIÓN
  // ============================

  /// Obtiene la información de la finca desde la base de datos.
  ///
  /// Si existe:
  /// - Llena automáticamente los campos del formulario
  Future<void> _cargarConfiguracion() async {

    final finca = await DatabaseHelper.instance.getFinca();

    if (finca != null) {

      /// Asignación de valores a los inputs
      _nombreProductorController.text = finca.nombreProductor;
      _nombreFincaController.text = finca.nombreFinca;
      _ubicacionController.text = finca.ubicacion;
      _numeroVacasController.text = finca.numeroVacas.toString();
      _precioLitroController.text = finca.precioLitro.toString();
    }

    setState(() {
      _isLoading = false;
    });
  }

  // ============================
  // 💾 GUARDAR CONFIGURACIÓN
  // ============================

  /// Guarda o actualiza la configuración de la finca en la base de datos.
  ///
  /// Flujo:
  /// 1. Valida el formulario
  /// 2. Construye el objeto de datos
  /// 3. Inserta o actualiza en SQLite
  /// 4. Muestra mensaje de confirmación
  Future<void> _guardarConfiguracion() async {

    if (_formKey.currentState!.validate()) {

      setState(() {
        _isSaving = true;
      });

      /// Construcción del objeto a guardar
      final finca = FincaModel(
        nombreProductor: _nombreProductorController.text,
        nombreFinca: _nombreFincaController.text,
        ubicacion: _ubicacionController.text,
        numeroVacas: int.parse(_numeroVacasController.text),
        precioLitro: double.parse(_precioLitroController.text),
      );

      /// Inserta o actualiza en la base de datos
      await DatabaseHelper.instance.insertOrUpdateFinca(finca);

      setState(() {
        _isSaving = false;
      });

      /// Muestra mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada exitosamente'),
          ),
        );
      }
    }
  }

  // ============================
  // 🧱 UI PRINCIPAL
  // ============================

  @override
  Widget build(BuildContext context) {

    /// Estado de carga inicial
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

      /// Barra superior
      appBar: AppBar(
        title: const Text('Configuración de Finca'),
        backgroundColor: Colors.green,
      ),

      /// Contenido desplazable
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        /// Formulario principal
        child: Form(
          key: _formKey,

          child: Column(
            children: [

              // ============================
              // 🧾 TARJETA DE INFORMACIÓN
              // ============================

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    children: [

                      /// Título de la sección
                      const Text(
                        'Información del Productor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ============================
                      // 🧍 NOMBRE PRODUCTOR
                      // ============================

                      TextFormField(
                        controller: _nombreProductorController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Productor',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? 'Campo requerido' : null,
                      ),

                      const SizedBox(height: 16),

                      // ============================
                      // 🏡 NOMBRE FINCA
                      // ============================

                      TextFormField(
                        controller: _nombreFincaController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Finca',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? 'Campo requerido' : null,
                      ),

                      const SizedBox(height: 16),

                      // ============================
                      // 📍 UBICACIÓN
                      // ============================

                      TextFormField(
                        controller: _ubicacionController,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) =>
                        value!.isEmpty ? 'Campo requerido' : null,
                      ),

                      const SizedBox(height: 16),

                      // ============================
                      // 🐄 NÚMERO DE VACAS
                      // ============================

                  TextFormField(
                    controller: _numeroVacasController,
                    decoration: InputDecoration(
                      labelText: 'Número de Vacas',
                      border: OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/images/icon_vaca.png',
                          width: 16,
                          height: 16,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                        /// Validación numérica
                        validator: (value) {
                          if (value!.isEmpty) return 'Campo requerido';
                          if (int.tryParse(value) == null) return 'Número válido';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ============================
                      // 💰 PRECIO POR LITRO
                      // ============================

                      TextFormField(
                        controller: _precioLitroController,
                        decoration: const InputDecoration(
                          labelText: 'Precio por Litro (COP)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,

                        /// Validación numérica
                        validator: (value) {
                          if (value!.isEmpty) return 'Campo requerido';
                          if (double.tryParse(value) == null) return 'Valor válido';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ============================
              // 💾 BOTÓN GUARDAR
              // ============================

              ElevatedButton(
                key: const Key('btn_guardar_config'),
                onPressed: _isSaving ? null : _guardarConfiguracion,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: _isSaving

                /// Loader mientras guarda
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )

                /// Texto normal
                    : const Text(
                  'Guardar Configuración',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================
  // 🧹 LIBERACIÓN DE RECURSOS
  // ============================

  /// Libera los controladores para evitar fugas de memoria
  @override
  void dispose() {
    _nombreProductorController.dispose();
    _nombreFincaController.dispose();
    _ubicacionController.dispose();
    _numeroVacasController.dispose();
    _precioLitroController.dispose();

    super.dispose();
  }
}