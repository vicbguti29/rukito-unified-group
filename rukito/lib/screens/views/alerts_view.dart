import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/index.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alert_item.dart';

class AlertsView extends StatefulWidget {
  const AlertsView({Key? key}) : super(key: key);

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  String? _selectedFilterChamberId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AlertProvider>().loadAlerts();
    });
  }

  void _onFilterChanged(String? chamberId) {
    setState(() {
      _selectedFilterChamberId = chamberId;
    });
    
    final provider = context.read<AlertProvider>();
    if (chamberId == null) {
      provider.loadAlerts();
    } else {
      provider.loadChamberAlerts(chamberId);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color indigoColor = Color(0xFF1A237E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Título Principal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Centro de Alertas',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: indigoColor,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            // Botón de Acción con Color Índigo
            Consumer<AlertProvider>(
              builder: (context, alertProvider, _) {
                final bool hasUnread = alertProvider.unreadCount > 0;
                final Color inactiveColor = Colors.blueGrey.shade400;

                return TextButton.icon(
                  onPressed: hasUnread ? () => alertProvider.markAllAsRead() : null,
                  icon: Icon(Icons.done_all_rounded, 
                    color: hasUnread ? indigoColor : inactiveColor,
                    size: 20,
                  ),
                  label: Text(
                    'Marcar todo como leído',
                    style: TextStyle(
                      color: hasUnread ? indigoColor : inactiveColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: hasUnread ? indigoColor.withOpacity(0.08) : inactiveColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ],
        ),
        
        const SizedBox(height: 24),

        // 2. Panel de Control (Stats + Filtro)
        _buildControlPanel(indigoColor),

        const SizedBox(height: 24),

        // 3. Lista de Alertas
        Consumer<AlertProvider>(
          builder: (context, alertProvider, _) {
            if (alertProvider.isLoading) {
              return const SizedBox(
                height: 200, 
                child: Center(child: CircularProgressIndicator(strokeWidth: 2))
              );
            }

            if (alertProvider.error != null) {
              return _buildErrorState(alertProvider);
            }

            final alerts = alertProvider.sortedAlerts;

            if (alerts.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 40),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return AlertItemWidget(alert: alert);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildControlPanel(Color indigoColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fila de KPIs
          Consumer<AlertProvider>(
            builder: (context, provider, _) {
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Total Activas',
                      value: provider.totalAlerts.toString(),
                      icon: Icons.notifications_active_outlined,
                      color: indigoColor, 
                      isActive: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Sin Leer',
                      value: provider.unreadCount.toString(),
                      icon: Icons.mark_email_unread_outlined,
                      color: AppColors.critical,
                      isActive: provider.unreadCount > 0,
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Filtro por Cámara (Estilo Premium Morado)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: indigoColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded, color: indigoColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<ChamberProvider>(
                    builder: (context, chamberProvider, _) {
                      final chambers = chamberProvider.chambers;
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilterChamberId,
                          hint: Text('Filtrar por frigorífico', style: TextStyle(color: indigoColor.withOpacity(0.5), fontWeight: FontWeight.w600)),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: indigoColor),
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          style: TextStyle(color: indigoColor, fontWeight: FontWeight.bold),
                          onChanged: _onFilterChanged,
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('Todas las cámaras', style: TextStyle(color: indigoColor.withOpacity(0.7), fontWeight: FontWeight.w800)),
                            ),
                            ...chambers.map((c) => DropdownMenuItem(
                              value: c.id, 
                              child: Text(c.name),
                            )),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label, 
    required String value, 
    required IconData icon, 
    required Color color,
    bool isActive = false,
  }) {
    // Si no está activo, usamos gris
    final Color effectiveColor = isActive ? color : Colors.blueGrey.shade400;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? effectiveColor.withOpacity(0.3) : Colors.grey.shade200
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(0.1), // Burbuja de color claro
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: effectiveColor, size: 20), // Icono color sólido
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900, 
                  color: isActive ? effectiveColor : const Color(0xFF1E293B),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w700, 
                  color: Colors.grey.shade500
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.normal.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.normal,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sin alertas activas',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          Text(
            'Todo está funcionando correctamente',
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AlertProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical, size: 48),
          const SizedBox(height: 16),
          Text('Error al cargar alertas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(provider.error ?? '', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadAlerts(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
