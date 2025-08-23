const mongoose = require('mongoose');

const checkInRequestSchema = new mongoose.Schema({
  journey: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Journey'
  },
  parent: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  child: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  message: {
    type: String,
    default: 'Please confirm you are safe'
  },
  requestType: {
    type: String,
    enum: ['safety_check', 'location_update', 'eta_update', 'emergency_check'],
    default: 'safety_check'
  },
  response: {
    message: String,
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
      },
      coordinates: [Number]
    },
    status: {
      type: String,
      enum: ['safe', 'need_help', 'emergency'],
      default: 'safe'
    },
    respondedAt: Date
  },
  status: {
    type: String,
    enum: ['pending', 'responded', 'expired'],
    default: 'pending'
  },
  expiresAt: {
    type: Date,
    default: function() {
      return new Date(Date.now() + 10 * 60 * 1000); // 10 minutes from now
    }
  }
}, {
  timestamps: true
});

// Indexes
checkInRequestSchema.index({ child: 1, status: 1 });
checkInRequestSchema.index({ parent: 1, createdAt: -1 });
checkInRequestSchema.index({ journey: 1 });
checkInRequestSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('CheckInRequest', checkInRequestSchema);