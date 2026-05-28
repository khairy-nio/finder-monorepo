const PostRepo = require('../Repository/post.repo');
const AIService = require('../config/ai.config');
const pineconeIndex = require('../config/pinecone.config');
const RecoveryService = require('./recovery.service');
const { normalizeLocation } = require('../utils/normalization.util');


class PostService {

    /**
     * Create a new post with image embedding
     */
    async createPost(userId, postData) {
        try {
            // Validate required fields
            if (!postData.title || !postData.post_type || !postData.image_url) {
                return {
                    success: false,
                    message: 'Title, post type, and image are required'
                };
            }

            // Validate post_type enum
            if (!['lost', 'found'].includes(postData.post_type)) {
                return {
                    success: false,
                    message: 'Post type must be either "lost" or "found"'
                };
            }

            // Prepare data for database - with consistent normalization
            const data = {
                user_id: userId,
                title: postData.title,
                post_type: postData.post_type,
                country: normalizeLocation(postData.country),
                state: postData.state ? normalizeLocation(postData.state) : null,
                city: postData.city ? normalizeLocation(postData.city) : null,
                area: postData.area ? normalizeLocation(postData.area) : null,
                description: postData.description || null,
                category: postData.category ? normalizeLocation(postData.category) : null,
                latitude:postData.latitude || null,
                longitude:postData.longitude || null,
                image_url: postData.image_url,
                status: 'active',
                vector_id: null
            };

            // Create post in database
            const newPost = await PostRepo.createPost(data);

            // Generate and store embedding asynchronously (don't block response)
            this.processEmbedding(newPost).catch(error => {
                console.error(`Failed to process embedding for post ${newPost.id}:`, error.message);
                // TODO: Add to retry queue
            });

            // Generate matches synchronously to return to user
            let matches = [];
            try {
                const MatchingService = require('./matching.service');
                const matchResult = await MatchingService.checkMatch(
                    postData.image_url,
                    postData.post_type,
                    postData.category,
                    postData.country,
                    postData.state,
                    postData.city,
                    postData.area,
                    postData.latitude,
                    postData.longitude
                );
                if (matchResult.success) {
                    matches = matchResult.data;
                }
            } catch (err) {
                console.error("Failed to generate matches during post creation:", err);
            }

            return {
                success: true,
                message: 'Post created successfully',
                data: newPost,
                matches: matches
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Generate embedding and store in Pinecone + Update Supabase
     * @private
     */
    async processEmbedding(post) {
        try {
            console.log(`Processing embedding for post ${post.id}`);
            
            // Generate 512-dimensional vector using CLIP
            const embedding = await AIService.generateEmbedding(post.image_url);
            
            // Store vector in Pinecone - with consistent normalization
            // NOTE: Pinecone forbids null metadata values — only include lat/lng if numeric
            const pineconeMetadata = {
                user_id: post.user_id,
                post_type: post.post_type,
                category: post.category ? normalizeLocation(post.category) : '',
                country: normalizeLocation(post.country),
                state: post.state ? normalizeLocation(post.state) : '',
                city: post.city ? normalizeLocation(post.city) : '',
                area: post.area ? normalizeLocation(post.area) : '',
                status: post.status,
                moderation_status: post.moderation_status || 'visible',
                created_at: post.created_at.toISOString()
            };

            // Only add coordinates if they are valid numbers
            if (post.latitude != null && post.longitude != null) {
                pineconeMetadata.lat = parseFloat(post.latitude);
                pineconeMetadata.lng = parseFloat(post.longitude);
            }

            await pineconeIndex.upsert([{
                id: post.id,
                values: embedding,
                metadata: pineconeMetadata
            }]);

            console.log(`Vector stored in Pinecone: ${post.id}`);
            
            // Update Supabase with vector_id
            await PostRepo.updateVectorId(post.id, post.id);
            
            console.log(`Supabase updated with vector_id: ${post.id}`);
            
        } catch (error) {
            console.error(`Embedding processing failed for post ${post.id}:`, error);
            throw error;
        }
    }

    // Get all posts by a specific user
    async getUserPosts(userId) {
        try {
            const posts = await PostRepo.getUserPosts(userId);
            
            return {
                success: true,
                message: 'User posts retrieved successfully',
                data: posts,
                count: posts.length
            };
        } catch (err) {
            throw err;
        }
    }

    // Get a single post by ID
    async getPostById(postId) {
        try {
            const post = await PostRepo.getPostById(postId);
            
            if (!post) {
                return {
                    success: false,
                    message: 'Post not found'
                };
            }
            
            return {
                success: true,
                message: 'Post retrieved successfully',
                data: post
            };
        } catch (err) {
            throw err;
        }
    }

    // Get all active posts (for browse page)
    async getAllActivePosts(limit = 50, offset = 0) {
        try {
            const result = await PostRepo.getAllActivePosts(limit, offset);
            
            return {
                success: true,
                message: 'Active posts retrieved successfully',
                data: result.rows,
                pagination: {
                    total: result.count,
                    limit,
                    offset,
                    hasMore: offset + limit < result.count
                }
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get posts with dynamic filters
     */
    async  getFilteredPosts(filters) {
        try {
            const { type, country, state, city, area, category, status, moderation_status, userId, limit, offset, latitude, longitude } = filters;
            
            // Validate type if provided
            if (type && !['lost', 'found'].includes(type)) {
                return {
                    success: false,
                    message: 'Post type must be either "lost" or "found"'
                };
            }

            // Validate status if provided
            if (status && !['active', 'matched', 'closed', 'resolved'].includes(status)) {
                return {
                    success: false,
                    message: 'Invalid status value'
                };
            }

            // Validate moderation_status if provided
            if (moderation_status && !['visible', 'hidden', 'removed', 'all'].includes(moderation_status)) {
                return {
                    success: false,
                    message: 'Invalid moderation status value'
                };
            }
            
            const result = await PostRepo.getFilteredPosts({
                type,
                country,
                state,
                city,
                area,
                 latitude,
                 longitude,
                category,
                status: status || 'active',
                moderation_status,
                userId,
                limit: parseInt(limit) || 50,
                offset: parseInt(offset) || 0
            });
            
            return {
                success: true,
                message: 'Filtered posts retrieved successfully',
                data: result.rows,
                pagination: {
                    total: result.count,
                    limit: parseInt(limit) || 50,
                    offset: parseInt(offset) || 0,
                    hasMore: (parseInt(offset) || 0) + (parseInt(limit) || 50) < result.count
                }
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Update user's own post
     */
    async updateUserPost(userId, postId, updateData) {
        try {
            // Check ownership
            const post = await PostRepo.getPostById(postId);
            if (!post) {
                return {
                    success: false,
                    message: 'Post not found'
                };
            }

            if (post.user_id !== userId) {
                return {
                    success: false,
                    message: 'Unauthorized: You can only edit your own posts'
                };
            }

            // Normalize location data if provided
            if (updateData.country) updateData.country = normalizeLocation(updateData.country);
            if (updateData.state) updateData.state = normalizeLocation(updateData.state);
            if (updateData.city) updateData.city = normalizeLocation(updateData.city);
            if (updateData.area) updateData.area = normalizeLocation(updateData.area);
            if (updateData.category) updateData.category = normalizeLocation(updateData.category);

            const result = await PostRepo.updatePost(userId, postId, updateData);

            if (result[0] === 0) {
                return {
                    success: false,
                    message: 'Post not found or no changes made'
                };
            }

            // Update Pinecone if image or important text or location changed
            if (updateData.image_url || updateData.description || updateData.title || 
                updateData.city || updateData.area || updateData.category) {
                const updatedPost = await PostRepo.getPostById(postId);
                this.processEmbedding(updatedPost).catch(error => {
                    console.error(`Failed to update embedding for post ${postId}:`, error.message);
                });
            }

            return {
                success: true,
                message: 'Post updated successfully'
            };        } catch (err) {
            throw err;
        }
    }

    /**
     * Delete user's own post
     */
    async deleteUserPost(userId, postId) {
        try {
            // Check ownership
            const post = await PostRepo.getPostById(postId);
            if (!post) {
                return {
                    success: false,
                    message: 'Post not found'
                };
            }

            if (post.user_id !== userId) {
                return {
                    success: false,
                    message: 'Unauthorized: You can only delete your own posts'
                };
            }

            // Delete from Supabase
            const result = await PostRepo.deletePost(userId, postId);
          
            if (result === 0) {
                return {
                    success: false,
                    message: 'Post not found'
                };
            }

            // Delete vector from Pinecone if exists
            if (post.vector_id) {
                try {
                    await pineconeIndex.deleteOne(post.vector_id);
                    console.log(`Deleted vector from Pinecone: ${post.vector_id}`);
                } catch (error) {
                    console.error(`Failed to delete vector from Pinecone: ${error.message}`);
                }
            }

            return {
                success: true,
                message: 'Post deleted successfully'
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Update post status
     */
    async updatePostStatus(userId, postId, status) {
        try {
            // Validate status
            if (!['active', 'matched', 'closed', 'resolved'].includes(status)) {
                return {
                    success: false,
                    message: 'Invalid status value'
                };
            }

            const post = await PostRepo.getPostById(postId);
            if (!post) {
                return {
                    success: false,
                    message: 'Post not found'
                };
            }

            if (post.user_id !== userId) {
                return {
                    success: false,
                    message: 'Unauthorized: You can only update your own posts'
                };
            }

            const result = await PostRepo.updatePostStatus(postId, userId, status);
            
            if (result[0] === 0) {
                return {
                    success: false,
                    message: 'Failed to update status'
                };
            }

            // Sync with Pinecone so AI matching reflects status change
            try {
                if (post.vector_id) {
                    await pineconeIndex.update({
                        id: post.vector_id,
                        metadata: { status: status }
                    });
                    console.log(`Updated Pinecone metadata status for vector ${post.vector_id} to ${status}`);
                }
            } catch (error) {
                console.error(`Failed to update Pinecone status for post ${postId}:`, error);
            }

            // Award points for legitimate resolution
            if (status === 'resolved') {
                try {
                    await RecoveryService.awardRecoveryPointsForPost(postId);
                } catch (pointError) {
                    console.error('[PostService] Failed to award points upon resolution:', pointError);
                }
            }

            return {
                success: true,
                message: 'Status updated successfully',
                data: { status }
            };

        } catch (err) {
            throw err;
        }
    }

    // ========== ADMIN METHODS ==========

    /**
     * Admin: Update any post (no ownership check, role verified by middleware)
     */
    async adminUpdatePost(postId, updateData) {
        try {
            const post = await PostRepo.getPostById(postId);
            if (!post) {
                return {
                    success: false,
                    message: 'Post not found'
                };
            }

            // Normalize location data if provided
            if (updateData.country) updateData.country = normalizeLocation(updateData.country);
            if (updateData.state) updateData.state = normalizeLocation(updateData.state);
            if (updateData.city) updateData.city = normalizeLocation(updateData.city);
            if (updateData.area) updateData.area = normalizeLocation(updateData.area);
            if (updateData.category) updateData.category = normalizeLocation(updateData.category);

            const result = await PostRepo.adminUpdatePost(postId, updateData);
            
            if (result[0] === 0) {
                return {
                    success: false,
                    message: 'No changes made'
                };
            }

            // Sync with Pinecone if visibility or status changed
            try {
                if (post.vector_id && (updateData.moderation_status || updateData.status || 
                    updateData.city || updateData.area || updateData.category)) {
                    
                    const updatedPost = await PostRepo.getPostById(postId);
                    this.processEmbedding(updatedPost).catch(error => {
                        console.error(`Failed to update embedding for post ${postId} via admin action:`, error.message);
                    });
                    
                    console.log(`Updated Pinecone metadata for post ${postId} via admin action`);
                }
            } catch (error) {
                console.error(`Failed to update Pinecone metadata for post ${postId}:`, error);
            }

            return {
                success: true,
                message: 'Post updated by admin'
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Admin: Delete any post (no ownership check, role verified by middleware)
     */
    async adminDeletePost(postId) {
        try {
            const post = await PostRepo.getPostById(postId);
            if (!post) {
                return {
                    success: false,
                    message: 'Post not found'
                };
            }

            // Delete from Supabase
            const result = await PostRepo.adminDeletePost(postId);
            
            if (result === 0) {
                return {
                    success: false,
                    message: 'Post not found'
                };
            }
         
            // Delete vector from Pinecone if exists
            if (post.vector_id) {
                try {
                    await pineconeIndex.deleteOne(post.vector_id);
                    console.log(`Admin deleted vector from Pinecone: ${post.vector_id}`);
                } catch (error) {
                    console.error(`Failed to delete vector from Pinecone: ${error.message}`);
                }
            }

            return {
                success: true,
                message: 'Post deleted by admin'
            };
        } catch (err) {
            throw err;
        }
    }

    // ========== SECURE FEED METHODS ==========

    /**
     * Get posts for the public home feed — no sensitive data exposed.
     * Strips: image_url, latitude, longitude, verification_questions.
     * Used by GET /api/post/feed
     */
    async getPublicFeedPosts(filters) {
        try {
            const {
                type, country, state, city, area, category,
                status, moderationStatus, limit = 50, offset = 0
            } = filters;

            // Validate type if provided
            if (type && !['lost', 'found'].includes(type)) {
                return { success: false, message: 'Post type must be "lost" or "found"' };
            }

            const result = await PostRepo.getPublicFeedPosts({
                type,
                country,
                state,
                city,
                area,
                category,
                status: status || 'active',
                moderation_status: moderationStatus || null,
                limit: parseInt(limit),
                offset: parseInt(offset)
            });

            return {
                success: true,
                message: 'Feed retrieved successfully',
                data: result.rows,
                pagination: {
                    total: result.count,
                    limit: parseInt(limit),
                    offset: parseInt(offset),
                    hasMore: parseInt(offset) + parseInt(limit) < result.count
                }
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get verification questions for a specific post (for claimants).
     * Returns ONLY question IDs + text — never answers, never other post data.
     * Returns empty array if post has no questions configured.
     * @param {string} postId
     */
    async getVerificationQuestions(postId) {
        try {
            const post = await PostRepo.getPostById(postId);
            if (!post) {
                return { success: false, message: 'Post not found' };
            }

            // verification_questions is NULL for old/unconfigured posts
            const questions = post.verification_questions || [];

            return {
                success: true,
                data: questions   // [{ id, question }] — safe to return
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Set/update verification questions for a post (owner only).
     * @param {string} userId
     * @param {string} postId
     * @param {Array}  questions - [{ id, question }], 0–4 items
     */
    async updateVerificationQuestions(userId, postId, questions) {
        try {
            const post = await PostRepo.getPostById(postId);
            if (!post) {
                return { success: false, message: 'Post not found' };
            }
            if (post.user_id !== userId) {
                return { success: false, message: 'Unauthorized: You can only set questions on your own posts' };
            }

            if (!Array.isArray(questions)) {
                return { success: false, message: 'Questions must be provided in an array format' };
            }

            // Sanitize: Trim whitespace, filter empty, and reject duplicate questions
            const uniqueQuestions = [];
            const seen = new Set();
            for (const q of questions) {
                if (q && q.question) {
                    const trimmed = q.question.trim();
                    if (trimmed.length > 0 && !seen.has(trimmed.toLowerCase())) {
                        seen.add(trimmed.toLowerCase());
                        uniqueQuestions.push({ question: trimmed });
                    }
                }
            }

            // If not empty, enforce: minimum 3 and maximum 10 questions
            if (uniqueQuestions.length > 0) {
                if (uniqueQuestions.length < 3) {
                    return { success: false, message: 'Please add at least 3 verification questions.' };
                }
                if (uniqueQuestions.length > 10) {
                    return { success: false, message: 'Maximum 10 questions allowed.' };
                }
            }

            // Validate character constraints
            for (const q of uniqueQuestions) {
                if (q.question.length < 5 || q.question.length > 200) {
                    return { success: false, message: 'Each question must be between 5 and 200 characters' };
                }
            }

            // Assign sequential IDs
            const sanitized = uniqueQuestions.map((q, idx) => ({
                id: idx + 1,
                question: q.question
            }));

            await PostRepo.updateVerificationQuestions(postId, userId, sanitized);

            return {
                success: true,
                message: 'Verification questions updated',
                data: sanitized
            };
        } catch (err) {
            throw err;
        }
    }
}

module.exports = new PostService();
