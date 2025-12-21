import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/index.dart';
import '../../providers/index.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chamber_card.dart';
import '../../widgets/stats_card.dart';
import '../../widgets/temperature_chart.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    // Cargar cámaras al entrar a la vista
    Future.microtask(() {
      context.read<ChamberProvider>().loadChambers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          'Dashboard',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 24),

        // Contenido principal
        Consumer<ChamberProvider>(
          builder: (context, chamberProvider, _) {
            if (chamberProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (chamberProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.critical,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar datos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chamberProvider.error ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        chamberProvider.loadChambers();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final chambers = chamberProvider.chambers;

            if (chambers.isEmpty) {
              return Center(
                child: Text(
                  'No hay cámaras disponibles',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid de cámaras
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
                    return ChamberCard(chamber: chamber);
                  },
                ),
                const SizedBox(height: 40),

                // Estadísticas
                Text(
                  'Estadísticas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    StatsCard(
                      label: 'Cámaras Operativas',
                      value: '${chamberProvider.activeChamberCount}',
                      subtitle:
                          'de ${chambers.length} en operación',
                      color: AppColors.normal,
                    ),
                    StatsCard(
                      label: 'Promedio de Temperatura',
                      value:
                          '${chamberProvider.averageTemperature.toStringAsFixed(1)}°C',
                      subtitle: 'Todas las cámaras',
                      color: chamberProvider.averageTemperature > -15
                          ? AppColors.warning
                          : AppColors.normal,
                    ),
                    StatsCard(
                      label: 'Alertas Activas',
                      value: '${context.watch<AlertProvider>().unreadCount}',
                      subtitle: 'Requieren atención',
                      color: context.watch<AlertProvider>().unreadCount > 0
                          ? AppColors.critical
                          : AppColors.normal,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
