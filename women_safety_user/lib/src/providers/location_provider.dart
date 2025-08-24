import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_tracking_service.dart';
import '../services/api_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationTrackingService _locationService;
  
  Position? _currentPosition;
  bool _isTracking = false;
  bool _hasPermission = false;

  LocationProvider(ApiService api) : _locationService = LocationTrackingService(api) {
    // Initialize in the next frame to avoid issues during widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
    });
  }

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;

  Future<void> initialize() async {
    try {
      _hasPermission = await _locationService.checkPermissions();
      if (_hasPermission) {
        await updateCurrentLocation();
        // Auto-start location tracking for safety
        startTracking();
        debugPrint('🎯 Location tracking started automatically');
      } else {
        debugPrint('❌ Location permissions not granted - tracking disabled');
      }
    } catch (e) {
      debugPrint('LocationProvider initialization error: $e');
      _hasPermission = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        _currentPosition = position;
        // Reduce logging frequency to avoid spam
        if (DateTime.now().millisecondsSinceEpoch % 30000 < 1000) {
          debugPrint('Location provider updated: ${position.latitude}, ${position.longitude}');
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  void startTracking() {
    if (!_hasPermission) return;
    
    _isTracking = true;
    _locationService.startRealTimeTracking();
    notifyListeners();
  }

  void stopTracking() {
    _isTracking = false;
    _locationService.stopLocationTracking();
    notifyListeners();
  }

  // Get last known location for a specific user/child
  Future<Map<String, dynamic>?> getLastKnownLocation(String userId) async {
    try {
      debugPrint('🔍 Fetching last known location for user: $userId');
      
      // Use the API service to get the latest location
      final response = await _locationService.api.getLatestLocation(userId);
      
      if (response.isNotEmpty) {
        debugPrint('📍 Location found for $userId: ${response['lat']}, ${response['lng']}');
        return {
          'lat': response['lat'],
          'lng': response['lng'],
          'timestamp': response['timestamp'] ?? response['updatedAt'] ?? DateTime.now().toIso8601String(),
          'accuracy': response['accuracy'],
          'speed': response['speed'],
          'address': response['address'], // If available from backend
        };
      } else {
        debugPrint('❌ No location data found for user: $userId');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching location for user $userId: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}