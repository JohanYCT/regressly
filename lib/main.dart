import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/date_symbol_data_local.dart';

// Importa el archivo donde defines los estilos (colores, temas, etc.)
import 'package:regressly/app_theme.dart';
import 'package:regressly/screens/financiero_screen.dart';

// Importa las diferentes pantallas de la aplicación
import 'package:regressly/screens/home_screen.dart';
import 'package:regressly/screens/registro_screen.dart';
import 'package:regressly/screens/configuracion_screen.dart';
import 'package:regressly/screens/graficas_screen.dart';
import 'package:regressly/screens/historial_screen.dart';
import 'package:regressly/screens/login_screen.dart';

// Importa el servicio de autenticación
import 'package:regressly/services/auth_service.dart';

// Función principal del programa (punto de entrada de la app)
// Aquí es donde inicia toda la aplicación Flutter
void main() async {
  // Asegura la inicialización previa de los bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar formato de fechas en español
    await initializeDateFormatting('es_ES', null);
  } catch (e) {
    debugPrint('Error al inicializar date formatting: $e');
  }

  try {
    // Inicializar Firebase
    await Firebase.initializeApp();

    // Inicializar Firebase App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  } catch (e) {
    debugPrint('Error al inicializar Firebase/App Check: $e');
  }

  bool hasSession = false;
  try {
    // Verifica si el usuario ya tiene sesión activa o seleccionó modo invitado previamente
    hasSession = await AuthService.instance.hasSession();
  } catch (e) {
    debugPrint('Error al verificar sesión inicial: $e');
  }

  // runApp ejecuta la aplicación y recibe el widget principal (MyApp)
  runApp(MyApp(hasSession: hasSession));
}

// Clase principal de la aplicación
class MyApp extends StatelessWidget {
  final bool hasSession;

  // Constructor de la clase
  const MyApp({super.key, this.hasSession = false});

  // Método build: construye toda la interfaz visual de la app
  @override
  Widget build(BuildContext context) {

    // MaterialApp es el contenedor principal de toda la aplicación
    return MaterialApp(

      // Título de la aplicación (puede aparecer en el sistema)
      title: 'Regressly',

      // Tema visual de la aplicación (colores, estilos)
      theme: AppTheme.lightTheme(),

      // Oculta la etiqueta de "DEBUG" en la esquina de la app
      debugShowCheckedModeBanner: false,

      // Ruta inicial (si ya tiene sesión va a Home, de lo contrario va a Login)
      initialRoute: hasSession ? '/' : '/login',

      // Definición de rutas (navegación entre pantallas)
      routes: {

        // Pantalla de inicio de sesión
        '/login': (context) => const LoginScreen(),

        // Pantalla principal (Home)
        '/': (context) => const HomeScreen(),

        // Pantalla de registro de producción (litros de leche)
        '/registro': (context) => const RegistroScreen(),

        // Pantalla de configuración (datos de la finca)
        '/configuracion': (context) => const ConfiguracionScreen(),

        // Pantalla de análisis y gráficas (regresión lineal)
        '/analisis': (context) => const GraficasScreen(),

        // Pantalla de estimaciones financieras $
        '/calculo': (context) => const FinancieroScreen(),

        // Pantalla de historial de producción y reporte PDF
        '/historial': (context) => const HistorialScreen(),
      },
    );
  }
}
