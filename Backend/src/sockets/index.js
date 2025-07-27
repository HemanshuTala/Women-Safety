// sockets/index.js
module.exports = (io) => {
  io.on('connection', (socket) => {
    console.log('New client connected:', socket.id);

    socket.on('disconnect', () => {
      console.log('Client disconnected:', socket.id);
    });

    // Join parent room
    socket.on('join_parent_room', (userId) => {
      socket.join(`parent_${userId}`);
      console.log(`Socket ${socket.id} joined room parent_${userId}`);
    });

    // User sends location updates
    socket.on('location_update', (data) => {
      console.log('Received location_update:', data);
      io.to(`parent_${data.userId}`).emit('location_broadcast', data);
    });

    // Emergency
    socket.on('emergency_alert', (data) => {
      console.log('Emergency alert received:', data);
      io.to(`parent_${data.userId}`).emit('emergency_broadcast', data);
    });
  });

  const emitLocation = (userId, locationData) => {
    io.to(`parent_${userId}`).emit('location_broadcast', { userId, ...locationData });
  };

  const emitEmergency = (userId, emergencyData) => {
    io.to(`parent_${userId}`).emit('emergency_broadcast', { userId, ...emergencyData });
  };

  return { emitLocation, emitEmergency };
};
