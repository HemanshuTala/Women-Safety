const path = require('path');

// Handles audio upload
exports.uploadAudio = (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'No audio file uploaded.' });
  }

  // Save the file URL path you want to return or store in DB
  const audioUrl = `/uploads/${req.file.filename}`;
  res.status(200).json({ audioUrl });
};
