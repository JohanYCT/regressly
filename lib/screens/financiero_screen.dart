import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/app_theme.dart';

class FinancieroScreen extends StatefulWidget {
  const FinancieroScreen({super.key});

  @override
  State<FinancieroScreen> createState() => _FinancieroScreenState();
}

class _FinancieroScreenState extends State<FinancieroScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Indica si se están cargando los datos iniciales
  bool _isLoading = false;

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






