let io = null;

function initSocket(ioInstance) {
  io = ioInstance;

  io.on('connection', (socket) => {
    console.log('Socket connected', socket.id);

    socket.on('register_socket', ({ userId, role }) => {
      if (!userId) return;
      // Personal room for the user
      socket.join(`user_socket_${userId}`);
      console.log(`Socket ${socket.id} joined user_socket_${userId}`);
    });

    // allow parents to watch child
    socket.on('parent:watch', ({ childId }) => {
      if (!childId) return;
      socket.join(`parent_of_${childId}`);
      console.log(`Socket ${socket.id} joined parent_of_${childId}`);
    });

    socket.on('parent:unwatch', ({ childId }) => {
      if (!childId) return;
      socket.leave(`parent_of_${childId}`);
    });

    // Journey tracking rooms
    socket.on('journey:join', ({ journeyId }) => {
      if (!journeyId) return;
      socket.join(`journey_${journeyId}`);
      console.log(`Socket ${socket.id} joined journey_${journeyId}`);
    });

    socket.on('journey:leave', ({ journeyId }) => {
      if (!journeyId) return;
      socket.leave(`journey_${journeyId}`);
      console.log(`Socket ${socket.id} left journey_${journeyId}`);
    });

    // Parent monitoring rooms
    socket.on('parent:monitor', ({ parentId }) => {
      if (!parentId) return;
      socket.join(`parent_monitor_${parentId}`);
      console.log(`Socket ${socket.id} joined parent_monitor_${parentId}`);
    });

    socket.on('disconnect', () => {
      console.log('Socket disconnected', socket.id);
    });
  });
}

function emitLocationToParents(userId, payload) {
  if (!io) return;
  io.to(`parent_of_${userId}`).emit('location:update', payload);
}

function emitSOS(userId, payload) {
  if (!io) return;
  io.to(`parent_of_${userId}`).emit('sos:alert', payload);
}

// Journey tracking functions
function emitJourneyUpdate(journeyId, payload) {
  if (!io) return;
  console.log(`📡 Emitting journey update for journey ${journeyId}:`, payload.type);
  io.to(`journey_${journeyId}`).emit('journey:update', payload);
}

function emitSafetyAlert(journeyId, payload) {
  if (!io) return;
  console.log(`🚨 Emitting safety alert for journey ${journeyId}:`, payload.type);
  io.to(`journey_${journeyId}`).emit('safety:alert', payload);
}

function emitToParents(parentIds, eventName, payload) {
  if (!io || !Array.isArray(parentIds)) return;
  
  parentIds.forEach(parentId => {
    io.to(`parent_monitor_${parentId}`).emit(eventName, payload);
  });
}

function emitLocationUpdate(journeyId, locationData) {
  if (!io) return;
  io.to(`journey_${journeyId}`).emit('location:realtime', locationData);
}

module.exports = {
  initSocket,
  emitLocationToParents,
  emitSOS,
  emitJourneyUpdate,
  emitSafetyAlert,
  emitToParents,
  emitLocationUpdate
};
