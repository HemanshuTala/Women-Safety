require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const connectDB = require('./src/config/db');
const authRoutes = require('./src/routes/authRoutes');
const userRoutes = require('./src/routes/userRoutes');
const locationRoutes = require('./src/routes/locationRoutes');
const sosRoutes = require('./src/routes/sosRoutes');
const journeyRoutes = require('./src/routes/journeyRoutes');
const { initSocket } = require('./src/services/socketService');
const path = require('path');
const fs = require('fs');
const User = require('./src/models/User');
const app = express();
const server = http.createServer(app);
const { Server } = require('socket.io');

const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || '*',
    methods: ['GET', 'POST']
  }
});

initSocket(io);

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Ensure uploads folder exists and serve it statically
const uploadsDir = path.join(__dirname, 'uploads');
fs.mkdirSync(uploadsDir, { recursive: true });
app.use('/uploads', express.static(uploadsDir));

app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/sos', sosRoutes);
app.use('/api/journey', journeyRoutes);

// Additional socket handlers: location updates directly via socket
io.on('connection', (socket) => {
  socket.on('location:update', (payload) => {
    // payload: { userId, lat, lng, speed, accuracy, timestamp }
    if (!payload || !payload.userId) return;
    io.to(`parent_of_${payload.userId}`).emit('location:update', payload);
  });

  socket.on('sos:send', (payload) => {
    if (!payload || !payload.userId) return;
    io.to(`parent_of_${payload.userId}`).emit('sos:alert', payload);
  });

  socket.on('register_socket', async ({ userId }) => {
    if (!userId) return;
    try {
      await User.findByIdAndUpdate(userId, { socketId: socket.id });
    } catch (err) {
      console.warn('Failed to store socketId', err.message);
    }
  });
});

(async () => {
  await connectDB(process.env.MONGO_URI);
  const PORT = process.env.PORT || 5000;
  server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
  });
})();
