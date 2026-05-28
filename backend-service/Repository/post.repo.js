const Post = require('../models/post.model');
const User = require('../models/User.model');
const { Op } = require('sequelize'); 

// Safe attribute list for public feed — strips all sensitive/identifying fields.
// NEVER include: image_url, vector_id, latitude, longitude, verification_questions
const PUBLIC_FEED_ATTRIBUTES = [
    'id', 'user_id', 'post_type', 'title', 'description',
    'category', 'country', 'state', 'city', 'area',
    'status', 'moderation_status', 'created_at'
];

class PostRepository {

    async getUserPosts(userId) {
        try {
            return await Post.findAll({
                where: { user_id: userId },
                order: [['created_at', 'DESC']],
                include: { model: User, as: 'owner', attributes: ['id', 'name', 'email'] }
            });
        } catch (error) {
            throw error;
        }
    }

    async getPostById(postId) {
        try {
            return await Post.findByPk(postId, {
                include: { model: User, as: 'owner', attributes: ['id', 'name', 'email'] }
            });
        } catch (error) {
            throw error;
        }
    }

    async getAllActivePosts(limit = 50, offset = 0) {
        try {
            return await Post.findAndCountAll({
                where: { 
                    status: 'active',
                    moderation_status: 'visible'
                },
                order: [['created_at', 'DESC']],
                limit: limit,
                offset: offset,
                include: { model: User, as: 'owner', attributes: ['id', 'name'] }
            });
        } catch (error) {
            throw error;
        }
    }
    async getPostsByIds(ids){
        try{
            return await Post.findAll({
                where:{id:{
                    [Op.in]: ids
                }},
                include:{
                    model:User,
                    as:'owner',
                    attributes:['id','name','verified']
                }
            });
        } catch (error){
            throw error;
        }
    }
        
    
    // Get posts with dynamic filters
    async getFilteredPosts(filters) {
     
        const { type, country,state, city, area, category, status, moderation_status, userId, limit, offset, latitude, longitude } = filters;
        
        try {
            // Build WHERE clause dynamically
            const whereClause = {};
            
            // Always filter by status (default 'active')
            whereClause.status = status || 'active';
            
            // Apply moderation filter (default to visible for safety)
            if (moderation_status && moderation_status !== 'all') {
                whereClause.moderation_status = moderation_status;
            } else if (!moderation_status) {
                whereClause.moderation_status = 'visible';
            }
            
            // Add filters only if provided
            if (type) whereClause.post_type = type;
            if (category) whereClause.category = { [Op.iLike]: `%${category}%` };
            if (userId) whereClause.user_id = userId;
            if(country) whereClause.country = { [Op.iLike]: `%${country}%` };
            if(state) whereClause.state = { [Op.iLike]: `%${state}%` };
            if(city) whereClause.city = { [Op.iLike]: `%${city}%` };
            if(area) whereClause.area = { [Op.iLike]: `%${area}%` };
            // Note: latitude/longitude removed from SQL filters (used for distance calculation in service)
           
            return await Post.findAndCountAll({
                where: whereClause,
                order: [['created_at', 'DESC']],
                limit: limit || 50,
                offset: offset || 0,
                include: { 
                    model: User, 
                    as: 'owner', 
                    attributes: ['id', 'name', 'trust_score', 'verified'] 
                }
            });
        } catch (error) {
            throw error;
        }
    }

    async createPost(data) {
        try {
            return await Post.create(data);
        } catch (err) {
            throw err;
        }
    }

    async updatePost(userid, postid, data) {
        try {
            const allowedUpdates = {};

            if (data.title) allowedUpdates.title = data.title;
            if (data.description !== undefined) allowedUpdates.description = data.description;
            if (data.category) allowedUpdates.category = data.category;
            if (data.country) allowedUpdates.country = data.country;
            if (data.state) allowedUpdates.state = data.state;
            if (data.city) allowedUpdates.city = data.city;
            if (data.area) allowedUpdates.area = data.area;
            if (data.latitude) allowedUpdates.latitude = data.latitude;
            if (data.longitude) allowedUpdates.longitude = data.longitude;
            if (data.image_url) allowedUpdates.image_url = data.image_url;
            if (data.post_type) allowedUpdates.post_type = data.post_type;

            return await Post.update(
                allowedUpdates,
                {                    where: { 
                        id: postid,
                        user_id:userid
                    } 
                }
            );
        } catch (error) {
            throw error;
        }
    }
    async getPostsByType(postType, limit = 50, offset = 0) {
    try {
        return await Post.findAndCountAll({
            where: { 
                post_type: postType,
                status: 'active',
                moderation_status: 'visible'
            },
            order: [['created_at', 'DESC']],
            limit: limit,
            offset: offset,
            include: { model: User, as: 'owner', attributes: ['id', 'name'] }
        });
    } catch (error) {
        throw error;
    }
}

    async adminUpdatePost(postid, data) {
    try {
        const allowedUpdates = {};
        
        if (data.title) allowedUpdates.title = data.title;
        if (data.post_type) allowedUpdates.post_type = data.post_type;
        if (data.description !== undefined) allowedUpdates.description = data.description; 
        if (data.category) allowedUpdates.category = data.category;
        if (data.status) allowedUpdates.status = data.status; 
        if (data.moderation_status) allowedUpdates.moderation_status = data.moderation_status;
        if (data.image_url) allowedUpdates.image_url = data.image_url;
        if(data.country) allowedUpdates.country = data.country;
        if(data.state) allowedUpdates.state = data.state;
        if(data.city) allowedUpdates.city = data.city;
        if(data.area) allowedUpdates.area = data.area;
        if(data.latitude) allowedUpdates.latitude = data.latitude;
        if(data.longitude) allowedUpdates.longitude = data.longitude;
        return await Post.update(
            allowedUpdates,
            { where: { id: postid } } 
        );
    } catch (error) {
        throw error;
    }
}
    async adminDeletePost(postId) {
    try {
        return await Post.destroy({
            where: { id: postId }  // No user_id check
        });
    } catch (error) {
        throw error;
    }
}
    async updatePostStatus(postId, userId, newStatus) {
        try {
            return await Post.update(
                { status: newStatus },
                { where: { id: postId, user_id: userId } }
            );
        } catch (error) {
            throw error;
        }
    }

    /**
     * Update vector_id after Pinecone storage
     */
    async updateVectorId(postId, vectorId) {
        try {
            return await Post.update(
                { vector_id: vectorId },
                { where: { id: postId } }
            );
        } catch (error) {
            throw error;
        }
    }

    async deletePost(userid, postId) {
        try {
            return await Post.destroy({
                where: {
                    user_id: userid,
                    id: postId
                }
            });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Get posts for public home feed — strips all sensitive fields.
     * No image_url, no coordinates, no verification_questions in response.
     * Identical filter logic to getFilteredPosts but uses PUBLIC_FEED_ATTRIBUTES.
     */
    async getPublicFeedPosts(filters) {
        const { type, country, state, city, area, category, status, moderation_status, limit, offset } = filters;
        try {
            const whereClause = {};
            whereClause.status = status || 'active';

            if (moderation_status && moderation_status !== 'all') {
                whereClause.moderation_status = moderation_status;
            } else if (!moderation_status) {
                whereClause.moderation_status = 'visible';
            }

            if (type)     whereClause.post_type = type;
            if (category) whereClause.category  = { [Op.iLike]: `%${category}%` };
            if (country)  whereClause.country   = { [Op.iLike]: `%${country}%` };
            if (state)    whereClause.state      = { [Op.iLike]: `%${state}%` };
            if (city)     whereClause.city       = { [Op.iLike]: `%${city}%` };
            if (area)     whereClause.area       = { [Op.iLike]: `%${area}%` };

            return await Post.findAndCountAll({
                attributes: PUBLIC_FEED_ATTRIBUTES,
                where: whereClause,
                order: [['created_at', 'DESC']],
                limit:  limit  || 50,
                offset: offset || 0,
                include: {
                    model: User,
                    as: 'owner',
                    attributes: ['id', 'verified', 'trust_score']  // No name/email in public feed
                }
            });
        } catch (error) {
            throw error;
        }
    }

    /**
     * Update verification_questions for a post (owner only — enforced in service).
     * @param {string} postId
     * @param {string} userId - Must match post.user_id
     * @param {Array}  questions - [{ id, question }]
     */
    async updateVerificationQuestions(postId, userId, questions) {
        try {
            return await Post.update(
                { verification_questions: questions },
                { where: { id: postId, user_id: userId } }
            );
        } catch (error) {
            throw error;
        }
    }
}

module.exports = new PostRepository();
