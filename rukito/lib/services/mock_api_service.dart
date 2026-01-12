import '../models/index.dart';
import 'api_interface.dart';

/// Servicio API simulado con congruencia matemática estricta
class MockApiService implements IApiService {
  
  // 1. CÁMARAS CON ESTADOS VARIADOS
  final List<ColdChamber> _chambers = [
    ColdChamber(
      id: 'CF-1',
      name: 'Cámara Frigorífica 1 (CF-1)',
      content: 'Carnes Prime',
      currentTemperature: -10.5, // Muy caliente vs Target -20
      targetTemperature: -20,
      warningThreshold: -15, 
      criticalThreshold: -12,
      rateOfChange: 1.2,
      status: ChamberStatus.offline, // Se verá ROJO (Desconectado/Crítico)
      lastUpdate: DateTime.now(),
      recentTemperatures: [-14, -13, -12.5, -11, -10.5, -10.5],
      location: 'Zona de Carga A',
    ),
    ColdChamber(
      id: 'CF-2',
      name: 'Cámara Frigorífica 2 (CF-2)',
      content: 'Lácteos y Moros',
      currentTemperature: 7.5, // Un poco caliente vs Target 4
      targetTemperature: 4,
      warningThreshold: 7,
      criticalThreshold: 9,
      rateOfChange: 0.3,
      status: ChamberStatus.warning, // NARANJA
      lastUpdate: DateTime.now(),
      recentTemperatures: [6, 6.5, 7, 7.2, 7.5, 7.5],
      location: 'Pasillo Central',
    ),
    ColdChamber(
      id: 'REF-3',
      name: 'Refrigerador 3 (REF-3)',
      content: 'Vegetales',
      currentTemperature: 2.1, // Perfecto vs Target 2
      targetTemperature: 2,
      warningThreshold: 5,
      criticalThreshold: 8,
      rateOfChange: 0.0,
      status: ChamberStatus.online, // VERDE
      lastUpdate: DateTime.now(),
      recentTemperatures: [2, 2.1, 1.9, 2, 2.1, 2.1],
      location: 'Cocina Fría',
    ),
  ];

  late List<Alert> _alerts;

  MockApiService() {
    _generateConsistentAlerts();
  }

  // 2. GENERAR ALERTAS QUE COINCIDAN CON EL REPORTE
  void _generateConsistentAlerts() {
    _alerts = [];
    final now = DateTime.now();

    // Generar 12 Alertas para CF-1 (5 Críticas, 7 Advertencias)
    for (int i = 0; i < 5; i++) {
      _alerts.add(Alert(
        id: 'ALT-CF1-C-$i',
        title: 'Temperatura Crítica Detectada',
        description: 'La temperatura superó el límite crítico de -12°C. Posible puerta abierta.',
        priority: AlertPriority.p1,
        type: AlertType.temperatureCritical,
        sensorId: 'CF-1',
        timestamp: now.subtract(Duration(hours: i * 4)), // Distribuidas en el tiempo
        isRead: false,
        estimatedCost: 500 * (i + 1),
      ));
    }
    for (int i = 0; i < 7; i++) {
      _alerts.add(Alert(
        id: 'ALT-CF1-W-$i',
        title: 'Advertencia de Estabilidad',
        description: 'Variación inusual detectada. Ciclo de deshielo irregular.',
        priority: AlertPriority.p2,
        type: AlertType.maintenanceRequired,
        sensorId: 'CF-1',
        timestamp: now.subtract(Duration(hours: i * 3 + 1)),
        isRead: true,
      ));
    }

    // Un par para CF-2 (Advertencias)
    _alerts.add(Alert(
      id: 'ALT-CF2-1',
      title: 'Ligera desviación térmica',
      description: 'Temperatura en 7.5°C (Límite 7°C).',
      priority: AlertPriority.p2,
      type: AlertType.powerFailure,
      sensorId: 'CF-2',
      timestamp: now.subtract(const Duration(minutes: 30)),
      isRead: false,
    ));
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
    return _generateReadings(chamberId, limit);
  }

  @override
  Future<List<TemperatureReading>> getTemperatureHistory(String chamberId, {required DateTime startDate, required DateTime endDate}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _generateHistory(chamberId, startDate, endDate);
  }

  // Helper para generar historial congruente con las alertas
  List<TemperatureReading> _generateHistory(String chamberId, DateTime start, DateTime end) {
    final List<TemperatureReading> history = [];
    final duration = end.difference(start);
    int points = 40; 
    final interval = duration.inMinutes ~/ points;
    if (interval == 0) return [];

    final chamber = _chambers.firstWhere((c) => c.id == chamberId, orElse: () => _chambers[0]);
    final isCriticalChamber = chamberId == 'CF-1';

    for (int i = 0; i <= points; i++) {
      final timestamp = start.add(Duration(minutes: i * interval));
      double temp;

      if (isCriticalChamber) {
        // CF-1: Generar picos que coincidan con la cantidad de alertas (aprox)
        // Necesitamos cruzar el umbral rojo (-12) y naranja (-15) varias veces.
        // Base: -18. Picos hacia arriba.
        
        // Simular 5 picos grandes (Críticos) y fluctuación alta
        bool triggerCritical = (i % 8 == 0); // Puntos 0, 8, 16, 24, 32 (5 picos)
        bool triggerWarning = (i % 4 == 0) && !triggerCritical; 

        if (triggerCritical) {
          temp = -10.0; // CRÍTICO (Mayor a -12)
        } else if (triggerWarning) {
          temp = -13.0; // ADVERTENCIA (Entre -15 y -12)
        } else {
          temp = -18.0 + (i % 3); // Normal fluctuando
        }
      } else if (chamberId == 'CF-2') {
        // CF-2: Estable con leve subida
        temp = 4.0 + (i / points * 3.5); // Sube de 4 a 7.5
      } else {
        // REF-3: Estable
        temp = 2.0 + ((i % 2) * 0.1);
      }

      history.add(TemperatureReading(
        id: 'H-$i',
        sensorId: chamberId,
        temperature: double.parse(temp.toStringAsFixed(1)),
        targetTemperature: chamber.targetTemperature,
        minTemperature: chamber.targetTemperature - 5,
        maxTemperature: chamber.criticalThreshold + 5,
        rateOfChange: 0.1,
        timestamp: timestamp,
        status: temp >= chamber.criticalThreshold ? 'CRÍTICO' : temp >= chamber.warningThreshold ? 'ADVERTENCIA' : 'NORMAL',
      ));
    }
    return history;
  }

  List<TemperatureReading> _generateReadings(String chamberId, int limit) {
    // Versión simplificada para "lecturas recientes"
    return _generateHistory(chamberId, DateTime.now().subtract(const Duration(hours: 4)), DateTime.now());
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
    
    // LÓGICA DE REPORTE CONGRUENTE
    if (chamberId == 'CF-1') {
      // Coincide con _generateConsistentAlerts
      return {
        'chamber_id': chamberId,
        'total_alerts': 12, // 5 + 7
        'critical_alerts': 5,
        'warning_alerts': 7,
        'info_alerts': 0,
        
        'alert_causes': {
          'Puerta Abierta (Detectado)': 5, // Coincide con críticas
          'Ciclo Deshielo Irregular': 4,
          'Sobrecarga Compresor': 3,
        }, // Suma = 12

        'hours_at_risk': 6.5,
        'estimated_cost': 2500,
        'uptime_percentage': 92.0,
        'avg_rate_of_change': 1.2,
        'critical_rate_events': 5,
        'demand_correlation': 0.95,
        'total_risk_hours': 6.5,
        'monthly_cost': 2500,
        
        'analysis_rate_text': "Inestabilidad severa. Los picos coinciden con 5 eventos críticos de puerta abierta.",
        'analysis_risk_text': "El producto estuvo expuesto a temperaturas > -12°C durante 6.5 horas acumuladas.",
        'analysis_cost_text': "Pérdida de calidad estimada en el lote de carnes debido a la ruptura de cadena de frío.",
      };
    } else if (chamberId == 'CF-2') {
      return {
        'chamber_id': chamberId,
        'total_alerts': 1,
        'critical_alerts': 0,
        'warning_alerts': 1,
        'info_alerts': 0,
        'alert_causes': {'Fluctuación Voltaje': 1},
        'hours_at_risk': 0.5,
        'estimated_cost': 0,
        'uptime_percentage': 99.5,
        'avg_rate_of_change': 0.3,
        'monthly_cost': 0,
        'analysis_rate_text': "Estabilidad aceptable con tendencia leve al alza.",
        'analysis_risk_text': "Riesgo mínimo controlado.",
        'analysis_cost_text': "Sin impacto financiero.",
      };
    } else {
      // REF-3
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
        'analysis_rate_text': "Funcionamiento perfecto.",
        'analysis_risk_text': "Sin riesgo.",
        'analysis_cost_text': "Operación eficiente.",
      };
    }
  }

  // ==================== CONFIGURACIÓN ====================
  @override
  Future<AlertConfig> getAlertConfig(String chamberId) async {
    final chamber = _chambers.firstWhere((c) => c.id == chamberId, orElse: () => _chambers[0]);
    return AlertConfig(
      id: 'CFG-$chamberId',
      sensorId: chamberId,
      maxTemperature: chamber.criticalThreshold,
      minTemperature: -30,
      rateOfChangeThreshold: 1.0,
      priority: 2,
      isEnabled: true,
      notificationChannels: ['push'],
      recipients: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<AlertConfig> updateAlertConfig(String chamberId, AlertConfig config) async => config;

  @override
  Future<Map<String, dynamic>> getStatistics() async => {'total_chambers': 3};

  @override
  Future<bool> healthCheck() async => true;
}