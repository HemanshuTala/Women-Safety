const Location = require('../models/Location');
const User = require('../models/User');
const { emitLocationToParents } = require('../services/socketService');

exports.updateLocation = async (req, res) => {
  try {
    const { lat, lng, speed, accuracy, timestamp } = req.body;
    const user = req.user;

    const coords = [parseFloat(lng), parseFloat(lat)];
    const loc = await Location.create({
      user: user._id,
      coords,
      speed,
      accuracy,
      timestamp: timestamp || Date.now()
    });

    user.lastLocation = { coordinates: coords, updatedAt: new Date() };
    await user.save();

    emitLocationToParents(user._id.toString(), {
      userId: user._id,
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      speed,
      accuracy,
      timestamp: loc.timestamp
    });

    res.json({ success: true, loc });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getLatestLocation = async (req, res) => {
  try {
    const targetId = req.params.id;
    const user = await User.findById(targetId);
    if (!user) return res.status(404).json({ message: 'User not found' });
    res.json(user.lastLocation);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};
