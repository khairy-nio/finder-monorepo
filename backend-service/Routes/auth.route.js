'use strict';
const express = require('express');
const Router = express.Router();
const adminAuthController = require('../Controllers/admin_auth.controller');
const { requireJWT } = require('../Middlewares/jwt.middleware');

/**
 * @route   POST /api/v1/auth/login
 * @desc    Admin login with email + password, returns JWT
 * @access  Public
 * @body    { email, password }
 */
Router.post('/login', adminAuthController.login);

/**
 * @route   GET /api/v1/auth/me
 * @desc    Get current authenticated admin user info
 * @access  Private (JWT required)
 */
Router.get('/me', requireJWT, adminAuthController.me);

module.exports = Router;
