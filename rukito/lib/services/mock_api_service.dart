import '../models/index.dart';
import 'api_interface.dart';

/// Servicio API simulado con congruencia matemática estricta
class MockApiService implements IApiService {
  
  // 1. CÁMARAS
  final List<ColdChamber> _chambers = [
    ColdChamber(
      id: 'CF-1',
      name: 'Cámara Frigorífica 1 (CF-1)',
      content: 'Carnes Prime',
      currentTemperature: -10.5,
      targetTemperature: -20,
      rateOfChange: 1.2,
      status: ChamberStatus.criticalHot, // Rojo (Antes offline, pero -10.5 vs -20 es critical hot)
      lastUpdate: DateTime.now(),
      recentTemperatures: [-14, -13, -12.5, -11, -10.5, -10.5],
      location: 'Zona de Carga A',
    ),
    ColdChamber(
      id: 'CF-2',
      name: 'Cámara Frigorífica 2 (CF-2)',
      content: 'Lácteos y Moros',
      currentTemperature: 5.5, 
      targetTemperature: 4,
      rateOfChange: 0.3,
      status: ChamberStatus.normal, // 5.5 vs target 4 is likely normal or slight warning
      lastUpdate: DateTime.now(),
      recentTemperatures: [4.2, 4.5, 5.0, 6.5, 7.2, 5.5],
      location: 'Pasillo Central',
    ),
    ColdChamber(
      id: 'REF-3',
      name: 'Refrigerador 3 (REF-3)',
      content: 'Vegetales',
      currentTemperature: 2.1, 
      targetTemperature: 2,
      rateOfChange: 0.0,
      status: ChamberStatus.normal, // Verde
      lastUpdate: DateTime.now(),
      recentTemperatures: [2, 2.1, 1.9, 2, 2.1, 2.1],
      location: 'Cocina Fría',
    ),
  ];

  late List<Alert> _alerts;

  MockApiService() {
    _generateConsistentAlerts();
  }

  void _generateConsistentAlerts() {
    _alerts = [];
    final now = DateTime.now();

    // CF-1: 12 Alertas (5 Crit, 7 Warn)
    for (int i = 0; i < 5; i++) {
      _alerts.add(Alert(
        id: 'ALT-CF1-C-$i',
        title: 'Temperatura Crítica',
        description: 'Temp > -12°C. Puerta abierta detectada.',
        severity: AlertSeverity.CRITICAL,
        category: AlertCategory.HOT_TEMP,
        sensorId: 'CF-1',
        timestamp: now.subtract(Duration(hours: i * 4)),
        isRead: false,
        estimatedCost: 500 * (i + 1),
        channels: ['PUSH', 'SMS', 'EMAIL'],
      ));
    }
    for (int i = 0; i < 7; i++) {
      _alerts.add(Alert(
        id: 'ALT-CF1-W-$i',
        title: 'Advertencia de Estabilidad',
        description: 'Ciclo de deshielo irregular.',
        severity: AlertSeverity.WARNING,
        category: AlertCategory.RAPID_CHANGE,
        sensorId: 'CF-1',
        timestamp: now.subtract(Duration(hours: i * 3 + 1)),
        isRead: true,
        channels: ['PUSH'],
      ));
    }

    // CF-2: EXACTAMENTE 1 Alerta (Advertencia)
    _alerts.add(Alert(
      id: 'ALT-CF2-1',
      title: 'Pico de Temperatura',
      description: 'Lectura de 7.2°C superó el umbral de advertencia (7°C).',
      severity: AlertSeverity.WARNING,
      category: AlertCategory.HOT_TEMP,
      sensorId: 'CF-2',
      timestamp: now.subtract(const Duration(hours: 2)),
      isRead: false,
      channels: ['PUSH'],
    ));
    
    // REF-3: 0 Alertas
  }

  // ==================== CÁMARAS ====================
  @override
  Future<List<ColdChamber>> getColdChambers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _chambers;
  }

  @override
  Future<ColdChamber> getColdChamber(String chamberId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _chambers.firstWhere((c) => c.id == chamberId, orElse: () => _chambers[0]);
  }

  // ==================== LECTURAS ====================
  @override
  Future<List<TemperatureReading>> getTemperatureReadings(String chamberId, {int limit = 100}) async {
    return _generateHistory(chamberId, DateTime.now().subtract(const Duration(hours: 4)), DateTime.now());
  }

  @override
  Future<List<TemperatureReading>> getTemperatureHistory(String chamberId, {required DateTime startDate, required DateTime endDate}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _generateHistory(chamberId, startDate, endDate);
  }

  List<TemperatureReading> _generateHistory(String chamberId, DateTime start, DateTime end) {
    final List<TemperatureReading> history = [];
    final duration = end.difference(start);
    int points = 40; 
    final interval = duration.inMinutes ~/ points;
    if (interval == 0) return [];

    final chamber = _chambers.firstWhere((c) => c.id == chamberId, orElse: () => _chambers[0]);

    // Lógica local de simulación de umbrales (ya que el modelo no los tiene)
    double criticalThreshold = -12.0;
    double warningThreshold = -15.0;
    double minTemp = -30.0;
    
    if (chamberId == 'CF-2') {
       criticalThreshold = 9.0;
       warningThreshold = 7.0;
       minTemp = 0.0;
    } else if (chamberId == 'REF-3') {
       criticalThreshold = 8.0;
       warningThreshold = 5.0;
       minTemp = 0.0;
    }

    for (int i = 0; i <= points; i++) {
      final timestamp = start.add(Duration(minutes: i * interval));
      double temp;

      if (chamberId == 'CF-1') {
        // CF-1: Caos (Muchos picos)
        bool triggerCritical = (i % 8 == 0); 
        bool triggerWarning = (i % 4 == 0) && !triggerCritical; 
        if (triggerCritical) temp = -10.0;
        else if (triggerWarning) temp = -13.0;
        else temp = -18.0 + (i % 3);
      } else if (chamberId == 'CF-2') {
        // CF-2: Estable (4°C) con UN SOLO PICO a 7.2°C
        if (i == 30) {
          temp = 7.2; 
        } else if (i == 29 || i == 31) {
          temp = 6.5; 
        } else {
          temp = 4.0 + (i % 2) * 0.2; 
        }
      } else {
        // REF-3: Perfectamente estable (2°C)
        temp = 2.0 + ((i % 3) * 0.1) - 0.1; 
      }

      String status = 'NORMAL';
      if (temp >= criticalThreshold) status = 'CRITICAL_HOT';
      else if (temp >= warningThreshold) status = 'WARNING_HOT';
      else if (temp <= minTemp) status = 'CRITICAL_COLD';

      history.add(TemperatureReading(
        id: 'H-$i',
        sensorId: chamberId,
        temperature: double.parse(temp.toStringAsFixed(1)),
        targetTemperature: chamber.targetTemperature,
        minTemperature: minTemp,
        maxTemperature: criticalThreshold + 5,
        rateOfChange: 0.1,
        timestamp: timestamp,
        status: status,
      ));
    }
    return history;
  }

  // ==================== ALERTAS ====================
  @override
  Future<List<Alert>> getAlerts({int limit = 50, bool unreadOnly = false}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    var result = _alerts;
    if (unreadOnly) result = result.where((a) => !a.isRead).toList();
    return result.take(limit).toList();
  }

  @override
  Future<List<Alert>> getChamberAlerts(String chamberId) async {
    return _alerts.where((a) => a.sensorId == chamberId).toList();
  }

  @override
  Future<void> markAlertAsRead(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) _alerts[index] = _alerts[index].copyWith(isRead: true);
  }

  // ==================== REPORTES ====================
  @override
  Future<Map<String, dynamic>> getReport({required String chamberId, required DateTime startDate, required DateTime endDate}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Simular respuesta del nuevo endpoint de reportes
    if (chamberId == 'CF-1') {
      return {
        'chamber_id': chamberId,
        'total_alerts': 12,
        'critical_alerts': 5,
        'warning_alerts': 7,
        'info_alerts': 0,
        'alert_causes': {
          'Puerta Abierta (Detectado)': 5,
          'Ciclo Deshielo Irregular': 4,
          'Sobrecarga Compresor': 3,
        },
        'hours_at_risk': 6.5,
        'estimated_cost': 2500,
        'uptime_percentage': 92.0,
        'avg_rate_of_change': 1.2,
        'monthly_cost': 2500,
        'total_risk_hours': 6.5,
        'demand_correlation': 0.9,
        'critical_rate_events': 5,
        'analysis_rate_text': "Inestabilidad severa. Picos coinciden con eventos de puerta abierta.",
        'analysis_risk_text': "6.5 horas acumuladas fuera de rango seguro.",
        'analysis_cost_text': "Pérdida de calidad estimada en lote de carnes.",
      };
    } else if (chamberId == 'CF-2') {
      return {
        'chamber_id': chamberId,
        'total_alerts': 1, 
        'critical_alerts': 0,
        'warning_alerts': 1,
        'info_alerts': 0,
        'alert_causes': {'Pico Transitorio': 1},
        'hours_at_risk': 0.1, 
        'estimated_cost': 0,
        'uptime_percentage': 40.0,
        'avg_rate_of_change': 0.3,
        'monthly_cost': 0,
        'total_risk_hours': 0.1,
        'demand_correlation': 0.1,
        'critical_rate_events': 0,
        'analysis_rate_text': "Estabilidad alta. Solo un evento aislado registrado.",
        'analysis_risk_text': "Riesgo despreciable.",
        'analysis_cost_text': "Sin impacto financiero.",
      };
    } else {
      return {
        'chamber_id': chamberId,
        'total_alerts': 0,
        'critical_alerts': 0,
        'warning_alerts': 0,
        'info_alerts': 0,
        'alert_causes': {},
        'hours_at_risk': 0.0,
        'estimated_cost': 0,
        'uptime_percentage': 100.0,
        'avg_rate_of_change': 0.0,
        'monthly_cost': 0,
        'total_risk_hours': 0.0,
        'demand_correlation': 0.0,
        'critical_rate_events': 0,
        'analysis_rate_text': "Operación nominal perfecta.",
        'analysis_risk_text': "Sin riesgo.",
        'analysis_cost_text': "Eficiencia máxima.",
      };
    }
  }

  // ==================== CONFIGURACIÓN ====================
  @override
  Future<AlertConfig> getAlertConfig(String chamberId) async {
    final chamber = _chambers.firstWhere((c) => c.id == chamberId, orElse: () => _chambers[0]);
    
    // Mapeo lógico de umbrales (Simulado localmente porque el modelo ya no los tiene)
    double criticalThreshold = -12.0;
    double warningThreshold = -15.0;
    double criticalCold = -30.0;
    
    if (chamberId == 'CF-2') {
       criticalThreshold = 9.0;
       warningThreshold = 7.0;
       criticalCold = 0.0;
    } else if (chamberId == 'REF-3') {
       criticalThreshold = 8.0;
       warningThreshold = 5.0;
       criticalCold = 0.0;
    }
    
    return AlertConfig(
      id: 'CFG-$chamberId',
      sensorId: chamberId,
      thresholds: AlertThresholds(
        criticalCold: criticalCold,
        target: chamber.targetTemperature,
        warningHot: warningThreshold,
        criticalHot: criticalThreshold,
        rateOfChange: 1.0,
      ),
      notifications: NotificationConfig(
        onWarningHot: NotificationAction(
          channels: ['push'], 
          targetRoles: ['staff']
        ),
        onCriticalHot: NotificationAction(
          channels: ['push', 'sms', 'email'], 
          targetRoles: ['manager', 'admin']
        ),
        onCriticalCold: NotificationAction(
          channels: ['email'], 
          targetRoles: ['technician']
        ),
      ),
      isEnabled: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<AlertConfig> updateAlertConfig(String chamberId, AlertConfig config) async => config;

  @override
  Future<Map<String, dynamic>> getStatistics() async => {'total_chambers': 3};

  @override
  Future<bool> healthCheck() async => true;

  // ==================== USUARIO ====================
  UserProfile _user = UserProfile(
    id: 'USR-001',
    name: 'Don Jorge (Admin)',
    email: 'jorge.admin@rukito.com',
    phoneNumber: '+593 98 765 4321',
    role: 'admin',
  );

  @override
  Future<UserProfile> getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _user;
  }

  @override
  Future<UserProfile> updateUserProfile(UserProfile user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _user = user;
    return _user;
  }
}