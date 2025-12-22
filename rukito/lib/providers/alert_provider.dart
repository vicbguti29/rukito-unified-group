import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class AlertProvider extends ChangeNotifier {
  final IApiService _apiService;

  List<Alert> _alerts = [];
  List<Alert> _unreadAlerts = [];
  bool _isLoading = false;
  String? _error;

  AlertProvider({required IApiService apiService}) : _apiService = apiService;

  // ==================== GETTERS ====================

  List<Alert> get alerts => _alerts;
  List<Alert> get unreadAlerts => _unreadAlerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalAlerts => _alerts.length;
  int get unreadCount => _unreadAlerts.length;

  List<Alert> get criticalAlerts =>
      _alerts.where((a) => a.isCritical).toList();

  List<Alert> get sortedAlerts {
    final sorted = [..._alerts];
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  // ==================== MÉTODOS ====================

  /// Carga todas las alertas desde la API
  Future<void> loadAlerts({bool unreadOnly = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _apiService.getAlerts(unreadOnly: unreadOnly);
      _unreadAlerts = _alerts.where((a) => !a.isRead).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga alertas de una cámara específica
  Future<void> loadChamberAlerts(String chamberId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _apiService.getChamberAlerts(chamberId);
      _unreadAlerts = _alerts.where((a) => !a.isRead).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marca una alerta como leída
  Future<void> markAsRead(String alertId) async {
    try {
      await _apiService.markAlertAsRead(alertId);
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isRead: true);
        _unreadAlerts.removeWhere((a) => a.id == alertId);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Marca todas las alertas como leídas
  Future<void> markAllAsRead() async {
    try {
      for (final alert in _unreadAlerts) {
        await _apiService.markAlertAsRead(alert.id);
      }
      _alerts = _alerts.map((a) => a.copyWith(isRead: true)).toList();
      _unreadAlerts.clear();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Agrega una nueva alerta a la lista
  void addAlert(Alert alert) {
    _alerts.insert(0, alert);
    if (!alert.isRead) {
      _unreadAlerts.insert(0, alert);
    }
    notifyListeners();
  }

  /// Limpia el error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
