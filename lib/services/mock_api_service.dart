import '../models/index.dart';
import 'api_interface.dart';

/// Servicio API simulado para desarrollo sin backend
class MockApiService implements IApiService {
  // Datos simulados
  final List<ColdChamber> _chambers = [
    ColdChamber(
      id: 'CF-1',
      name: 'Cámara Frigorífica 1 (CF-1)',
      content: 'Carnes Prime',
      currentTemperature: -16,
      targetTemperature: -20,
      criticalThreshold: -18,
      warningThreshold: -17,
      rateOfChange: 0.5,
      status: ChamberStatus.warning,
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 2)),
      recentTemperatures: [-20, -19.5, -18.5, -17.5, -16.5, -16],
      location: 'Sala Principal',
    ),
    ColdChamber(
      id: 'CF-2',
      name: 'Cámara Frigorífica 2 (CF-2)',
      content: 'Lácteos y Moros',
      currentTemperature: 5,
      targetTemperature: 4,
      criticalThreshold: 8,
      warningThreshold: 6,
      rateOfChange: 1,
      status: ChamberStatus.warning,
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 5)),
      recentTemperatures: [3.5, 4, 4.5, 5, 5.5, 5],
      location: 'Sala Principal',
    ),
    ColdChamber(
      id: 'REF-3',
      name: 'Refrigerador 3 (REF-3)',
      content: 'Vegetales',
      currentTemperature: 2,
      targetTemperature: 2,
      criticalThreshold: 5,
      warningThreshold: 3,
      rateOfChange: 0,
      status: ChamberStatus.online,
      lastUpdate: DateTime.now().subtract(const Duration(minutes: 1)),
      recentTemperatures: [2, 2, 2, 2, 2, 2],
      location: 'Sala Principal',
    ),
  ];

  final List<Alert> _alerts = [
    Alert(
      id: 'ALT-001',
      title: 'CF-1 en Riesgo de Pérdida Total',
      description:
          'La puerta de CF-1 (Carnes Prime) detectada abierta. Temperatura subiendo desde -20°C a -16°C.',
      priority: AlertPriority.p1,
      type: AlertType.temperatureCritical,
      sensorId: 'CF-1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      isRead: false,
      estimatedCost: 15000,
      affectedContent: 'Carnes Premium',
      suggestedAction: 'Cerrar puerta inmediatamente',
    ),
    Alert(
      id: 'ALT-002',
      title: 'SMS Enviado a Don Jorge',
      description:
          '+593-999-XXXX - Mensaje de alerta de temperatura crítica en CF-1 entregado exitosamente.',
      priority: AlertPriority.p1,
      type: AlertType.smsNotification,
      sensorId: 'CF-1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      isRead: false,
    ),
    Alert(
      id: 'ALT-003',
      title: 'CF-2 Oscilando - Micro-corte de Energía',
      description:
          'CF-2 (Lácteos/Moros) detecta fluctuaciones de ±2°C. Compresor activado automáticamente.',
      priority: AlertPriority.p2,
      type: AlertType.powerFailure,
      sensorId: 'CF-2',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    Alert(
      id: 'ALT-004',
      title: 'REF-3 Operando Normalmente',
      description:
          'Temperatura estable en 2°C. Sin variaciones detectadas. Vegetales en óptimas condiciones.',
      priority: AlertPriority.p3,
      type: AlertType.normalOperation,
      sensorId: 'REF-3',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      isRead: true,
    ),
    Alert(
      id: 'ALT-005',
      title: 'Mantenimiento Preventivo Pendiente',
      description:
          'CF-1: Mantenimiento de filtros programado para mañana a las 06:00. Duración estimada: 45 minutos.',
      priority: AlertPriority.p2,
      type: AlertType.maintenanceRequired,
      sensorId: 'CF-1',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
  ];

  // ==================== CÁMARAS ====================

  Future<List<ColdChamber>> getColdChambers() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _chambers;
  }

  Future<ColdChamber> getColdChamber(String chamberId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _chambers.firstWhere(
      (c) => c.id == chamberId,
      orElse: () => throw Exception('Cámara no encontrada'),
    );
  }

  // ==================== LECTURAS ====================

  Future<List<TemperatureReading>> getTemperatureReadings(
    String chamberId, {
    int limit = 100,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final chamber = _chambers.firstWhere((c) => c.id == chamberId);
    final readings = <TemperatureReading>[];

    for (int i = 0; i < limit; i++) {
      final temp = chamber.currentTemperature +
          (i * 0.1 * (i % 2 == 0 ? -1 : 1));
      readings.add(
        TemperatureReading(
          id: 'READ-$chamberId-$i',
          sensorId: chamberId,
          temperature: temp,
          targetTemperature: chamber.targetTemperature,
          minTemperature: chamber.currentTemperature - 2,
          maxTemperature: chamber.currentTemperature + 2,
          rateOfChange: chamber.rateOfChange,
          timestamp:
              DateTime.now().subtract(Duration(minutes: i * 5)),
          status: temp > chamber.criticalThreshold
              ? 'CRÍTICO'
              : temp > chamber.warningThreshold
                  ? 'ADVERTENCIA'
                  : 'NORMAL',
        ),
      );
    }

    return readings;
  }

  Future<List<TemperatureReading>> getTemperatureHistory(
    String chamberId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return getTemperatureReadings(chamberId, limit: 50);
  }

  // ==================== ALERTAS ====================

  Future<List<Alert>> getAlerts({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final filtered = unreadOnly
        ? _alerts.where((a) => !a.isRead).toList()
        : _alerts;
    return filtered.take(limit).toList();
  }

  Future<List<Alert>> getChamberAlerts(String chamberId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _alerts.where((a) => a.sensorId == chamberId).toList();
  }

  Future<void> markAlertAsRead(String alertId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
    }
  }

  // ==================== CONFIGURACIÓN ====================

  Future<AlertConfig> getAlertConfig(String chamberId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return AlertConfig(
      id: 'CONFIG-$chamberId',
      sensorId: chamberId,
      maxTemperature: 5,
      minTemperature: -25,
      rateOfChangeThreshold: 0.5,
      priority: AlertPriorityLevel.high,
      isEnabled: true,
      notificationChannels: ['sms', 'push'],
      recipients: ['+593999123456'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  Future<AlertConfig> updateAlertConfig(
    String chamberId,
    AlertConfig config,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return config.copyWith(updatedAt: DateTime.now());
  }

  // ==================== REPORTES ====================

  Future<Map<String, dynamic>> getReport({
    required String chamberId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'chamber_id': chamberId,
      'period_start': startDate.toIso8601String(),
      'period_end': endDate.toIso8601String(),
      'hours_at_risk': 2.5,
      'estimated_cost': 15000,
      'uptime_percentage': 99.8,
      'total_alerts': 24,
      'critical_alerts': 3,
      'warning_alerts': 8,
      'info_alerts': 13,
      'avg_rate_of_change': 0.45,
      'critical_rate_events': 3,
      'demand_correlation': 0.78,
      'total_risk_hours': 4.2,
      'monthly_cost': 1200,
    };
  }

  Future<Map<String, dynamic>> getStatistics() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'total_chambers': 3,
      'active_chambers': 3,
      'critical_chambers': 1,
      'warning_chambers': 1,
      'average_temperature': -3.0,
      'total_alerts': 5,
      'unread_alerts': 4,
      'system_uptime': 99.8,
      'last_update': DateTime.now().toIso8601String(),
    };
  }

  // ==================== HEALTH CHECK ====================

  Future<bool> healthCheck() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }
}
