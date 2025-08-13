const Twilio = require('twilio');
const client = new Twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

async function sendSms(to, body) {
  return client.messages.create({
    from: process.env.TWILIO_PHONE_NUMBER,
    to,
    body
  });
}

async function callParent(to, message) {
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
