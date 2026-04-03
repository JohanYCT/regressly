import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/app_theme.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _litrosMananaController = TextEditingController();
  final _litrosTardeController = TextEditingController();
  final _observacionesController = TextEditingController();

  String _fechaSeleccionada = DateFormat('yyyy-MM-dd').format(DateTime.now());
  bool _isLoading = false;
  bool _editando = false;
  Map<String, dynamic>? _registroExistente;

  @override
  void initState() {
    super.initState();
    _verificarRegistroHoy();
  }

  Future<void> _verificarRegistroHoy() async {
    final existente = await DatabaseHelper.instance.getRegistroPorFecha(_fechaSeleccionada);
    if (existente != null) {
      setState(() {
        _editando = true;
        _registroExistente = existente;
        _litrosMananaController.text = (existente['litros_manana'] ?? 0).toString();
        _litrosTardeController.text = (existente['litros_tarde'] ?? 0).toString();
        _observacionesController.text = existente['observaciones'] ?? '';
      });
    }
  }

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
        _editando = false;
        _registroExistente = null;
        _litrosMananaController.clear();
        _litrosTardeController.clear();
        _observacionesController.clear();
      });
      _verificarRegistroHoy();
    }
  }

  Future<void> _guardarRegistro() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final double litrosManana = double.tryParse(_litrosMananaController.text) ?? 0;
      final double litrosTarde = double.tryParse(_litrosTardeController.text) ?? 0;
      final double litrosTotal = litrosManana + litrosTarde;

      final registroData = {
        'fecha': _fechaSeleccionada,
        'litros_manana': litrosManana,
        'litros_tarde': litrosTarde,
        'litros_total': litrosTotal,
        'observaciones': _observacionesController.text,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (_editando && _registroExistente != null) {
        registroData['id'] = _registroExistente!['id'];
        await DatabaseHelper.instance.updateRegistro(registroData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro actualizado exitosamente')),
          );
        }
      } else {
        await DatabaseHelper.instance.insertRegistro(registroData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro guardado exitosamente')),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });

      if (!_editando) {
        _litrosMananaController.clear();
        _litrosTardeController.clear();
        _observacionesController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Producción'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Tarjeta de fecha (como en Figura A2)
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

              // Tarjeta de producción (como en Figura A2)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _litrosMananaController,
                              decoration: const InputDecoration(
                                labelText: 'Litros Mañana',
                                prefixIcon: Icon(Icons.wb_sunny),
                                suffixText: 'L',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value!.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
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

              // Tarjeta de observaciones
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      TextFormField(
                        controller: _observacionesController,
                        decoration: const InputDecoration(
                          hintText: 'Ej: Cambio de alimento, condición sanitaria, etc.',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _guardarRegistro,
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text(_editando ? 'Actualizar Registro' : 'Guardar Registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _litrosMananaController.dispose();
    _litrosTardeController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}