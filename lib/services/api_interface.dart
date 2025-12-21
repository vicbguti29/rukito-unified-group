import '../models/index.dart';

abstract class IApiService {
  Future<List<ColdChamber>> getColdChambers();
  Future<ColdChamber> getColdChamber(String chamberId);
  Future<List<TemperatureReading>> getTemperatureReadings(
    String chamberId, {
    int limit = 100,
  });
  Future<List<TemperatureReading>> getTemperatureHistory(
    String chamberId, {
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<List<Alert>> getAlerts({
    int limit = 50,
    bool unreadOnly = false,
  });
  Future<List<Alert>> getChamberAlerts(String chamberId);
  Future<void> markAlertAsRead(String alertId);
  Future<AlertConfig> getAlertConfig(String chamberId);
  Future<AlertConfig> updateAlertConfig(String chamberId, AlertConfig config);
  Future<Map<String, dynamic>> getReport({
    required String chamberId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<Map<String, dynamic>> getStatistics();
  Future<bool> healthCheck();
}
