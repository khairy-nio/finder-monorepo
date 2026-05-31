'use strict';
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User.model');
const response = require('../utils/response.util');

const JWT_EXPIRES_IN = '24h';

class AdminAuthController {
    async login(req, res) {
        try {
            const { email, password } = req.body;

            if (!email || !password) {
                return response.ErrorResponse(res, 'Email and password are required', null, 400);
            }

            const secret = process.env.JWT_SECRET;
            if (!secret) {
                console.error('JWT_SECRET is not configured');
                return response.ErrorResponse(res, 'Server configuration error', null, 500);
            }

            const user = await User.findOne({ where: { email } });

            if (!user) {
                return response.ErrorResponse(res, 'Invalid credentials', null, 401);
            }

            if (!user.password_hash) {
                return response.ErrorResponse(
                    res,
                    'Password not set for this account. Run the admin seed script.',
                    null,
                    401
                );
            }

            const isValid = await bcrypt.compare(password, user.password_hash);
            if (!isValid) {
                return response.ErrorResponse(res, 'Invalid credentials', null, 401);
            }

            if (user.status !== 'active') {
                return response.ErrorResponse(res, 'Account suspended or banned', null, 403);
            }

            const payload = {
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
                status: user.status,
            };

            const token = jwt.sign(payload, secret, { expiresIn: JWT_EXPIRES_IN });

            return response.Success(res, 'Login successful', {
                token,
                user: {
                    id: user.id,
                    email: user.email,
                    name: user.name,
                    role: user.role,
                    status: user.status,
                    verified: user.verified,
                    profile_image_url: user.profile_image_url,
                },
            }, 200);
        } catch (error) {
            console.error('Login error:', error);
            return response.ErrorResponse(res, 'Internal Server Error', error.message, 500);
        }
    }

    async me(req, res) {
        try {
            const user = await User.findByPk(req.user.id, {
                attributes: [
                    'id', 'email', 'name', 'role', 'status',
                    'verified', 'profile_image_url', 'created_at',
                ],
            });

            if (!user) {
                return response.ErrorResponse(res, 'User not found', null, 404);
            }

            return response.Success(res, 'User info retrieved', { user }, 200);
        } catch (error) {
            console.error('Me error:', error);
            return response.ErrorResponse(res, 'Internal Server Error', error.message, 500);
        }
    }
}

module.exports = new AdminAuthController();
