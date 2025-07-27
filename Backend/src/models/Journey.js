const mongoose = require('mongoose');

const JourneySchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    startLocation: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
      address: String,
    },
    endLocation: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
      address: String,
    },
    startedAt: { type: Date, required: true },
    endedAt: Date,
    status: {
      type: String,
      enum: ['active', 'completed', 'unsafe', 'no_response'],
      default: 'active',
    },
    checkpoints: [
      {
        timestamp: { type: Date, required: true },
        status: { type: String, enum: ['safe', 'unsafe', 'no_response'], required: true },
        location: {
          latitude: Number,
          longitude: Number,
        },
        audioUrl: String,
      },
    ],
    lastKnownLocation: {
      latitude: Number,
      longitude: Number,
      updatedAt: Date,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Journey', JourneySchema);
