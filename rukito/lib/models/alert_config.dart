enum AlertPriorityLevel { low, medium, high }

class AlertThresholds {
  final double criticalCold;
  final double target;
  final double warningHot;
  final double criticalHot;
  final double rateOfChange;

  AlertThresholds({
    required this.criticalCold,
    required this.target,
    required this.warningHot,
    required this.criticalHot,
    required this.rateOfChange,
  });

  factory AlertThresholds.fromJson(Map<String, dynamic> json) {
    return AlertThresholds(
      criticalCold: (json['critical_cold'] as num).toDouble(),
      target: (json['target'] as num).toDouble(),
      warningHot: (json['warning_hot'] as num).toDouble(),
      criticalHot: (json['critical_hot'] as num).toDouble(),
      rateOfChange: (json['rate_of_change'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'critical_cold': criticalCold,
        'target': target,
        'warning_hot': warningHot,
        'critical_hot': criticalHot,
        'rate_of_change': rateOfChange,
      };

  AlertThresholds copyWith({
    double? criticalCold,
    double? target,
    double? warningHot,
    double? criticalHot,
    double? rateOfChange,
  }) {
    return AlertThresholds(
      criticalCold: criticalCold ?? this.criticalCold,
      target: target ?? this.target,
      warningHot: warningHot ?? this.warningHot,
      criticalHot: criticalHot ?? this.criticalHot,
      rateOfChange: rateOfChange ?? this.rateOfChange,
    );
  }
}

class NotificationAction {
  final List<String> channels;
  final List<String> targetRoles;

  NotificationAction({
    required this.channels,
    required this.targetRoles,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      channels: List<String>.from(json['channels'] ?? []),
      targetRoles: List<String>.from(json['target_roles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'channels': channels,
        'target_roles': targetRoles,
      };

  NotificationAction copyWith({
    List<String>? channels,
    List<String>? targetRoles,
  }) {
    return NotificationAction(
      channels: channels ?? this.channels,
      targetRoles: targetRoles ?? this.targetRoles,
    );
  }
}

class NotificationConfig {
  final NotificationAction onWarningHot;
  final NotificationAction onCriticalHot;
  final NotificationAction onCriticalCold;

  NotificationConfig({
    required this.onWarningHot,
    required this.onCriticalHot,
    required this.onCriticalCold,
  });

  factory NotificationConfig.fromJson(Map<String, dynamic> json) {
    return NotificationConfig(
      onWarningHot: NotificationAction.fromJson(json['on_warning_hot'] ?? {}),
      onCriticalHot: NotificationAction.fromJson(json['on_critical_hot'] ?? {}),
      onCriticalCold: NotificationAction.fromJson(json['on_critical_cold'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'on_warning_hot': onWarningHot.toJson(),
        'on_critical_hot': onCriticalHot.toJson(),
        'on_critical_cold': onCriticalCold.toJson(),
      };
      
  NotificationConfig copyWith({
    NotificationAction? onWarningHot,
    NotificationAction? onCriticalHot,
    NotificationAction? onCriticalCold,
  }) {
    return NotificationConfig(
      onWarningHot: onWarningHot ?? this.onWarningHot,
      onCriticalHot: onCriticalHot ?? this.onCriticalHot,
      onCriticalCold: onCriticalCold ?? this.onCriticalCold,
    );
  }
}

class AlertConfig {
  final String? id; // Opcional, ya que a veces viene solo sensor_id
  final String sensorId;
  final AlertThresholds thresholds;
  final NotificationConfig notifications;
  final bool isEnabled;
  final DateTime updatedAt;

  // Constructor
  AlertConfig({
    this.id,
    required this.sensorId,
    required this.thresholds,
    required this.notifications,
    required this.isEnabled,
    required this.updatedAt,
  });

  // Deprecated Getters para compatibilidad temporal (Legacy Support)
  @Deprecated('Use thresholds.criticalHot')
  double get maxTemperature => thresholds.criticalHot;
  
  @Deprecated('Use thresholds.criticalCold')
  double get minTemperature => thresholds.criticalCold;
  
  @Deprecated('Use thresholds.rateOfChange')
  double get rateOfChangeThreshold => thresholds.rateOfChange;
  
  @Deprecated('Use notifications.onCriticalHot.channels')
  List<String> get notificationChannels => notifications.onCriticalHot.channels;

  @Deprecated('Use notifications.onCriticalHot.targetRoles')
  List<String> get recipients => notifications.onCriticalHot.targetRoles;


  factory AlertConfig.fromJson(Map<String, dynamic> json) {
    return AlertConfig(
      id: json['id'] as String?,
      sensorId: json['sensor_id'] as String,
      thresholds: AlertThresholds.fromJson(json['thresholds'] ?? {}),
      notifications: NotificationConfig.fromJson(json['notifications'] ?? {}),
      isEnabled: json['is_enabled'] as bool? ?? true,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'sensor_id': sensorId,
        'thresholds': thresholds.toJson(),
        'notifications': notifications.toJson(),
        'is_enabled': isEnabled,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  AlertConfig copyWith({
    String? id,
    String? sensorId,
    AlertThresholds? thresholds,
    NotificationConfig? notifications,
    bool? isEnabled,
    DateTime? updatedAt,
  }) {
    return AlertConfig(
      id: id ?? this.id,
      sensorId: sensorId ?? this.sensorId,
      thresholds: thresholds ?? this.thresholds,
      notifications: notifications ?? this.notifications,
      isEnabled: isEnabled ?? this.isEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
