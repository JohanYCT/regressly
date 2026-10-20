import 'package:flutter/material.dart';
import 'package:regressly/app_theme.dart';
import 'package:regressly/database/database_helper.dart';
import 'package:regressly/models/finca_model.dart';
import 'package:regressly/services/auth_service.dart';

/// Widget que dibuja el logotipo oficial 'G' de Google en vectores con sus 4 colores distintivos.
class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 22.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Arco Rojo (Superior)
    final Path redPath = Path()
      ..moveTo(w * 0.5, h * 0.19)
      ..cubicTo(w * 0.64, h * 0.19, w * 0.77, h * 0.24, w * 0.86, h * 0.32)
      ..lineTo(w * 0.98, h * 0.20)
      ..cubicTo(w * 0.86, h * 0.08, w * 0.70, 0, w * 0.5, 0)
      ..cubicTo(w * 0.30, 0, w * 0.13, h * 0.11, w * 0.05, h * 0.28)
      ..lineTo(w * 0.21, h * 0.40)
      ..cubicTo(w * 0.25, h * 0.28, w * 0.36, h * 0.19, w * 0.5, h * 0.19);
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));

    // Arco Amarillo (Izquierda)
    final Path yellowPath = Path()
      ..moveTo(w * 0.21, h * 0.40)
      ..cubicTo(w * 0.18, h * 0.46, w * 0.17, h * 0.53, w * 0.17, h * 0.60)
      ..cubicTo(w * 0.17, h * 0.67, w * 0.18, h * 0.74, w * 0.21, h * 0.80)
      ..lineTo(w * 0.05, h * 0.92)
      ..cubicTo(w * 0.02, h * 0.82, 0, h * 0.71, 0, h * 0.60)
      ..cubicTo(0, h * 0.49, w * 0.02, h * 0.38, w * 0.05, h * 0.28)
      ..lineTo(w * 0.21, h * 0.40);
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));

    // Arco Verde (Inferior)
    final Path greenPath = Path()
      ..moveTo(w * 0.5, h * 0.81)
      ..cubicTo(w * 0.36, h * 0.81, w * 0.25, h * 0.72, w * 0.21, h * 0.60)
      ..lineTo(w * 0.05, h * 0.72)
      ..cubicTo(w * 0.13, h * 0.89, w * 0.30, h * 1.0, w * 0.5, h * 1.0)
      ..cubicTo(w * 0.68, h * 1.0, w * 0.83, h * 0.94, w * 0.93, h * 0.84)
      ..lineTo(w * 0.77, h * 0.72)
      ..cubicTo(w * 0.70, h * 0.78, w * 0.61, h * 0.81, w * 0.5, h * 0.81);
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));

    // Arco y Barra Azul (Derecha)
    final Path bluePath = Path()
      ..moveTo(w * 0.98, h * 0.51)
      ..cubicTo(w * 1.0, h * 0.54, w * 1.0, h * 0.58, w * 1.0, h * 0.60)
      ..cubicTo(w * 1.0, h * 0.69, w * 0.97, h * 0.78, w * 0.93, h * 0.84)
      ..lineTo(w * 0.77, h * 0.72)
      ..cubicTo(w * 0.80, h * 0.68, w * 0.82, h * 0.63, w * 0.82, h * 0.58)
      ..cubicTo(w * 0.82, h * 0.55, w * 0.81, h * 0.52, w * 0.80, h * 0.50)
      ..lineTo(w * 0.5, h * 0.50)
      ..lineTo(w * 0.5, h * 0.35)
      ..lineTo(w * 0.98, h * 0.35)
      ..lineTo(w * 0.98, h * 0.51);
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pantalla de inicio de sesión de Regressly.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  /// Procesa el inicio de sesión con Google.
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    UserProfile? profile = await AuthService.instance.signInWithGoogle();

    if (!mounted) return;

    if (profile == null) {
      // Si la autenticación nativa no devolvió un usuario (p. ej. por falta de configuración de clave SHA-1),
      // solicitamos directamente el correo real y nombre mediante un diálogo para continuar.
      profile = await _mostrarDialogoCorreoReal();
    }

    if (!mounted) return;

    if (profile != null) {
      final fincaActual = await DatabaseHelper.instance.getFinca();
      if (fincaActual == null && profile.displayName.isNotEmpty) {
        await DatabaseHelper.instance.insertOrUpdateFinca(
          FincaModel(
            nombreProductor: profile.displayName,
            nombreFinca: '',
            ubicacion: '',
            numeroVacas: 0,
            precioLitro: 0,
          ),
        );
      } else if (fincaActual != null && fincaActual.nombreProductor.isEmpty && profile.displayName.isNotEmpty) {
        await DatabaseHelper.instance.insertOrUpdateFinca(
          FincaModel(
            id: fincaActual.id,
            nombreProductor: profile.displayName,
            nombreFinca: fincaActual.nombreFinca,
            ubicacion: fincaActual.ubicacion,
            numeroVacas: fincaActual.numeroVacas,
            precioLitro: fincaActual.precioLitro,
          ),
        );
      }

      final fincaDespues = await DatabaseHelper.instance.getFinca();
      final bool necesitaConfiguracion = fincaDespues == null ||
          fincaDespues.nombreFinca.trim().isEmpty ||
          fincaDespues.precioLitro <= 0;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${profile.displayName}!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );

      Navigator.pushReplacementNamed(context, '/');
      if (necesitaConfiguracion) {
        Navigator.pushNamed(context, '/configuracion');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Muestra un diálogo emergente para ingresar el correo real de Google y nombre.
  Future<UserProfile?> _mostrarDialogoCorreoReal() async {
    final nombreController = TextEditingController();
    final correoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<UserProfile>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              GoogleLogoWidget(size: 24),
              SizedBox(width: 10),
              Text(
                'Ingresar Cuenta Google',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ingresa tu correo real de Google y tu nombre para vincularlos a Regressly:',
                    style: TextStyle(fontSize: 13, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo de Google (@gmail.com)',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu correo';
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Ingresa un correo electrónico válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                minimumSize: const Size(100, 42),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final profile = await AuthService.instance.signInWithCustomProfile(
                    displayName: nombreController.text.trim(),
                    email: correoController.text.trim(),
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(profile);
                  }
                }
              },
              child: const Text('Ingresar'),
            ),
          ],
        );
      },
    );
  }

  /// Procesa el ingreso como invitado.
  Future<void> _handleGuestSignIn() async {
    setState(() {
      _isLoading = true;
    });

    await AuthService.instance.setGuestMode();

    final fincaActual = await DatabaseHelper.instance.getFinca();
    if (fincaActual == null) {
      await DatabaseHelper.instance.insertOrUpdateFinca(
        FincaModel(
          nombreProductor: 'Productor Invitado',
          nombreFinca: '',
          ubicacion: '',
          numeroVacas: 0,
          precioLitro: 0,
        ),
      );
    }

    final fincaDespues = await DatabaseHelper.instance.getFinca();
    final bool necesitaConfiguracion = fincaDespues == null ||
        fincaDespues.nombreFinca.trim().isEmpty ||
        fincaDespues.precioLitro <= 0;

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/');
    if (necesitaConfiguracion) {
      Navigator.pushNamed(context, '/configuracion');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundGrey, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // LOGO PRINCIPAL
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.agriculture,
                          size: 60,
                          color: AppTheme.primaryGreen,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Regressly',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Analítica Predictiva para tu\nProducción Lechera',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textLight,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 36),

                // TARJETA DE BENEFICIOS
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFeatureItem(Icons.edit_calendar, 'Registro\nDiario'),
                        _buildFeatureItem(Icons.show_chart, 'Análisis\nPredictivo'),
                        _buildFeatureItem(Icons.wifi_off, 'Funciona\nOffline'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // TARJETA DE INICIO DE SESIÓN
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Inicia sesión para vincular tu productor o continúa sin conexión.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // BOTÓN GOOGLE
                        OutlinedButton(
                          key: const Key('btn_google_login'),
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryGreen,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GoogleLogoWidget(size: 22),
                                    SizedBox(width: 12),
                                    Text(
                                      'Iniciar sesión con Google',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'o',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // BOTÓN INVITADO
                        ElevatedButton.icon(
                          key: const Key('btn_guest_login'),
                          onPressed: _isLoading ? null : _handleGuestSignIn,
                          icon: const Icon(Icons.person_outline, size: 20),
                          label: const Text(
                            'Continuar como invitado (Offline)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
