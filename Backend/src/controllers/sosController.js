const SOS = require('../models/SOS');
const { emitSOS } = require('../services/socketService');
const { sendSms } = require('../services/twilioService');
const path = require('path');
const User = require('../models/User');
exports.sendSos = async (req, res) => {
  try {
    const user = req.user;
    let { lat, lng, message } = req.body;
    let audioUrl = req.body.audioUrl || '';

    if (req.file) {
      // Build a public URL for the uploaded file
      // e.g. http://your-server-host/uploads/audios/<filename>
      const filename = path.basename(req.file.path);
      const host = `${req.protocol}://${req.get('host')}`;
      audioUrl = `${host}/uploads/audios/${filename}`;
    }

    if (!lat || !lng) return res.status(400).json({ message: 'lat and lng are required' });

    const coords = [parseFloat(lng), parseFloat(lat)];

    const sos = await SOS.create({
      user: user._id,
      coords,
      message: message || '',
      audioUrl: audioUrl || ''
    });

    const parents = await User.find({ _id: { $in: user.parents } });

    emitSOS(user._id.toString(), {
      sosId: sos._id,
      userId: user._id,
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      message: sos.message,
      audioUrl: sos.audioUrl,
      createdAt: sos.createdAt
    });

    for (const p of parents) {
      if (p.phone) {
        const body = `SOS from ${user.name || user.phone}. Msg: ${message || 'No message'}. Location: https://www.google.com/maps?q=${lat},${lng}`;
        try {
          await sendSms(p.phone, body);
          sos.notifiedParents.push(p._id);
        } catch (err) {
          console.warn('Failed to send SMS to parent', p.phone, err.message);
        }
      }
    }

    await sos.save();

    res.json({ success: true, sos });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getSos = async (req, res) => {
  try {
    const sos = await SOS.findById(req.params.id).populate('user', 'name phone');
    if (!sos) return res.status(404).json({ message: 'SOS not found' });
    res.json(sos);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};
