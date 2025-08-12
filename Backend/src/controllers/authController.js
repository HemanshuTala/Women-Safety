const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const redis = require('../services/redisClient');
const { sendSms } = require('../services/twilioService');

function signToken(user) {
  return jwt.sign({ id: user._id, phone: user.phone, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });
}

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit
}

exports.register = async (req, res) => {
  try {
    const { name, phone, password, role } = req.body;
    const exists = await User.findOne({ phone });
    if (exists) return res.status(400).json({ message: 'Phone already registered' });

    const passwordHash = password ? await bcrypt.hash(password, 10) : undefined;
    const user = await User.create({ name, phone, passwordHash, role: role || 'user' });
    const token = signToken(user);
    res.json({ user, token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.login = async (req, res) => {
  try {
    const { phone, password } = req.body;
    const user = await User.findOne({ phone });
    if (!user) return res.status(400).json({ message: 'No user found' });

    if (password) {
      const ok = await bcrypt.compare(password, user.passwordHash || '');
      if (!ok) return res.status(401).json({ message: 'Invalid credentials' });
    }

    const token = signToken(user);
    res.json({ user, token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.sendOtp = async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.status(400).json({ message: 'Phone required' });

    const otp = generateOtp();
    await redis.set(`otp:${phone}`, otp, 'EX', 300); // 5 minutes

    try {
      await sendSms(phone, `Your verification code is ${otp}`);
    } catch (err) {
      console.warn('Twilio send failed', err.message);
      // OTP still set in Redis for test/dev
    }

    res.json({ success: true, message: 'OTP sent' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const { phone, code } = req.body;
    if (!phone || !code) return res.status(400).json({ message: 'Phone and code required' });

    const stored = await redis.get(`otp:${phone}`);
    if (!stored) return res.status(400).json({ message: 'OTP expired or not found' });
    if (stored !== code) return res.status(400).json({ message: 'Invalid OTP' });

    await redis.del(`otp:${phone}`);

    let user = await User.findOne({ phone });
    if (!user) user = await User.create({ phone, role: 'user', name: '' });

    const token = signToken(user);
    res.json({ user, token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};
