import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_user/src/providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../routes.dart';

class ParentHome extends StatefulWidget {
  const ParentHome({super.key});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> with TickerProviderStateMixin {
  List<dynamic> _children = [];
  List<dynamic> _recentSosAlerts = [];
  Map<String, Map<String, dynamic>> _childrenLocations = {};
  bool _loading = true;
  bool _loadingSos = false;
  bool _loadingLocations = false;
  late AnimationController _animationController;
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadChildren();
    await _loadRecentSosAlerts();
    await _loadChildrenLocations();
  }

  Future<void> _loadChildren() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.refreshProfile();
      final user = auth.user;
      if (user != null && user['children'] is List) {
        setState(() {
          _children = user['children'] as List<dynamic>;
        });
        debugPrint('Loaded ${_children.length} children');
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error loading children: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load children: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRecentSosAlerts() async {
    setState(() => _loadingSos = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      List<dynamic> allSosAlerts = [];

      // Load SOS history for each connected child
      for (final child in _children) {
        try {
          final childId = child['_id']?.toString() ?? child['id']?.toString();
          if (childId != null && childId.isNotEmpty) {
            debugPrint(
                'Loading SOS history for child: ${child['name']} (ID: $childId)');
            final sosHistory = await auth.api.getSosHistory(childId);

            // Add child info to each SOS alert for display
            for (final sos in sosHistory) {
              if (sos is Map<String, dynamic>) {
                sos['childInfo'] = child;
                allSosAlerts.add(sos);
              }
            }
            debugPrint(
                'Loaded ${sosHistory.length} SOS alerts for ${child['name']}');
          }
        } catch (e) {
          debugPrint('Error loading SOS for child ${child['name']}: $e');
        }
      }

      // Sort by date (newest first) and take recent 10
      allSosAlerts.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime(2000);
        final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime(2000);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _recentSosAlerts = allSosAlerts.take(10).toList();
      });

      debugPrint('Total SOS alerts loaded: ${_recentSosAlerts.length}');
    } catch (e) {
      debugPrint('Error loading SOS alerts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load SOS alerts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loadingSos = false);
    }
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return 'C';
    return name[0].toUpperCase();
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown time';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }

  Future<void> _loadChildrenLocations() async {
    setState(() => _loadingLocations = true);
    try {
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      Map<String, Map<String, dynamic>> locations = {};

      debugPrint(
          '📍 Starting location loading for ${_children.length} children');

      for (final child in _children) {
        final childId = child['_id']?.toString() ?? child['id']?.toString();
        final childName = child['name']?.toString() ?? 'Unknown Child';

        if (childId != null && childId.isNotEmpty) {
          try {
            debugPrint(
                '🔍 Fetching location for child: $childName (ID: $childId)');
            final location =
                await locationProvider.getLastKnownLocation(childId);
            if (location != null) {
              locations[childId] = location;
              debugPrint(
                  '✅ Location found for $childName: ${location['lat']}, ${location['lng']} at ${location['timestamp']}');
            } else {
              debugPrint('❌ No location data for $childName');
            }
          } catch (e) {
            debugPrint('❌ Error loading location for child $childName: $e');
          }
        } else {
          debugPrint('⚠️ Child has no valid ID for location lookup: $child');
        }
      }

      setState(() {
        _childrenLocations = locations;
      });

      debugPrint(
          '🎯 Final locations loaded: ${locations.length}/${_children.length}');
    } catch (e) {
      debugPrint('❌ Critical error loading children locations: $e');
    } finally {
      setState(() => _loadingLocations = false);
    }
  }

  void _viewChildSosHistory(Map<String, dynamic> child) {
    final childId = child['_id']?.toString() ?? child['id']?.toString();
    if (childId != null) {
      Navigator.pushNamed(
        context,
        Routes.sosHistory,
        arguments: {'userId': childId, 'childName': child['name']?.toString()},
      );
    }
  }

  String _getLocationStatus(String childId) {
    final location = _childrenLocations[childId];
    if (location == null) return 'Location unavailable';

    final timestamp = location['timestamp'] as String?;
    if (timestamp == null) return 'Location unavailable';

    try {
      final locationTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(locationTime);

      if (difference.inMinutes < 5) {
        return 'Online now';
      } else if (difference.inMinutes < 30) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours}h ago';
      } else {
        return 'Last seen ${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Location unavailable';
    }
  }

  Color _getLocationStatusColor(String childId) {
    final location = _childrenLocations[childId];
    if (location == null) return Colors.grey;

    final timestamp = location['timestamp'] as String?;
    if (timestamp == null) return Colors.grey;

    try {
      final locationTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(locationTime);

      if (difference.inMinutes < 5) {
        return Colors.green;
      } else if (difference.inMinutes < 30) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade400,
              Colors.pink.shade300,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guardian Dashboard',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return Text(
                                    'Hello, ${auth.user?['name']?.toString() ?? 'Parent'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, Routes.settings),
                                icon: const Icon(Icons.settings,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, Routes.profile),
                                icon: const Icon(Icons.person,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stats Cards Row
                    Row(
                      children: [
                        // Connected Children Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.pink.shade200
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.family_restroom,
                                    color: Colors.pink.shade400,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${_children.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Children',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Online Status Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.shade200
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: _pulseController != null
                                      ? AnimatedBuilder(
                                          animation: _pulseController!,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: 1.0 +
                                                  (_pulseController!.value *
                                                      0.1),
                                              child: Icon(
                                                Icons.location_on,
                                                color: Colors.green.shade400,
                                                size: 24,
                                              ),
                                            );
                                          },
                                        )
                                      : Icon(
                                          Icons.location_on,
                                          color: Colors.green.shade400,
                                          size: 24,
                                        ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${_childrenLocations.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Tracked',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // SOS Alerts Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _recentSosAlerts.isNotEmpty
                                            ? Colors.red.shade200
                                                .withValues(alpha: 0.4)
                                            : Colors.grey.shade200
                                                .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.warning,
                                    color: _recentSosAlerts.isNotEmpty
                                        ? Colors.red.shade400
                                        : Colors.grey.shade400,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${_recentSosAlerts.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Alerts',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Recent SOS Alerts Section
                              Row(
                                children: [
                                  Icon(Icons.warning,
                                      color: Colors.red.shade400, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recent SOS Alerts',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_loadingSos)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  else
                                    IconButton(
                                      onPressed: _loadRecentSosAlerts,
                                      icon: Icon(Icons.refresh,
                                          color: Colors.pink.shade400),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (_recentSosAlerts.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.check_circle,
                                          size: 48,
                                          color: Colors.green.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No Recent SOS Alerts',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        'All your children are safe',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._recentSosAlerts
                                    .take(3)
                                    .map((alert) => _buildSosAlertCard(alert)),

                              const SizedBox(height: 30),

                              // Connected Children Section
                              Row(
                                children: [
                                  Icon(Icons.child_care,
                                      color: Colors.pink.shade400, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Connected Children',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_loadingLocations)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  else
                                    IconButton(
                                      onPressed: _loadChildrenLocations,
                                      icon: Icon(Icons.refresh,
                                          color: Colors.pink.shade400),
                                      tooltip: 'Refresh Locations',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (_children.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade50,
                                        Colors.white
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.family_restroom,
                                          size: 48,
                                          color: Colors.blue.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No Children Connected Yet',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start protecting your loved ones by connecting with your children',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.blue.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => Navigator.pushNamed(
                                            context, Routes.connectChild),
                                        icon: const Icon(Icons.person_add,
                                            color: Colors.white),
                                        label: Text(
                                          'Connect with Child',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade400,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._children
                                    .map((child) => _buildChildCard(child)),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSosAlertCard(Map<String, dynamic> alert) {
    final childInfo = alert['childInfo'] as Map<String, dynamic>?;
    final childName = childInfo?['name']?.toString() ??
        alert['user']?['name']?.toString() ??
        'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SOS Alert from $childName',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    Text(
                      _formatDateTime(alert['createdAt']?.toString()),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'URGENT',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (alert['message'] != null &&
              alert['message'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              alert['message'].toString(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          if (alert['lat'] != null && alert['lng'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Text(
                  'Location: ${alert['lat']}, ${alert['lng']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChildCard(Map<String, dynamic> child) {
    final childId = child['_id']?.toString() ?? child['id']?.toString() ?? '';
    final locationStatus = _getLocationStatus(childId);
    final statusColor = _getLocationStatusColor(childId);
    final location = _childrenLocations[childId];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.pink.shade50.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade100.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Main child info section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Profile Avatar with Status Indicator
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.shade400,
                              Colors.pink.shade300
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.pink.shade200.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getInitial(child['name']?.toString()),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Status indicator
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: statusColor == Colors.green &&
                                  _pulseController != null
                              ? AnimatedBuilder(
                                  animation: _pulseController!,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale:
                                          1.0 + (_pulseController!.value * 0.2),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Child Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child['name']?.toString() ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (child['phone']?.toString().isNotEmpty == true)
                          Row(
                            children: [
                              Icon(Icons.phone,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                child['phone'].toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 6),

                        // Location Status
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationStatus,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Location Details (if available)
            if (location != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location['address']?.toString() ??
                            'Lat: ${location['lat']?.toStringAsFixed(4)}, Lng: ${location['lng']?.toStringAsFixed(4)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // View Location Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        Routes.parentMap,
                        arguments: child,
                      ),
                      icon: const Icon(Icons.map, size: 18),
                      label: Text(
                        'View Map',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // SOS History Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewChildSosHistory(child),
                      icon: const Icon(Icons.history, size: 18),
                      label: Text(
                        'SOS History',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade600,
                        side: BorderSide(color: Colors.orange.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
