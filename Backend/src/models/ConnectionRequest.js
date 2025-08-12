const mongoose = require('mongoose');

const requestSchema = new mongoose.Schema({
  requester: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // parent
  target: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // child
  status: { type: String, enum: ['pending', 'accepted', 'rejected'], default: 'pending' },
  message: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now },
  respondedAt: Date
});

module.exports = mongoose.model('ConnectionRequest', requestSchema);
