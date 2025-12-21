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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AlertProvider>().loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de Alertas',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 4),
                Consumer<AlertProvider>(
                  builder: (context, alertProvider, _) {
                    return Text(
                      '${alertProvider.totalAlerts} total • ${alertProvider.unreadCount} sin leer',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  },
                ),
              ],
            ),
            Consumer<AlertProvider>(
              builder: (context, alertProvider, _) {
                return ElevatedButton.icon(
                  onPressed: alertProvider.unreadCount > 0
                      ? () => alertProvider.markAllAsRead()
                      : null,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Marcar todas como leídas'),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Contenido
        Consumer<AlertProvider>(
          builder: (context, alertProvider, _) {
            if (alertProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (alertProvider.error != null) {
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
                      'Error al cargar alertas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alertProvider.error ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        alertProvider.loadAlerts();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final alerts = alertProvider.sortedAlerts;

            if (alerts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.normal,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sin alertas activas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Todo está funcionando correctamente',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
}
