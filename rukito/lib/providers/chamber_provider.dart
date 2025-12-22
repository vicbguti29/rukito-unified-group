import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class ChamberProvider extends ChangeNotifier {
  final IApiService _apiService;

  List<ColdChamber> _chambers = [];
  bool _isLoading = false;
  String? _error;

  ChamberProvider({required IApiService apiService}) : _apiService = apiService;

  // ==================== GETTERS ====================

  List<ColdChamber> get chambers => _chambers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ColdChamber? getChamberById(String id) {
    try {
      return _chambers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  int get activeChamberCount => _chambers.where((c) => c.isActive).length;

  double get averageTemperature {
    if (_chambers.isEmpty) return 0;
    final sum = _chambers.fold<double>(
      0,
      (prev, chamber) => prev + chamber.currentTemperature,
    );
    return sum / _chambers.length;
  }

  int get criticalChamberCount =>
      _chambers.where((c) => c.currentTemperature > c.criticalThreshold).length;

  int get warningChamberCount =>
      _chambers.where((c) => c.currentTemperature > c.warningThreshold).length;

  // ==================== MÉTODOS ====================

  /// Carga todas las cámaras desde la API
  Future<void> loadChambers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chambers = await _apiService.getColdChambers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recarga una cámara específica
  Future<void> refreshChamber(String chamberId) async {
    try {
      final updated = await _apiService.getColdChamber(chamberId);
      final index = _chambers.indexWhere((c) => c.id == chamberId);
      if (index != -1) {
        _chambers[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Actualiza una cámara en la lista local
  void updateChamber(ColdChamber chamber) {
    final index = _chambers.indexWhere((c) => c.id == chamber.id);
    if (index != -1) {
      _chambers[index] = chamber;
      notifyListeners();
    }
  }

  /// Limpia el error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
