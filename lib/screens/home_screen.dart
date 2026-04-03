import 'package:flutter/material.dart';
import 'package:regressly/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regressly'),
      ),
      body: Container(
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

            // LOGO - Imagen desde assets
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
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
                    // Si no encuentra la imagen, muestra el icono por defecto
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

            const Text(
              'Analítica Predictiva para tu\nProducción Lechera',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textLight,
              ),
            ),

            const SizedBox(height: 60),

            // Botones de navegación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildMenuCard(
                    context,
                    icon: Icons.edit_calendar,
                    title: 'Registro Diario',
                    subtitle: 'Registra la producción de leche',
                    color: AppTheme.primaryGreen,
                    route: '/registro',
                  ),
                  const SizedBox(height: 16),
                  _buildMenuCard(
                    context,
                    icon: Icons.show_chart,
                    title: 'Gráficas y Análisis',
                    subtitle: 'Visualiza tendencias y proyecciones',
                    color: AppTheme.lightGreen,
                    route: '/analisis',
                  ),
                  const SizedBox(height: 16),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}