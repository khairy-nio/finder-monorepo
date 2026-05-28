const response = require('../utils/response.util');
const UserService = require('../services/user.service');
const RecoveryService = require('../services/recovery.service');


class userController {

     async getprofile(req, res){
        try{
            const userId = req.user.id; // Database UUID
            const result = await UserService.getUserById(userId);
            
            if(!result.success){
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            return response.Success(res, result.message, result.data, 200);
        }
        catch(err){
            console.error('Error in getprofile:', err);
            return response.ErrorResponse(res, 'Internal Server Error', err.message, 500);
        }
     }

     async editprofile(req, res){
        try{
            const userId = req.user.id; // Database UUID
            const { name, phone_number, country, state, city, area, selfie_image_url, bio } = req.body; // Data to update
            
            const updateResult = await UserService.updateUserProfile(userId, { 
                name, 
                phone_number,
                country,
                state,
                city,
                area,
                selfie_image_url,
                bio
            });

            
            if(!updateResult.success){
                return response.ErrorResponse(res, updateResult.message, null, 400);
            }
            
            return response.Success(res, updateResult.message, null, 200);
        }
        catch(err){
            console.error('Error in editprofile:', err);
            return response.ErrorResponse(res, 'Internal server error', err.message, 500);
        }
     }

     async deleteprofile(req, res){
        try{
            const userId = req.user.id; // Database UUID
            
            const deleteResult = await UserService.deleteUser(userId);
            
            if(!deleteResult.success){
                return response.ErrorResponse(res, deleteResult.message, null, 400);
            }
            
            return response.Success(res, deleteResult.message, null, 200);
        }
        catch(err){
            console.error('Error in deleteprofile:', err);
            return response.ErrorResponse(res, 'Internal server error', err.message, 500);
        }
    }

    /**
     * Submit identity verification documents
     */
    async submitVerification(req, res) {
        try {
            const userId = req.user.id;
            const { national_id, phone_number, id_image_url, selfie_image_url, verification_location } = req.body;

            const result = await UserService.submitVerification(
                userId, 
                national_id, 
                phone_number, 
                id_image_url, 
                selfie_image_url, 
                verification_location
            );
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            console.error('Error in submitVerification:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * Get verification status for current user
     */
    async getVerificationStatus(req, res) {
        try {
            const userId = req.user.id;
            const result = await UserService.getVerificationStatus(userId);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            console.error('Error in getVerificationStatus:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * GET /api/v1/user/me/points/history
     * Get user's points transaction history
     */
    async getPointsHistory(req, res) {
        try {
            const userId = req.user.id;
            const history = await RecoveryService.getUserPointTransactions(userId);
            return response.Success(res, 'Point transactions retrieved successfully', history, 200);
        } catch (error) {
            console.error('Error in getPointsHistory:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * GET /api/v1/user/me/redemptions
     * Get user's redemptions history
     */
    async getRedemptionsHistory(req, res) {
        try {
            const userId = req.user.id;
            const redemptions = await RecoveryService.getUserRedemptions(userId);
            return response.Success(res, 'Redemptions history retrieved successfully', redemptions, 200);
        } catch (error) {
            console.error('Error in getRedemptionsHistory:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }

    /**
     * POST /api/v1/user/me/redeem
     * Redeem a reward from catalog
     */
    async redeemReward(req, res) {
        try {
            const userId = req.user.id;
            const { reward_id } = req.body;

            if (!reward_id) {
                return response.ErrorResponse(res, 'reward_id is required', null, 400);
            }

            const result = await RecoveryService.redeemReward(userId, reward_id);
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }

            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            console.error('Error in redeemReward:', error);
            return response.ErrorResponse(res, 'Server Error', error.message, 500);
        }
    }
}

module.exports = new userController();

