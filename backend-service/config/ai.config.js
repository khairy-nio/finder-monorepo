const axios = require('axios');

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://localhost:8000';

class AIService {
    
    /**
     * Generate 512-dimensional embedding from image URL
     * @param {string} imageUrl - Public image URL (Firebase Storage, etc.)
     * @returns {Promise<number[]>} 512-dimensional vector
     */
    async generateEmbedding(imageUrl) {
        try {
            console.log(`🤖 Requesting embedding for: ${imageUrl}`);
            
            const response = await axios.post(`${AI_SERVICE_URL}/embed`, {
                image_url: imageUrl
            }, {
                timeout: 30000, // 30 seconds
                headers: {
                    'Content-Type': 'application/json'
                }
            });
            
            console.log(`✅ Embedding received: ${response.data.dimension} dimensions`);
            return response.data.embedding;
            
        } catch (error) {
            if (error.response) {
                // AI service returned error (400, 500, etc.)
                console.error('❌ AI Service Error:', error.response.data);
                throw new Error(`AI Service: ${error.response.data.detail || 'Failed to generate embedding'}`);
            } else if (error.request) {
                // Request sent but no response (timeout, network issue)
                console.error('❌ AI Service Unreachable');
                throw new Error('AI Service is unreachable. Please try again later.');
            } else {
                // Something else went wrong
                console.error('❌ Embedding Error:', error.message);
                throw new Error('Failed to generate embedding');
            }
        }
    }

    /**
     * Check if AI service is healthy and model is loaded
     * @returns {Promise<boolean>}
     */
    async healthCheck() {
        try {
            const response = await axios.get(`${AI_SERVICE_URL}/health`, {
                timeout: 5000
            });
            return response.data.model_loaded === true;
        } catch (error) {
            console.error('❌ AI health check failed:', error.message);
            return false;
        }
    }

    /**
     * Generate embeddings for multiple images (batch processing)
     * @param {string[]} imageUrls - Array of image URLs (max 10)
     * @returns {Promise<Object>} Batch results
     */
    async generateBatchEmbeddings(imageUrls) {
        try {
            if (imageUrls.length > 10) {
                throw new Error('Maximum 10 images per batch');
            }

            console.log(`🤖 Requesting batch embeddings for ${imageUrls.length} images`);

            const response = await axios.post(`${AI_SERVICE_URL}/embed/batch`, {
                image_urls: imageUrls
            }, {
                timeout: 60000 // 1 minute for batch
            });
            
            console.log(`✅ Batch complete: ${response.data.successful}/${response.data.total} successful`);
            return response.data;
            
        } catch (error) {
            console.error('❌ Batch embedding error:', error.response?.data || error.message);
            throw new Error('Failed to generate batch embeddings');
        }
    }
}

module.exports = new AIService();
