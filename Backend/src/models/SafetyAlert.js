const mongoose = require('mongoose');

const safetyAlertSchema = new mongoose.Schema({
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
  alertType: {
    type: String,
    enum: [
      'route_deviation',
      'unexpected_stop',
      'high_risk_area',
      'low_battery',
      'communication_loss',
      'emergency',
      'speed_alert',
      'late_arrival',
      'safe_arrival'
    ],
    required: true
  },
  severity: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'medium'
  },
  message: {
    type: String,
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
  metadata: {
    // Additional context based on alert type
    deviationDistance: Number, // meters
    stopDuration: Number, // seconds
    batteryLevel: Number, // percentage
    speed: Number, // km/h
    expectedArrival: Date,
    actualArrival: Date
  },
  resolved: {
    type: Boolean,
    default: false
  },
  resolvedAt: Date,
  resolvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  notifiedParents: [{
    parent: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    notifiedAt: {
      type: Date,
      default: Date.now
    },
    acknowledged: {
      type: Boolean,
      default: false
    },
    acknowledgedAt: Date
  }]
}, {
  timestamps: true
});

// Indexes
safetyAlertSchema.index({ journey: 1, createdAt: -1 });
safetyAlertSchema.index({ user: 1, alertType: 1 });
safetyAlertSchema.index({ severity: 1, resolved: 1 });
safetyAlertSchema.index({ 'location': '2dsphere' });

module.exports = mongoose.model('SafetyAlert', safetyAlertSchema);