import 'package:flutter/material.dart';
import 'package:regressly/app_theme.dart';

/// Pantalla principal (Home) de la aplicación Regressly.
///
/// Esta pantalla actúa como el punto de entrada visual para el usuario,
/// permitiendo la navegación hacia los módulos principales del sistema:
/// - Registro diario de producción
/// - Análisis y gráficas
/// - Configuración de la finca
///
/// Incluye:
/// - Logo de la aplicación
/// - Descripción breve del propósito
/// - Menú de navegación mediante tarjetas interactivas
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // ============================
      // 📌 APP BAR
      // ============================

      /// Barra superior con el nombre de la aplicación
      appBar: AppBar(
        title: const Text('Regressly'),
      ),

      // ============================
      // 🧱 CUERPO PRINCIPAL
      // ============================

      body: Container(

        /// Fondo con degradado vertical (de gris claro a blanco)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundGrey, Colors.white],
          ),
        ),

        child: Column(
          children: [

            const SizedBox(height: 50),

            // ============================
            // 🖼️ LOGO DE LA APLICACIÓN
            // ============================

            /// Contenedor circular que muestra el logo desde assets.
            ///
            /// Incluye:
            /// - Sombra para efecto visual
            /// - Manejo de error si la imagen no existe
            Container(
              width: 140,
              height: 140,

              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,

                /// Sombra del contenedor
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),

              /// Recorta la imagen en forma circular
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',

                  /// Ajuste de la imagen dentro del contenedor
                  fit: BoxFit.cover,

                  /// Manejo de error si no se encuentra la imagen
                  errorBuilder: (context, error, stackTrace) {

                    /// Muestra un ícono por defecto en caso de fallo
                    return Container(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      child: const Icon(
                        Icons.agriculture,
                        size: 60,
                        color: AppTheme.primaryGreen,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 8),

            // ============================
            // 📝 DESCRIPCIÓN DE LA APP
            // ============================

            /// Texto descriptivo del propósito de la aplicación
            const Text(
              'Analítica Predictiva para tu\nProducción Lechera',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textLight,
              ),
            ),

            const SizedBox(height: 60),

            // ============================
            // 📋 MENÚ DE NAVEGACIÓN
            // ============================

            /// Contenedor con las tarjetas de navegación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),

              child: Column(
                children: [

                  // ============================
                  // 📅 OPCIÓN: REGISTRO DIARIO
                  // ============================

                  _buildMenuCard(
                    context,
                    icon: Icons.edit_calendar,
                    title: 'Registro Diario',
                    subtitle: 'Registra la producción de leche',
                    color: AppTheme.primaryGreen,
                    route: '/registro',
                  ),

                  const SizedBox(height: 16),

                  // ============================
                  // 📊 OPCIÓN: ANÁLISIS
                  // ============================

                  _buildMenuCard(
                    context,
                    icon: Icons.show_chart,
                    title: 'Gráficas y Análisis',
                    subtitle: 'Visualiza tendencias y proyecciones',
                    color: AppTheme.lightGreen,
                    route: '/analisis',
                  ),

                  const SizedBox(height: 16),

                  // ============================
                  // ⚙️ OPCIÓN: CONFIGURACIÓN
                  // ============================

                  _buildMenuCard(
                    context,
                    icon: Icons.settings,
                    title: 'Configuración',
                    subtitle: 'Configura tu finca',
                    color: AppTheme.textLight,
                    route: '/configuracion',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // 🧩 COMPONENTE REUTILIZABLE
  // ============================

  /// Widget reutilizable para construir las tarjetas del menú principal.
  ///
  /// Parámetros:
  /// - [icon]: Ícono representativo de la opción
  /// - [title]: Título principal
  /// - [subtitle]: Descripción breve
  /// - [color]: Color temático de la opción
  /// - [route]: Ruta de navegación
  ///
  /// Comportamiento:
  /// - Al hacer tap navega a la ruta definida usando Navigator
  Widget _buildMenuCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required String route,
      }) {

    return Card(
      elevation: 2,

      /// Bordes redondeados
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      /// InkWell permite efecto visual al hacer tap
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),

        borderRadius: BorderRadius.circular(16),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Row(
            children: [

              // ============================
              // 🎯 ICONO DE LA OPCIÓN
              // ============================

              Container(
                padding: const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(icon, color: color, size: 28),
              ),

              const SizedBox(width: 16),

              // ============================
              // 📝 TEXTO DE LA OPCIÓN
              // ============================

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// Título principal
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// Subtítulo descriptivo
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),

              // ============================
              // ➡️ ICONO DE NAVEGACIÓN
              // ============================

              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16,),
            ],
          ),
        ),
      ),
    );
  }
}