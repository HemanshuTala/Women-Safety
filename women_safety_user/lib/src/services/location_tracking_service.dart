import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';

class LocationTrackingService {
  final ApiService api;
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;
  
  LocationTrackingService(this.api);

  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      if (!await checkPermissions()) {
        debugPrint('Location permissions not granted');
        return null;
      }
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );
      
      // Only log location updates occasionally to reduce spam
      if (DateTime.now().millisecondsSinceEpoch % 10000 < 1000) {
        debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
      }
      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      
      // Try to get last known position as fallback
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          debugPrint('Using last known position: ${lastPosition.latitude}, ${lastPosition.longitude}');
          return lastPosition;
        }
      } catch (e2) {
        debugPrint('Error getting last known position: $e2');
      }
      
      return null;
    }
  }

  void startLocationTracking({Duration interval = const Duration(seconds: 30)}) {
    _locationTimer?.cancel();
    
    _locationTimer = Timer.periodic(interval, (timer) async {
      try {
        final position = await getCurrentLocation();
        if (position != null) {
          await _updateLocationOnServer(position);
        }
      } catch (e) {
        debugPrint('Error in location tracking: $e');
      }
    });
  }

  void startRealTimeTracking() {
    _positionStream?.cancel();
    
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        try {
          await _updateLocationOnServer(position);
        } catch (e) {
          debugPrint('Error updating location: $e');
        }
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  Future<void> _updateLocationOnServer(Position position) async {
    try {
      debugPrint('📤 Updating location on server: ${position.latitude}, ${position.longitude}');
      final response = await api.updateLocation(
        lat: position.latitude,
        lng: position.longitude,
        speed: position.speed,
        accuracy: position.accuracy,
        timestamp: DateTime.now().toIso8601String(),
      );
      debugPrint('✅ Location updated successfully: $response');
    } catch (e) {
      debugPrint('❌ Failed to update location on server: $e');
    }
  }

  void stopLocationTracking() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    _locationTimer = null;
    _positionStream = null;
  }

  void dispose() {
    stopLocationTracking();
  }
}