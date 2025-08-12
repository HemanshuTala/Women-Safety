const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const userCtrl = require('../controllers/userController');

router.get('/profile/:id', auth, userCtrl.getProfile);

router.post('/request-connect/:id', auth, userCtrl.requestConnect);
router.get('/requests/:id', auth, userCtrl.listRequests);
router.post('/requests/:id/respond', auth, userCtrl.respondRequest);

router.post('/disconnect-parent/:id', auth, userCtrl.disconnectParent);
router.get('/sos-history/:userId', auth, userCtrl.getSosHistory);

module.exports = router;
