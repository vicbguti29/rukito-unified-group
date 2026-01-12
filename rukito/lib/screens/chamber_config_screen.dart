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

class _RecipientRow {
  String type; // 'email' | 'sms'
  TextEditingController controller;

  _RecipientRow({required this.type, String value = ''}) 
      : controller = TextEditingController(text: value);
  
  void dispose() {
    controller.dispose();
  }
}

class _ChamberConfigScreenState extends State<ChamberConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  AlertConfig? _config;
  String? _error;

  // Controladores
  final _maxTempController = TextEditingController();
  final _minTempController = TextEditingController();
  final _rateController = TextEditingController();
  
  // Lista dinámica de destinatarios
  final List<_RecipientRow> _recipientRows = [];
  
  // Estados Locales para UI Dinámica
  bool _isEnabled = true;
  int _priority = 2;
  List<String> _selectedChannels = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _maxTempController.dispose();
    _minTempController.dispose();
    _rateController.dispose();
    for (var row in _recipientRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<IApiService>();
      final config = await api.getAlertConfig(widget.chamberId);
      
      setState(() {
        _config = config;
        _maxTempController.text = config.maxTemperature.toString();
        _minTempController.text = config.minTemperature.toString();
        _rateController.text = config.rateOfChangeThreshold.toString();
        
        // Parsear destinatarios existentes
        _recipientRows.clear();
        for (var recipient in config.recipients) {
          final type = recipient.contains('@') ? 'email' : 'sms';
          _recipientRows.add(_RecipientRow(type: type, value: recipient));
        }
        // Si no hay, agregamos uno vacío por defecto
        if (_recipientRows.isEmpty) {
          _recipientRows.add(_RecipientRow(type: 'sms'));
        }
        
        _isEnabled = config.isEnabled;
        _priority = config.priority;
        _selectedChannels = List.from(config.notificationChannels);
        
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

    // VALIDACIÓN PREVIA (Frontend)
    if (_isEnabled) {
      final hasSmsChannel = _selectedChannels.contains('sms');
      final hasEmailChannel = _selectedChannels.contains('email');
      
      final hasSmsRecipient = _recipientRows.any((r) => r.type == 'sms' && r.controller.text.trim().isNotEmpty);
      final hasEmailRecipient = _recipientRows.any((r) => r.type == 'email' && r.controller.text.trim().isNotEmpty);

      if (hasSmsChannel && !hasSmsRecipient) {
        _showErrorSnackBar('Has seleccionado SMS como canal, pero no hay números de teléfono válidos.');
        return;
      }

      if (hasEmailChannel && !hasEmailRecipient) {
        _showErrorSnackBar('Has seleccionado Correo como canal, pero no hay emails válidos.');
        return;
      }
    }
    
    setState(() => _isSaving = true);
    try {
      // Recopilar destinatarios válidos
      final recipientsList = _recipientRows
          .map((r) => r.controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final updatedConfig = _config!.copyWith(
        maxTemperature: double.tryParse(_maxTempController.text) ?? 0,
        minTemperature: double.tryParse(_minTempController.text) ?? 0,
        rateOfChangeThreshold: double.tryParse(_rateController.text) ?? 0,
        priority: _priority,
        isEnabled: _isEnabled,
        notificationChannels: _selectedChannels,
        recipients: recipientsList,
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
      if (value == true) {
        if (!_selectedChannels.contains(channel)) {
          _selectedChannels.add(channel);
        }
      } else {
        _selectedChannels.remove(channel);
      }
    });
  }
  
  void _addRecipientRow() {
    setState(() {
      _recipientRows.add(_RecipientRow(type: 'sms'));
    });
  }

  void _removeRecipientRow(int index) {
    setState(() {
      _recipientRows[index].dispose();
      _recipientRows.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurar ${widget.chamberName}'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjeta 1: Estado del Sistema
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SwitchListTile(
                            title: const Text('Sistema de Alertas Activado', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(_isEnabled 
                              ? 'El monitoreo está activo' 
                              : 'No se generarán alertas',
                              style: TextStyle(color: _isEnabled ? Colors.green : Colors.grey),
                            ),
                            value: _isEnabled,
                            onChanged: (val) => setState(() => _isEnabled = val),
                            activeColor: AppColors.info,
                            secondary: Icon(
                              _isEnabled ? Icons.notifications_active : Icons.notifications_off,
                              color: _isEnabled ? AppColors.info : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tarjeta 2: Umbrales
                      _buildSectionCard(
                        title: 'Umbrales de Activación',
                        icon: Icons.thermostat,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _minTempController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Temp. Mínima',
                                    suffixText: '°C',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.arrow_downward, color: Colors.blue),
                                  ),
                                  enabled: _isEnabled,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _maxTempController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Temp. Máxima',
                                    suffixText: '°C',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.arrow_upward, color: Colors.red),
                                  ),
                                  enabled: _isEnabled,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Umbral Tasa de Cambio',
                              helperText: 'Ej: 0.8 activará alerta si sube 0.8°C en 1 min',
                              suffixText: '°C/min',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.show_chart),
                            ),
                            enabled: _isEnabled,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),

                      // Tarjeta 3: Prioridad y Notificación
                      _buildSectionCard(
                        title: 'Prioridad y Notificación',
                        icon: Icons.notification_important,
                        children: [
                           SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 1, label: Text('Baja'), icon: Icon(Icons.info_outline)),
                                ButtonSegment(value: 2, label: Text('Media'), icon: Icon(Icons.warning_amber)),
                                ButtonSegment(value: 3, label: Text('Alta'), icon: Icon(Icons.error_outline)),
                              ],
                              selected: {_priority},
                              onSelectionChanged: (Set<int> newSelection) {
                                setState(() {
                                  _priority = newSelection.first;
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.selected)) {
                                      if (_priority == 1) return Colors.blue.shade100;
                                      if (_priority == 2) return Colors.orange.shade100;
                                      if (_priority == 3) return Colors.red.shade100;
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Canales de Envío', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 8),
                          _buildCheckbox('Notificación Push (App)', 'push'),
                          _buildCheckbox('Mensaje SMS', 'sms'),
                          _buildCheckbox('Correo Electrónico', 'email'),
                          
                          const SizedBox(height: 24),
                          const Text('Destinatarios', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 8),
                          
                          // Lista dinámica de filas
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recipientRows.length,
                            separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final row = _recipientRows[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Dropdown Tipo
                                  Container(
                                    width: 120, // Un poco más ancho para el texto
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.veryLightGray,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      border: Border.all(color: AppColors.borderColor),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: row.type,
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'sms', 
                                            child: Row(
                                              children: [
                                                Icon(Icons.phone_android, size: 18, color: Colors.grey),
                                                SizedBox(width: 8),
                                                Text('SMS', style: TextStyle(fontSize: 13)),
                                              ],
                                            )
                                          ),
                                          DropdownMenuItem(
                                            value: 'email', 
                                            child: Row(
                                              children: [
                                                Icon(Icons.email, size: 18, color: Colors.grey),
                                                SizedBox(width: 8),
                                                Text('Email', style: TextStyle(fontSize: 13)),
                                              ],
                                            )
                                          ),
                                        ],
                                        onChanged: _isEnabled ? (val) {
                                          if (val != null) setState(() => row.type = val);
                                        } : null,
                                      ),
                                    ),
                                  ),
                                  // Campo de Texto
                                  Expanded(
                                    child: TextField(
                                      controller: row.controller,
                                      keyboardType: row.type == 'email' 
                                          ? TextInputType.emailAddress 
                                          : TextInputType.phone,
                                      decoration: InputDecoration(
                                        hintText: row.type == 'email' ? 'ejemplo@correo.com' : '+593...',
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                      ),
                                      enabled: _isEnabled,
                                    ),
                                  ),
                                  // Botón eliminar (solo si hay más de 1 o si se permite vaciar todo)
                                  if (_recipientRows.length > 1 || row.controller.text.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                      onPressed: _isEnabled ? () => _removeRecipientRow(index) : null,
                                    ),
                                ],
                              );
                            },
                          ),
                          
                          const SizedBox(height: 10),
                          if (_isEnabled)
                            TextButton.icon(
                              onPressed: _addRecipientRow,
                              icon: const Icon(Icons.add_circle, color: AppColors.info),
                              label: const Text('Agregar Destinatario', style: TextStyle(color: AppColors.info)),
                            ),
                        ],
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveConfig,
                          icon: _isSaving 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSaving ? 'Guardando...' : 'Guardar Configuración',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.info),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 30),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, String channelKey) {
    return CheckboxListTile(
      title: Text(title),
      value: _selectedChannels.contains(channelKey),
      onChanged: _isEnabled ? (v) => _toggleChannel(channelKey, v) : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.info,
    );
  }
}