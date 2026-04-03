import 'package:flutter/material.dart';
import 'package:regressly/app_theme.dart';
import 'package:regressly/screens/home_screen.dart';
import 'package:regressly/screens/registro_screen.dart';
import 'package:regressly/screens/configuracion_screen.dart';
import 'package:regressly/screens/graficas_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Regressly',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/configuracion': (context) => const ConfiguracionScreen(),
        '/analisis': (context) => const GraficasScreen(),
      },
    );
  }
}