import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/api_service.dart';

class ConnectionStatusWidget extends StatefulWidget {
  final ApiService apiService;
  final Widget child;

  const ConnectionStatusWidget({
    super.key,
    required this.apiService,
    required this.child,
  });

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  bool _isConnected = true;
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    _startConnectionCheck();
  }

  void _startConnectionCheck() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkConnection();
    });
    _checkConnection(); // Initial check
  }

  Future<void> _checkConnection() async {
    try {
      final isConnected = await widget.apiService.checkConnection();
      if (mounted && _isConnected != isConnected) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    } catch (e) {
      if (mounted && _isConnected) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isConnected)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'No internet connection',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}