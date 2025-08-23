const express = require('express');
const router = express.Router();
const journeyController = require('../controllers/journeyController');
const authMiddleware = require('../middleware/authMiddleware');

// All routes require authentication
router.use(authMiddleware);

// Journey management routes
router.post('/', journeyController.createJourney);
router.post('/:journeyId/start', journeyController.startJourney);
router.post('/:journeyId/complete', journeyController.completeJourney);
router.post('/:journeyId/location', journeyController.updateLocation);

// Journey monitoring routes
router.get('/active', journeyController.getActiveJourneys);
router.get('/history', journeyController.getJourneyHistory);

module.exports = router;