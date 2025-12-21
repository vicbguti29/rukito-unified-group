/// Configuración centralizada de la aplicación
class AppConfig {
  // ==================== API Configuration ====================

  /// URL base del servidor backend
  /// Cambiar según el entorno (desarrollo, staging, producción)
  static const String apiBaseUrl = 'http://localhost:8080/api';

  /// Timeout para peticiones HTTP (en segundos)
  static const int apiTimeout = 10;

  /// Habilitar logs de API (debug)
  static const bool enableApiLogging = true;

  // ==================== App Configuration ====================

  /// Nombre de la aplicación
  static const String appName = 'Rukito';

  /// Versión de la aplicación
  static const String appVersion = '1.0.0';

  /// Modo debug
  static const bool debugMode = true;

  // ==================== UI Configuration ====================

  /// Intervalo de refresco automático del dashboard (en segundos)
  static const int dashboardRefreshInterval = 30;

  /// Duración de animaciones (en milisegundos)
  static const int animationDuration = 300;

  /// Tamaño máximo de lista antes de paginar
  static const int pageSize = 50;

  // ==================== Feature Flags ====================

  /// Habilitar WebSocket en tiempo real
  static const bool enableRealtimeUpdates = false;

  /// Habilitar notificaciones push
  static const bool enablePushNotifications = false;

  /// Habilitar análisis offline
  static const bool enableOfflineMode = false;

  // ==================== Métodos de configuración ====================

  /// Obtiene la URL completa de un endpoint
  static String getEndpoint(String path) {
    return '$apiBaseUrl$path';
  }

  /// Obtiene la configuración para el entorno actual
  static Map<String, dynamic> toMap() {
    return {
      'apiBaseUrl': apiBaseUrl,
      'apiTimeout': apiTimeout,
      'appName': appName,
      'appVersion': appVersion,
      'debugMode': debugMode,
      'dashboardRefreshInterval': dashboardRefreshInterval,
      'enableRealtimeUpdates': enableRealtimeUpdates,
      'enablePushNotifications': enablePushNotifications,
      'enableOfflineMode': enableOfflineMode,
    };
  }
}

/// Configuración por entorno
class EnvironmentConfig {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  /// Obtiene la configuración según el entorno
  static String getEnvironment() {
    // Cambiar a 'production' para despliegue final
    return development;
  }

  /// URLs por entorno
  static String getApiUrl(String environment) {
    switch (environment) {
      case staging:
        return 'http://staging-api.rukito.local:8080/api';
      case production:
        return 'https://api.rukito.com/api';
      case development:
      default:
        return 'http://localhost:8080/api';
    }
  }
}
