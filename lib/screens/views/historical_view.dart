import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/index.dart';
import '../../providers/index.dart';
import '../../services/index.dart';
import '../../theme/app_colors.dart';

class HistoricalView extends StatefulWidget {
  const HistoricalView({Key? key}) : super(key: key);

  @override
  State<HistoricalView> createState() => _HistoricalViewState();
}

class _HistoricalViewState extends State<HistoricalView> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String? _selectedChamberId;
  List<TemperatureReading> _historicalData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final chambers = context.read<ChamberProvider>().chambers;
      if (chambers.isNotEmpty) {
        setState(() {
          _selectedChamberId = chambers.first.id;
        });
        _loadHistoricalData();
      }
    });
  }

  Future<void> _loadHistoricalData() async {
    if (_selectedChamberId == null) return;

    setState(() => _isLoading = true);

    try {
      final apiService = context.read<IApiService>();
      final data = await apiService.getTemperatureHistory(
        _selectedChamberId!,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _historicalData = data;
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
          'Histórico de Temperaturas',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 24),

        // Filtros
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Rango de fechas
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
                                      firstDate:
                                          DateTime.now().subtract(
                                            const Duration(days: 90),
                                          ),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() => _startDate = picked);
                                      _loadHistoricalData();
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
                                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('a'),
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
                                      _loadHistoricalData();
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
                                      '${_endDate.day}/${_endDate.month}/${_endDate.year}',
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

                    // Selector de cámara
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
                                    _loadHistoricalData();
                                  }
                                },
                                items: chambers
                                    .map(
                                      (chamber) =>
                                          DropdownMenuItem<String>(
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Contenido
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_historicalData.isEmpty)
          Center(
            child: Text(
              'Sin datos para el período seleccionado',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos históricos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  // Tabla de datos
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Hora')),
                        const DataColumn(label: Text('Temperatura')),
                        const DataColumn(label: Text('Diferencia')),
                        const DataColumn(label: Text('dT/dt')),
                        const DataColumn(label: Text('Estado')),
                      ],
                      rows: _historicalData
                          .take(20)
                          .map(
                            (reading) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    reading.formattedTime,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    reading.formattedTemperature,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${reading.temperatureDifference > 0 ? '+' : ''}${reading.temperatureDifference.toStringAsFixed(1)}°C',
                                    style: TextStyle(
                                      color: reading.temperatureDifference > 0
                                          ? AppColors.critical
                                          : AppColors.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    reading.formattedRateOfChange,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: reading.isCritical
                                          ? AppColors.criticalBackground
                                          : reading.isWarning
                                              ? AppColors.warningBackground
                                              : AppColors.white,
                                      border: Border.all(
                                        color: AppColors.borderColor,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      reading.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: reading.isCritical
                                            ? AppColors.critical
                                            : reading.isWarning
                                                ? AppColors.warning
                                                : AppColors.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (_historicalData.length > 20)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Mostrando 20 de ${_historicalData.length} registros',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
