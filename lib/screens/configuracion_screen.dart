import 'package:flutter/material.dart';
import 'package:regressly/app_theme.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/models/finca_model.dart';
import 'package:regressly/services/auth_service.dart';

/// Pantalla encargada de gestionar la configuración de la finca y la cuenta del usuario.
///
/// Permite al usuario:
/// - Ver su estado de sesión / perfil de Google
/// - Registrar información del productor y datos de la finca
/// - Guardar configuración en la base de datos local
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

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

  bool _isLoading = true;
  bool _isSaving = false;

  /// Datos de la sesión actual
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  // ============================
  // 📥 CARGAR CONFIGURACIÓN Y SESIÓN
  // ============================

  Future<void> _cargarConfiguracion() async {
    final profile = await AuthService.instance.getUserProfile();

    final finca = await DatabaseHelper.instance.getFinca();

    if (finca != null) {
      _nombreProductorController.text = finca.nombreProductor;
      _nombreFincaController.text = finca.nombreFinca;
      _ubicacionController.text = finca.ubicacion;
      _numeroVacasController.text = finca.numeroVacas.toString();
      _precioLitroController.text = finca.precioLitro.toString();
    }

    // Si el campo de nombre del productor está vacío pero hay un perfil de Google, lo autocompletamos
    if (_nombreProductorController.text.isEmpty && profile != null) {
      _nombreProductorController.text = profile.displayName;
    }

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  // ============================
  // 💾 GUARDAR CONFIGURACIÓN
  // ============================

  Future<void> _guardarConfiguracion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final finca = FincaModel(
        nombreProductor: _nombreProductorController.text,
        nombreFinca: _nombreFincaController.text,
        ubicacion: _ubicacionController.text,
        numeroVacas: int.parse(_numeroVacasController.text),
        precioLitro: double.parse(_precioLitroController.text),
      );

      await DatabaseHelper.instance.insertOrUpdateFinca(finca);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada exitosamente'),
        ),
      );

      // Si se ingresó a Configuración tras iniciar sesión, regresa suavemente al Home tras guardar
      if (Navigator.canPop(context)) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  // ============================
  // 🚪 GESTIÓN DE SESIÓN
  // ============================

  Future<void> _cerrarSesion() async {
    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _vincularGoogle() async {
    final profile = await AuthService.instance.signInWithGoogle();
    if (mounted && profile != null) {
      if (_nombreProductorController.text.isEmpty) {
        _nombreProductorController.text = profile.displayName;
      }
      setState(() {
        _userProfile = profile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cuenta vinculada exitosamente: ${profile.email}'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  // ============================
  // 🧱 UI PRINCIPAL
  // ============================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Finca'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ============================
              // 👤 TARJETA DE CUENTA DE USUARIO
              // ============================
              Card(
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
                        'Cuenta de Usuario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_userProfile != null) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                              backgroundImage: _userProfile!.photoUrl != null
                                  ? NetworkImage(_userProfile!.photoUrl!)
                                  : null,
                              child: _userProfile!.photoUrl == null
                                  ? const Icon(Icons.person, color: AppTheme.primaryGreen)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userProfile!.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    _userProfile!.email,
                                    style: const TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const Key('btn_cerrar_sesion'),
                          onPressed: _cerrarSesion,
                          icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                          label: const Text(
                            'Cerrar Sesión',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade200,
                              child: const Icon(Icons.person_outline, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Modo Invitado (Offline)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Sin cuenta vinculada',
                                    style: TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          key: const Key('btn_vincular_google'),
                          onPressed: _vincularGoogle,
                          icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                          label: const Text('Vincular Cuenta de Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            minimumSize: const Size(double.infinity, 42),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ============================
              // 🧾 TARJETA DE INFORMACIÓN DE FINCA
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
                      const Text(
                        'Información del Productor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

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

                      TextFormField(
                        controller: _numeroVacasController,
                        decoration: InputDecoration(
                          labelText: 'Número de Vacas',
                          border: const OutlineInputBorder(),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/images/icon_vaca.png',
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Campo requerido';
                          if (int.tryParse(value) == null) return 'Número válido';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _precioLitroController,
                        decoration: const InputDecoration(
                          labelText: 'Precio por Litro (COP)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
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
                  backgroundColor: AppTheme.primaryGreen,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar Configuración',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

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
