
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final String baseUrl;
  final Dio _dio;

  // OpenRoute API key for routing calls
  final String openRouteApiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjYwZGFkNTMwNzc3YzRmNTlhMDU4YmI2MjI3MTk5Yzk2IiwiaCI6Im11cm11cjY0In0=';

  ApiService({required this.baseUrl})
      : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    // Add interceptors for better error handling and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('🚀 REQUEST: ${options.method} ${options.path}');
          debugPrint('📤 DATA: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
              '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('❌ ERROR: ${error.message}');
          debugPrint('📍 PATH: ${error.requestOptions.path}');
          if (error.response != null) {
            debugPrint('📄 RESPONSE DATA: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  // Auth token management
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    debugPrint('🔑 Auth token set');
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
    debugPrint('🔓 Auth token cleared');
  }

  // Generic HTTP methods with error handling and retry
  Future<Response> post(String path, Map<String, dynamic> data,
      {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      try {
        return await _dio.post(path, data: data);
      } on DioException catch (e) {
        if (i == retries || !_shouldRetry(e)) {
          throw _handleDioError(e);
        }
        await Future.delayed(
            Duration(seconds: (i + 1) * 2)); // Exponential backoff
      } catch (e) {
        if (i == retries) {
          throw Exception('Network error: $e');
        }
        await Future.delayed(Duration(seconds: (i + 1) * 2));
      }
    }
    throw Exception('Max retries exceeded');
  }

  Future<Response> get(String path,
      [Map<String, dynamic>? params, int retries = 2]) async {
    for (int i = 0; i <= retries; i++) {
      try {
        return await _dio.get(path, queryParameters: params);
      } on DioException catch (e) {
        if (i == retries || !_shouldRetry(e)) {
          throw _handleDioError(e);
        }
        await Future.delayed(Duration(seconds: (i + 1) * 2));
      } catch (e) {
        if (i == retries) {
          throw Exception('Network error: $e');
        }
        await Future.delayed(Duration(seconds: (i + 1) * 2));
      }
    }
    throw Exception('Max retries exceeded');
  }

  Future<Response> put(String path, Map<String, dynamic> data) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await post('/api/auth/otp/send', {'phone': phone});
    return _extractData(response);
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String code) async {
    final response = await post('/api/auth/otp/verify', {
      'phone': phone,
      'code': code,
    });
    return _extractData(response);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await post('/api/auth/register', {
      'name': name,
      'phone': phone,
      'password': password,
      'role': role,
    });
    return _extractData(response);
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await post('/api/auth/login', {
      'phone': phone,
      'password': password,
    });
    return _extractData(response);
  }

  // User profile endpoints
  Future<Map<String, dynamic>> getUserProfile([String? userId]) async {
    try {
      // Use provided userId or get from auth provider context
      final id = userId ?? 'me'; // Backend should handle 'me' as current user
      final response = await get('/api/user/profile/$id');
      return _extractData(response);
    } catch (e) {
      // If profile endpoint fails, throw the error so auth provider can handle it
      debugPrint('Profile endpoint not available: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> data) async {
    final response = await post('/api/user/profile', data);
    return _extractData(response);
  }

  // Connection management endpoints
  Future<Map<String, dynamic>> requestConnectToChild(
      String childPhone, String message) async {
    try {
      // Backend expects user ID in URL path
      debugPrint(
          '🔗 Calling connection endpoint: /api/user/request-connect/me');
      final response = await post('/api/user/request-connect/me', {
        'childPhone': childPhone,
        'message': message,
      });
      return _extractData(response);
    } catch (e) {
      // Handle connection request endpoint not available
      debugPrint('Connection request endpoint not available: $e');
      throw Exception(
          'Connection request feature is not available at the moment. Please try again later.');
    }
  }

  Future<List<dynamic>> getConnectionRequests([String? userId]) async {
    try {
      // Backend route requires ID parameter: /api/user/requests/:id
      final id = userId ?? 'me'; // Use 'me' for current user or specific userId
      final response = await get('/api/user/requests/$id');

      // Backend returns array directly, not wrapped in an object
      if (response.data is List) {
        debugPrint('📥 Direct array response: ${response.data}');
        return response.data as List<dynamic>;
      }

      // Fallback: if wrapped in an object, extract it
      final data = _extractData(response);

      // Try different possible keys for the requests array
      final requests = data['requests'];
      if (requests is List) return requests;

      final dataList = data['data'];
      if (dataList is List) return dataList;

      // If it's a single request wrapped in an object
      if (data.containsKey('_id')) {
        return [data];
      }

      return [];
    } catch (e) {
      // Return empty list if endpoint is not available
      debugPrint('Connection requests endpoint not available: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> respondToConnectionRequest(
      String requestId, String action) async {
    try {
      final response = await post('/api/user/requests/$requestId/respond', {
        'action': action,
      });
      return _extractData(response);
    } catch (e) {
      debugPrint('Connection response endpoint not available: $e');
      throw Exception(
          'Unable to respond to connection request. Please try again later.');
    }
  }

  Future<Map<String, dynamic>> disconnectParentFromChild(String childId) async {
    try {
      // Backend expects user ID in URL path, send childId in body
      final response = await post('/api/user/disconnect-parent/me', {
        'childId': childId,
      });
      return _extractData(response);
    } catch (e) {
      debugPrint('Disconnect parent endpoint not available: $e');
      throw Exception('Unable to disconnect parent. Please try again later.');
    }
  }

  // Location endpoints
  Future<Map<String, dynamic>> updateLocation({
    required double lat,
    required double lng,
    double? speed,
    double? accuracy,
    String? timestamp,
  }) async {
    try {
      // Backend route requires user ID: /api/location/update/:id
      // Use 'me' as the ID to represent current user
      debugPrint('📤 Updating location: lat=$lat, lng=$lng, speed=$speed, accuracy=$accuracy');
      final response = await post('/api/location/update/me', {
        'lat': lat,
        'lng': lng,
        if (speed != null) 'speed': speed,
        if (accuracy != null) 'accuracy': accuracy,
        'timestamp': timestamp ?? DateTime.now().toIso8601String(),
      });
      final data = _extractData(response);
      debugPrint('✅ Location update response: $data');
      return data;
    } catch (e) {
      debugPrint('❌ Location update failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLatestLocation(String userId) async {
    try {
      debugPrint('🔍 Fetching location for user: $userId');
      final response = await get('/api/location/$userId');
      final data = _extractData(response);
      debugPrint('📍 Location response for $userId: $data');
      return data;
    } catch (e) {
      debugPrint('❌ Error fetching location for $userId: $e');
      rethrow;
    }
  }

  // SOS endpoints
  Future<Map<String, dynamic>> sendSosMultipart({
    required double lat,
    required double lng,
    required String userId,
    String? message,
  }) async {
    try {
      final form = FormData();

      // Add location data
      form.fields.addAll([
        MapEntry('lat', lat.toString()),
        MapEntry('lng', lng.toString()),
      ]);

      // Add message if provided
      if (message != null && message.isNotEmpty) {
        form.fields.add(MapEntry('message', message));
      }

      // No audio file handling

      // Updated to match backend route which requires user ID in the path
      final response = await _dio.post('/api/sos/send/${userId}', data: form);
      return _extractData(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('SOS send error: $e');
    }
  }

  Future<Map<String, dynamic>> getSosDetails(String sosId) async {
    final response = await get('/api/sos/$sosId');
    return _extractData(response);
  }

  Future<List<dynamic>> getSosHistory(String userId) async {
    final response = await get('/api/user/sos-history/$userId');

    // Handle response data directly since it might be a List
    final responseData = response.data;

    if (responseData is List) {
      return responseData;
    } else if (responseData is Map<String, dynamic>) {
      // Try different possible keys for the SOS alerts array
      final sosAlerts = responseData['sosAlerts'];
      if (sosAlerts is List) return sosAlerts;

      final dataList = responseData['data'];
      if (dataList is List) return dataList;

      final alerts = responseData['alerts'];
      if (alerts is List) return alerts;

      final history = responseData['history'];
      if (history is List) return history;
    }

    return [];
  }

  // OpenRoute Service for directions
  Future<Map<String, dynamic>> getDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final directionsUrl =
          'https://api.openrouteservice.org/v2/directions/driving-car';
      final directionsResponse = await Dio().post(
        directionsUrl,
        options: Options(
          headers: {
            'Authorization': openRouteApiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "coordinates": [
            [startLng, startLat],
            [endLng, endLat],
          ],
          "format": "geojson",
        },
      );

      return directionsResponse.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Directions error: $e');
    }
  }

  // Helper methods
  Map<String, dynamic> _extractData(Response response) {
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    } else if (response.data is List) {
      return {'data': response.data};
    } else {
      return {'message': 'Success', 'data': response.data};
    }
  }

  bool _shouldRetry(DioException error) {
    // Retry on timeout and connection errors, but not on client errors (4xx)
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return statusCode != null &&
            statusCode >= 500; // Only retry server errors
      default:
        return false;
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception('Connection timeout. Using offline mode.');
      case DioExceptionType.sendTimeout:
        return Exception('Send timeout. Please try again.');
      case DioExceptionType.receiveTimeout:
        return Exception('Receive timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return Exception('API endpoint not found. Using offline mode.');
        }
        // Improved handling for non-JSON responses
        String message = 'Server error';
        if (error.response?.data is String) {
          // If HTML or text, extract possible message
          message = 'Internal server error occurred.';
        } else {
          message = error.response?.data?['message'] ?? 'Server error';
        }
        return Exception('Server error ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Using offline mode.');
      default:
        return Exception('Network error: ${error.message}');
    }
  }

  // Health check
  Future<bool> checkConnection() async {
    try {
      // Try a simple GET request to the base URL or a health endpoint
      final response = await _dio.get(
        '/',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          validateStatus: (status) =>
          status != null && status < 500, // Accept any non-server error
        ),
      );
      return response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      debugPrint('Connection check failed: $e');
      return false;
    }
  }
}