import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      
      if (!mounted) return;

      setState(() {
        _historicalData = data.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: $e'),
            backgroundColor: AppColors.critical,
          ),
        );
      }
    }
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Principal
          Text(
            'Histórico de Temperaturas',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: const Color(0xFF1A237E),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Consulta el registro detallado de lecturas minuto a minuto.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // 2. Barra de Herramientas (Filtros)
          _buildFilterBar(),
          
          const SizedBox(height: 32),

          // 3. Título de Sección con Estilo Premium
          _buildSectionTitle('Datos Históricos'),
          const SizedBox(height: 16),

          // 4. Tabla de Datos
          if (_isLoading)
            const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_historicalData.isEmpty)
            _buildEmptyState()
          else
            _buildModernTable(),
            
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.w800, 
            color: Color(0xFF283593),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF283593).withOpacity(0.2), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 20, color: Colors.blueGrey.shade700),
              const SizedBox(width: 8),
              Text(
                "Configuración de Búsqueda",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Selector de Fechas
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      _buildDateButton(_startDate, (picked) => setState(() { _startDate = picked; _loadHistoricalData(); })),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey.shade400),
                      ),
                      _buildDateButton(_endDate, (picked) => setState(() { _endDate = picked; _loadHistoricalData(); })),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 16),

              // Selector de Cámara
              Expanded(
                flex: 4,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF283593), Color(0xFF1A237E)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A237E).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Consumer<ChamberProvider>(
                    builder: (context, chamberProvider, _) {
                      final chambers = chamberProvider.chambers;
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedChamberId,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                          dropdownColor: const Color(0xFF283593),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() => _selectedChamberId = value);
                              _loadHistoricalData();
                            }
                          },
                          items: chambers
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                              .toList(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(DateTime date, Function(DateTime) onSelect) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E)),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) onSelect(picked);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.blueGrey.shade400),
              const SizedBox(width: 8),
              Text(
                _formatDateShort(date),
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.grey.shade100,
          dataTableTheme: DataTableThemeData(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
            dataRowColor: MaterialStateProperty.resolveWith((states) => Colors.white),
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12, letterSpacing: 1),
          ),
        ),
        child: PaginatedDataTable(
          rowsPerPage: 10,
          availableRowsPerPage: const [10, 20, 50],
          columnSpacing: 30, // Más espaciado entre columnas
          horizontalMargin: 24,
          onRowsPerPageChanged: (value) {},
          columns: const [
            DataColumn(label: Text('HORA')),
            DataColumn(label: Text('TEMPERATURA')),
            DataColumn(label: Text('DIFERENCIA')),
            DataColumn(label: Text('TASA (dT/dt)')),
            DataColumn(label: Text('ESTADO')),
          ],
          source: HistoricalDataSource(_historicalData, context),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
        ),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Sin datos en este período",
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoricalDataSource extends DataTableSource {
  final List<TemperatureReading> _data;
  final BuildContext _context;

  HistoricalDataSource(this._data, this._context);

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final reading = _data[index];

    return DataRow(cells: [
      // Hora (Sin icono, estilo limpio)
      DataCell(
        Text(
          reading.formattedTime, 
          style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF475569))
        )
      ),
      
      // Temperatura
      DataCell(
        Text(
          reading.formattedTemperature, 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B))
        )
      ),
      
      // Diferencia
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (reading.temperatureDifference > 0 ? AppColors.critical : AppColors.info).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${reading.temperatureDifference > 0 ? '+' : ''}${reading.temperatureDifference.toStringAsFixed(1)}°C',
            style: TextStyle(
              color: reading.temperatureDifference > 0 ? AppColors.critical : AppColors.info,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
      
      // Tasa (Estilo normalizado)
      DataCell(
        Text(
          reading.formattedRateOfChange,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 13
          )
        )
      ),
      
      // Estado (Rectángulo con bordes suaves, sin iconos, color verde para normal)
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: reading.status == 'CRITICAL_COLD'
                ? Colors.blue.withOpacity(0.1)
                : reading.isCritical
                    ? AppColors.critical.withOpacity(0.1)
                    : reading.isWarning
                        ? AppColors.warning.withOpacity(0.1)
                        : AppColors.normal.withOpacity(0.1), // Verde para normal
            border: Border.all(
              color: reading.status == 'CRITICAL_COLD' 
                  ? Colors.blue.withOpacity(0.3) 
                  : reading.isCritical
                    ? AppColors.critical.withOpacity(0.3)
                    : reading.isWarning
                        ? AppColors.warning.withOpacity(0.3)
                        : AppColors.normal.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8), // Rectángulo con bordes suavizados
          ),
          child: Text(
            reading.statusDisplay,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: reading.status == 'CRITICAL_COLD'
                  ? Colors.blue
                  : reading.isCritical
                      ? AppColors.critical
                      : reading.isWarning
                          ? AppColors.warning
                          : AppColors.normal, // Verde para normal
            ),
          ),
        ),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _data.length;

  @override
  int get selectedRowCount => 0;
}