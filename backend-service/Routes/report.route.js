const express = require('express');
const router = express.Router();
const reportController = require('../Controllers/report.controller');
const { createReportValidator, updateReportStatusValidator } = require('../validators/report.validator');
const validate = require('../Middlewares/validation');
const { requireAuthentication, requireVerification } = require('../Middlewares/isVerfied.middleware');
const { verfyFirebaseToken: verifyFirebaseToken } = require('../Middlewares/auth.middleware');
const isAdmin = require('../Middlewares/isAdmin.middleware');

// User routes
router.post(
    '/create',
    verifyFirebaseToken,
    requireVerification,
    createReportValidator,
    validate,
    reportController.createReport
);

// Admin routes
router.get(
    '/all',
    verifyFirebaseToken,
    isAdmin,
    reportController.getAllReports
);

router.get(
    '/:id',
    verifyFirebaseToken,
    isAdmin,
    reportController.getReportById
);

router.put(
    '/:id/status',
    verifyFirebaseToken,
    isAdmin,
    updateReportStatusValidator,
    validate,
    reportController.updateReportStatus
);

module.exports = router;
