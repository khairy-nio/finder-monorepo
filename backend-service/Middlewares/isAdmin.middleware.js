const response = require('../utils/response.util');


const isAdmin = (req, res, next) => {
    try {
        if (!req.user) {
            return response.ErrorResponse(res, 'Authentication required', null, 401);
        }

        if (req.user.role !== 'admin') {
            return response.ErrorResponse(res, 'Forbidden: Admin access required', null, 403);
        }

        next();
    } catch (error) {
        return response.ErrorResponse(res, 'Authorization error', error.message, 500);
    }
};

module.exports = isAdmin;
