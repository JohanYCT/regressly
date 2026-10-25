import 'package:flutter/material.dart';
import 'package:regressly/app_theme.dart';
import 'package:regressly/services/auth_service.dart';

/// Pantalla principal (Home) de la aplicación Regressly.
///
/// Esta pantalla actúa como el punto de entrada visual para el usuario,
/// permitiendo la navegación hacia los módulos principales del sistema:
/// - Registro diario de producción
/// - Análisis y gráficas
/// - Configuración de la finca
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await AuthService.instance.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ============================
      // 📌 APP BAR
      // ============================
      appBar: AppBar(
        title: const Text('Regressly'),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              backgroundImage: _userProfile?.photoUrl != null
                  ? NetworkImage(_userProfile!.photoUrl!)
                  : null,
              child: _userProfile?.photoUrl == null
                  ? const Icon(Icons.person, size: 18, color: AppTheme.primaryGreen)
                  : null,
            ),
            tooltip: _userProfile != null ? _userProfile!.displayName : 'Modo Invitado',
            onPressed: () {
              Navigator.pushNamed(context, '/configuracion').then((_) => _loadUserProfile());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ============================
      // 🧱 CUERPO PRINCIPAL
      // ============================
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.backgroundGrey, Colors.white],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // Saludo personalizado si el usuario inició sesión
              if (_userProfile != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_circle, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Hola, ${_userProfile!.displayName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ============================
              // 🖼️ LOGO DE LA APLICACIÓN
              // ============================
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
                      return Container(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
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

              const SizedBox(height: 20),

              // ============================
              // 📝 DESCRIPCIÓN DE LA APP
              // ============================
              const Text(
                'Analítica Predictiva para tu\nProducción Lechera',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textLight,
                ),
              ),

              const SizedBox(height: 40),

              // ============================
              // 📋 MENÚ DE NAVEGACIÓN
              // ============================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildMenuCard(
                      context,
                      key: const Key('nav_registro'),
                      icon: Icons.edit_calendar,
                      title: 'Registro Diario',
                      subtitle: 'Registra la producción de leche',
                      color: AppTheme.textLight,
                      route: '/registro',
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      context,
                      key: const Key('nav_analisis'),
                      icon: Icons.show_chart,
                      title: 'Gráficas y Análisis',
                      subtitle: 'Visualiza tendencias y proyecciones',
                      color: AppTheme.lightGreen,
                      route: '/analisis',
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      context,
                      key: const Key('nav_configuracion'),
                      icon: Icons.settings,
                      title: 'Configuración',
                      subtitle: 'Configura tu finca y cuenta',
                      color: AppTheme.textLight,
                      route: '/configuracion',
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      context,
                      key: const Key('nav_estimaciones'),
                      icon: Icons.attach_money,
                      title: 'Estimaciones Financieras',
                      subtitle: 'Visualiza ingresos y proyecciones financieras',
                      color: AppTheme.lightGreen,
                      route: '/calculo',
                    ),
                    const SizedBox(height: 16),
                    _buildMenuCard(
                      context,
                      key: const Key('nav_historial'),
                      icon: Icons.history_edu,
                      title: 'Historial y Reporte PDF',
                      subtitle: 'Consulta el historial y exporta reportes PDF',
                      color: AppTheme.primaryGreen,
                      route: '/historial',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
  }) {
    return Card(
      key: key,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.pushNamed(context, route);
          _loadUserProfile();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textLight,
                      ),
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
