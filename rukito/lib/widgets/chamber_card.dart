import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cold_chamber.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../screens/chamber_config_screen.dart';

class ChamberCard extends StatelessWidget {
  final ColdChamber chamber;

  const ChamberCard({
    Key? key,
    required this.chamber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine status color
    final statusColor = _statusColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // 1. Status Strip (Left Border)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(
              color: statusColor,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 20), // Left padding accounts for strip
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 2. Header Rediseñado (Sin solapamiento)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            chamber.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B), // Slate 800
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Settings Button alineado con el título
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChamberConfigScreen(
                                  chamberId: chamber.id,
                                  chamberName: chamber.name,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                            child: Icon(Icons.settings_outlined, size: 20, color: Colors.grey.shade400),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            chamber.content,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status Pill (Debajo del botón, alineada a la derecha)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(chamber.statusEmoji, style: const TextStyle(fontSize: 10)),
                              const SizedBox(width: 4),
                              Text(
                                chamber.statusText.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // 3. Big Temperature
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chamber.formattedTemperature.replaceAll('°C', ''),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6, left: 2),
                      child: Text(
                        '°C',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 4. Compact Details (Updated Labels)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC), // Slate 50
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(label: 'Temp. Objetivo', value: '${chamber.targetTemperature}°C'),
                      const SizedBox(height: 6),
                      _DetailRow(
                        label: 'Tasa de Cambio', 
                        value: chamber.formattedRateOfChange,
                        isBold: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Sparkline Chart (Tendencia Reciente)
                SizedBox(
                  height: 50,
                  child: chamber.recentTemperatures.length < 2 
                    ? Center(child: Text("Sin datos de tendencia", style: TextStyle(fontSize: 10, color: Colors.grey.shade400)))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minY: chamber.recentTemperatures.reduce((a, b) => a < b ? a : b) - 1,
                          maxY: chamber.recentTemperatures.reduce((a, b) => a > b ? a : b) + 1,
                          lineBarsData: [
                            LineChartBarData(
                              spots: chamber.recentTemperatures.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value);
                              }).toList(),
                              isCurved: true,
                              curveSmoothness: 0.3,
                              color: statusColor,
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                checkToShowDot: (spot, barData) {
                                  // Mostrar solo el último punto (el actual)
                                  return spot.x == chamber.recentTemperatures.length - 1;
                                },
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 3,
                                    color: statusColor,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    statusColor.withOpacity(0.2),
                                    statusColor.withOpacity(0.0),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(enabled: false), // Static display
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (chamber.status) {
      case ChamberStatus.criticalHot:
      case ChamberStatus.criticalCold:
        return AppColors.critical;
      case ChamberStatus.warningHot:
        return AppColors.warning;
      case ChamberStatus.normal:
        return AppColors.normal;
      case ChamberStatus.offline:
        return Colors.grey;
      default:
        return AppColors.normal;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11, 
            color: const Color(0xFF334155),
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}