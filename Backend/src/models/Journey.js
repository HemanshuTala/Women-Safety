const mongoose = require('mongoose');

const journeySchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  startLocation: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true
    },
    address: String
  },
  destination: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true
    },
    address: String
  },
  plannedRoute: {
    routeId: String,
    waypoints: [{
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
      },
      coordinates: [Number]
    }],
    distance: Number, // in meters
    estimatedDuration: Number, // in seconds
    safetyScore: {
      type: Number,
      min: 0,
      max: 100,
      default: 50
    }
  },
  transportMode: {
    type: String,
    enum: ['walking', 'cycling', 'driving', 'transit', 'rideshare'],
    default: 'walking'
  },
  status: {
    type: String,
    enum: ['planned', 'active', 'completed', 'cancelled', 'emergency'],
    default: 'planned'
  },
  scheduledTime: {
    type: Date,
    required: true
  },
  startTime: Date,
  endTime: Date,
  actualDuration: Number, // in seconds
  actualDistance: Number, // in meters
  sharedWithParents: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  safetyAlerts: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'SafetyAlert'
  }],
  checkInRequests: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'CheckInRequest'
  }],
  // Journey metrics
  metrics: {
    averageSpeed: Number, // km/h
    maxSpeed: Number,
    routeDeviations: Number,
    alertsCount: Number,
    safetyScore: Number
  }
}, {
  timestamps: true
});

// Geospatial indexes for location queries
journeySchema.index({ 'startLocation': '2dsphere' });
journeySchema.index({ 'destination': '2dsphere' });
journeySchema.index({ user: 1, status: 1 });
journeySchema.index({ sharedWithParents: 1, status: 1 });
journeySchema.index({ createdAt: -1 });

module.exports = mongoose.model('Journey', journeySchema);