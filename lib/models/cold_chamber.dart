enum ChamberStatus { online, warning, offline }

class ColdChamber {
  final String id;
  final String name;
  final String content;
  final double currentTemperature;
  final double targetTemperature;
  final double criticalThreshold;
  final double warningThreshold;
  final double rateOfChange;
  final ChamberStatus status;
  final DateTime lastUpdate;
  final List<double> recentTemperatures; // Últimas 6 lecturas para gráfico
  final bool isActive;
  final String location;

  ColdChamber({
    required this.id,
    required this.name,
    required this.content,
    required this.currentTemperature,
    required this.targetTemperature,
    required this.criticalThreshold,
    required this.warningThreshold,
    required this.rateOfChange,
    required this.status,
    required this.lastUpdate,
    required this.recentTemperatures,
    this.isActive = true,
    required this.location,
  });

  // Calcula diferencia con objetivo
  double get temperatureDifference => currentTemperature - targetTemperature;

  // Formatea temperatura actual
  String get formattedTemperature =>
      '${currentTemperature.toStringAsFixed(1)}°C';

  // Formatea tasa de cambio
  String get formattedRateOfChange =>
      '${rateOfChange > 0 ? '+' : ''}${rateOfChange.toStringAsFixed(2)}°C/min';

  // Formatea la última actualización
  String get formattedLastUpdate {
    final difference = DateTime.now().difference(lastUpdate);
    if (difference.inMinutes < 1) return 'Hace unos segundos';
    if (difference.inMinutes < 60)
      return 'Hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Hace ${difference.inHours}h';
    return 'Hace ${difference.inDays}d';
  }

  // Determina color de borde según estado
  String get borderColor {
    if (status == ChamberStatus.offline) return '#e74c3c'; // Rojo
    if (currentTemperature > criticalThreshold)
      return '#e74c3c'; // Rojo crítico
    if (currentTemperature > warningThreshold)
      return '#f39c12'; // Naranja advertencia
    return '#2ecc71'; // Verde normal
  }

  // Determina color de fondo según estado
  String get backgroundColor {
    if (status == ChamberStatus.offline || currentTemperature > criticalThreshold)
      return '#fff5f5'; // Fondo rojo claro
    if (currentTemperature > warningThreshold)
      return '#fffbf0'; // Fondo naranja claro
    return '#ffffff'; // Blanco normal
  }

  // Emoji de estado
  String get statusEmoji {
    switch (status) {
      case ChamberStatus.online:
        return '✓';
      case ChamberStatus.warning:
        return '⚠️';
      case ChamberStatus.offline:
        return '✗';
    }
  }

  // Texto de estado
  String get statusText {
    if (currentTemperature > criticalThreshold) return 'CRÍTICO';
    if (currentTemperature > warningThreshold) return 'ADVERTENCIA';
    if (status == ChamberStatus.offline) return 'Desconectado';
    return 'Normal';
  }

  factory ColdChamber.fromJson(Map<String, dynamic> json) {
    return ColdChamber(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      currentTemperature: (json['current_temperature'] as num).toDouble(),
      targetTemperature: (json['target_temperature'] as num).toDouble(),
      criticalThreshold: (json['critical_threshold'] as num).toDouble(),
      warningThreshold: (json['warning_threshold'] as num).toDouble(),
      rateOfChange: (json['rate_of_change'] as num).toDouble(),
      status: ChamberStatus.values[json['status'] as int],
      lastUpdate: DateTime.parse(json['last_update'] as String),
      recentTemperatures: List<double>.from(
        (json['recent_temperatures'] as List<dynamic>)
            .map((x) => (x as num).toDouble()),
      ),
      isActive: json['is_active'] as bool? ?? true,
      location: json['location'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'current_temperature': currentTemperature,
        'target_temperature': targetTemperature,
        'critical_threshold': criticalThreshold,
        'warning_threshold': warningThreshold,
        'rate_of_change': rateOfChange,
        'status': status.index,
        'last_update': lastUpdate.toIso8601String(),
        'recent_temperatures': recentTemperatures,
        'is_active': isActive,
        'location': location,
      };

  ColdChamber copyWith({
    String? id,
    String? name,
    String? content,
    double? currentTemperature,
    double? targetTemperature,
    double? criticalThreshold,
    double? warningThreshold,
    double? rateOfChange,
    ChamberStatus? status,
    DateTime? lastUpdate,
    List<double>? recentTemperatures,
    bool? isActive,
    String? location,
  }) {
    return ColdChamber(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      criticalThreshold: criticalThreshold ?? this.criticalThreshold,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      rateOfChange: rateOfChange ?? this.rateOfChange,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      recentTemperatures: recentTemperatures ?? this.recentTemperatures,
      isActive: isActive ?? this.isActive,
      location: location ?? this.location,
    );
  }
}
