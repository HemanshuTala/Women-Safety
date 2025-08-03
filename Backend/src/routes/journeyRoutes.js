const express = require('express');
const router = express.Router();
const journeyController = require('../controllers/journeyController');




router.post('/start', journeyController.start);
router.post('/end', journeyController.end);
router.post('/emergency', journeyController.emergency);

router.get('/:userId/emergency-history', journeyController.getJourneyDetails);
router.get('/:userId/current', journeyController.getCurrentJourney);









module.exports = router;

