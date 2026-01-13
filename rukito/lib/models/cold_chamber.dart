enum ChamberStatus { normal, warningHot, criticalHot, criticalCold, offline }

class ColdChamber {
  final String id;
  final String name;
  final String content;
  final double currentTemperature;
  final double targetTemperature;
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

  // Determina color de borde según estado (Hex strings para uso general, pero preferible usar Theme)
  String get borderColor {
    switch (status) {
      case ChamberStatus.criticalHot:
      case ChamberStatus.criticalCold:
        return '#e74c3c'; // Rojo
      case ChamberStatus.warningHot:
        return '#f39c12'; // Naranja
      case ChamberStatus.normal:
        return '#2ecc71'; // Verde
      case ChamberStatus.offline:
        return '#95a5a6'; // Gris
    }
  }

  // Emoji de estado
  String get statusEmoji {
    switch (status) {
      case ChamberStatus.normal:
        return '✓';
      case ChamberStatus.warningHot:
        return '⚠️';
      case ChamberStatus.criticalHot:
        return '🔥';
      case ChamberStatus.criticalCold:
        return '❄️';
      case ChamberStatus.offline:
        return '⚡';
    }
  }

  // Texto de estado
  String get statusText {
    switch (status) {
      case ChamberStatus.normal:
        return 'Normal';
      case ChamberStatus.warningHot:
        return 'Precaución';
      case ChamberStatus.criticalHot:
        return 'Crítico Calor';
      case ChamberStatus.criticalCold:
        return 'Crítico Frío';
      case ChamberStatus.offline:
        return 'Desconectado';
    }
  }

  factory ColdChamber.fromJson(Map<String, dynamic> json) {
    return ColdChamber(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String? ?? 'Contenido General',
      currentTemperature: (json['current_temperature'] as num).toDouble(),
      targetTemperature: (json['target_temperature'] as num?)?.toDouble() ?? -18.0, // Default fallback
      rateOfChange: (json['rate_of_change'] as num).toDouble(),
      status: _parseStatus(json['status'] as String?),
      lastUpdate: DateTime.parse(json['last_update'] as String),
      recentTemperatures: json['recent_temperatures'] != null 
          ? List<double>.from((json['recent_temperatures'] as List<dynamic>).map((x) => (x as num).toDouble()))
          : [],
      isActive: json['is_active'] as bool? ?? true,
      location: json['location'] as String? ?? 'Principal',
    );
  }

  static ChamberStatus _parseStatus(String? status) {
    switch (status) {
      case 'NORMAL': return ChamberStatus.normal;
      case 'WARNING_HOT': return ChamberStatus.warningHot;
      case 'CRITICAL_HOT': return ChamberStatus.criticalHot;
      case 'CRITICAL_COLD': return ChamberStatus.criticalCold;
      case 'OFFLINE': return ChamberStatus.offline;
      default: return ChamberStatus.normal;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'current_temperature': currentTemperature,
        'target_temperature': targetTemperature,
        'rate_of_change': rateOfChange,
        'status': _statusToString(status),
        'last_update': lastUpdate.toIso8601String(),
        'recent_temperatures': recentTemperatures,
        'is_active': isActive,
        'location': location,
      };
      
  String _statusToString(ChamberStatus status) {
    switch (status) {
      case ChamberStatus.normal: return 'NORMAL';
      case ChamberStatus.warningHot: return 'WARNING_HOT';
      case ChamberStatus.criticalHot: return 'CRITICAL_HOT';
      case ChamberStatus.criticalCold: return 'CRITICAL_COLD';
      case ChamberStatus.offline: return 'OFFLINE';
    }
  }

  ColdChamber copyWith({
    String? id,
    String? name,
    String? content,
    double? currentTemperature,
    double? targetTemperature,
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
      rateOfChange: rateOfChange ?? this.rateOfChange,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      recentTemperatures: recentTemperatures ?? this.recentTemperatures,
      isActive: isActive ?? this.isActive,
      location: location ?? this.location,
    );
  }
}