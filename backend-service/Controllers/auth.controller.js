const response = require('../utils/response.util');
const UserService = require('../services/user.service');

class authController {

    async login(req, res){
        try{
            // Data from Middleware (verified token)
            const { firebase_uid, email } = req.user;
            
            // Data from Body (user input)
            const { name } = req.body;
            
            if (!firebase_uid) {
                return response.ErrorResponse(res, 'Invalid token data', null, 401);
            }

            // Check if user exists
            const userResult = await UserService.getLoginUser(firebase_uid);
            
            if(userResult.success){
                return response.Success(res, userResult.message, userResult.data, 200);
            }
            else {
                // Create new user
                const newUserResult = await UserService.registerUser(firebase_uid, name, email);
                
                if (!newUserResult.success) {
                    return response.ErrorResponse(res, newUserResult.message, null, 400);
                }
                
                return response.Success(res, newUserResult.message, newUserResult.data, 201);
            }

        } catch (error) {
            console.error('Error in login:', error);
            return response.ErrorResponse(res, 'Internal Server Error', error.message, 500);
        }
    }
}

module.exports = new authController();