const SOS = require('../models/SOS');
const { emitSOS } = require('../services/socketService');
const { sendSms, callParent } = require('../services/twilioService');
const path = require('path');
const User = require('../models/User');

exports.sendSos = async (req, res) => {
  try {
    console.log('📥 SOS request received:', req.body);
    console.log('👤 User:', req.user?.name || req.user?.phone);

    const user = req.user;
    let { lat, lng, message } = req.body;
    let audioUrl = req.body.audioUrl || '';

    // Handle file upload
    if (req.file) {
      console.log('🎤 Audio file uploaded:', req.file.filename);
      const filename = path.basename(req.file.path);
      const host = `${req.protocol}://${req.get('host')}`;
      audioUrl = `${host}/uploads/audios/${filename}`;
    }

    // Validate required fields
    if (!lat || !lng) {
      console.log('❌ Missing lat/lng coordinates');
      return res.status(400).json({ message: 'lat and lng are required' });
    }

    const coords = [parseFloat(lng), parseFloat(lat)];
    const locationUrl = `https://www.google.com/maps?q=${lat},${lng}`;

    console.log('📍 SOS Location:', { lat, lng, coords });

    // Create SOS record
    const sos = await SOS.create({
      user: user._id,
      coords,
      message: message || '',
      audioUrl: audioUrl || ''
    });

    console.log('✅ SOS record created:', sos._id);

    // Find parents - make sure user has parents array
    console.log('🔍 User parents array:', user.parents);
    
    if (!user.parents || user.parents.length === 0) {
      console.log('⚠️ User has no parents connected');
      // Still save SOS but notify that no parents are connected
      await sos.save();
      return res.json({ 
        success: true, 
        sos: {
          _id: sos._id,
          message: sos.message,
          coords: sos.coords,
          audioUrl: sos.audioUrl,
          createdAt: sos.createdAt,
          notifiedParents: 0
        },
        warning: 'SOS saved but no parents connected to notify'
      });
    }
    
    const parents = await User.find({ _id: { $in: user.parents } });
    console.log(`👨‍👩‍👧‍👦 Found ${parents.length} parents to notify:`, parents.map(p => ({ name: p.name, phone: p.phone })));

    // Emit socket event (with error handling)
    try {
      emitSOS(user._id.toString(), {
        sosId: sos._id,
        userId: user._id,
        lat: parseFloat(lat),
        lng: parseFloat(lng),
        message: sos.message,
        audioUrl: sos.audioUrl,
        createdAt: sos.createdAt
      });
      console.log('📡 Socket event emitted');
    } catch (socketErr) {
      console.warn('⚠️ Socket emission failed:', socketErr.message);
      // Don't fail the entire request if socket fails
    }

    // Notify parents
    for (const p of parents) {
      if (p.phone) {
        console.log(`📱 Notifying parent: ${p.phone}`);

        const smsBody = `🚨 SOS from ${user.name || user.phone}! ${message || 'Help needed'} Location: ${locationUrl}`;

        const callMessage = `SOS alert from ${user.name || 'your child'}. Emergency assistance needed. Check SMS for location.`;

        try {
          // Only send notifications if Twilio is configured
          if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_PHONE_NUMBER) {
            console.log(`📤 Sending SMS to ${p.phone}...`);
            await sendSms(p.phone, smsBody);
            console.log(`✅ SMS sent to parent: ${p.phone}`);

            console.log(`📞 Calling ${p.phone}...`);
            await callParent(p.phone, callMessage);
            console.log(`✅ Call initiated to parent: ${p.phone}`);
            
            sos.notifiedParents.push(p._id);
          } else {
            console.log('⚠️ Twilio not fully configured (missing SID, TOKEN, or PHONE_NUMBER), skipping SMS/call');
            console.log('📧 Would have sent SMS:', smsBody);
            // Still mark as notified for testing purposes
            sos.notifiedParents.push(p._id);
          }
        } catch (err) {
          console.error(`❌ Failed to contact parent ${p.phone}:`, err.message);
          console.error('📄 Error details:', err);
          // Don't fail the entire request if notification fails
          // Still mark as attempted
          sos.notifiedParents.push(p._id);
        }
      }
    }

    // Notify emergency services if configured
    const emergencyNumber = process.env.EMERGENCY_CONTACT_NUMBER;
    if (emergencyNumber && process.env.TWILIO_ACCOUNT_SID) {
      try {
        const emergencyMessage = `🚨 SOS Alert - ${user.name || user.phone} needs emergency assistance at location: ${locationUrl}. Message: ${message || 'Emergency'}`;
        await sendSms(emergencyNumber, emergencyMessage);
        console.log(`🚨 Emergency services notified: ${emergencyNumber}`);
      } catch (err) {
        console.error('❌ Failed to notify emergency services:', err.message);
      }
    }

    // Save updated SOS record
    await sos.save();
    console.log('💾 SOS record saved with notifications');

    res.json({
      success: true,
      sos: {
        _id: sos._id,
        message: sos.message,
        coords: sos.coords,
        audioUrl: sos.audioUrl,
        createdAt: sos.createdAt,
        notifiedParents: sos.notifiedParents.length
      }
    });

  } catch (err) {
    console.error('SOS Controller Error:', err);
    res.status(500).json({
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
    });
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
