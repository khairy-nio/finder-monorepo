const PostService = require('../services/Post.service');
const response = require('../utils/response.util');
const ContactRequest = require('../models/ContactRequest.model');
const { normalizeLocation } = require('../utils/normalization.util');

class PostController {

    // Create a new post
    async createPost(req, res) {
        try {
            const userId = req.user.id;
            const postData = req.body;

            const result = await PostService.createPost(userId, postData);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return res.status(201).json({
                success: true,
                message: result.message,
                data: result.data,
                matches: result.matches
            });
        } catch (error) {
            console.error('Error creating post:', error);
            return response.ErrorResponse(res, error.message, null, 400);
        }
    }

    // Get all posts by logged-in user
    async getMyPosts(req, res) {
        try {
            const userId = req.user.id;
            const result = await PostService.getUserPosts(userId);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }
            
            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            console.error('Error getting posts:', error);
            return response.ErrorResponse(res, error.message, null, 500);
        }
    }

    /**
     * GET /api/post/:id
     * Access gate:
     *   - Full data → post owner, or user with an accepted ContactRequest for this post
     *   - Safe DTO  → everyone else (no image_url, no verification_questions)
     * The existing matched flow is preserved: accepted ContactRequest = full access.
     */
    async getPostById(req, res) {
        try {
            const { id: postId } = req.params;
            const result = await PostService.getPostById(postId);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }

            const post = result.data;
            const currentUserId = req.user?.id;

            // --- Access gate ---
            const isOwner = currentUserId && post.user_id === currentUserId;

            let hasAcceptedRequest = false;
            if (currentUserId && !isOwner) {
                const { Op } = require('sequelize');
                const accepted = await ContactRequest.findOne({
                    where: {
                        sender_id: currentUserId,
                        post_id: postId,
                        status: { [Op.in]: ['accepted', 'pending'] }
                    }
                });
                hasAcceptedRequest = !!accepted;
            }

            const isAuthorized = isOwner || hasAcceptedRequest;

            if (isAuthorized) {
                // Full post data — matched/accepted flow, completely unchanged
                return response.Success(res, result.message, post, 200);
            }

            // Safe DTO for non-authorized users — strip sensitive fields
            const safePost = {
                id: post.id,
                user_id: post.user_id,
                post_type: post.post_type,
                title: post.title,
                description: post.description,
                category: post.category,
                country: post.country,
                state: post.state,
                city: post.city,
                area: post.area,
                status: post.status,
                moderation_status: post.moderation_status,
                created_at: post.created_at,
                owner: post.owner ? { verified: post.owner.verified } : null,
                // Explicitly absent: image_url, latitude, longitude, vector_id, verification_questions
                _protected: true  // Flutter flag to show protected UI
            };

            return response.Success(res, 'Post preview (protected)', safePost, 200);
        } catch (error) {
            console.error('Error getting post:', error);
            return response.ErrorResponse(res, error.message, null, 404);
        }
    }

    /**
     * GET /api/post/feed
     * Public home feed — safe DTO only. Strips image_url, coordinates, questions.
     * Auth is optional (set by router — uses verfyFirebaseToken in optional mode).
     */
    async getPublicFeed(req, res) {
        try {
            const {
                type, category, country, state, city, area,
                limit = 50, offset = 0
            } = req.query;

            const result = await PostService.getPublicFeedPosts({
                type, 
                country: country ? normalizeLocation(country) : null, 
                state: state ? normalizeLocation(state) : null, 
                city: city ? normalizeLocation(city) : null, 
                area: area ? normalizeLocation(area) : null, 
                category: category ? normalizeLocation(category) : null,
                limit: parseInt(limit),
                offset: parseInt(offset)
            });

            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }

            return response.Success(res, result.message, result.data, 200, result.pagination || null);
        } catch (error) {
            console.error('Error getting public feed:', error);
            return response.ErrorResponse(res, error.message, null, 500);
        }
    }

    // Get all posts with dynamic filtering (admin / internal use — untouched)
    async getAllPosts(req, res) {
        try {
            const {
                type, category, status, moderationStatus,
                userId, country, state, city, area,
                latitude, longitude, limit = 50, offset = 0
            } = req.query;

            const filters = {
                type, 
                country: country ? normalizeLocation(country) : null, 
                state: state ? normalizeLocation(state) : null, 
                city: city ? normalizeLocation(city) : null, 
                area: area ? normalizeLocation(area) : null, 
                category: category ? normalizeLocation(category) : null,
                latitude, longitude,
                status: status === 'all' ? null : (status || 'active'),
                moderation_status: moderationStatus,
                userId,
                limit: parseInt(limit),
                offset: parseInt(offset)
            };

            const result = await PostService.getFilteredPosts(filters);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, result.data, 200, result.pagination || null);
        } catch (error) {
            console.error('Error getting posts:', error);
            return response.ErrorResponse(res, error.message, null, 500);
        }
    }

    // Update user's post
    async updatePost(req, res) {
        try {
            const userId = req.user.id;
            const { id: postId } = req.params;
            const updateData = req.body;

            const result = await PostService.updateUserPost(userId, postId, updateData);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            console.error('Error updating post:', error);
            return response.ErrorResponse(res, error.message, null, 400);
        }
    }

    // Delete user's post
    async deletePost(req, res) {
        try {
            const userId = req.user.id;
            const { id: postId } = req.params;

            const result = await PostService.deleteUserPost(userId, postId);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, null, 200);
        } catch (error) {
            console.error('Error deleting post:', error);
            return response.ErrorResponse(res, error.message, null, 400);
        }
    }

    // Update post status
    async updatePostStatus(req, res) {
        try {
            const userId = req.user.id;
            const { id: postId } = req.params;
            const { status } = req.body;

            const result = await PostService.updatePostStatus(userId, postId, status);
            
            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }
            
            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            console.error('Error updating status:', error);
            return response.ErrorResponse(res, error.message, null, 400);
        }
    }

    /**
     * GET /api/post/:id/questions
     * Returns verification questions for a post (safe — question text only, no answers).
     * Returns empty array [] if post has no questions configured.
     */
    async getVerificationQuestions(req, res) {
        try {
            const { id: postId } = req.params;
            const result = await PostService.getVerificationQuestions(postId);

            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 404);
            }

            return response.Success(res, 'Verification questions retrieved', result.data, 200);
        } catch (error) {
            console.error('Error getting questions:', error);
            return response.ErrorResponse(res, error.message, null, 500);
        }
    }

    /**
     * PUT /api/post/:id/questions
     * Owner sets/updates verification questions for their post.
     * Body: { questions: [{ question: string }, ...] }  (0–4 items)
     */
    async updateVerificationQuestions(req, res) {
        try {
            const userId = req.user.id;
            const { id: postId } = req.params;
            const { questions } = req.body;

            if (!Array.isArray(questions)) {
                return response.ErrorResponse(res, 'questions must be an array', null, 400);
            }

            const result = await PostService.updateVerificationQuestions(userId, postId, questions);

            if (!result.success) {
                return response.ErrorResponse(res, result.message, null, 400);
            }

            return response.Success(res, result.message, result.data, 200);
        } catch (error) {
            console.error('Error updating questions:', error);
            return response.ErrorResponse(res, error.message, null, 500);
        }
    }
}

module.exports = new PostController();
