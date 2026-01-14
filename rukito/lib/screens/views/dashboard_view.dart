import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/index.dart';
import '../../providers/index.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chamber_card.dart';
// import '../../widgets/stats_card.dart'; // Replaced by custom enhanced card

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ChamberProvider>().loadChambers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título Principal
          Text(
            'Resumen General',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: const Color(0xFF1A237E),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
      
          Consumer<ChamberProvider>(
            builder: (context, chamberProvider, _) {
              if (chamberProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
      
              if (chamberProvider.error != null) {
                return _buildErrorView(chamberProvider);
              }
      
              final chambers = chamberProvider.chambers;
      
              if (chambers.isEmpty) {
                return const Center(child: Text('No hay cámaras disponibles'));
              }
      
              // Data for stats
              final activeCount = chamberProvider.activeChamberCount;
              final avgTemp = chamberProvider.averageTemperature;
              final alertsCount = context.watch<AlertProvider>().unreadCount;
      
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SECCIÓN DE ESTADÍSTICAS (Ahora Arriba)
                  _buildSectionTitle('Estadísticas del Sistema', Icons.analytics_outlined),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.5, // Más apaisado
                    children: [
                      _buildDashboardKpi(
                        label: 'Cámaras Activas',
                        value: '$activeCount',
                        subtitle: 'de ${chambers.length} operativas',
                        color: AppColors.normal,
                        icon: Icons.ac_unit,
                      ),
                      _buildDashboardKpi(
                        label: 'Temp. Promedio',
                        value: '${avgTemp.toStringAsFixed(1)}°C',
                        subtitle: 'Global',
                        color: avgTemp > -5 ? AppColors.warning : AppColors.info, // Warning if too hot
                        icon: Icons.thermostat,
                      ),
                      _buildDashboardKpi(
                        label: 'Alertas Activas',
                        value: '$alertsCount',
                        subtitle: 'Requieren atención',
                        color: alertsCount > 0 ? AppColors.critical : AppColors.normal,
                        icon: Icons.notifications_active,
                      ),
                    ],
                  ),
      
                  const SizedBox(height: 40),
      
                  // 2. SECCIÓN DE FRIGORÍFICOS (Ahora Abajo)
                  _buildSectionTitle(
                    'Monitoreo de Frigoríficos', 
                    Icons.kitchen,
                    infoTooltip: 'Guía de Lectura:\n\n'
                        '• Gráfico (Curva Sólida): Tendencia real de las últimas lecturas.\n'
                        '• Línea Punteada Verde: Temperatura Objetivo ideal.\n\n'
                        'Colores de Estado:\n'
                        '🟢 Verde: Operación Normal\n'
                        '🟠 Naranja: Advertencia (Precaución)\n'
                        '🔴 Rojo: Peligro (Calor o Frío Extremo)'
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: chambers.length,
                    itemBuilder: (context, index) {
                      final chamber = chambers[index];
                      // PRESERVADO: El widget ChamberCard se mantiene intacto
                      return ChamberCard(chamber: chamber);
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {String? infoTooltip}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1A237E), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.w800, 
            color: Color(0xFF1A237E),
            letterSpacing: 0.5,
          ),
        ),
        if (infoTooltip != null) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: infoTooltip,
            triggerMode: TooltipTriggerMode.tap,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(16),
            showDuration: const Duration(seconds: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Slate 800
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            child: Icon(Icons.info_outline_rounded, size: 22, color: Colors.blueGrey.shade300),
          ),
        ],
      ],
    );
  }

  Widget _buildDashboardKpi({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2), // Clean border
      ),
      child: Stack(
        children: [
          // Icono de fondo gigante y sutil
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              icon,
              size: 100,
              color: color.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569), // Slate 600
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ChamberProvider provider) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.critical, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error de Conexión',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'No se pudieron cargar los datos.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadChambers(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar Conexión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

