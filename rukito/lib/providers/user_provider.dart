import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class UserProvider extends ChangeNotifier {
  final IApiService _apiService;

  UserProfile? _user;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  UserProvider({required IApiService apiService}) : _apiService = apiService;

  // Getters
  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  /// Carga el perfil del usuario
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _apiService.getUserProfile();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza el perfil del usuario
  Future<bool> updateProfile(UserProfile updatedUser) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _apiService.updateUserProfile(updatedUser);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpia los errores
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
