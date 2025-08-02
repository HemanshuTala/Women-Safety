const Journey = require('../models/Journey');
const EmergencyAction = require('../models/EmergencyAction');
const notificationService = require('../services/notificationService');
const twilioService = require('../services/twilioService');

// Start a new journey
exports.start = async (req, res, next) => {
  try {
    /*
    Expected req.body:
    {
      userId,           // String (ObjectId)
      startLocation: { latitude, longitude, address },
      endLocation: { latitude, longitude, address }
    }
    */

    const { userId, startLocation, endLocation } = req.body;

    if (!userId || !startLocation || !endLocation) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Check if user already has an active journey
    const activeJourney = await Journey.findOne({ userId, status: 'active' });
    if (activeJourney) {
      return res.status(400).json({ message: 'There is already an active journey for this user' });
    }

    const newJourney = new Journey({
      userId,
      startLocation,
      endLocation,
      startedAt: new Date(),
      status: 'active',
      checkpoints: [],
      lastKnownLocation: {
        latitude: startLocation.latitude,
        longitude: startLocation.longitude,
        updatedAt: new Date(),
      },
    });

    await newJourney.save();

    res.status(201).json({ message: 'Journey started', journeyId: newJourney._id });
  } catch (err) {
    next(err);
  }
};

// End an active journey
exports.end = async (req, res, next) => {
  try {
    /*
    Expected req.body:
    {
      userId,      // String (ObjectId)
      journeyId    // String (ObjectId)
    }
    */
    const { userId, journeyId } = req.body;

    if (!userId || !journeyId) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const journey = await Journey.findOne({ _id: journeyId, userId, status: 'active' });
    if (!journey) {
      return res.status(404).json({ message: 'Active journey not found' });
    }

    journey.endedAt = new Date();
    journey.status = 'completed';

    await journey.save();

    res.status(200).json({ message: 'Journey ended successfully' });
  } catch (err) {
    next(err);
  }
};

// Record a checkpoint (Safe / Unsafe / No response)
exports.checkpoint = async (req, res, next) => {
  try {
    /*
    Expected req.body:
    {
      userId,        // String (ObjectId)
      journeyId,     // String (ObjectId)
      status,        // 'safe' | 'unsafe' | 'no_response'
      location: { latitude, longitude }
    }
    */
    const { userId, journeyId, status, location } = req.body;

    if (!userId || !journeyId || !status || !location) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    if (!['safe', 'unsafe', 'no_response'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status value' });
    }

    const journey = await Journey.findOne({ _id: journeyId, userId, status: 'active' });
    if (!journey) {
      return res.status(404).json({ message: 'Active journey not found' });
    }

    const checkpoint = {
      timestamp: new Date(),
      status,
      location,
    };
    journey.checkpoints.push(checkpoint);

    // Update last known location
    journey.lastKnownLocation = {
      latitude: location.latitude,
      longitude: location.longitude,
      updatedAt: new Date(),
    };

    // If status is unsafe or no_response, update journey status and notify parents
    if (status === 'unsafe' || status === 'no_response') {
      journey.status = status === 'unsafe' ? 'unsafe' : 'no_response';

      // Notify parents - assuming notificationService.notifyParents expects userId
      await notificationService.notifyParents(userId, {
        title: 'Safety Alert',
        message: `User marked their journey status as ${status.toUpperCase()}`,
        journeyId: journey._id,
      });

      // Optional: send SMS via Twilio (you can customize message)
      // Could fetch parents phone numbers from User.relations - assuming notificationService handles this
      await twilioService.sendSmsToParents(userId, `Alert: User status is ${status.toUpperCase()}`);
    }

    await journey.save();

    res.status(200).json({ message: 'Checkpoint recorded successfully' });
  } catch (err) {
    next(err);
  }
};

// Handle Emergency (e.g., SOS pressed, voice recorded)
exports.emergency = async (req, res, next) => {
  try {
    /*
    Expected req.body:
    {
      userId,            // String (ObjectId)
      journeyId,         // String (ObjectId)
      action,            // 'sos_call' | 'voice_recording' | 'no_response'
      audioUrl           // optional String when action is voice_recording
    }
    */
    const { userId, journeyId, action, audioUrl } = req.body;

    if (!userId || !journeyId || !action) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    if (!['sos_call', 'voice_recording', 'no_response'].includes(action)) {
      return res.status(400).json({ message: 'Invalid action value' });
    }

    const journey = await Journey.findOne({ _id: journeyId, userId, status: 'active' });
    if (!journey) {
      return res.status(404).json({ message: 'Active journey not found' });
    }

    // Create EmergencyAction record
    const emergency = new EmergencyAction({
      journeyId,
      userId,
      timestamp: new Date(),
      action,
      audioUrl: audioUrl || '',
      notifiedParents: [], // Will fill after notifications
    });

    // Notify parents
    await notificationService.notifyParents(userId, {
      title: 'Emergency Alert',
      message: `User triggered an emergency: ${action.replace('_', ' ')}`,
      journeyId,
      audioUrl,
    });

    // Send SMS / Call parents
    if (action === 'sos_call') {
      await twilioService.sendSmsToParents(userId, 'Emergency SOS alert triggered!');
      await twilioService.makeCallToParents(userId);
    } else if (action === 'voice_recording' && audioUrl) {
      await twilioService.sendSmsToParents(userId, `Emergency voice recording available.`);
    }

    // Mark journey as unsafe to reflect emergency
    journey.status = 'unsafe';
    await journey.save();

    // Save emergency action record with notifiedParents updated if you track them in notificationService
    await emergency.save();

    res.status(200).json({ message: 'Emergency handled successfully' });
  } catch (err) {
    next(err);
  }
};

// Get current active journey for a user
exports.getCurrentJourney = async (req, res, next) => {
  try {
    /*
    Expected req.params.userId
    OR could be in req.query.userId or from JWT decoded token in req.user
    For simplicity, req.params.userId
    */
    const userId = req.params.userId || req.query.userId;

    if (!userId) {
      return res.status(400).json({ message: 'UserId is required' });
    }

    const journey = await Journey.findOne({ userId, status: 'active' });

    if (!journey) {
      return res.status(404).json({ message: 'No active journey found for this user' });
    }

    res.status(200).json({ journey });
  } catch (err) {
    next(err);
  }
};
exports.getJourneyDetails = async (req, res, next) => {
  try {
    /*
    Expected req.params.journeyId
    */
    const journeyId = req.params.journeyId;

    if (!journeyId) {
      return res.status(400).json({ message: 'JourneyId is required' });
    }

    const journey = await Journey.findById(journeyId);
    if (!journey) {
      return res.status(404).json({ message: 'Journey not found' });
    }

    res.status(200).json({ journey });
  } catch (err) {
    next(err);
  }
};
// Update user’s current live location during the journey
exports.updateCurrentLocation = async (req, res, next) => {
  try {
    const { userId, journeyId, latitude, longitude } = req.body;

    if (!userId || !journeyId || !latitude || !longitude) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const journey = await Journey.findOne({ _id: journeyId, userId, status: 'active' });

    if (!journey) {
      return res.status(404).json({ message: 'Active journey not found' });
    }

    journey.lastKnownLocation = {
      latitude,
      longitude,
      updatedAt: new Date(),
    };

    await journey.save();

    // Optional: Emit to socket
    req.io?.to(`parent_${userId}`).emit('location_broadcast', {
      userId,
      journeyId,
      latitude,
      longitude,
      updatedAt: new Date(),
    });

    res.status(200).json({ message: 'Location updated successfully' });
  } catch (err) {
    next(err);
  }
};