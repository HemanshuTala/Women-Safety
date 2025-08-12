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

module.exports = {
  initSocket,
  emitLocationToParents,
  emitSOS
};
