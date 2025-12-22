import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));

    Future.microtask(() {
      final chambers = context.read<ChamberProvider>().chambers;
      if (chambers.isNotEmpty) {
        setState(() {
          _selectedChamberId = chambers.first.id;
        });
        _loadReport();
      }
    });
  }

  Future<void> _loadReport() async {
    if (_selectedChamberId == null) return;

    setState(() => _isLoading = true);

    try {
      final apiService = context.read<IApiService>();
      final data = await apiService.getReport(
        chamberId: _selectedChamberId!,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          'Reportes y Análisis',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 24),

        // Filtros
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 90),
                                  ),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _startDate = picked);
                                  _loadReport();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.borderColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_startDate.day}/${_startDate.month}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('-'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: _startDate,
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _endDate = picked);
                                  _loadReport();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.borderColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_endDate.day}/${_endDate.month}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cámara:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Consumer<ChamberProvider>(
                        builder: (context, chamberProvider, _) {
                          final chambers = chamberProvider.chambers;
                          return DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedChamberId,
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() => _selectedChamberId = value);
                                _loadReport();
                              }
                            },
                            items: chambers
                                .map(
                                  (chamber) => DropdownMenuItem<String>(
                                    value: chamber.id,
                                    child: Text(chamber.name),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // KPIs
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_reportData != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KPIs - Últimos 30 Días',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  StatsCard(
                    label: 'Horas en Riesgo',
                    value:
                        '${_reportData!['hours_at_risk']?.toStringAsFixed(1) ?? '0'}h',
                    subtitle: 'Por encima de umbral',
                    color: AppColors.critical,
                  ),
                  StatsCard(
                    label: 'Costo Estimado',
                    value: '\$${_reportData!['estimated_cost'] ?? '0'}',
                    subtitle: 'Riesgo total',
                    color: AppColors.critical,
                  ),
                  StatsCard(
                    label: 'Confiabilidad',
                    value:
                        '${(_reportData!['uptime_percentage'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                    subtitle: 'Sistema operativo',
                    color: AppColors.normal,
                  ),
                  StatsCard(
                    label: 'Alertas Generadas',
                    value: '${_reportData!['total_alerts'] ?? '0'}',
                    subtitle: '${_reportData!['critical_alerts'] ?? '0'} críticas',
                    color: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Análisis detallado
              Text(
                'Análisis Detallado',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnalysisItem(
                        context,
                        'P1: Tasa de Cambio (dT/dt)',
                        'Promedio: ${_reportData!['avg_rate_of_change']?.toStringAsFixed(2) ?? '0'}°C/min',
                        'El umbral crítico fue superado ${_reportData!['critical_rate_events'] ?? '0'} veces',
                      ),
                      const SizedBox(height: 20),
                      _buildAnalysisItem(
                        context,
                        'P2: Correlación con Demanda',
                        'Correlación: ${_reportData!['demand_correlation']?.toStringAsFixed(2) ?? '0'}',
                        'Mayor impacto durante horas pico',
                      ),
                      const SizedBox(height: 20),
                      _buildAnalysisItem(
                        context,
                        'P3: Análisis de Tiempo en Riesgo',
                        'Total: ${_reportData!['total_risk_hours']?.toStringAsFixed(1) ?? '0'} horas/mes',
                        'Costo aproximado: \$${_reportData!['monthly_cost'] ?? '0'}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAnalysisItem(
    BuildContext context,
    String title,
    String value,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.veryLightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
