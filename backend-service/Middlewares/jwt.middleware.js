'use strict';
const jwt = require('jsonwebtoken');
const response = require('../utils/response.util');

const requireJWT = (req, res, next) => {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

    if (!token) {
        return response.ErrorResponse(res, 'No token provided', null, 401);
    }

    const secret = process.env.JWT_SECRET;
    if (!secret) {
        console.error('JWT_SECRET is not configured');
        return response.ErrorResponse(res, 'Server configuration error', null, 500);
    }

    try {
        const decoded = jwt.verify(token, secret);
        req.user = {
            id: decoded.id,
            email: decoded.email,
            name: decoded.name,
            role: decoded.role,
            status: decoded.status,
        };
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return response.ErrorResponse(res, 'Token expired', null, 401);
        }
        return response.ErrorResponse(res, 'Invalid token', null, 401);
    }
};

const requireAdmin = (req, res, next) => {
    if (!req.user) {
        return response.ErrorResponse(res, 'Authentication required', null, 401);
    }
    if (req.user.role !== 'admin') {
        return response.ErrorResponse(res, 'Forbidden: Admin access required', null, 403);
    }
    next();
};

module.exports = { requireJWT, requireAdmin };
