const twilio = require('twilio');
const User = require('../models/User');

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const fromNumber = process.env.TWILIO_PHONE_NUMBER;

if (!accountSid || !authToken || !fromNumber) {
  console.warn('Twilio credentials are missing in environment variables.');
}

const client = twilio(accountSid, authToken);

/**
 * Get parent phone numbers linked to a userId
 * @param {String} userId
 * @returns {Promise<String[]>} Array of phone numbers
 */
async function getParentPhoneNumbers(userId) {
  const user = await User.findById(userId).populate('relations');
  if (!user) return [];

  const phoneNumbers = [];
  user.relations.forEach(parent => {
    if (parent.phone) {
      phoneNumbers.push(parent.phone);
    }
  });
  return phoneNumbers;
}

/**
 * Send SMS to parent's phone numbers linked to userId
 * @param {String} userId
 * @param {String} message
 */
exports.sendSmsToParents = async (userId, message) => {
  try {
    const phoneNumbers = await getParentPhoneNumbers(userId);
    if (phoneNumbers.length === 0) {
      console.warn('No parent phone numbers found for SMS');
      return;
    }
    for (const toNumber of phoneNumbers) {
      await client.messages.create({
        body: message,
        from: fromNumber,
        to: toNumber,
      });
      console.log(`SMS sent to ${toNumber}`);
    }
  } catch (err) {
    console.error('Error sending SMS via Twilio', err);
  }
};

/**
 * Make a call to parents linked to userId
 * Note: This example just places a call to the phone that plays a message or connects to a number
 * You need to configure TwiML URLs for call control.
 */
exports.makeCallToParents = async (userId) => {
  try {
    const phoneNumbers = await getParentPhoneNumbers(userId);
    if (phoneNumbers.length === 0) {
      console.warn('No parent phone numbers found to call');
      return;
    }

    for (const toNumber of phoneNumbers) {
      await client.calls.create({
        url: 'http://demo.twilio.com/docs/voice.xml', // Example TwiML URL; replace with your own
        to: toNumber,
        from: fromNumber,
      });
      console.log(`Call initiated to ${toNumber}`);
    }
  } catch (err) {
    console.error('Error making call via Twilio', err);
  }
};
