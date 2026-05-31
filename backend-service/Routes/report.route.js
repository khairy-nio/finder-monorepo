'use strict';
const express = require('express');
const router = express.Router();
const reportController = require('../Controllers/report.controller');
const { createReportValidator } = require('../validators/report.validator');
const validate = require('../Middlewares/validation');
const { requireVerification } = require('../Middlewares/isVerfied.middleware');
const { verfyFirebaseToken: verifyFirebaseToken } = require('../Middlewares/auth.middleware');

// ─── MOBILE ONLY ─────────────────────────────────────────────────────────────
// All report management (list, update status) lives in /api/v1/admin/reports
// with JWT auth. Only report CREATION is a mobile user action.

/**
 * @route   POST /api/v1/report/create
 * @desc    Mobile user submits a report (user/post/chat)
 * @access  Firebase — verified users only
 */
router.post(
    '/create',
    verifyFirebaseToken,
    requireVerification,
    createReportValidator,
    validate,
    reportController.createReport
);

module.exports = router;
