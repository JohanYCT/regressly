import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/app_theme.dart';
import 'package:regressly/models/registro_model.dart';

/// Pantalla principal encargada del registro diario de la producción de leche.
///
/// Esta pantalla permite al usuario:
/// - Seleccionar una fecha específica
/// - Registrar litros producidos en la mañana y en la tarde
/// - Calcular automáticamente el total del día
/// - Añadir observaciones adicionales
/// - Guardar o actualizar registros en la base de datos local (SQLite)
///
/// Implementa un formulario validado y persistencia de datos mediante `DatabaseHelper`.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

/// Estado de la pantalla RegistroScreen.
///
/// Aquí se maneja toda la lógica:
/// - Controladores de inputs
/// - Validación del formulario
/// - Interacción con la base de datos
/// - Control de estado (loading, edición, etc.)
class _RegistroScreenState extends State<RegistroScreen> {

  /// Clave global para manejar y validar el formulario
  final _formKey = GlobalKey<FormState>();

  // ============================
  // 🎛️ CONTROLADORES DE INPUT
  // ============================

  /// Controlador para los litros registrados en la mañana
  final _litrosMananaController = TextEditingController();

  /// Controlador para los litros registrados en la tarde
  final _litrosTardeController = TextEditingController();

  /// Controlador para observaciones adicionales
  final _observacionesController = TextEditingController();

  // ============================
  // 📅 ESTADO DE LA PANTALLA
  // ============================

  /// Fecha seleccionada por el usuario (formato YYYY-MM-DD)
  String _fechaSeleccionada = DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Indica si se está realizando una operación (guardar/actualizar)
  bool _isLoading = false;

  /// Indica si el usuario está editando un registro existente
  bool _editando = false;

  /// Almacena el registro existente (si ya hay datos en esa fecha)
  RegistroModel? _registroExistente;

  @override
  void initState() {
    super.initState();

    /// Al iniciar la pantalla se verifica si ya existe un registro para hoy
    _verificarRegistroHoy();
  }

  // ============================
  // 🔍 VERIFICAR REGISTRO EXISTENTE
  // ============================

  /// Consulta en la base de datos si ya existe un registro para la fecha seleccionada.
  ///
  /// Si existe:
  /// - Activa el modo edición
  /// - Carga los datos en los campos del formulario
  Future<void> _verificarRegistroHoy() async {
    final existente = await DatabaseHelper.instance.getRegistroPorFecha(_fechaSeleccionada);

    if (existente != null) {
      setState(() {
        _editando = true;
        _registroExistente = existente;

        /// Carga de datos en los inputs
        _litrosMananaController.text = existente.litrosManana.toString();
        _litrosTardeController.text = existente.litrosTarde.toString();
        _observacionesController.text = existente.observaciones;
      });
    }
  }

  // ============================
  // 📅 SELECCIÓN DE FECHA
  // ============================

  /// Abre un selector de fecha para que el usuario pueda cambiar el día del registro.
  ///
  /// Al seleccionar una nueva fecha:
  /// - Se limpian los campos
  /// - Se desactiva modo edición
  /// - Se verifica si ya existe un registro para esa fecha
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_fechaSeleccionada),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _fechaSeleccionada = DateFormat('yyyy-MM-dd').format(picked);

        /// Reset de estado
        _editando = false;
        _registroExistente = null;

        /// Limpieza de inputs
        _litrosMananaController.clear();
        _litrosTardeController.clear();
        _observacionesController.clear();
      });

      _verificarRegistroHoy();
    }
  }

  // ============================
  // 💾 GUARDAR / ACTUALIZAR REGISTRO
  // ============================

  /// Guarda un nuevo registro o actualiza uno existente en la base de datos.
  ///
  /// Flujo:
  /// 1. Valida el formulario
  /// 2. Calcula el total de litros
  /// 3. Construye el objeto de datos
  /// 4. Inserta o actualiza en SQLite
  /// 5. Muestra feedback al usuario (SnackBar)
  Future<void> _guardarRegistro() async {

    /// Validación del formulario
    if (_formKey.currentState!.validate()) {

      setState(() {
        _isLoading = true;
      });

      /// Conversión de texto a números
      final double litrosManana = double.tryParse(_litrosMananaController.text) ?? 0;
      final double litrosTarde = double.tryParse(_litrosTardeController.text) ?? 0;

      /// Cálculo del total diario
      final double litrosTotal = litrosManana + litrosTarde;

      /// Construcción del objeto a guardar
      final registro = RegistroModel(
        id: _editando ? _registroExistente?.id : null,
        fecha: _fechaSeleccionada,
        litrosManana: litrosManana,
        litrosTarde: litrosTarde,
        litrosTotal: litrosTotal,
        observaciones: _observacionesController.text,
        createdAt: DateTime.now().toIso8601String(),
      );

      // ============================
      // ✏️ MODO EDICIÓN
      // ============================

      if (_editando && _registroExistente != null) {

        await DatabaseHelper.instance.updateRegistro(registro);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro actualizado exitosamente')),
          );
        }

      } else {

        // ============================
        // ➕ NUEVO REGISTRO
        // ============================

        await DatabaseHelper.instance.insertRegistro(registro);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro guardado exitosamente')),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });

      /// Limpia los campos solo si es un nuevo registro
      if (!_editando) {
        _litrosMananaController.clear();
        _litrosTardeController.clear();
        _observacionesController.clear();
      }
    }
  }

  // ============================
  // 🧱 UI PRINCIPAL
  // ============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      /// Barra superior de la pantalla
      appBar: AppBar(
        title: const Text('Registro de Producción'),
      ),

      /// Contenido desplazable (scroll)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        /// Formulario principal
        child: Form(
          key: _formKey,

          child: Column(
            children: [

              // ============================
              // 📅 TARJETA DE FECHA
              // ============================

              /// Muestra la fecha seleccionada y permite editarla
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppTheme.primaryGreen),
                  title: const Text('Fecha'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(_fechaSeleccionada)),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _seleccionarFecha,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ============================
              // 🥛 TARJETA DE PRODUCCIÓN
              // ============================

              /// Tarjeta donde el usuario ingresa la producción de leche
              /// separada en jornada de mañana y tarde.
              ///
              /// Incluye:
              /// - Inputs numéricos
              /// - Validación obligatoria
              /// - Cálculo automático del total del día
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// Encabezado de la sección
                      Row(
                        children: [
                          const Icon(Icons.production_quantity_limits, color: AppTheme.primaryGreen),
                          const SizedBox(width: 12),
                          const Text(
                            'Producción de Leche',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const Divider(),

                      // ============================
                      // 📥 INPUTS DE PRODUCCIÓN
                      // ============================

                      Row(
                        children: [

                          /// Input: Litros de la mañana
                          Expanded(
                            child: TextFormField(
                              controller: _litrosMananaController,

                              decoration: const InputDecoration(
                                labelText: 'Litros Mañana',
                                prefixIcon: Icon(Icons.wb_sunny),
                                suffixText: 'L',
                              ),

                              /// Tipo de teclado numérico
                              keyboardType: TextInputType.number,

                              /// Validación obligatoria
                              validator: (value) => value!.isEmpty ? 'Requerido' : null,
                            ),
                          ),

                          const SizedBox(width: 16),

                          /// Input: Litros de la tarde
                          Expanded(
                            child: TextFormField(
                              controller: _litrosTardeController,

                              decoration: const InputDecoration(
                                labelText: 'Litros Tarde',
                                prefixIcon: Icon(Icons.nightlight_round),
                                suffixText: 'L',
                              ),

                              keyboardType: TextInputType.number,
                              validator: (value) => value!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ============================
                      // 📊 RESUMEN DEL TOTAL
                      // ============================

                      /// Contenedor que muestra el total calculado en tiempo real.
                      ///
                      /// Nota:
                      /// Este valor se recalcula cada vez que el widget se reconstruye (build).
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            const Text('Total del día:'),

                            /// Cálculo dinámico del total de litros
                            Text(
                              '${(double.tryParse(_litrosMananaController.text) ?? 0) + (double.tryParse(_litrosTardeController.text) ?? 0)} Litros',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ============================
              // 📝 TARJETA DE OBSERVACIONES
              // ============================

              /// Sección donde el usuario puede registrar información adicional,
              /// como cambios en alimentación, salud del ganado, etc.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// Encabezado de la sección
                      Row(
                        children: [
                          const Icon(Icons.note, color: AppTheme.primaryGreen),
                          const SizedBox(width: 12),
                          const Text(
                            'Observaciones',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const Divider(),

                      /// Campo de texto multilínea
                      TextFormField(
                        controller: _observacionesController,

                        decoration: const InputDecoration(
                          hintText: 'Ej: Cambio de alimento, condición sanitaria, etc.',
                          border: OutlineInputBorder(),
                        ),

                        /// Permite múltiples líneas de texto
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ============================
              // 💾 BOTÓN DE ACCIÓN
              // ============================

              /// Botón principal para guardar o actualizar el registro.
              ///
              /// Comportamiento:
              /// - Se desactiva mientras `_isLoading` es true
              /// - Muestra un loader durante la operación
              /// - Cambia el texto según el modo (guardar / editar)
              ElevatedButton(
                key: const Key('btn_guardar_registro'),
                onPressed: _isLoading ? null : _guardarRegistro,

                child: _isLoading

                /// Indicador de carga
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )

                /// Texto dinámico según estado
                    : Text(_editando ? 'Actualizar Registro' : 'Guardar Registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================
  // 🧹 LIMPIEZA DE RECURSOS
  // ============================

  /// Método que se ejecuta cuando el widget se destruye.
  ///
  /// Es fundamental liberar los controladores para evitar fugas de memoria.
  @override
  void dispose() {
    _litrosMananaController.dispose();
    _litrosTardeController.dispose();
    _observacionesController.dispose();

    super.dispose();
  }
}