const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    name: String,
    phone: String,
    email: String,
    password: { type: String, required: true },
    role: { type: String, enum: ['user', 'parent'], required: true },

    linkingCode: { type: String, index: true },
    linkingCodeExpiresAt: Date,

    relations: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    usedLinkingCode: String,
    deviceTokens: [String]
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', UserSchema);
