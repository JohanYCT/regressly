import 'package:flutter/material.dart';

class FinancieroScreen extends StatefulWidget {
  const FinancieroScreen({super.key});

  @override
  State<FinancieroScreen> createState() => _FinancieroScreenState();
}

class _FinancieroScreenState extends State<FinancieroScreen> {
  /// Indica si se están cargando los datos iniciales
  final bool _isLoading = false;

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
        title: const Text('Estimación Financiera'),
        backgroundColor: Colors.green,
      ),
    );
  }
}






