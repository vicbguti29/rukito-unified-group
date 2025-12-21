import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cold_chamber.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class ChamberCard extends StatelessWidget {
  final ColdChamber chamber;

  const ChamberCard({
    Key? key,
    required this.chamber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _borderColor,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chamber.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chamber.content,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chamber.statusEmoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chamber.statusText,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Temperatura prominente
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                chamber.formattedTemperature,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _temperatureColor,
                ),
              ),
            ),

            // Detalles
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Objetivo',
                    value: '${chamber.targetTemperature.toStringAsFixed(1)}°C',
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Diferencia',
                    value: '${chamber.temperatureDifference > 0 ? '+' : ''}${chamber.temperatureDifference.toStringAsFixed(1)}°C',
                    valueColor: _temperatureColor,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Tasa de Cambio',
                    value: chamber.formattedRateOfChange,
                    valueColor: _temperatureColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Timestamp
            Text(
              'Última actualización: ${chamber.formattedLastUpdate}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 12),

            // Mini gráfico de barras
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: chamber.recentTemperatures
                    .map(
                      (temp) => Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: _getChartBarHeight(temp),
                          decoration: BoxDecoration(
                            color: _getChartBarColor(temp),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _borderColor {
    if (chamber.currentTemperature > chamber.criticalThreshold) {
      return AppColors.critical;
    } else if (chamber.currentTemperature > chamber.warningThreshold) {
      return AppColors.warning;
    } else {
      return AppColors.normal;
    }
  }

  Color get _backgroundColor {
    if (chamber.currentTemperature > chamber.criticalThreshold) {
      return AppColors.criticalBackground;
    } else if (chamber.currentTemperature > chamber.warningThreshold) {
      return AppColors.warningBackground;
    } else {
      return AppColors.white;
    }
  }

  Color get _temperatureColor {
    if (chamber.currentTemperature > chamber.criticalThreshold) {
      return AppColors.critical;
    } else if (chamber.currentTemperature > chamber.warningThreshold) {
      return AppColors.warning;
    } else {
      return AppColors.normal;
    }
  }

  Color get _statusColor {
    if (chamber.currentTemperature > chamber.criticalThreshold) {
      return AppColors.critical;
    } else if (chamber.currentTemperature > chamber.warningThreshold) {
      return AppColors.warning;
    } else {
      return AppColors.normal;
    }
  }

  double _getChartBarHeight(double temperature) {
    // Normaliza altura basada en rango de temperatura
    const minTemp = -25.0;
    const maxTemp = 10.0;
    const maxHeight = 50.0;

    final normalized = ((temperature - minTemp) / (maxTemp - minTemp)) * maxHeight;
    return normalized.clamp(5.0, maxHeight);
  }

  Color _getChartBarColor(double temperature) {
    if (temperature > chamber.criticalThreshold) {
      return AppColors.critical;
    } else if (temperature > chamber.warningThreshold) {
      return AppColors.warning;
    } else {
      return AppColors.normal;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.darkGray,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
