// test-client.js
const { io } = require('socket.io-client');

const userId = 'student123'; // Example user ID
const socket = io('http://localhost:3000');

// Join as parent to receive updates
socket.on('connect', () => {
  console.log('Connected to server');

  socket.emit('join_parent_room', userId);

  // Simulate location updates every 5 seconds
  setInterval(() => {
    const locationData = {
      userId,
      latitude: 21.123 + Math.random(),
      longitude: 72.456 + Math.random(),
      timestamp: new Date().toISOString(),
    };
    console.log('Sending location_update:', locationData);
    socket.emit('location_update', locationData);
  }, 5000);

  // Simulate emergency after 15 seconds
  setTimeout(() => {
    const emergencyData = {
      userId,
      type: 'SOS',
      message: 'Help needed!',
      timestamp: new Date().toISOString(),
    };
    console.log('Sending emergency_alert:', emergencyData);
    socket.emit('emergency_alert', emergencyData);
  }, 15000);
});

// Receive location updates (as parent)
socket.on('location_broadcast', (data) => {
  console.log('[PARENT] Location broadcast received:', data);
});

// Receive emergency alert
socket.on('emergency_broadcast', (data) => {
  console.log('[PARENT] Emergency broadcast received:', data);
});
