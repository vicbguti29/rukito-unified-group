import 'package:intl/intl.dart';

enum AlertSeverity { WARNING, CRITICAL }

enum AlertCategory { HOT_TEMP, COLD_TEMP, RAPID_CHANGE, SENSOR_OFFLINE }

class Alert {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertCategory category;
  final String sensorId;
  final DateTime timestamp;
  final bool isRead;
  final double? estimatedCost;
  final String? affectedContent;
  final String? suggestedAction;
  final List<String> channels; // Nuevo campo: ['PUSH', 'SMS', 'EMAIL']

  Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
    required this.sensorId,
    required this.timestamp,
    this.isRead = false,
    this.estimatedCost,
    this.affectedContent,
    this.suggestedAction,
    this.channels = const [],
  });

  // Obtiene el emoji según categoría
  String get emoji {
    switch (category) {
      case AlertCategory.HOT_TEMP:
        return '🔥';
      case AlertCategory.COLD_TEMP:
        return '❄️';
      case AlertCategory.RAPID_CHANGE:
        return '📉';
      case AlertCategory.SENSOR_OFFLINE:
        return '📡';
    }
  }

  // Obtiene el color según severidad
  String get colorHex {
    switch (severity) {
      case AlertSeverity.CRITICAL:
        return '#e74c3c'; // Rojo
      case AlertSeverity.WARNING:
        return '#f39c12'; // Naranja
    }
  }

  // Obtiene la etiqueta de severidad
  String get severityLabel {
    switch (severity) {
      case AlertSeverity.CRITICAL:
        return 'CRÍTICO';
      case AlertSeverity.WARNING:
        return 'ADVERTENCIA';
    }
  }

  // Formatea timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }

  // Determina si es crítica
  bool get isCritical => severity == AlertSeverity.CRITICAL;

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: _parseSeverity(json['severity'] as String?),
      category: _parseCategory(json['category'] as String?),
      sensorId: json['sensor_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      affectedContent: json['affected_content'] as String?,
      suggestedAction: json['suggested_action'] as String?,
      channels: json['channels'] != null 
          ? List<String>.from(json['channels']) 
          : [],
    );
  }

  static AlertSeverity _parseSeverity(String? value) {
    if (value == 'CRITICAL') return AlertSeverity.CRITICAL;
    return AlertSeverity.WARNING;
  }

  static AlertCategory _parseCategory(String? value) {
    switch (value) {
      case 'HOT_TEMP': return AlertCategory.HOT_TEMP;
      case 'COLD_TEMP': return AlertCategory.COLD_TEMP;
      case 'RAPID_CHANGE': return AlertCategory.RAPID_CHANGE;
      case 'SENSOR_OFFLINE': return AlertCategory.SENSOR_OFFLINE;
      default: return AlertCategory.HOT_TEMP;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'severity': severity == AlertSeverity.CRITICAL ? 'CRITICAL' : 'WARNING',
        'category': category.toString().split('.').last,
        'sensor_id': sensorId,
        'timestamp': timestamp.toIso8601String(),
        'is_read': isRead,
        'estimated_cost': estimatedCost,
        'affected_content': affectedContent,
        'suggested_action': suggestedAction,
        'channels': channels,
      };

  Alert copyWith({
    String? id,
    String? title,
    String? description,
    AlertSeverity? severity,
    AlertCategory? category,
    String? sensorId,
    DateTime? timestamp,
    bool? isRead,
    double? estimatedCost,
    String? affectedContent,
    String? suggestedAction,
    List<String>? channels,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      sensorId: sensorId ?? this.sensorId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      affectedContent: affectedContent ?? this.affectedContent,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      channels: channels ?? this.channels,
    );
  }
}
