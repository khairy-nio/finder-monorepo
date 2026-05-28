const response = require('../utils/response.util');

const requireActiveUser = (req, res, next) => {
    if (!req.user || !req.user.status) {
        return response.ErrorResponse(res, 'Authentication required to verify status.', null, 401);
    }

    if (req.user.status === 'suspended') {
        return response.ErrorResponse(res, 'Account suspended. You cannot perform this action.', null, 403);
    }

    if (req.user.status === 'banned') {
        return response.ErrorResponse(res, 'Account banned. You cannot perform this action.', null, 403);
    }

    next();
};

module.exports = { requireActiveUser };