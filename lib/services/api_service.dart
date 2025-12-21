import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/index.dart';
import 'api_interface.dart';

class ApiService implements IApiService {
  static final String _baseUrl = AppConfig.apiBaseUrl;
  static final Duration _timeout = Duration(seconds: AppConfig.apiTimeout);

  final http.Client _httpClient;

  ApiService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  // ==================== CÁMARAS FRIGORÍFICAS ====================

  /// Obtiene todas las cámaras frigoríficas activas
  Future<List<ColdChamber>> getColdChambers() async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/chambers'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ColdChamber.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener cámaras: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en getColdChambers: $e');
    }
  }

  /// Obtiene una cámara específica por ID
  Future<ColdChamber> getColdChamber(String chamberId) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/chambers/$chamberId'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ColdChamber.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener cámara: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en getColdChamber: $e');
    }
  }

  // ==================== LECTURAS DE TEMPERATURA ====================

  /// Obtiene las lecturas recientes de una cámara
  Future<List<TemperatureReading>> getTemperatureReadings(
    String chamberId, {
    int limit = 100,
  }) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/readings/$chamberId?limit=$limit'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => TemperatureReading.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener lecturas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en getTemperatureReadings: $e');
    }
  }

  /// Obtiene histórico de temperatura para un rango de fechas
  Future<List<TemperatureReading>> getTemperatureHistory(
    String chamberId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse(
              '$_baseUrl/readings/$chamberId/history'
              '?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}',
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => TemperatureReading.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener histórico: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en getTemperatureHistory: $e');
    }
  }

  // ==================== ALERTAS ====================

  /// Obtiene todas las alertas activas
  Future<List<Alert>> getAlerts({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/alerts?limit=$limit&unread_only=$unreadOnly'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Alert.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener alertas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en getAlerts: $e');
    }
  }

  /// Obtiene alertas de una cámara específica
  Future<List<Alert>> getChamberAlerts(String chamberId) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/alerts/chamber/$chamberId'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Alert.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener alertas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en getChamberAlerts: $e');
    }
  }

  /// Marca una alerta como leída
  Future<void> markAlertAsRead(String alertId) async {
    try {
      final response = await _httpClient
          .patch(
            Uri.parse('$_baseUrl/alerts/$alertId/read'),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception('Error al marcar alerta como leída: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en markAlertAsRead: $e');
    }
  }

  // ==================== CONFIGURACIÓN DE ALERTAS ====================

  /// Obtiene la configuración de alertas de una cámara
  Future<AlertConfig> getAlertConfig(String chamberId) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/config/alerts/$chamberId'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return AlertConfig.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener configuración: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en getAlertConfig: $e');
    }
  }

  /// Actualiza la configuración de alertas
  Future<AlertConfig> updateAlertConfig(
    String chamberId,
    AlertConfig config,
  ) async {
    try {
      final response = await _httpClient
          .put(
            Uri.parse('$_baseUrl/config/alerts/$chamberId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(config.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return AlertConfig.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al actualizar configuración: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en updateAlertConfig: $e');
    }
  }

  // ==================== REPORTES Y ANÁLISIS ====================

  /// Obtiene reportes de análisis
  Future<Map<String, dynamic>> getReport({
    required String chamberId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse(
              '$_baseUrl/reports/$chamberId'
              '?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}',
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al obtener reporte: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en getReport: $e');
    }
  }

  /// Obtiene estadísticas generales
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/statistics'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al obtener estadísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en getStatistics: $e');
    }
  }

  // ==================== HEALTH CHECK ====================

  /// Verifica la disponibilidad del servidor
  Future<bool> healthCheck() async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/health'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
