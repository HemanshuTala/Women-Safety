import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class SocketProvider extends ChangeNotifier {
  final ApiService api;
  final socketService = SocketService();

  SocketProvider(this.api);

  void connect(String baseUrl, String userId, String role) {
    socketService.connect(baseUrl, userId, role);
  }

  void watchChild(String childId) => socketService.joinParentRoom(childId);
  void unwatchChild(String childId) => socketService.leaveParentRoom(childId);
  void emitLocation(String userId, double lat, double lng, double speed) => socketService.emitLocation(userId, lat, lng, speed);

  void disposeSocket() => socketService.dispose();
}
