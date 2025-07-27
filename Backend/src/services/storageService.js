const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');

// Assuming Firebase Admin SDK is already initialized (as in notificationService)
if (!admin.apps.length) {
  const serviceAccount = require('../../firebase-service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket: '<your-firebase-bucket-url>', // e.g. 'your-project-id.appspot.com'
  });
}

const bucket = admin.storage().bucket();

/**
 * Upload audio file buffer to Firebase Storage and return public URL
 * @param {Buffer} fileBuffer - Audio file as buffer
 * @param {String} filename - Original filename or generated name
 * @returns {Promise<String>} Public HTTPS URL of uploaded file
 */
exports.uploadAudio = async (fileBuffer, filename = 'audio.webm') => {
  try {
    const uuid = uuidv4();
    const file = bucket.file(`audio/${uuid}-${filename}`);

    await file.save(fileBuffer, {
      metadata: {
        contentType: 'audio/webm',
        metadata: {
          firebaseStorageDownloadTokens: uuid,
        },
      },
    });

    const publicUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(file.name)}?alt=media&token=${uuid}`;

    return publicUrl;
  } catch (error) {
    console.error('Error uploading audio:', error);
    throw error;
  }
};
