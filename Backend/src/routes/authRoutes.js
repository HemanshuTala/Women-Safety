const express = require('express');
const router = express.Router();
const authCtrl = require('../controllers/authController');

router.post('/register', authCtrl.register);
router.post('/login', authCtrl.login);
router.post('/otp/send', authCtrl.sendOtp);
router.post('/otp/verify', authCtrl.verifyOtp);

module.exports = router;
