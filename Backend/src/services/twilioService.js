const Twilio = require('twilio');

// Initialize Twilio client only if credentials are available
let client = null;
if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
  try {
    client = new Twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
    console.log('✅ Twilio client initialized');
  } catch (err) {
    console.error('❌ Failed to initialize Twilio client:', err.message);
  }
} else {
  console.warn('⚠️ Twilio credentials not found in environment variables');
}

async function sendSms(to, body) {
  if (!client) {
    throw new Error('Twilio client not initialized');
  }
  
  if (!process.env.TWILIO_PHONE_NUMBER) {
    throw new Error('TWILIO_PHONE_NUMBER not configured');
  }
  
  return client.messages.create({
    from: process.env.TWILIO_PHONE_NUMBER,
    to,
    body
  });
}

async function callParent(to, message) {
  if (!client) {
    throw new Error('Twilio client not initialized');
  }
  
  if (!process.env.TWILIO_PHONE_NUMBER) {
    throw new Error('TWILIO_PHONE_NUMBER not configured');
  }
  
  return client.calls.create({
    twiml: `<Response><Say>${message}</Say></Response>`,
    to,
    from: process.env.TWILIO_PHONE_NUMBER
  });
}

module.exports = {
  sendSms,
  callParent
};
