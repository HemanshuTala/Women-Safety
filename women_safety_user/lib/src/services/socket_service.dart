import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  void connect(String serverUrl, String userId, String role) {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket!.on('connect', (_) {
      socket!.emit('register_socket', {'userId': userId, 'role': role});
    });

    socket!.on('location:update', (data) {
      // handle
    });

    socket!.on('sos:alert', (data) {
      // handle
    });

    socket!.on('disconnect', (_) {});
  }

  void joinParentRoom(String childId) {
    socket?.emit('parent:watch', {'childId': childId});
  }

  void leaveParentRoom(String childId) {
    socket?.emit('parent:unwatch', {'childId': childId});
  }

  void emitLocation(String userId, double lat, double lng, double speed) {
    socket?.emit('location:update', {
      'userId': userId,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  void emitSos(Map<String, dynamic> payload) {
    socket?.emit('sos:send', payload);
  }

  void dispose() => socket?.dispose();
}
