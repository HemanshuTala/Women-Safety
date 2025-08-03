const express = require('express');
const router = express.Router();
const journeyController = require('../controllers/journeyController');

const multer = require('multer');
const path = require('path');
const { uploadAudio } = require('../controllers/create/uploadAudio');
router.post('/start', journeyController.start);
router.post('/end', journeyController.end);

router.post('/emergency', journeyController.emergency);
router.get('/:userId/current', journeyController.getCurrentJourney);

router.post('/update-location', journeyController.updateCurrentLocation);






const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, '../uploads'));
  },
  filename: function (req, file, cb) {
    // Ensure unique file name
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + '-' + file.originalname);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new Error('Only audio files allowed!'), false);
    }
  }
});

router.post('/upload-audio', upload.single('audio'), uploadAudio);

module.exports = router;

