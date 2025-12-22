import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TemperatureChart extends StatelessWidget {
  final List<double> temperatures;
  final double minTemp;
  final double maxTemp;
  final String title;

  const TemperatureChart({
    Key? key,
    required this.temperatures,
    required this.minTemp,
    required this.maxTemp,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (temperatures.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.veryLightGray,
        ),
        child: Center(
          child: Text(
            'Sin datos disponibles',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColors.veryLightGray,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: temperatures
                .map(
                  (temp) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: _getBarHeight(temp),
                      decoration: BoxDecoration(
                        color: _getBarColor(temp),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 4),
                      child: Tooltip(
                        message: '${temp.toStringAsFixed(1)}°C',
                        child: const SizedBox(),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  double _getBarHeight(double temperature) {
    const maxHeight = 180.0;
    final range = maxTemp - minTemp;
    if (range == 0) return maxHeight / 2;

    final normalized = ((temperature - minTemp) / range) * maxHeight;
    return normalized.clamp(5.0, maxHeight);
  }

  Color _getBarColor(double temperature) {
    // Asume que maxTemp es crítico, minTemp es normal
    final midPoint = minTemp + ((maxTemp - minTemp) / 2);

    if (temperature > maxTemp * 0.8) {
      return AppColors.critical;
    } else if (temperature > midPoint) {
      return AppColors.warning;
    } else {
      return AppColors.normal;
    }
  }
}
