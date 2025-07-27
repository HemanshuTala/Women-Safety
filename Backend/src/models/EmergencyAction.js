const mongoose = require('mongoose');

const EmergencyActionSchema = new mongoose.Schema(
  {
    journeyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Journey', required: true },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    timestamp: { type: Date, required: true },
    action: {
      type: String,
      enum: ['sos_call', 'voice_recording', 'no_response'],
      required: true,
    },
    audioUrl: String,
    notifiedParents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
);

module.exports = mongoose.model('EmergencyAction', EmergencyActionSchema);
