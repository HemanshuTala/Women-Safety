const admin = require('firebase-admin');
const User = require('../models/User'); // To fetch device tokens

// Initialize Firebase Admin SDK once
if (!admin.apps.length) {
  const serviceAccount = require('../../women-safety-fb109-firebase-adminsdk-fbsvc-e4e9857dd5.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

/**
 * Send a notification to all parents linked to the given userId
 * @param {String} userId - ID of user whose parents should be notified
 * @param {Object} payload - Notification payload (title, message, etc.)
 */
exports.notifyParents = async (userId, payload) => {
  try {
    // Fetch the user to get linked parent IDs
    const user = await User.findById(userId).populate('relations');
    if (!user) {
      console.warn(`User not found for notifications: ${userId}`);
      return;
    }

    // Collect all device tokens from parents
    const deviceTokens = [];
    user.relations.forEach(parent => {
      if (parent.deviceTokens && parent.deviceTokens.length) {
        deviceTokens.push(...parent.deviceTokens);
      }
    });

    if (deviceTokens.length === 0) {
      console.warn('No device tokens found for parents');
      return;
    }

    // Prepare notification message
    const message = {
      notification: {
        title: payload.title || 'Alert',
        body: payload.message || '',
      },
      data: {
        journeyId: payload.journeyId ? String(payload.journeyId) : '',
        audioUrl: payload.audioUrl || '',
      },
      tokens: deviceTokens,
    };

    // Send messages in batch
    const response = await admin.messaging().sendMulticast(message);
    console.log(`Sent notifications to parents: success=${response.successCount}, failure=${response.failureCount}`);

  } catch (err) {
    console.error('Error sending notifications', err);
  }
};
