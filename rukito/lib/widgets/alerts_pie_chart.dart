import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AlertsPieChart extends StatelessWidget {
  final int critical;
  final int warning;
  final int info;

  const AlertsPieChart({
    Key? key,
    required this.critical,
    required this.warning,
    required this.info,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = critical + warning + info;
    if (total == 0) return const SizedBox();

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        height: 250, // Altura fija para el gráfico
        child: Row(
          children: [
            // El Gráfico
            Expanded(
              flex: 3,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    if (critical > 0)
                      PieChartSectionData(
                        color: AppColors.critical,
                        value: critical.toDouble(),
                        title: '${((critical / total) * 100).toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (warning > 0)
                      PieChartSectionData(
                        color: AppColors.warning,
                        value: warning.toDouble(),
                        title: '${((warning / total) * 100).toStringAsFixed(0)}%',
                        radius: 45, // Un poco más pequeño para efecto visual
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (info > 0)
                      PieChartSectionData(
                        color: AppColors.info,
                        value: info.toDouble(),
                        title: '${((info / total) * 100).toStringAsFixed(0)}%',
                        radius: 40,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // La Leyenda
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribución de Alertas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _LegendItem(
                    color: AppColors.critical,
                    label: 'Críticas ($critical)',
                  ),
                  const SizedBox(height: 8),
                  _LegendItem(
                    color: AppColors.warning,
                    label: 'Advertencias ($warning)',
                  ),
                  const SizedBox(height: 8),
                  _LegendItem(
                    color: AppColors.info,
                    label: 'Informativas ($info)',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
