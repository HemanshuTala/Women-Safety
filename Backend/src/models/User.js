const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, default: '' },
  phone: { type: String, required: true, unique: true },
  passwordHash: { type: String },
  role: { type: String, enum: ['user', 'parent'], default: 'user' },
  parents: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  children: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  lastLocation: {
    coordinates: { type: [Number], default: [0, 0] }, // [lng, lat]
    updatedAt: Date
  },
  socketId: { type: String, default: null }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
