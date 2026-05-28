const admin = require('../../config/firebase.config');
const UserRepo = require('../../Repository/user.repo');

const socketAuthMiddleware = async (socket, next) => {
    try {
        const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split('Bearer ')[1];
        
        if (!token) {
            return next(new Error('Authentication error: No token provided'));
        }

        const decodedToken = await admin.auth().verifyIdToken(token);
        const user = await UserRepo.findUserBy_firbase_id(decodedToken.uid);
        
        if (!user) {
            return next(new Error('Authentication error: User not found'));
        }

        socket.user = {
            firebase_uid: decodedToken.uid,
            id: user.id,
            role: user.role
        };

        next();
    } catch (error) {
        console.error('Socket authentication error:', error.message);
        next(new Error('Authentication error: Invalid token'));
    }
};

module.exports = socketAuthMiddleware;