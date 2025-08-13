const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendSms } = require('../services/twilioService');

// In-memory OTP store
const otpStore = new Map(); // key: phone, value: { code, expiresAt }

function signToken(user) {
  return jwt.sign(
    { id: user._id, phone: user.phone, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
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
    console.log(`Generated OTP for ${phone}: ${otp}`);

    otpStore.set(phone, { code: otp, expiresAt: Date.now() + 5 * 60 * 1000 }); // 5 mins expiry

    try {
      await sendSms(phone, `Your verification code is ${otp}`);
    } catch (err) {
      console.warn('Twilio send failed', err.message);
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

    const entry = otpStore.get(phone);
    if (!entry) return res.status(400).json({ message: 'OTP expired or not found' });

    if (entry.expiresAt < Date.now()) {
      otpStore.delete(phone);
      return res.status(400).json({ message: 'OTP expired' });
    }

    if (entry.code !== code) return res.status(400).json({ message: 'Invalid OTP' });

    otpStore.delete(phone);

    let user = await User.findOne({ phone });
    if (!user) user = await User.create({ phone, role: 'user', name: '' });

    const token = signToken(user);
    res.json({ user, token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};
