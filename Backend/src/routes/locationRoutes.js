const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const locationCtrl = require('../controllers/locationController');

router.post('/update/:id', auth, locationCtrl.updateLocation);
router.get('/:id', auth, locationCtrl.getLatestLocation);

module.exports = router;
