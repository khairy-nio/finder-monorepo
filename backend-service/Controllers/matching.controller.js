const MatchingService = require('../services/matching.service');
const response = require('../utils/response.util');

class MatchingController {
    
    // Check for matches before creating a post
    async findMatches(req, res) {
        try {
            const { image_url, type, category, country, state, city, area, latitude, longitude } = req.body;

            if (!image_url) {
                return response.ErrorResponse(res, 'Image URL is required', null, 400);
            }
            if (!type) {
                return response.ErrorResponse(res, 'Post type (lost/found) is required', null, 400);
            }
            if (!country) {
                return response.ErrorResponse(res, 'Country is required for location-based matching', null, 400);
            }

            // Convert coordinates to floats if provided
            const lat = latitude ? parseFloat(latitude) : null;
            const lng = longitude ? parseFloat(longitude) : null;

            const result = await MatchingService.checkMatch(
                image_url, 
                type, 
                category, 
                country, 
                state, 
                city, 
                area,
                lat, 
                lng
            );
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, {
                matches: result.data,
                uploaded_image_url: image_url
            }, 200, result.metadata);

        } catch (error) {
            console.error('Error finding matches:', error);
            return response.ErrorResponse(res, error.message, null, 500);
        }
    }
}

module.exports = new MatchingController();
