import 'package:intl/intl.dart';

enum AlertPriority { p1, p2, p3 }

enum AlertType {
  temperatureCritical,
  temperatureWarning,
  doorOpen,
  powerFailure,
  maintenanceRequired,
  normalOperation,
  smsNotification,
}

class Alert {
  final String id;
  final String title;
  final String description;
  final AlertPriority priority;
  final AlertType type;
  final String sensorId;
  final DateTime timestamp;
  final bool isRead;
  final double? estimatedCost;
  final String? affectedContent;
  final String? suggestedAction;

  Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.type,
    required this.sensorId,
    required this.timestamp,
    this.isRead = false,
    this.estimatedCost,
    this.affectedContent,
    this.suggestedAction,
  });

  // Obtiene el emoji según tipo
  String get emoji {
    switch (type) {
      case AlertType.temperatureCritical:
        return '🚨';
      case AlertType.temperatureWarning:
        return '⚠️';
      case AlertType.doorOpen:
        return '🚪';
      case AlertType.powerFailure:
        return '⚡';
      case AlertType.maintenanceRequired:
        return '🔧';
      case AlertType.normalOperation:
        return 'ℹ️';
      case AlertType.smsNotification:
        return '📢';
    }
  }

  // Obtiene el color según prioridad
  String get colorHex {
    switch (priority) {
      case AlertPriority.p1:
        return '#e74c3c'; // Rojo
      case AlertPriority.p2:
        return '#f39c12'; // Naranja
      case AlertPriority.p3:
        return '#3498db'; // Azul
    }
  }

  // Obtiene la etiqueta de prioridad
  String get priorityLabel {
    switch (priority) {
      case AlertPriority.p1:
        return 'P1';
      case AlertPriority.p2:
        return 'P2';
      case AlertPriority.p3:
        return 'P3';
    }
  }

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

  // Determina si debe reproducir sonido
  bool get shouldPlaySound => priority == AlertPriority.p1;

  // Determina si debe animar (pulsación)
  bool get shouldAnimate => priority == AlertPriority.p1;

  // Determina si es crítica
  bool get isCritical => priority == AlertPriority.p1;

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: AlertPriority.values[json['priority'] as int],
      type: AlertType.values[json['type'] as int],
      sensorId: json['sensor_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble(),
      affectedContent: json['affected_content'] as String?,
      suggestedAction: json['suggested_action'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.index,
        'type': type.index,
        'sensor_id': sensorId,
        'timestamp': timestamp.toIso8601String(),
        'is_read': isRead,
        'estimated_cost': estimatedCost,
        'affected_content': affectedContent,
        'suggested_action': suggestedAction,
      };

  Alert copyWith({
    String? id,
    String? title,
    String? description,
    AlertPriority? priority,
    AlertType? type,
    String? sensorId,
    DateTime? timestamp,
    bool? isRead,
    double? estimatedCost,
    String? affectedContent,
    String? suggestedAction,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      sensorId: sensorId ?? this.sensorId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      affectedContent: affectedContent ?? this.affectedContent,
      suggestedAction: suggestedAction ?? this.suggestedAction,
    );
  }
}
