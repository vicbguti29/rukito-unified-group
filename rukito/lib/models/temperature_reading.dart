import 'package:intl/intl.dart';

class TemperatureReading {
  final String id;
  final String sensorId;
  final double temperature;
  final double targetTemperature;
  final double minTemperature;
  final double maxTemperature;
  final double rateOfChange; // dT/dt en °C/min
  final DateTime timestamp;
  final String status; // NORMAL, WARNING_HOT, CRITICAL_HOT, CRITICAL_COLD

  TemperatureReading({
    required this.id,
    required this.sensorId,
    required this.temperature,
    required this.targetTemperature,
    required this.minTemperature,
    required this.maxTemperature,
    required this.rateOfChange,
    required this.timestamp,
    required this.status,
  });

  // Calcula la diferencia con el objetivo
  double get temperatureDifference => temperature - targetTemperature;

  // Formatea la temperatura para UI
  String get formattedTemperature => '${temperature.toStringAsFixed(1)}°C';

  // Formatea la tasa de cambio
  String get formattedRateOfChange =>
      '${rateOfChange > 0 ? '+' : ''}${rateOfChange.toStringAsFixed(2)}°C/min';

  // Formatea timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    }
  }

  // Determina si está en estado crítico (Calor o Frío)
  bool get isCritical => status == 'CRITICAL_HOT' || status == 'CRITICAL_COLD';

  // Determina si está en estado de advertencia
  bool get isWarning => status == 'WARNING_HOT';

  // Determina si está normal
  bool get isNormal => status == 'NORMAL';
  
  // Texto amigable para UI
  String get statusDisplay {
    switch (status) {
      case 'CRITICAL_HOT': return 'CRÍTICO CALOR';
      case 'CRITICAL_COLD': return 'CRÍTICO FRÍO';
      case 'WARNING_HOT': return 'ADVERTENCIA';
      case 'NORMAL': return 'NORMAL';
      default: return status;
    }
  }

  factory TemperatureReading.fromJson(Map<String, dynamic> json) {
    return TemperatureReading(
      id: json['id'].toString(), // Convertir int a String
      sensorId: json['sensor_id'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      targetTemperature: (json['target_temperature'] as num?)?.toDouble() ?? 0.0,
      minTemperature: (json['min_temperature'] as num?)?.toDouble() ?? 0.0,
      maxTemperature: (json['max_temperature'] as num?)?.toDouble() ?? 0.0,
      rateOfChange: (json['rate_of_change'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sensor_id': sensorId,
        'temperature': temperature,
        'target_temperature': targetTemperature,
        'min_temperature': minTemperature,
        'max_temperature': maxTemperature,
        'rate_of_change': rateOfChange,
        'timestamp': timestamp.toIso8601String(),
        'status': status,
      };

  TemperatureReading copyWith({
    String? id,
    String? sensorId,
    double? temperature,
    double? targetTemperature,
    double? minTemperature,
    double? maxTemperature,
    double? rateOfChange,
    DateTime? timestamp,
    String? status,
  }) {
    return TemperatureReading(
      id: id ?? this.id,
      sensorId: sensorId ?? this.sensorId,
      temperature: temperature ?? this.temperature,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      rateOfChange: rateOfChange ?? this.rateOfChange,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}