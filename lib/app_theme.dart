import 'package:flutter/material.dart';

/// Clase encargada de definir la configuración visual global de la aplicación.
///
/// Aquí se centralizan todos los colores, estilos y temas utilizados en la app,
/// lo que permite mantener consistencia en la interfaz y facilitar cambios futuros.
///
/// Esta clase implementa un tema claro (`lightTheme`) basado en Material 3.
class AppTheme {

  // ============================
  // 🎨 PALETA DE COLORES
  // ============================

  /// Color principal de la aplicación (verde oscuro).
  /// Usado en AppBar, botones principales, etc.
  static const Color primaryGreen = Color(0xFF2E7D32);

  /// Variante más clara del color principal.
  /// Usado como color secundario en algunos componentes.
  static const Color lightGreen = Color(0xFF4CAF50);

  /// Color de acento para detalles visuales.
  static const Color accentGreen = Color(0xFF81C784);

  /// Color de fondo general de las pantallas.
  static const Color backgroundGrey = Color(0xFFF5F5F5);

  /// Color blanco estándar.
  static const Color white = Color(0xFFFFFFFF);

  /// Color para textos principales (oscuros).
  static const Color textDark = Color(0xFF333333);

  /// Color para textos secundarios (grises).
  static const Color textLight = Color(0xFF757575);

  // ============================
  // 🌗 TEMA CLARO DE LA APP
  // ============================

  /// Método que retorna la configuración completa del tema claro de la aplicación.
  ///
  /// Este tema define:
  /// - Colores principales
  /// - Estilo de AppBar
  /// - Tarjetas (Card)
  /// - Botones
  /// - Campos de entrada (TextField)
  ///
  /// Se utiliza normalmente en el `MaterialApp`:
  /// ```dart
  /// theme: AppTheme.lightTheme(),
  /// ```
  static ThemeData lightTheme() {
    return ThemeData(

      /// Activa el diseño basado en Material Design 3
      useMaterial3: true,

      /// Define que el tema es claro
      brightness: Brightness.light,

      /// Color principal de la aplicación
      primaryColor: primaryGreen,

      /// Color de fondo de todas las pantallas (Scaffold)
      scaffoldBackgroundColor: backgroundGrey,

      /// Esquema de colores general de la app
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: lightGreen,
        surface: white,
      ),

      // ============================
      // 📌 APP BAR
      // ============================

      /// Configuración global de la barra superior (AppBar)
      appBarTheme: const AppBarTheme(
        elevation: 0, // Sin sombra
        centerTitle: true, // Centra el título
        backgroundColor: primaryGreen, // Fondo verde
        foregroundColor: white, // Color del texto e íconos

        /// Estilo del texto del título
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),

      // ============================
      // 🃏 TARJETAS (CARDS)
      // ============================

      /// Estilo global para widgets tipo Card
      cardTheme: CardThemeData(
        elevation: 2, // Sombra ligera
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Bordes redondeados
        ),
        color: white,
      ),

      // ============================
      // 🔘 BOTONES ELEVADOS
      // ============================

      /// Configuración global de botones ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(

          /// Color de fondo del botón
          backgroundColor: primaryGreen,

          /// Color del texto del botón
          foregroundColor: white,

          /// Tamaño mínimo (ancho completo, altura 48)
          minimumSize: const Size(double.infinity, 48),

          /// Forma del botón (bordes redondeados)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),

          /// Estilo del texto del botón
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ============================
      // 📝 INPUTS (TEXTFIELDS)
      // ============================

      /// Configuración global de los campos de entrada
      inputDecorationTheme: InputDecorationTheme(

        /// Hace que el campo tenga fondo
        filled: true,

        /// Color de fondo del input
        fillColor: white,

        /// Borde por defecto (sin borde visible)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        /// Borde cuando el campo está habilitado
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        /// Borde cuando el campo está enfocado
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),

        /// Espaciado interno del campo
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}