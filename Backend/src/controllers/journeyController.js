const Journey = require('../models/Journey');
const EmergencyAction = require('../models/EmergencyAction');
const notificationService = require('../services/notificationService');
const twilioService = require('../services/twilioService');
const User = require('../models/User'); // Add User model import

// Start a new journey
exports.start = async (req, res, next) => {
  try {
    const { userId, startLocation, endLocation } = req.body;

    if (!userId || !startLocation || !endLocation) {
      console.error('Missing required fields:', { userId, startLocation, endLocation });
      return res.status(400).json({ message: 'Missing required fields' });
    }

    if (!startLocation.latitude || !startLocation.longitude || !endLocation.latitude || !endLocation.longitude) {
      console.error('Invalid coordinates:', { startLocation, endLocation });
      return res.status(400).json({ message: 'Invalid location coordinates' });
    }

    const activeJourney = await Journey.findOne({ userId, status: 'active' });
    if (activeJourney) {
      console.warn(`Active journey already exists for user ${userId}: ${activeJourney._id}`);
      return res.status(400).json({ message: 'There is already an active journey for this user' });
    }

    const newJourney = new Journey({
      userId,
      startLocation,
      endLocation,
      startedAt: new Date(),
      status: 'active',
      checkpoints: [],
      distanceTraveled: 0,
      lastKnownLocation: {
        latitude: startLocation.latitude,
        longitude: startLocation.longitude,
        updatedAt: new Date(),
      },
    });

    await newJourney.save();
    console.log(`Journey started for user ${userId}: ${newJourney._id}`);

    const startMessage = `Journey started from (${startLocation.latitude}, ${startLocation.longitude}) to ${endLocation.address}`;
    try {
      await twilioService.sendSmsToParents(userId, startMessage);
      await notificationService.notifyParents(userId, {
        title: 'Journey Started',
        message: startMessage,
        journeyId: newJourney._id,
      });
      console.log(`SMS and notification sent for journey start: ${newJourney._id}`);
    } catch (err) {
      console.error('Error sending journey start notifications:', err);
    }

    res.status(201).json({ message: 'Journey started', journeyId: newJourney._id.toString() });
  } catch (err) {
    console.error('Error starting journey:', err);
    next(err);
  }
};

// End an active journey
exports.end = async (req, res, next) => {
  try {
    const { userId, journeyId, totalDistance, endLocation } = req.body;

    if (!userId || !journeyId || totalDistance == null || !endLocation) {
      console.error('Missing required fields:', { userId, journeyId, totalDistance, endLocation });
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const journey = await Journey.findOne({ _id: journeyId, userId, status: 'active' });
    if (!journey) {
      console.warn(`Active journey not found for user ${userId}, journey ${journeyId}`);
      return res.status(404).json({ message: 'Active journey not found' });
    }

    journey.endedAt = new Date();
    journey.status = 'completed';
    journey.distanceTraveled = totalDistance;
    journey.endLocation = endLocation;

    await journey.save();
    console.log(`Journey ended for user ${userId}: ${journeyId}`);

    const endMessage = `Journey ended. Total distance: ${totalDistance.toFixed(2)} km. Ended at (${endLocation.latitude}, ${endLocation.longitude})`;
    try {
      await twilioService.sendSmsToParents(userId, endMessage);
      await notificationService.notifyParents(userId, {
        title: 'Journey Ended',
        message: endMessage,
        journeyId,
      });
      console.log(`SMS and notification sent for journey end: ${journeyId}`);
    } catch (err) {
      console.error('Error sending journey end notifications:', err);
    }

    res.status(200).json({ message: 'Journey ended successfully' });
  } catch (err) {
    console.error('Error ending journey:', err);
    next(err);
  }
};

// Handle Emergency
exports.emergency = async (req, res, next) => {
  try {
    const { userId, journeyId, action, location } = req.body;

    if (!userId || !journeyId || !action || !location) {
      console.error('Missing required fields:', { userId, journeyId, action, location });
      return res.status(400).json({ message: 'Missing required fields' });
    }

    if (!['sos_call', 'voice_recording', 'no_response'].includes(action)) {
      console.error('Invalid action value:', action);
      return res.status(400).json({ message: 'Invalid action value' });
    }

    const journey = await Journey.findOne({ _id: journeyId, userId, status: 'active' });
    if (!journey) {
      console.warn(`Active journey not found for user ${userId}, journey ${journeyId}`);
      return res.status(404).json({ message: 'Active journey not found' });
    }

    journey.lastKnownLocation = {
      latitude: location.latitude,
      longitude: location.longitude,
      updatedAt: new Date(),
    };

    const emergency = new EmergencyAction({
      journeyId,
      userId,
      timestamp: new Date(),
      action,
      audioUrl: req.body.audioUrl || '',
      notifiedParents: [],
      location: {
        latitude: location.latitude,
        longitude: location.longitude,
      },
    });

    const message = `Emergency ${action.replace('_', ' ')} triggered at (${location.latitude}, ${location.longitude})`;
    try {
      await twilioService.sendSmsToParents(userId, message);
      if (action === 'sos_call') {
        await twilioService.makeCallToParents(userId);
        console.log(`SOS call initiated for user ${userId}, journey ${journeyId}`);
      }
      await notificationService.notifyParents(userId, {
        title: 'Emergency Alert',
        message,
        journeyId,
        audioUrl: req.body.audioUrl,
      });
      console.log(`SMS and notification sent for emergency: ${action}, journey ${journeyId}`);
      req.io?.to(userId).emit('emergency', { message: `Emergency ${action} processed`, journeyId });
    } catch (err) {
      console.error('Error sending emergency notifications:', err);
    }

    await journey.save();
    await emergency.save();

    res.status(200).json({ message: 'Emergency handled successfully' });
  } catch (err) {
    console.error('Error handling emergency:', err);
    next(err);
  }
};

// Get current active journey for a user
exports.getCurrentJourney = async (req, res, next) => {
  try {
    const userId = req.params.userId || req.query.userId;
    if (!userId) {
      console.error('UserId is required');
      return res.status(400).json({ message: 'UserId is required' });
    }

    const journey = await Journey.findOne({ userId, status: 'active' });
    if (!journey) {
      console.log(`No active journey found for user ${userId}`);
      return res.status(404).json({ message: 'No active journey found for this user', active: false });
    }

    res.status(200).json({
      active: true,
      journeyId: journey._id.toString(),
      startLocation: journey.startLocation,
      endLocation: journey.endLocation,
      lastKnownLocation: journey.lastKnownLocation,
      distanceTraveled: journey.distanceTraveled,
    });
  } catch (err) {
    console.error('Error fetching current journey:', err);
    next(err);
  }
};

// Get journey details by ID
exports.getJourneyDetails = async (req, res, next) => {
  try {
    const journeyId = req.params.journeyId;
    if (!journeyId) {
      console.error('JourneyId is required');
      return res.status(400).json({ message: 'JourneyId is required' });
    }

    const journey = await Journey.findById(journeyId);
    if (!journey) {
      console.warn(`Journey not found: ${journeyId}`);
      return res.status(404).json({ message: 'Journey not found' });
    }

    res.status(200).json({ journey });
  } catch (err) {
    console.error('Error fetching journey details:', err);
    next(err);
  }
};

// Update user’s current live location during the journey
exports.updateCurrentLocation = async (req, res, next) => {
  try {
    const { userId, journeyId, latitude, longitude } = req.body;

    if (!userId || !journeyId || latitude == null || longitude == null) {
      console.error('Missing required fields:', { userId, journeyId, latitude, longitude });
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const journey = await Journey.findOne({ _id: journeyId, userId, status: 'active' });
    if (!journey) {
      console.warn(`Active journey not found for user ${userId}, journey ${journeyId}`);
      return res.status(404).json({ message: 'Active journey not found' });
    }

    journey.lastKnownLocation = {
      latitude,
      longitude,
      updatedAt: new Date(),
    };

    await journey.save();
    console.log(`Location updated for user ${userId}, journey ${journeyId}: (${latitude}, ${longitude})`);

    req.io?.to(userId).emit('location_broadcast', {
      userId,
      journeyId,
      latitude,
      longitude,
      updatedAt: new Date(),
    });

    res.status(200).json({ message: 'Location updated successfully' });
  } catch (err) {
    console.error('Error updating location:', err);
    next(err);
  }
};

// Get all emergency actions for a user's linked accounts
exports.getEmergencyHistory = async (req, res, next) => {
  try {
    const userId = req.params.userId;
    if (!userId) {
      console.error('UserId is required');
      return res.status(400).json({ message: 'UserId is required' });
    }

    const user = await User.findById(userId);
    if (!user) {
      console.warn(`User not found: ${userId}`);
      return res.status(404).json({ message: 'User not found' });
    }

    const linkedUserIds = user.relations.map(relation => relation.userId).concat(userId);
    const emergencies = await EmergencyAction.find({ userId: { $in: linkedUserIds } })
      .populate('journeyId', 'startLocation endLocation')
      .sort({ timestamp: -1 });

    const formattedEmergencies = emergencies.map(emergency => ({
      userId: emergency.userId,
      journeyId: emergency.journeyId?._id.toString(),
      message: `Emergency ${emergency.action.replace('_', ' ')} triggered at (${emergency.location?.latitude || 0}, ${emergency.location?.longitude || 0})`,
      action: emergency.action,
      timestamp: emergency.timestamp,
      location: emergency.location || { latitude: 0, longitude: 0 },
      audioUrl: emergency.audioUrl || '',
      journeyStart: emergency.journeyId?.startLocation,
      journeyEnd: emergency.journeyId?.endLocation,
    }));

    console.log(`Fetched ${emergencies.length} emergency actions for user ${userId} and linked users`);
    res.status(200).json({ emergencies: formattedEmergencies });
  } catch (err) {
    console.error('Error fetching emergency history:', err);
    next(err);
  }
};