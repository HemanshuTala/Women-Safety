const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const sosCtrl = require('../controllers/sosController');
const upload = require('../middleware/upload');

router.post('/send/:id', auth, upload.single('audio'), sosCtrl.sendSos);
router.get('/:id', auth, sosCtrl.getSos);

module.exports = router;
