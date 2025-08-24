import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService {
  final ApiService api;

  AuthService(this.api);

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await api.post('/api/auth/otp/send', {'phone': phone});
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>? ?? {};
      } else {
        throw Exception('Failed to send OTP: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server is taking too long to respond. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please check your internet connection.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Send OTP error: $e');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    try {
      final response = await api.post('/api/auth/otp/verify', {
        'phone': phone,
        'code': code,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>? ?? {};
      } else {
        throw Exception('Failed to verify OTP: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server is taking too long to respond. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please check your internet connection.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Verify OTP error: $e');
    }
  }

  Future<Map<String, dynamic>> register(String name, String phone, String password, String role) async {
    try {
      final response = await api.post('/api/auth/register', {
        'name': name,
        'phone': phone,
        'password': password,
        'role': role,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>? ?? {};
      } else {
        throw Exception('Failed to register: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server is taking too long to respond. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please check your internet connection.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Register error: $e');
    }
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await api.post('/api/auth/login', {
        'phone': phone,
        'password': password,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>? ?? {};
      } else {
        throw Exception('Failed to login: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server is taking too long to respond. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Unable to connect to server. Please check your internet connection.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }
}
