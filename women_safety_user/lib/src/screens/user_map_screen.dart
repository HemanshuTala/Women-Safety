import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';

class UserMapScreen extends StatefulWidget {
  const UserMapScreen({super.key});

  @override
  State<UserMapScreen> createState() => _UserMapScreenState();
}

class _UserMapScreenState extends State<UserMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  LatLng? _currentLocation;
  double? _accuracy;
  DateTime? _lastUpdate;
  bool _isTracking = false;
  bool _showSafeZones = true;
  bool _isLoadingLocation = true;

  final Location location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _locationUpdateTimer;

  // Sample safe zones (you can load these from your API)
  final List<LatLng> _safeZones = [
    LatLng(23.0225, 72.5714), // Example safe zone 1
    LatLng(23.0250, 72.5750), // Example safe zone 2
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initLocation();
    _startLocationTracking();
    
    // Set a timeout for loading state
    Timer(const Duration(seconds: 15), () {
      if (_isLoadingLocation && mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showSnackBar('Location request timed out. Please try again.', Colors.orange);
      }
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      
      // Initialize location provider
      await locationProvider.initialize();

      if (locationProvider.hasPermission) {
        await locationProvider.updateCurrentLocation();
        final position = locationProvider.currentPosition;
        if (position != null) {
          _updateLocation(LocationData.fromMap({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
          }));
        } else {
          debugPrint('No position available after initialization');
        }
      } else {
        debugPrint('Location permission not granted');
        _showSnackBar('Location permission is required for this feature', Colors.orange);
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      _showSnackBar('Failed to get location: $e', Colors.red);
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _startLocationTracking() {
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isTracking) {
        final locationProvider =
            Provider.of<LocationProvider>(context, listen: false);
        await locationProvider.updateCurrentLocation();
        
        // Update the map with new location
        final position = locationProvider.currentPosition;
        if (position != null) {
          _updateLocation(LocationData.fromMap({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
          }));
        }
      }
    });
  }

  void _updateLocation(LocationData loc) {
    final lat = loc.latitude;
    final lng = loc.longitude;

    if (lat == null || lng == null) return;

    final newLatLng = LatLng(lat, lng);
    setState(() {
      _currentLocation = newLatLng;
      _accuracy = loc.accuracy;
      _lastUpdate = DateTime.now();
      _isLoadingLocation = false; // Location loaded successfully
    });

    // Auto-center map on first location update
    if (_currentLocation != null) {
      _mapController.move(newLatLng, 16);
    }
  }

  void _toggleTracking() {
    setState(() {
      _isTracking = !_isTracking;
    });

    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    if (_isTracking) {
      locationProvider.startTracking();
    } else {
      locationProvider.stopTracking();
    }
  }

  void _copyCoordinates() {
    if (_currentLocation != null) {
      final coords =
          '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}';
      Clipboard.setData(ClipboardData(text: coords));
      _showSnackBar('📋 Coordinates copied: $coords', Colors.green);
    }
  }

  void _shareLocation() {
    if (_currentLocation != null) {
      final coords =
          '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}';
      final mapsUrl = 'https://www.google.com/maps?q=$coords';
      Share.share('📍 My current location: $mapsUrl');
    }
  }

  void _centerOnLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 17);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        // Update current location from provider if available
        if (locationProvider.currentPosition != null && _currentLocation == null) {
          final position = locationProvider.currentPosition!;
          // Use addPostFrameCallback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateLocation(LocationData.fromMap({
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
            }));
          });
        }
        
        final center = _currentLocation ?? LatLng(23.022505, 72.571365);

        return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              maxZoom: 19,
              minZoom: 5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Base map tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.women_safety_user',
                maxZoom: 19,
                // Add proper attribution as required by OSM
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors',
                },
              ),

              // Safe zones
              if (_showSafeZones)
                CircleLayer(
                  circles: _safeZones
                      .map((zone) => CircleMarker(
                            point: zone,
                            radius: 200,
                            color: Colors.green.withValues(alpha: 0.2),
                            borderColor: Colors.green,
                            borderStrokeWidth: 2,
                          ))
                      .toList(),
                ),

              // Current location marker
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 100,
                      height: 100,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withValues(alpha: 0.3),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Colors.blue,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

              // Accuracy circle
              if (_currentLocation != null && _accuracy != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLocation!,
                      radius: _accuracy!,
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderColor: Colors.blue.withValues(alpha: 0.3),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
            ],
          ),

          // Top info panel
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _isTracking ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isTracking
                            ? 'Live Tracking Active'
                            : 'Tracking Paused',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isTracking,
                        onChanged: (value) => _toggleTracking(),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  if (_currentLocation != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.gps_fixed,
                            label: 'Accuracy',
                            value:
                                '${_accuracy?.toStringAsFixed(1) ?? 'N/A'} m',
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.access_time,
                            label: 'Updated',
                            value: _lastUpdate != null
                                ? '${_lastUpdate!.hour.toString().padLeft(2, '0')}:${_lastUpdate!.minute.toString().padLeft(2, '0')}'
                                : 'N/A',
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),
          ),

          // Bottom action panel
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.my_location,
                    label: 'Center',
                    color: Colors.blue,
                    onTap: _centerOnLocation,
                  ),
                  _buildActionButton(
                    icon: Icons.copy,
                    label: 'Copy',
                    color: Colors.green,
                    onTap: _copyCoordinates,
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    color: Colors.orange,
                    onTap: _shareLocation,
                  ),
                  _buildActionButton(
                    icon: _showSafeZones
                        ? Icons.visibility
                        : Icons.visibility_off,
                    label: 'Zones',
                    color: Colors.purple,
                    onTap: () =>
                        setState(() => _showSafeZones = !_showSafeZones),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
          ),

          // Emergency SOS button
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'sos_btn',
                  backgroundColor: Colors.red,
                  onPressed: () => Navigator.pushNamed(context, '/sos'),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 28,
                  ),
                )
                    .animate()
                    .scale(delay: 600.ms, duration: 400.ms)
                    .then()
                    .shimmer(duration: 2000.ms),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'back_btn',
                  backgroundColor: Colors.white,
                  mini: true,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.grey,
                    size: 20,
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
          
          // Loading Overlay
          if (_isLoadingLocation)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Getting your location...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we locate you',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
