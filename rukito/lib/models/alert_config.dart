enum AlertPriorityLevel { low, medium, high }

class AlertConfig {
  final String id;
  final String sensorId;
  final double maxTemperature;
  final double minTemperature;
  final double rateOfChangeThreshold;
  final int priority; // 1: Low, 2: Medium, 3: High
  final bool isEnabled;
  final List<String> notificationChannels; // ["sms", "push", "email"]
  final List<String> recipients;
  final DateTime createdAt;
  final DateTime updatedAt;

  AlertConfig({
    required this.id,
    required this.sensorId,
    required this.maxTemperature,
    required this.minTemperature,
    required this.rateOfChangeThreshold,
    required this.priority,
    required this.isEnabled,
    required this.notificationChannels,
    required this.recipients,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helpers para UI
  AlertPriorityLevel get priorityLevel {
    switch (priority) {
      case 1: return AlertPriorityLevel.low;
      case 2: return AlertPriorityLevel.medium;
      case 3: return AlertPriorityLevel.high;
      default: return AlertPriorityLevel.medium;
    }
  }

  factory AlertConfig.fromJson(Map<String, dynamic> json) {
    return AlertConfig(
      id: json['id'] as String,
      sensorId: json['sensor_id'] as String,
      maxTemperature: (json['max_temperature'] as num).toDouble(),
      minTemperature: (json['min_temperature'] as num).toDouble(),
      rateOfChangeThreshold: (json['rate_of_change_threshold'] as num).toDouble(),
      priority: json['priority'] as int,
      isEnabled: json['is_enabled'] as bool,
      notificationChannels: List<String>.from(json['notification_channels'] ?? []),
      recipients: List<String>.from(json['recipients'] ?? []),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sensor_id': sensorId,
        'max_temperature': maxTemperature,
        'min_temperature': minTemperature,
        'rate_of_change_threshold': rateOfChangeThreshold,
        'priority': priority,
        'is_enabled': isEnabled,
        'notification_channels': notificationChannels,
        'recipients': recipients,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  AlertConfig copyWith({
    String? id,
    String? sensorId,
    double? maxTemperature,
    double? minTemperature,
    double? rateOfChangeThreshold,
    int? priority,
    bool? isEnabled,
    List<String>? notificationChannels,
    List<String>? recipients,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlertConfig(
      id: id ?? this.id,
      sensorId: sensorId ?? this.sensorId,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      minTemperature: minTemperature ?? this.minTemperature,
      rateOfChangeThreshold: rateOfChangeThreshold ?? this.rateOfChangeThreshold,
      priority: priority ?? this.priority,
      isEnabled: isEnabled ?? this.isEnabled,
      notificationChannels: notificationChannels ?? this.notificationChannels,
      recipients: recipients ?? this.recipients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}