import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cold_chamber.dart';
import '../../models/temperature_reading.dart';
import '../../providers/index.dart';
import '../../services/index.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stats_card.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({Key? key}) : super(key: key);

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _selectedChamberId;
  
  Map<String, dynamic>? _reportData;
  List<TemperatureReading> _history = [];
  ColdChamber? _selectedChamber; 
  
  bool _isLoading = false;
  DateFormat? _dateFormat;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 7));

    _initializeLocaleAndLoadData();
  }

  Future<void> _initializeLocaleAndLoadData() async {
    await initializeDateFormatting('es', null);
    
    if (mounted) {
      setState(() {
        _dateFormat = DateFormat('dd MMM', 'es');
      });

      final chambers = context.read<ChamberProvider>().chambers;
      if (chambers.isNotEmpty) {
        setState(() {
          _selectedChamberId = chambers.first.id;
        });
        _loadReport();
      }
    }
  }

  Future<void> _loadReport() async {
    if (_selectedChamberId == null) return;

    setState(() => _isLoading = true);

    try {
      final apiService = context.read<IApiService>();
      
      final results = await Future.wait([
        apiService.getReport(
          chamberId: _selectedChamberId!,
          startDate: _startDate,
          endDate: _endDate,
        ),
        apiService.getTemperatureHistory(
          _selectedChamberId!,
          startDate: _startDate,
          endDate: _endDate,
        ),
        apiService.getColdChamber(_selectedChamberId!),
      ]);

      setState(() {
        _reportData = results[0] as Map<String, dynamic>;
        _history = results[1] as List<TemperatureReading>;
        _selectedChamber = results[2] as ColdChamber;
        
        _history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    if (_dateFormat != null) {
      return _dateFormat!.format(date);
    }
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reportes y Análisis',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              if (_isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            ],
          ),
          const SizedBox(height: 24),

          _buildFilterBar(),
          const SizedBox(height: 24),

          if (_reportData != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKpiGrid(),
                const SizedBox(height: 24),

                _buildSectionTitle(
                  'Tendencia Térmica',
                  info: 'Muestra cómo ha variado la temperatura respecto a los límites permitidos. \nLas subidas hacia la línea roja indican pérdida de frío.'
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
                    child: SizedBox(
                      height: 300,
                      child: _history.isEmpty 
                        ? const Center(child: Text('Sin datos históricos'))
                        : _buildHistoryChart(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(
                            'Diagnóstico Probable',
                            info: 'Causas inferidas por el algoritmo basándose en patrones de temperatura (picos, duración, frecuencia).'
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: _buildDiagnosticChart(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título sin info general, ahora es por fila
                          Text(
                            'Insights del Sistema',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailedAnalysis(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            )
          else if (!_isLoading)
             const Center(child: Text('Seleccione una cámara para ver el reporte')),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required String info}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: info,
          triggerMode: TooltipTriggerMode.tap,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade800,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(color: Colors.white),
          child: Icon(Icons.info_outline, size: 20, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.calendar_month, color: AppColors.info),
          ),
          const SizedBox(width: 16),
          _buildDateSelector(_startDate, (picked) => setState(() { _startDate = picked; _loadReport(); })),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          ),
          _buildDateSelector(_endDate, (picked) => setState(() { _endDate = picked; _loadReport(); })),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.veryLightGray,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Consumer<ChamberProvider>(
              builder: (context, chamberProvider, _) {
                final chambers = chamberProvider.chambers;
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedChamberId,
                    hint: const Text('Seleccionar Cámara'),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.info),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _selectedChamberId = value);
                        _loadReport();
                      }
                    },
                    items: chambers.map((chamber) => DropdownMenuItem<String>(
                      value: chamber.id,
                      child: Text(chamber.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                    )).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now(),
        );
        if (picked != null) onSelect(picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDate(date),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            date.year.toString(),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.5,
      children: [
        StatsCard(
          label: 'Horas en Riesgo',
          value: '${_reportData!['hours_at_risk']?.toStringAsFixed(1) ?? '0'}h',
          subtitle: 'Último periodo',
          color: AppColors.critical,
        ),
        StatsCard(
          label: 'Costo Proyectado',
          value: '\$${_reportData!['estimated_cost'] ?? '0'}',
          subtitle: 'Pérdida potencial',
          color: AppColors.critical,
        ),
        StatsCard(
          label: 'Confiabilidad',
          value: '${(_reportData!['uptime_percentage'] as num?)?.toStringAsFixed(1) ?? '0'}%',
          subtitle: 'Uptime operativo',
          color: AppColors.normal,
        ),
        StatsCard(
          label: 'Alertas Totales',
          value: '${_reportData!['total_alerts'] ?? '0'}',
          subtitle: '${_reportData!['critical_alerts'] ?? '0'} Críticas',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildHistoryChart() {
    final warningLevel = _selectedChamber?.warningThreshold ?? 100.0;
    final criticalLevel = _selectedChamber?.criticalThreshold ?? 100.0;
    final targetLevel = _selectedChamber?.targetTemperature ?? 0.0;

    double minY = (targetLevel < _history.map((e) => e.temperature).reduce((a, b) => a < b ? a : b) 
              ? targetLevel 
              : _history.map((e) => e.temperature).reduce((a, b) => a < b ? a : b)) - 5;
    
    double maxY = (criticalLevel > _history.map((e) => e.temperature).reduce((a, b) => a > b ? a : b) 
              ? criticalLevel 
              : _history.map((e) => e.temperature).reduce((a, b) => a > b ? a : b)) + 5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: warningLevel,
              color: AppColors.warning.withOpacity(0.6),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true, 
                alignment: Alignment.topRight,
                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 10),
                labelResolver: (_) => 'ADVERTENCIA',
              ),
            ),
            HorizontalLine(
              y: criticalLevel,
              color: AppColors.critical.withOpacity(0.6),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true, 
                alignment: Alignment.topRight,
                style: TextStyle(color: AppColors.critical, fontWeight: FontWeight.bold, fontSize: 10),
                labelResolver: (_) => 'CRÍTICO',
              ),
            ),
          ],
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (_history.length / 5).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _history.length) {
                  final date = _history[value.toInt()].timestamp;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.day}/${date.month} ${date.hour}h',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value <= minY) return const SizedBox();
                return Text(
                  '${value.toInt()}°C',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d).withOpacity(0.2), width: 1),
        ),
        minX: 0,
        maxX: (_history.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: _history.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.temperature);
            }).toList(),
            isCurved: true,
            color: AppColors.info,
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.info.withOpacity(0.05),
            ),
            // PUNTOS DE ALERTA ACTIVADOS
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) {
                // Solo mostrar punto si cruza el umbral de advertencia
                return spot.y >= warningLevel;
              },
              getDotPainter: (spot, percent, barData, index) {
                final isCritical = spot.y >= criticalLevel;
                return FlDotCirclePainter(
                  radius: 5,
                  color: isCritical ? AppColors.critical : AppColors.warning,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final date = _history[barSpot.x.toInt()].timestamp;
                return LineTooltipItem(
                  '${barSpot.y}°C\n${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosticChart() {
    final Map<String, dynamic> causes = _reportData!['alert_causes'] ?? {};
    
    if (causes.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: AppColors.normal),
              SizedBox(height: 12),
              Text("Sin anomalías detectadas", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Calcular el máximo para normalizar las barras
    final int maxCount = causes.values.fold(0, (prev, curr) => (curr as int) > prev ? curr : prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: causes.entries.map((entry) {
        final count = entry.value as int;
        final percentage = count / maxCount;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    '$count eventos',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  // Fondo de la barra
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGray,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Barra de progreso
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            entry.key.contains('Puerta') ? AppColors.warning : AppColors.critical,
                            entry.key.contains('Puerta') ? AppColors.warning.withOpacity(0.7) : AppColors.critical.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailedAnalysis() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAnalysisRow(
              Icons.trending_up, 
              'Tasa de Cambio Promedio', 
              '${_reportData!['avg_rate_of_change']?.toStringAsFixed(2) ?? '0'}°C/min',
              Colors.blueAccent,
              _reportData!['analysis_rate_text'] ?? 'Sin análisis disponible'
            ),
            const Divider(height: 30),
            _buildAnalysisRow(
              Icons.access_time_filled, 
              'Tiempo Total en Riesgo', 
              '${_reportData!['total_risk_hours']?.toStringAsFixed(1) ?? '0'} Horas',
              Colors.orangeAccent,
              _reportData!['analysis_risk_text'] ?? 'Sin análisis disponible'
            ),
            const Divider(height: 30),
            _buildAnalysisRow(
              Icons.monetization_on, 
              'Impacto Económico', 
              '\$${_reportData!['monthly_cost'] ?? '0'}',
              Colors.redAccent,
              _reportData!['analysis_cost_text'] ?? 'Sin análisis disponible'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(IconData icon, String title, String value, Color iconColor, String infoText) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: infoText,
                    triggerMode: TooltipTriggerMode.tap,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(color: Colors.white),
                    child: Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
