const Journey = require('../models/Journey');
const LocationUpdate = require('../models/LocationUpdate');
const SafetyAlert = require('../models/SafetyAlert');
const CheckInRequest = require('../models/CheckInRequest');
const User = require('../models/User');
const { emitJourneyUpdate, emitSafetyAlert } = require('../services/socketService');

// Create a new journey
exports.createJourney = async (req, res) => {
  try {
    console.log('📍 Creating new journey:', req.body);
    
    const {
      startLocation,
      destination,
      plannedRoute,
      transportMode,
      scheduledTime,
      sharedWithParents
    } = req.body;

    // Validate required fields
    if (!startLocation || !destination || !scheduledTime) {
      return res.status(400).json({
        message: 'Start location, destination, and scheduled time are required'
      });
    }

    // Create journey
    const journey = new Journey({
      user: req.user._id,
      startLocation: {
        type: 'Point',
        coordinates: [startLocation.lng, startLocation.lat],
        address: startLocation.address
      },
      destination: {
        type: 'Point',
        coordinates: [destination.lng, destination.lat],
        address: destination.address
      },
      plannedRoute,
      transportMode: transportMode || 'walking',
      scheduledTime: new Date(scheduledTime),
      sharedWithParents: sharedWithParents || []
    });

    await journey.save();
    await journey.populate('user', 'name phone');
    await journey.populate('sharedWithParents', 'name phone');

    console.log('✅ Journey created:', journey._id);

    // Notify parents about planned journey
    if (journey.sharedWithParents.length > 0) {
      emitJourneyUpdate(journey._id.toString(), {
        type: 'journey_planned',
        journey: journey,
        message: `${journey.user.name} has planned a journey to ${journey.destination.address}`
      });
    }

    res.status(201).json({
      success: true,
      journey
    });

  } catch (error) {
    console.error('❌ Error creating journey:', error);
    res.status(500).json({
      message: 'Failed to create journey',
      error: error.message
    });
  }
};

// Start an active journey
exports.startJourney = async (req, res) => {
  try {
    const { journeyId } = req.params;
    const { currentLocation } = req.body;

    const journey = await Journey.findById(journeyId);
    if (!journey) {
      return res.status(404).json({ message: 'Journey not found' });
    }

    if (journey.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    // Update journey status
    journey.status = 'active';
    journey.startTime = new Date();
    
    // Update start location if provided
    if (currentLocation) {
      journey.startLocation = {
        type: 'Point',
        coordinates: [currentLocation.lng, currentLocation.lat],
        address: currentLocation.address
      };
    }

    await journey.save();
    await journey.populate('user', 'name phone');
    await journey.populate('sharedWithParents', 'name phone');

    console.log('🚀 Journey started:', journey._id);

    // Create initial location update
    if (currentLocation) {
      const locationUpdate = new LocationUpdate({
        journey: journey._id,
        user: req.user._id,
        location: {
          type: 'Point',
          coordinates: [currentLocation.lng, currentLocation.lat]
        },
        batteryLevel: currentLocation.batteryLevel || 100
      });
      await locationUpdate.save();
    }

    // Notify parents
    if (journey.sharedWithParents.length > 0) {
      emitJourneyUpdate(journey._id.toString(), {
        type: 'journey_started',
        journey: journey,
        message: `${journey.user.name} has started their journey`
      });
    }

    res.json({
      success: true,
      journey
    });

  } catch (error) {
    console.error('❌ Error starting journey:', error);
    res.status(500).json({
      message: 'Failed to start journey',
      error: error.message
    });
  }
};

// Update location during journey
exports.updateLocation = async (req, res) => {
  try {
    const { journeyId } = req.params;
    const {
      lat,
      lng,
      speed,
      heading,
      accuracy,
      batteryLevel,
      address
    } = req.body;

    const journey = await Journey.findById(journeyId);
    if (!journey) {
      return res.status(404).json({ message: 'Journey not found' });
    }

    if (journey.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    if (journey.status !== 'active') {
      return res.status(400).json({ message: 'Journey is not active' });
    }

    // Create location update
    const locationUpdate = new LocationUpdate({
      journey: journey._id,
      user: req.user._id,
      location: {
        type: 'Point',
        coordinates: [lng, lat]
      },
      speed: speed || 0,
      heading: heading || 0,
      accuracy: accuracy || 0,
      batteryLevel: batteryLevel || 100,
      address: address,
      isMoving: (speed || 0) > 1 // Consider moving if speed > 1 km/h
    });

    await locationUpdate.save();

    // Calculate journey progress
    const progress = await calculateJourneyProgress(journey, locationUpdate);

    // Check for safety alerts
    await checkSafetyAlerts(journey, locationUpdate);

    // Emit real-time update to parents
    if (journey.sharedWithParents.length > 0) {
      emitJourneyUpdate(journey._id.toString(), {
        type: 'location_update',
        journeyId: journey._id,
        location: {
          lat,
          lng,
          speed,
          heading,
          batteryLevel,
          address
        },
        progress: progress,
        timestamp: new Date()
      });
    }

    res.json({
      success: true,
      locationUpdate: {
        id: locationUpdate._id,
        progress: progress
      }
    });

  } catch (error) {
    console.error('❌ Error updating location:', error);
    res.status(500).json({
      message: 'Failed to update location',
      error: error.message
    });
  }
};

// Complete journey
exports.completeJourney = async (req, res) => {
  try {
    const { journeyId } = req.params;
    const { status, currentLocation } = req.body;

    const journey = await Journey.findById(journeyId);
    if (!journey) {
      return res.status(404).json({ message: 'Journey not found' });
    }

    if (journey.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    // Update journey
    journey.status = status || 'completed';
    journey.endTime = new Date();
    
    if (journey.startTime) {
      journey.actualDuration = Math.floor((journey.endTime - journey.startTime) / 1000);
    }

    // Calculate metrics
    const metrics = await calculateJourneyMetrics(journey._id);
    journey.metrics = metrics;

    await journey.save();
    await journey.populate('user', 'name phone');

    console.log('🏁 Journey completed:', journey._id);

    // Create safety alert for safe arrival
    if (status === 'completed') {
      const safetyAlert = new SafetyAlert({
        journey: journey._id,
        user: req.user._id,
        alertType: 'safe_arrival',
        severity: 'low',
        message: `${journey.user.name} has arrived safely at ${journey.destination.address}`,
        location: journey.destination
      });
      await safetyAlert.save();

      // Notify parents
      if (journey.sharedWithParents.length > 0) {
        emitSafetyAlert(journey._id.toString(), {
          type: 'safe_arrival',
          journey: journey,
          alert: safetyAlert,
          message: `${journey.user.name} has arrived safely`
        });
      }
    }

    res.json({
      success: true,
      journey
    });

  } catch (error) {
    console.error('❌ Error completing journey:', error);
    res.status(500).json({
      message: 'Failed to complete journey',
      error: error.message
    });
  }
};

// Get active journeys for parent monitoring
exports.getActiveJourneys = async (req, res) => {
  try {
    const parentId = req.user._id;

    // Find all active journeys where this user is a parent
    const journeys = await Journey.find({
      sharedWithParents: parentId,
      status: 'active'
    })
    .populate('user', 'name phone')
    .populate('sharedWithParents', 'name phone')
    .sort({ startTime: -1 });

    // Get latest location for each journey
    const journeysWithLocations = await Promise.all(
      journeys.map(async (journey) => {
        const latestLocation = await LocationUpdate.findOne({
          journey: journey._id
        }).sort({ timestamp: -1 });

        const progress = latestLocation ? 
          await calculateJourneyProgress(journey, latestLocation) : 0;

        return {
          ...journey.toObject(),
          latestLocation,
          progress
        };
      })
    );

    res.json({
      success: true,
      journeys: journeysWithLocations
    });

  } catch (error) {
    console.error('❌ Error getting active journeys:', error);
    res.status(500).json({
      message: 'Failed to get active journeys',
      error: error.message
    });
  }
};

// Get journey history
exports.getJourneyHistory = async (req, res) => {
  try {
    const { childId, limit = 20, offset = 0 } = req.query;
    const parentId = req.user._id;

    let query = {};
    
    if (childId) {
      // Parent viewing specific child's history
      query = {
        user: childId,
        sharedWithParents: parentId
      };
    } else {
      // User viewing their own history
      query = { user: req.user._id };
    }

    const journeys = await Journey.find(query)
      .populate('user', 'name phone')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(offset));

    const total = await Journey.countDocuments(query);

    res.json({
      success: true,
      journeys,
      pagination: {
        total,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: (parseInt(offset) + parseInt(limit)) < total
      }
    });

  } catch (error) {
    console.error('❌ Error getting journey history:', error);
    res.status(500).json({
      message: 'Failed to get journey history',
      error: error.message
    });
  }
};

// Helper functions
async function calculateJourneyProgress(journey, currentLocation) {
  try {
    // Simple progress calculation based on distance to destination
    const destCoords = journey.destination.coordinates;
    const currentCoords = currentLocation.location.coordinates;
    
    // Calculate distance to destination (simplified)
    const distanceToDestination = calculateDistance(
      currentCoords[1], currentCoords[0],
      destCoords[1], destCoords[0]
    );
    
    // If we have planned route distance, calculate progress
    if (journey.plannedRoute && journey.plannedRoute.distance) {
      const totalDistance = journey.plannedRoute.distance;
      const progress = Math.max(0, Math.min(1, 1 - (distanceToDestination / totalDistance)));
      return Math.round(progress * 100) / 100; // Round to 2 decimal places
    }
    
    // Fallback: if very close to destination, consider it nearly complete
    return distanceToDestination < 100 ? 0.95 : 0.1;
    
  } catch (error) {
    console.error('Error calculating progress:', error);
    return 0;
  }
}

async function checkSafetyAlerts(journey, locationUpdate) {
  try {
    const alerts = [];
    
    // Check battery level
    if (locationUpdate.batteryLevel < 20) {
      const existingAlert = await SafetyAlert.findOne({
        journey: journey._id,
        alertType: 'low_battery',
        resolved: false
      });
      
      if (!existingAlert) {
        const alert = new SafetyAlert({
          journey: journey._id,
          user: journey.user,
          alertType: 'low_battery',
          severity: locationUpdate.batteryLevel < 10 ? 'high' : 'medium',
          message: `Battery level is low (${locationUpdate.batteryLevel}%)`,
          location: locationUpdate.location,
          metadata: { batteryLevel: locationUpdate.batteryLevel }
        });
        await alert.save();
        alerts.push(alert);
      }
    }
    
    // Check for unexpected stops (not moving for more than 10 minutes)
    if (!locationUpdate.isMoving) {
      const recentUpdates = await LocationUpdate.find({
        journey: journey._id,
        timestamp: { $gte: new Date(Date.now() - 10 * 60 * 1000) }
      }).sort({ timestamp: -1 });
      
      const allStopped = recentUpdates.every(update => !update.isMoving);
      
      if (allStopped && recentUpdates.length >= 3) {
        const existingAlert = await SafetyAlert.findOne({
          journey: journey._id,
          alertType: 'unexpected_stop',
          resolved: false
        });
        
        if (!existingAlert) {
          const alert = new SafetyAlert({
            journey: journey._id,
            user: journey.user,
            alertType: 'unexpected_stop',
            severity: 'medium',
            message: 'User has stopped moving for an extended period',
            location: locationUpdate.location,
            metadata: { stopDuration: 600 } // 10 minutes
          });
          await alert.save();
          alerts.push(alert);
        }
      }
    }
    
    // Emit alerts to parents
    for (const alert of alerts) {
      if (journey.sharedWithParents.length > 0) {
        emitSafetyAlert(journey._id.toString(), {
          type: alert.alertType,
          alert: alert,
          journey: journey
        });
      }
    }
    
  } catch (error) {
    console.error('Error checking safety alerts:', error);
  }
}

async function calculateJourneyMetrics(journeyId) {
  try {
    const locationUpdates = await LocationUpdate.find({ journey: journeyId })
      .sort({ timestamp: 1 });
    
    if (locationUpdates.length === 0) {
      return {};
    }
    
    const speeds = locationUpdates.map(update => update.speed).filter(speed => speed > 0);
    const averageSpeed = speeds.length > 0 ? 
      speeds.reduce((sum, speed) => sum + speed, 0) / speeds.length : 0;
    const maxSpeed = speeds.length > 0 ? Math.max(...speeds) : 0;
    
    const alertsCount = await SafetyAlert.countDocuments({ journey: journeyId });
    
    return {
      averageSpeed: Math.round(averageSpeed * 100) / 100,
      maxSpeed: Math.round(maxSpeed * 100) / 100,
      alertsCount,
      safetyScore: Math.max(0, 100 - (alertsCount * 10)) // Simple safety score
    };
    
  } catch (error) {
    console.error('Error calculating metrics:', error);
    return {};
  }
}

// Haversine formula for distance calculation
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // Earth's radius in meters
  const φ1 = lat1 * Math.PI/180;
  const φ2 = lat2 * Math.PI/180;
  const Δφ = (lat2-lat1) * Math.PI/180;
  const Δλ = (lon2-lon1) * Math.PI/180;

  const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
          Math.cos(φ1) * Math.cos(φ2) *
          Math.sin(Δλ/2) * Math.sin(Δλ/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

  return R * c; // Distance in meters
}