// lib/src/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;
  late final AuthService authService;

  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  AuthProvider(this.api) {
    try {
      authService = AuthService(api);
      _loadFromPrefs();
    } catch (e) {
      debugPrint('AuthProvider initialization error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // public getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String get userId => _user?['_id']?.toString() ?? _user?['id']?.toString() ?? '';
  Map<String, dynamic>? get user => _user;

  /// Returns the first available parent phone number if present in saved user object.
  /// This is best-effort: it supports structures like:
  ///  - user['parents'] = [{ phone: '+911234' }, ...]
  ///  - user['parents'] = ['parentId', ...] -> can't derive phone
  ///  - user['parentPhone'] = '+91...'
  ///  - user['parentsPhones'] = ['+91...', ...]
  String? get parentPhone {
    final user = _user;
    if (user == null) return null;

    // Case: explicit parentPhone
    if (user['parentPhone'] != null && user['parentPhone'].toString().isNotEmpty) {
      return user['parentPhone'].toString();
    }

    // Case: list of parent phones
    if (user['parentsPhones'] is List && (user['parentsPhones'] as List).isNotEmpty) {
      final p = (user['parentsPhones'] as List).first;
      if (p != null) return p.toString();
    }

    // Case: parents as array of objects (populated from backend)
    if (user['parents'] is List && (user['parents'] as List).isNotEmpty) {
      final first = (user['parents'] as List).first;
      if (first is Map && first['phone'] != null) {
        return first['phone'].toString();
      }
      // if first is string (id), we can't extract phone without API call
    }

    return null;
  }
  
  /// Returns the name of the first parent if available
  String? get parentName {
    final user = _user;
    if (user == null) return null;
    
    // Case: parents as array of objects (populated from backend)
    if (user['parents'] is List && (user['parents'] as List).isNotEmpty) {
      final first = (user['parents'] as List).first;
      if (first is Map && first['name'] != null) return first['name'].toString();
    }
    
    // Case: parentName field
    if (user['parentName'] != null && user['parentName'].toString().isNotEmpty) {
      return user['parentName'].toString();
    }
    
    return null;
  }

  /// Returns true if user has connected parents
  bool get hasConnectedParents {
    final user = _user;
    if (user == null) return false;
    
    // Check if parents array exists and is not empty
    if (user['parents'] is List) {
      final parents = user['parents'] as List;
      return parents.isNotEmpty;
    }
    
    return false;
  }

  Future<void> _loadFromPrefs() async {
    try {
      debugPrint('AuthProvider: Loading preferences...');
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUser = prefs.getString('auth_user');

      debugPrint('AuthProvider: Token exists: ${savedToken != null}');
      
      if (savedToken != null) {
        _token = savedToken;
        api.setAuthToken(_token!);
        if (savedUser != null) {
          try {
            // decode into Map<String, dynamic>
            final decoded = jsonDecode(savedUser);
            if (decoded is Map<String, dynamic>) {
              _user = decoded;
            } else {
              // handle if user was saved as list/object differently
              _user = Map<String, dynamic>.from(decoded);
            }
            debugPrint('AuthProvider: User loaded successfully');
          } catch (e) {
            debugPrint('AuthProvider: Failed to decode user data: $e');
            _user = null;
          }
        }
      }
    } catch (e) {
      debugPrint('AuthProvider: failed to load prefs: $e');
    } finally {
      _isLoading = false;
      debugPrint('AuthProvider: Loading complete. IsLoggedIn: $isLoggedIn');
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
        debugPrint('AuthProvider: Token saved to preferences');
      } else {
        await prefs.remove('auth_token');
        debugPrint('AuthProvider: Token removed from preferences');
      }
      
      if (_user != null) {
        await prefs.setString('auth_user', jsonEncode(_user));
        debugPrint('AuthProvider: User data saved to preferences');
      } else {
        await prefs.remove('auth_user');
        debugPrint('AuthProvider: User data removed from preferences');
      }
    } catch (e) {
      debugPrint('AuthProvider: Failed to save to preferences: $e');
    }
  }

  // Auth methods
  Future<void> sendOtp(String phone) async {
    await authService.sendOtp(phone);
  }

  Future<void> verifyOtp(String phone, String code) async {
    final res = await authService.verifyOtp(phone, code);
    _token = res['token']?.toString();
    final u = res['user'];
    if (u is Map) {
      _user = Map<String, dynamic>.from(u);
    } else {
      _user = null;
    }
    if (_token != null) api.setAuthToken(_token!);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> register(String name, String phone, String password, String role) async {
    final res = await authService.register(name, phone, password, role);
    _token = res['token']?.toString();
    final u = res['user'];
    if (u is Map) {
      _user = Map<String, dynamic>.from(u);
    } else {
      _user = null;
    }
    if (_token != null) api.setAuthToken(_token!);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    final res = await authService.login(phone, password);
    _token = res['token']?.toString();
    final u = res['user'];
    if (u is Map) {
      _user = Map<String, dynamic>.from(u);
    } else {
      _user = null;
    }
    if (_token != null) api.setAuthToken(_token!);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final data = await api.getUserProfile();
      if (data.isNotEmpty) {
        _user = Map<String, dynamic>.from(data);
        await _saveToPrefs();
        notifyListeners();
      }
    } catch (e) {
      // If profile refresh fails, keep existing user data from login
      debugPrint('Profile refresh failed, using existing user data: $e');
      // Don't throw error, just use existing data
    }
  }

  Future<void> updateProfile(String name) async {
    try {
      await api.updateUserProfile({'name': name});
      await refreshProfile();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    api.clearAuthToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    notifyListeners();
  }
}
