import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert_config.dart';
import '../services/api_interface.dart';
import '../theme/app_colors.dart';

class ChamberConfigScreen extends StatefulWidget {
  final String chamberId;
  final String chamberName;

  const ChamberConfigScreen({
    Key? key,
    required this.chamberId,
    required this.chamberName,
  }) : super(key: key);

  @override
  State<ChamberConfigScreen> createState() => _ChamberConfigScreenState();
}

class _ChamberConfigScreenState extends State<ChamberConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  AlertConfig? _config;
  String? _error;

  // Controladores
  final _minTempController = TextEditingController();
  final _targetTempController = TextEditingController();
  final _warningTempController = TextEditingController();
  final _maxTempController = TextEditingController();
  final _rateController = TextEditingController();
  
  // Estados Locales para UI Dinámica
  bool _isEnabled = true;
  int _selectedNotificationState = 2; // 0: Frío, 1: Warning, 2: Calor
  
  // Mapa local para gestionar la UI de canales antes de guardar
  // 0: Critical Cold, 1: Warning Hot, 2: Critical Hot
  final Map<int, List<String>> _notificationRules = {
    0: [],
    1: [],
    2: []
  };

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _minTempController.dispose();
    _targetTempController.dispose();
    _warningTempController.dispose();
    _maxTempController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<IApiService>();
      final config = await api.getAlertConfig(widget.chamberId);
      
      setState(() {
        _config = config;
        
        // Mapeo de Umbrales (Nueva Estructura)
        _minTempController.text = config.thresholds.criticalCold.toString();
        _targetTempController.text = config.thresholds.target.toString();
        _warningTempController.text = config.thresholds.warningHot.toString();
        _maxTempController.text = config.thresholds.criticalHot.toString();
        _rateController.text = config.thresholds.rateOfChange.toString();
        
        _isEnabled = config.isEnabled;
        
        // Mapeo de Notificaciones (Nueva Estructura Jerárquica)
        _notificationRules[0] = List.from(config.notifications.onCriticalCold.channels);
        _notificationRules[1] = List.from(config.notifications.onWarningHot.channels);
        _notificationRules[2] = List.from(config.notifications.onCriticalHot.channels);
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando configuración: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;
    
    setState(() => _isSaving = true);
    try {
      // 1. Construir nuevos umbrales
      final newThresholds = AlertThresholds(
        criticalCold: double.tryParse(_minTempController.text) ?? -30.0,
        target: double.tryParse(_targetTempController.text) ?? -20.0,
        warningHot: double.tryParse(_warningTempController.text) ?? -15.0,
        criticalHot: double.tryParse(_maxTempController.text) ?? -10.0,
        rateOfChange: double.tryParse(_rateController.text) ?? 1.0,
      );

      // 2. Construir nueva configuración de notificaciones preservando roles existentes
      final newNotifications = NotificationConfig(
        onCriticalCold: _config!.notifications.onCriticalCold.copyWith(
          channels: _notificationRules[0]
        ),
        onWarningHot: _config!.notifications.onWarningHot.copyWith(
          channels: _notificationRules[1]
        ),
        onCriticalHot: _config!.notifications.onCriticalHot.copyWith(
          channels: _notificationRules[2]
        ),
      );

      // 3. Crear objeto actualizado completo
      final updatedConfig = _config!.copyWith(
        thresholds: newThresholds,
        notifications: newNotifications,
        isEnabled: _isEnabled,
        updatedAt: DateTime.now(),
      );

      final api = context.read<IApiService>();
      await api.updateAlertConfig(widget.chamberId, updatedConfig);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        _showErrorSnackBar('Error al guardar: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.critical,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleChannel(String channel, bool? value) {
    setState(() {
      final currentRules = _notificationRules[_selectedNotificationState] ?? [];
      if (value == true) {
        if (!currentRules.contains(channel)) currentRules.add(channel);
      } else {
        currentRules.remove(channel);
      }
      _notificationRules[_selectedNotificationState] = currentRules;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),
                        const SizedBox(height: 32),

                        // Switch de Activación
                        _buildStatusSwitch(),
                        const SizedBox(height: 24),

                        // Sección de Umbrales (Reorganizada)
                        _buildSectionContainer(
                          title: 'Umbrales de Activación',
                          icon: Icons.thermostat_rounded,
                          children: [
                            // Fila 1: Crítico Frío y Objetivo
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSunkenInput(
                                    controller: _minTempController,
                                    label: 'Mínima (Crítico Frío)',
                                    suffix: '°C',
                                    icon: Icons.ac_unit_rounded,
                                    iconColor: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildSunkenInput(
                                    controller: _targetTempController,
                                    label: 'Temperatura Objetivo',
                                    suffix: '°C',
                                    icon: Icons.track_changes_rounded,
                                    iconColor: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Fila 2: Advertencia y Crítico Calor
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSunkenInput(
                                    controller: _warningTempController,
                                    label: 'Temp. Advertencia',
                                    suffix: '°C',
                                    icon: Icons.warning_amber_rounded,
                                    iconColor: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildSunkenInput(
                                    controller: _maxTempController,
                                    label: 'Máxima (Crítico Calor)',
                                    suffix: '°C',
                                    icon: Icons.local_fire_department_rounded,
                                    iconColor: AppColors.critical,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Sensibilidad (Ocupando todo el ancho)
                            _buildSunkenInput(
                              controller: _rateController,
                              label: 'Sensibilidad (Tasa de Cambio)',
                              suffix: '°C/min',
                              icon: Icons.show_chart_rounded,
                              iconColor: Colors.indigo,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),

                        // Sección de Notificaciones
                        _buildSectionContainer(
                          title: 'Reglas de Notificación',
                          icon: Icons.notifications_active_outlined,
                          children: [
                            const Text('Selecciona un escenario para configurar sus alertas:', 
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildStateSelectorCard(0, 'Crítico Frío', Icons.ac_unit_rounded, Colors.blue)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStateSelectorCard(1, 'Advertencia', Icons.warning_amber_rounded, Colors.orange)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStateSelectorCard(2, 'Crítico Calor', Icons.local_fire_department_rounded, Colors.red)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildNotificationActions(),
                          ],
                        ),

                        const SizedBox(height: 40),
                        _buildSaveButton(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A237E)),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            'Configurar ${widget.chamberName}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF1A237E),
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isEnabled ? AppColors.info.withOpacity(0.15) : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: _isEnabled ? Border.all(color: AppColors.info.withOpacity(0.3)) : null,
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Sistema de Alertas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B))),
        subtitle: Text(_isEnabled ? 'Monitoreo activo y protegiendo' : 'MONITOREO DETENIDO',
          style: TextStyle(color: _isEnabled ? AppColors.info : AppColors.critical, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        value: _isEnabled,
        onChanged: (val) => setState(() => _isEnabled = val),
        activeColor: AppColors.info,
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _isEnabled ? AppColors.info.withOpacity(0.1) : Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(_isEnabled ? Icons.notifications_active : Icons.notifications_off, color: _isEnabled ? AppColors.info : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildNotificationActions() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(_selectedNotificationState),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedNotificationState == 0 ? 'Acciones para CONGELACIÓN EXCESIVA:' :
            _selectedNotificationState == 1 ? 'Acciones para PRECAUCIÓN:' :
            'Acciones para CALENTAMIENTO CRÍTICO:',
            style: TextStyle(
              fontWeight: FontWeight.w800, 
              color: !_isEnabled ? Colors.grey : (_selectedNotificationState == 0 ? Colors.blue : _selectedNotificationState == 1 ? Colors.orange : Colors.red),
              fontSize: 14
            ),
          ),
          const SizedBox(height: 12),
          _buildStyledCheckbox(title: 'Notificación Push', subtitle: 'Alertas instantáneas a la app móvil.', channelKey: 'push', icon: Icons.mobile_friendly),
          _buildStyledCheckbox(title: 'Mensaje SMS', subtitle: 'Mensaje de texto a números registrados.', channelKey: 'sms', icon: Icons.sms),
          _buildStyledCheckbox(title: 'Correo Electrónico', subtitle: 'Reporte detallado por email.', channelKey: 'email', icon: Icons.email),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
        boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveConfig,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Cambios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildSectionContainer({required String title, required IconData icon, required List<Widget> children}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: const Color(0xFF1A237E), size: 24),
              ),
              const SizedBox(width: 14),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSunkenInput({required TextEditingController controller, required String label, required String suffix, required IconData icon, required Color iconColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.black.withOpacity(0.04), Colors.transparent]),
          ),
          child: TextField(
            controller: controller,
            enabled: _isEnabled,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: InputBorder.none,
              icon: Icon(icon, color: _isEnabled ? iconColor : Colors.grey, size: 20),
              suffixText: suffix,
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateSelectorCard(int value, String label, IconData icon, Color color) {
    final isSelected = _selectedNotificationState == value;
    
    // Si el monitoreo está apagado, el color del seleccionado cambia a gris
    final Color effectiveColor = _isEnabled ? color : Colors.grey.shade600;

    return InkWell(
      onTap: _isEnabled ? () => setState(() => _selectedNotificationState = value) : null,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.grey.shade200, 
            width: isSelected ? 2 : 1
          ),
          boxShadow: isSelected && _isEnabled 
            ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] 
            : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? effectiveColor : Colors.grey.shade400, size: 28),
            const SizedBox(height: 8),
            Text(
              label, 
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isSelected ? effectiveColor : Colors.grey.shade400, 
                fontSize: 11
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledCheckbox({required String title, required String subtitle, required String channelKey, required IconData icon}) {
    final currentRules = _notificationRules[_selectedNotificationState] ?? [];
    final isChecked = currentRules.contains(channelKey);
    
    // Color principal que cambia si está deshabilitado
    final Color activeColor = _isEnabled ? const Color(0xFF1A237E) : Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: _isEnabled ? () => _toggleChannel(channelKey, !isChecked) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isChecked ? activeColor.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isChecked ? activeColor.withOpacity(0.3) : Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2), 
                child: Icon(
                  isChecked ? Icons.check_circle : Icons.circle_outlined, 
                  color: isChecked ? activeColor : Colors.grey.shade400, 
                  size: 22
                )
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: isChecked ? activeColor : Colors.grey.shade700), 
                        const SizedBox(width: 8), 
                        Text(
                          title, 
                          style: TextStyle(
                            fontWeight: isChecked ? FontWeight.w700 : FontWeight.w600, 
                            color: isChecked ? activeColor : const Color(0xFF1E293B), 
                            fontSize: 15
                          )
                        )
                      ]
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}