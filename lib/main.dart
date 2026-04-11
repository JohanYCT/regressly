// Importa la librería principal de Flutter para construir interfaces visuales
import 'package:flutter/material.dart';

// Importa el archivo donde defines los estilos (colores, temas, etc.)
import 'package:regressly/app_theme.dart';

// Importa las diferentes pantallas de la aplicación
import 'package:regressly/screens/home_screen.dart';
import 'package:regressly/screens/registro_screen.dart';
import 'package:regressly/screens/configuracion_screen.dart';
import 'package:regressly/screens/graficas_screen.dart';

// Función principal del programa (punto de entrada de la app)
// Aquí es donde inicia toda la aplicación Flutter
void main() {
  // runApp ejecuta la aplicación y recibe el widget principal (MyApp)
  runApp(const MyApp());
}

// Clase principal de la aplicación
// StatelessWidget significa que este widget NO cambia su estado dinámicamente
class MyApp extends StatelessWidget {

  // Constructor de la clase (const mejora rendimiento)
  const MyApp({super.key});

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

      // Ruta inicial (pantalla que se abre al iniciar la app)
      initialRoute: '/',

      // Definición de rutas (navegación entre pantallas)
      routes: {

        // Pantalla principal (Home)
        '/': (context) => const HomeScreen(),

        // Pantalla de registro de producción (litros de leche)
        '/registro': (context) => const RegistroScreen(),

        // Pantalla de configuración (datos de la finca)
        '/configuracion': (context) => const ConfiguracionScreen(),

        // Pantalla de análisis y gráficas (regresión lineal)
        '/analisis': (context) => const GraficasScreen(),
      },
    );
  }
}