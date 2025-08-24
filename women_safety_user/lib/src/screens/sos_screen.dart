import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:geolocator/geolocator.dart';
import 'package:women_safety_user/src/providers/auth_provider.dart';
import 'package:women_safety_user/src/providers/location_provider.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  final TextEditingController _messageController = TextEditingController();

  bool _isSendingSOS = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLocation();
    _messageController.text = "Help needed!";
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _initializeLocation() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    locationProvider.initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // No audio recording functionality

  Future<void> _activateSOS() async {
    if (_isSendingSOS) return;

    // Vibration feedback
    if (await Vibration.hasVibrator() == true) {
      Vibration.vibrate(duration: 500);
    }

    // Send SOS immediately
    await _sendSOS();
  }

  Future<void> _sendSOS() async {
    setState(() {
      _isSendingSOS = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);

      // Get current location with fallback
      await locationProvider.updateCurrentLocation();
      var position = locationProvider.currentPosition;

      // If no current position, try to get last known position
      if (position == null) {
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (e) {
          debugPrint('Failed to get last known position: $e');
        }
      }

      // If still no position, use a default location (you can customize this)
      if (position == null) {
        debugPrint('⚠️ No location available, using default coordinates');
        // Using a default location - you should replace with your city's coordinates
        position = Position(
          latitude: 21.2182134, // Default latitude
          longitude: 72.895403, // Default longitude
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      // Send SOS via API
      debugPrint('📤 Sending SOS with location: ${position.latitude}, ${position.longitude}');
      debugPrint('📝 Message: ${_messageController.text.trim()}');

      final response = await authProvider.api.sendSosMultipart(
        lat: position.latitude,
        lng: position.longitude,
        userId: authProvider.userId,
        message: _messageController.text.trim(),
      );

      debugPrint('✅ SOS sent successfully: $response');

      if (!mounted) return;

      // Show success message with details
      int notifiedParents = 0;
      if (response['sos']?['notifiedParents'] is List) {
        notifiedParents = (response['sos']?['notifiedParents'] as List).length;
      } else if (response['sos']?['notifiedParents'] is int) {
        notifiedParents = response['sos']?['notifiedParents'] as int;
      }
      
      if (notifiedParents > 0) {
        _showSuccess('SOS sent successfully! $notifiedParents guardian(s) notified. Help is on the way.');
      } else {
        _showWarning('SOS sent but no guardians are connected. Please connect with your parents first.');
      }

      // Call emergency services
      await _callEmergencyServices();

      // Reset state
      setState(() {
        _isSendingSOS = false;
      });

    } catch (e) {
      if (!mounted) return;
      _showError('Failed to send SOS: $e');
      setState(() {
        _isSendingSOS = false;
      });
    }
  }

  Future<void> _callEmergencyServices() async {
    try {
      const emergencyNumber = '112'; // International emergency number
      final uri = Uri(scheme: 'tel', path: emergencyNumber);
      if (await canLaunchUrl(uri)) {
        _showEmergencyCallDialog(uri);
      }
    } catch (e) {
      debugPrint('Failed to call emergency services: $e');
    }
  }

  void _showEmergencyCallDialog(Uri uri) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Emergency Services?'),
        content: const Text('Do you want to call emergency services (112)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              launchUrl(uri);
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final red = Colors.red.shade600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Emergency SOS',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Guardian Connection Status
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final hasParents = auth.hasConnectedParents;
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasParents ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasParents ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasParents ? Icons.check_circle : Icons.warning,
                        color: hasParents ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasParents ? 'Guardian Connected' : 'No Guardian Connected',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: hasParents ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasParents 
                                  ? 'SOS alerts will be sent to your guardian'
                                  : 'Connect with a guardian to receive SOS alerts',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: hasParents ? Colors.green.shade600 : Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Emergency Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'How SOS Works',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Edit the emergency message (keep it short)\n'
                        '2. Tap the SOS button to send immediately\n'
                        '3. Your guardians will receive:\n'
                        '   • SMS with your location & message\n'
                        '   • Phone call for immediate alert',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Audio Recording Section removed

            // Message Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Message',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    maxLength: 50, // Limit message length for SMS compatibility
                    decoration: InputDecoration(
                      hintText: 'Brief emergency message...',
                      helperText: 'Keep message short for SMS delivery',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // SOS Button
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: GestureDetector(
                            onTap: _isSendingSOS ? null : _activateSOS,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isSendingSOS ? Colors.grey : red,
                                boxShadow: [
                                  BoxShadow(
                                    color: _isSendingSOS ? Colors.grey.withValues(alpha: 0.3) : red.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSendingSOS) ...[
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sending SOS...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ] else ...[
                                    const Icon(
                                      Icons.emergency,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'SOS',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Tap to Send',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      var uri = Uri(scheme: 'tel', path: '112');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call 112'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final parentPhone = auth.parentPhone;
                      final parentName = auth.parentName;
                      final buttonText = parentName != null 
                          ? 'Call $parentName' 
                          : 'Call Guardian';
                      
                      return ElevatedButton.icon(
                        onPressed: parentPhone != null ? () async {
                          final uri = Uri(scheme: 'tel', path: parentPhone);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        } : null,
                        icon: const Icon(Icons.family_restroom),
                        label: Text(
                          buttonText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: parentPhone != null ? Colors.green : Colors.grey.shade300,
                          foregroundColor: parentPhone != null ? Colors.white : Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: parentPhone != null ? 4 : 0,
                      )
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}