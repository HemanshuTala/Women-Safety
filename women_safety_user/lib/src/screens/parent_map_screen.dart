import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ParentMapScreen extends StatefulWidget {
  const ParentMapScreen({super.key});

  @override
  State<ParentMapScreen> createState() => _ParentMapScreenState();
}

class _ParentMapScreenState extends State<ParentMapScreen> {
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _children = [];
  final Map<String, LatLng> _childrenLocations = {};
  final List<LatLng> _routePoints = [];
  String? _selectedChildId;
  final bool _showRoute = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
    _startLocationUpdates();
  }

  Future<void> _loadChildren() async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.refreshProfile();

      final user = auth.user;
      if (user != null && user['children'] is List) {
        final childrenList = user['children'] as List;

        // Convert children (which are IDs) to proper objects
        final childrenData = <Map<String, dynamic>>[];
        for (final childId in childrenList) {
          if (childId is String) {
            childrenData.add({
              'id': childId,
              '_id': childId,
              'name': 'Child ${childId.substring(0, 8)}...',
              'phone': 'Loading...',
            });
          } else if (childId is Map) {
            childrenData.add(Map<String, dynamic>.from(childId));
          }
        }

        setState(() {
          _children = childrenData;
          _isLoading = false;
        });

        // Load locations for each child
        for (final child in _children) {
          final childId =
              child['id']?.toString() ?? child['_id']?.toString() ?? '';
          if (childId.isNotEmpty) {
            await _loadChildLocation(childId);
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load children: $e');
    }
  }

  Future<void> _loadChildLocation(String childId) async {
    if (childId.isEmpty) return;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final data = await auth.api.getLatestLocation(childId);

      debugPrint('📍 Location data for child $childId: $data');

      // Handle different possible response structures
      double? lat, lng;

      if (data['lat'] != null && data['lng'] != null) {
        lat = double.tryParse(data['lat'].toString());
        lng = double.tryParse(data['lng'].toString());
      } else if (data['location'] != null) {
        final locationData = data['location'];
        if (locationData is Map) {
          lat = double.tryParse(locationData['lat']?.toString() ?? '');
          lng = double.tryParse(locationData['lng']?.toString() ?? '');
        }
      } else if (data['coordinates'] != null) {
        final coords = data['coordinates'];
        if (coords is List && coords.length >= 2) {
          lng = double.tryParse(
              coords[0].toString()); // longitude first in GeoJSON
          lat = double.tryParse(coords[1].toString()); // latitude second
        }
      }

      if (lat != null && lng != null && lat != 0 && lng != 0) {
        final location = LatLng(lat, lng);
        debugPrint('✅ Valid location found: $lat, $lng');

        setState(() {
          _childrenLocations[childId] = location;
        });

        // Center map on first child location
        if (_childrenLocations.length == 1) {
          _mapController.move(location, 15);
          debugPrint('🎯 Centered map on child location');
        }
      } else {
        debugPrint('❌ No valid location data found for child $childId');
      }
    } catch (e) {
      debugPrint('❌ Failed to load location for child $childId: $e');
      // Don't show error to user for individual location failures
      // as this happens frequently and would be annoying
    }
  }

  void _startLocationUpdates() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        for (final child in _children) {
          _loadChildLocation(child['id']?.toString() ?? '');
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _centerOnChild(String childId) {
    final location = _childrenLocations[childId];
    if (location != null) {
      _mapController.move(location, 17);
      setState(() => _selectedChildId = childId);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pink = Colors.pink.shade400;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(23.022505, 72.571365),
              initialZoom: 12,
              maxZoom: 19,
              minZoom: 5,
            ),
            children: [
              // Base map
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.women_safety_user',
                maxZoom: 19,
                // Add proper attribution as required by OSM
                additionalOptions: const {
                  'attribution': '© OpenStreetMap contributors',
                },
              ),

              // Route polyline
              if (_showRoute && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4,
                      color: Colors.pink.shade400,
                    ),
                  ],
                ),

              // Children markers
              MarkerLayer(
                markers: _childrenLocations.entries.map((entry) {
                  final childId = entry.key;
                  final location = entry.value;
                  final childData = _children.firstWhere(
                    (c) =>
                        (c['id']?.toString() ?? c['_id']?.toString()) ==
                        childId,
                    orElse: () => {'name': 'Unknown', 'id': childId},
                  );
                  final isSelected = _selectedChildId == childId;

                  return Marker(
                    point: location,
                    width: 70,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _centerOnChild(childId),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.red : Colors.pink.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 70),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              childData['name']?.toString() ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top header
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
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: pink),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Tracking',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          '${_children.length} children connected',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color:
                          _children.isNotEmpty ? Colors.pink.shade400 : Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Children list
          if (_children.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _children.length,
                  itemBuilder: (context, index) {
                    final child = _children[index];
                    final childId = child['id']?.toString() ??
                        child['_id']?.toString() ??
                        '';
                    final location = _childrenLocations[childId];
                    final isSelected = _selectedChildId == childId;

                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: pink, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: location != null
                                      ? Colors.pink.shade400
                                      : Colors.grey,
                                  child: Text(
                                    (child['name']?.toString() ?? 'U')[0]
                                        .toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          child['name']?.toString() ??
                                              'Unknown',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                            color: Colors.grey.shade800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        location != null ? 'Online' : 'Offline',
                                        style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          color: location != null
                                              ? Colors.pink.shade400
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: location != null
                                      ? () => _centerOnChild(childId)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: pink,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: const Size(0, 28),
                                  ),
                                  child: Text(
                                    'Locate',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: IconButton(
                                  onPressed: () {
                                    // Call child functionality
                                    final phone = child['phone']?.toString();
                                    if (phone != null) {
                                      // Implement call functionality
                                    }
                                  },
                                  icon: Icon(Icons.call,
                                      color: Colors.pink.shade400, size: 16),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          // Empty state
          if (!_isLoading && _children.isEmpty)
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.family_restroom,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Children Connected',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send connection requests to start tracking',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/connect_child'),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Connect Child'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pink,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
