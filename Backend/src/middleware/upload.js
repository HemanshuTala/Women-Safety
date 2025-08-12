const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure the uploads/audios directory exists
const uploadDir = path.join(__dirname, '..', 'uploads', 'audios');
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    // Keep original extension and add timestamp
    const ext = path.extname(file.originalname);
    const name = path.basename(file.originalname, ext).replace(/\s+/g, '_');
    cb(null, `${Date.now()}_${name}${ext}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 20 * 1024 * 1024 }, // 20MB
  fileFilter: function (req, file, cb) {
    // Accept common audio MIME types
    const allowed = ['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-wav', 'audio/ogg', 'audio/webm', 'audio/aac', 'audio/x-m4a'];
    if (allowed.includes(file.mimetype)) return cb(null, true);
    // If you want to accept other mimetypes, adjust allowed array
    cb(new Error('Only audio files are allowed.'));
  }
});

module.exports = upload;
