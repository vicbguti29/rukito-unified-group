import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/index.dart';
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
  
  // Datos
  Map<String, dynamic>? _reportData;
  List<TemperatureReading> _history = [];
  ColdChamber? _selectedChamber; 
  AlertConfig? _alertConfig;
  
  bool _isLoading = false;
  String? _errorMessage; 
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
        apiService.getAlertConfig(_selectedChamberId!),
      ]);

      if (!mounted) return; // PROTECCIÓN AGREGADA

      setState(() {
        _reportData = results[0] as Map<String, dynamic>;
        _history = results[1] as List<TemperatureReading>;
        _selectedChamber = results[2] as ColdChamber;
        _alertConfig = results[3] as AlertConfig;
        
        _history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
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
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: const Color(0xFF1A237E), // Azul Índigo Profundo
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              if (_isLoading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            ],
          ),
          const SizedBox(height: 24),

          _buildFilterBar(),
          const SizedBox(height: 24),

          if (_errorMessage != null)
            _buildErrorView()
          else if (_reportData != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BANNER DE CONFIABILIDAD (Nuevo Ubicación)
                if (((_reportData!['uptime_percentage'] as num?)?.toDouble() ?? 0) < 85.0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.critical.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.critical.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.report_problem_rounded, color: AppColors.critical, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Confiabilidad de Datos Crítica (< 85%)",
                                style: const TextStyle(color: AppColors.critical, fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "El análisis financiero y térmico no es confiable debido a la alta pérdida de conexión con el sensor.",
                                style: TextStyle(color: AppColors.critical.withOpacity(0.8), fontSize: 13, height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

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
                          Text(
                            'Insights del Sistema',
                            style: const TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.w800, 
                              color: Color(0xFF283593),
                              letterSpacing: 0.5,
                            ),
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

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.only(top: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.critical.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.critical),
            const SizedBox(height: 16),
            const Text(
              "Error al cargar el reporte",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Error desconocido",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh),
              label: const Text("Reintentar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required String info}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.w800, 
            color: Color(0xFF283593), // Azul un poco más suave que el título principal
            letterSpacing: 0.5,
          ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Selector de Fechas Rediseñado con Efecto Hundido
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF1A237E), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildDateSelector(_startDate, (picked) => setState(() { _startDate = picked; _loadReport(); }))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, size: 20, color: Color(0xFF1A237E)),
                ),
                Expanded(child: _buildDateSelector(_endDate, (picked) => setState(() { _endDate = picked; _loadReport(); }))),
              ],
            ),
          ),
          
          const SizedBox(width: 20),

          // 2. Selector de Cámara con Efecto Hundido Morado Real
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A237E).withOpacity(0.2)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF121858), // Morado más oscuro (Sombra sutil)
                    Color(0xFF1A237E), // Morado original
                  ],
                ),
              ),
              child: Consumer<ChamberProvider>(
                builder: (context, chamberProvider, _) {
                  final chambers = chamberProvider.chambers;
                  return DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedChamberId,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                      dropdownColor: const Color(0xFF283593),
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      isExpanded: true,
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _selectedChamberId = value);
                          _loadReport();
                        }
                      },
                      items: chambers.map((chamber) => DropdownMenuItem<String>(
                        value: chamber.id,
                        child: Text(
                          chamber.name, 
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                    ),
                  );
                },
              ),
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
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1A237E),
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Slate 100
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.03),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDate(date),
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                color: const Color(0xFF283593),
                letterSpacing: 0.2,
                shadows: [
                  Shadow(offset: const Offset(0.5, 0.5), blurRadius: 0.5, color: Colors.white.withOpacity(0.7)),
                  Shadow(offset: const Offset(-0.5, -0.5), blurRadius: 0.5, color: Colors.black.withOpacity(0.1)),
                ],
              ),
            ),
            Text(
              date.year.toString(),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    // Extracción de datos
    final double hoursAtRisk = (_reportData!['hours_at_risk'] as num?)?.toDouble() ?? 0;
    final int estimatedCost = (_reportData!['estimated_cost'] as num?)?.toInt() ?? 0;
    final double uptime = (_reportData!['uptime_percentage'] as num?)?.toDouble() ?? 0;
    final int totalAlerts = (_reportData!['total_alerts'] as num?)?.toInt() ?? 0;
    final int criticalAlerts = (_reportData!['critical_alerts'] as num?)?.toInt() ?? 0;

    // LÓGICA DE COLORES DINÁMICA
    
    // 1. Horas y Costo: Tolerancia hasta 1.5h
    Color riskColor;
    if (hoursAtRisk < 1.5) {
      riskColor = AppColors.normal;
    } else if (hoursAtRisk <= 4.0) {
      riskColor = AppColors.warning;
    } else {
      riskColor = AppColors.critical;
    }

    // 2. Alertas: Prioridad Crítica
    Color alertsColor;
    if (totalAlerts == 0) {
      alertsColor = AppColors.normal;
    } else if (criticalAlerts > 0) {
      alertsColor = AppColors.critical;
    } else {
      alertsColor = AppColors.warning;
    }

    // 3. Confiabilidad: Umbrales 95% y 85%
    Color uptimeColor;
    if (uptime >= 95.0) {
      uptimeColor = AppColors.normal;
    } else if (uptime >= 85.0) {
      uptimeColor = AppColors.warning;
    } else {
      uptimeColor = AppColors.critical;
    }

    // Análisis de Texto (Tooltips)
    String hoursAnalysis = hoursAtRisk > 4.0 
        ? "CRÍTICO: Exposición > 4h. Probable ruptura de cadena de frío y daño irreversible."
        : (hoursAtRisk >= 1.5 ? "ADVERTENCIA: Exposición moderada. Verificar calidad." : "ACEPTABLE: Exposición < 1.5h protegida por inercia térmica.");

    String uptimeAnalysis;
    if (uptime >= 95.0) {
      uptimeAnalysis = "ÓPTIMO: Sensor operando con alta precisión y disponibilidad.";
    } else if (uptime >= 85.0) {
      uptimeAnalysis = "REVISIÓN: Se detectan pérdidas de señal intermitentes. Programar mantenimiento técnico.";
    } else {
      uptimeAnalysis = "CRÍTICO: Pérdida masiva de datos (>85%). El monitoreo no es confiable. Revisar conectividad.";
    }

    String costAnalysis = estimatedCost > 1000
        ? "IMPACTO ALTO: Pérdidas proyectadas significativas. Requiere reporte a gerencia."
        : "IMPACTO BAJO: Costos dentro del margen de merma operativa.";

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildEnhancedKpiCard(
          label: 'Horas en Riesgo',
          value: '${hoursAtRisk.toStringAsFixed(1)}h',
          subtitle: 'Fuera de rango',
          color: riskColor,
          icon: Icons.timer_off_outlined,
          analysisText: hoursAnalysis,
        ),
        _buildEnhancedKpiCard(
          label: 'Costo Proyectado',
          value: '\$$estimatedCost',
          subtitle: 'Pérdida estimada',
          color: riskColor, // Hereda el color de riesgo
          icon: Icons.attach_money,
          analysisText: costAnalysis,
        ),
        _buildEnhancedKpiCard(
          label: 'Confiabilidad',
          value: '${uptime.toStringAsFixed(1)}%',
          subtitle: 'Uptime operativo',
          color: uptimeColor,
          icon: Icons.shield_outlined,
          analysisText: uptimeAnalysis,
        ),
        _buildEnhancedKpiCard(
          label: 'Alertas Totales',
          value: '$totalAlerts',
          subtitle: '$criticalAlerts Críticas',
          color: alertsColor,
          icon: Icons.notifications_active_outlined,
          analysisText: criticalAlerts > 0 ? "Presencia de fallos críticos." : "Sin fallos críticos.",
        ),
      ],
    );
  }

  Widget _buildEnhancedKpiCard({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
    required String analysisText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 80,
              color: color.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    Tooltip(
                      message: analysisText,
                      triggerMode: TooltipTriggerMode.tap,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
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

  Widget _buildHistoryChart() {
    if (_history.isEmpty) {
      return const Center(child: Text("No hay datos suficientes para graficar"));
    }

    final thresholds = _alertConfig?.thresholds;
    final warningLevel = thresholds?.warningHot ?? 100.0;
    final criticalLevel = thresholds?.criticalHot ?? 100.0;
    final targetLevel = thresholds?.target ?? 0.0;
    final criticalColdLevel = thresholds?.criticalCold ?? -100.0;

    double minY = ([
      targetLevel, 
      criticalColdLevel, 
      ..._history.map((e) => e.temperature)
    ].reduce((a, b) => a < b ? a : b)) - 5;
    
    double maxY = ([
      criticalLevel, 
      warningLevel, 
      ..._history.map((e) => e.temperature)
    ].reduce((a, b) => a > b ? a : b)) + 5;

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
              y: targetLevel,
              color: AppColors.normal.withOpacity(0.8),
              strokeWidth: 2,
              dashArray: [10, 5],
              label: HorizontalLineLabel(
                show: true, 
                alignment: Alignment.topRight,
                style: const TextStyle(color: AppColors.normal, fontWeight: FontWeight.bold, fontSize: 10),
                labelResolver: (_) => 'OBJETIVO (${targetLevel.toStringAsFixed(1)}°C)',
              ),
            ),
            HorizontalLine(
              y: warningLevel,
              color: AppColors.warning.withOpacity(0.6),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true, 
                alignment: Alignment.topRight,
                style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 10),
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
                style: const TextStyle(color: AppColors.critical, fontWeight: FontWeight.bold, fontSize: 10),
                labelResolver: (_) => 'CRÍTICO CALOR',
              ),
            ),
            HorizontalLine(
              y: criticalColdLevel,
              color: Colors.blue.withOpacity(0.6),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true, 
                alignment: Alignment.bottomRight,
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10),
                labelResolver: (_) => 'CRÍTICO FRÍO',
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
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final date = _history[barSpot.x.toInt()].timestamp;
                return LineTooltipItem(
                  '${barSpot.y.toStringAsFixed(1)}°C\n${date.hour}:${date.minute.toString().padLeft(2, '0')}',
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
    final Map<String, dynamic> causes = Map<String, dynamic>.from(_reportData!['alert_causes'] ?? {});
    
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
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.veryLightGray,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
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