module.exports = (io) => {
  io.on('connection', (socket) => {
    console.log('New client connected');

    socket.on('disconnect', () => {
      console.log('Client disconnected');
    });

    // Join parent room to receive updates for specific user
    socket.on('join_parent_room', (userId) => {
      socket.join(`parent_${userId}`);
      console.log(`Socket ${socket.id} joined room parent_${userId}`);
    });

    // Receive updated location from user client
    socket.on('location_update', async (data) => {
      console.log('Received location_update:', data);

      // Here you could update last known location in DB (Journey collection)
      // e.g. await updateJourneyLastKnownLocation(data.userId, data.latitude, data.longitude);

      // Broadcast location update to parents subscribed to this user
      io.to(`parent_${data.userId}`).emit('location_broadcast', data);
    });

    // Emergency alert from user
    socket.on('emergency_alert', (data) => {
      console.log('Emergency alert received:', data);
      io.to(`parent_${data.userId}`).emit('emergency_broadcast', data);
    });
  });

  // Helper to emit location update to parents of a user from any part of server code
  const emitLocation = (userId, locationData) => {
    io.to(`parent_${userId}`).emit('location_broadcast', { userId, ...locationData });
  };

  // Helper to emit emergency alert to parents from server code
  const emitEmergency = (userId, emergencyData) => {
    io.to(`parent_${userId}`).emit('emergency_broadcast', { userId, ...emergencyData });
  };

  return {
    emitLocation,
    emitEmergency,
  };
};
