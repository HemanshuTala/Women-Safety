const mongoose = require('mongoose');

const locationUpdateSchema = new mongoose.Schema({
  journey: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Journey',
    required: true
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true
    }
  },
  speed: {
    type: Number, // km/h
    default: 0
  },
  heading: {
    type: Number, // degrees (0-360)
    default: 0
  },
  accuracy: {
    type: Number, // meters
    default: 0
  },
  batteryLevel: {
    type: Number, // percentage (0-100)
    default: 100
  },
  isMoving: {
    type: Boolean,
    default: true
  },
  // Additional context
  address: String,
  timestamp: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
locationUpdateSchema.index({ journey: 1, timestamp: -1 });
locationUpdateSchema.index({ user: 1, timestamp: -1 });
locationUpdateSchema.index({ 'location': '2dsphere' });
locationUpdateSchema.index({ timestamp: -1 });

// TTL index to automatically delete old location updates after 30 days
locationUpdateSchema.index({ createdAt: 1 }, { expireAfterSeconds: 30 * 24 * 60 * 60 });

module.exports = mongoose.model('LocationUpdate', locationUpdateSchema);