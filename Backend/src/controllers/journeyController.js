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
      console.error('Missing required fields:', { userId, startLocation, endLocation });
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Validate coordinates
    if (!startLocation.latitude || !startLocation.longitude || !endLocation.latitude || !endLocation.longitude) {
      console.error('Invalid coordinates:', { startLocation, endLocation });
      return res.status(400).json({ message: 'Invalid location coordinates' });
    }

    // Check if user already has an active journey
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

    // Send SMS to parents
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
    /*
    Expected req.body:
    {
      userId,      // String (ObjectId)
      journeyId,   // String (ObjectId)
      totalDistance, // Number (in km)
      endLocation: { latitude, longitude, address }
    }
    */
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
    journey.endLocation = endLocation; // Update endLocation with final position

    await journey.save();
    console.log(`Journey ended for user ${userId}: ${journeyId}`);

    // Send SMS to parents
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


// Handle Emergency (e.g., SOS pressed, voice recorded)
exports.emergency = async (req, res, next) => {
  try {
    /*
    Expected req.body:
    {
      userId,            // String (ObjectId)
      journeyId,         // String (ObjectId)
      action,            // 'sos_call' | 'voice_recording' | 'no_response'
      location: { latitude, longitude } // Added to match frontend
    }
    */
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

    // Update last known location
    journey.lastKnownLocation = {
      latitude: location.latitude,
      longitude: location.longitude,
      updatedAt: new Date(),
    };

    // Create EmergencyAction record
    const emergency = new EmergencyAction({
      journeyId,
      userId,
      timestamp: new Date(),
      action,
      audioUrl: req.body.audioUrl || '',
      notifiedParents: [],
    });

    // Notify parents
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
    } catch (err) {
      console.error('Error sending emergency notifications:', err);
    }

    // Mark journey as unsafe
    journey.status = 'active';
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
      return res.status(404).json({ message: 'No active journey found for this user' });
    }

    res.status(200).json({ journey });
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

    // Emit to socket
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

