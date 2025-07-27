const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

router.post('/generate-code', userController.generateCode);
router.post('/link-parent', userController.linkParent);
router.get('/:userId', userController.getUser);

module.exports = router;
