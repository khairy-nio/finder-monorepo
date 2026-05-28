const { mod } = require('firebase/firestore/pipelines');
const ContactRequest = require('../models/ContactRequest.model');
const User = require('../models/User.model');
const Post = require('../models/post.model');

class Contact_req {

    /**
     * Create a new contact request (prevents duplicates)
     * @param {string} sender_id - UUID of the user sending the request
     * @param {string} receiver_id - UUID of the user receiving the request
     * @param {string} post_id - UUID of the post
     * @param {string} [intro_message] - Optional introduction message
     * @returns {Promise<[ContactRequest, boolean]>} - [instance, created]
     */
    async createContactReq(sender_id, receiver_id, post_id, intro_message, verification_answers) {
        try {
            return await ContactRequest.findOrCreate({
                where: {
                    sender_id: sender_id,
                    receiver_id: receiver_id,
                    post_id: post_id,
                },
                defaults: {
                    status: 'pending',
                    intro_message: intro_message || null,
                    // Store claimant's answers to owner's verification questions.
                    // NULL for old requests or posts with no questions.
                    verification_answers: verification_answers || null
                }
            });
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get a contact request by ID (for security validation)
     * @param {string} contactReq_id - UUID of the contact request
     * @returns {Promise<ContactRequest|null>}
     */
    async getRequestById(contactReq_id) {
        try {
            return await ContactRequest.findOne({
                where: { id: contactReq_id },
                include: [
                    {
                        model: User,
                        as: 'sender',
                        attributes: ['id', 'name', 'email']
                    },
                    {
                        model: User,
                        as: 'receiver',
                        attributes: ['id', 'name', 'email']
                    },
                    {
                        model: Post,
                        as: 'post',
                        attributes: ['id', 'title', 'post_type', 'status']
                    }
                ]
            });
        } catch (err) {
            throw err;
        }
    }

    /**
     * Update contact request status with receiver validation (secure update)
     * @param {string} contactReq_id - UUID of the contact request
     * @param {string} status - New status ('accepted' or 'rejected')
     * @param {string} receiver_id - UUID of the receiver (for security validation)
     * @returns {Promise<number>} - Number of rows affected
     */
    async changeReqStatus(contactReq_id, status, receiver_id) {
        try {
            return await ContactRequest.update(
                { status: status },
                {
                    where: {
                        id: contactReq_id,
                        receiver_id: receiver_id // Security: Only receiver can change status
                    }
                }
            );
        } catch (err) {
            throw err;
        }
    }

    /**
     * Check if a contact request already exists for a post
     * @param {string} user_id - UUID of the sender
     * @param {string} post_id - UUID of the post
     * @returns {Promise<ContactRequest|null>}
     */
    async checkReqStatus(user_id, post_id) {
        try {
            return await ContactRequest.findOne({
                where: {
                    sender_id: user_id,
                    post_id: post_id
                }
            });
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get all contact requests received by a user (with sender and post details)
     * @param {string} user_id - UUID of the receiver
     * @param {number} limit - Maximum number of results (default: 10)
     * @param {number} offset - Pagination offset (default: 0)
     * @returns {Promise<{rows: ContactRequest[], count: number}>}
     */
    async getMyReceivedRequests(user_id, limit = 10, offset = 0) {
        try {
            return await ContactRequest.findAndCountAll({
                where: { receiver_id: user_id },
                // verification_answers included so owner can review claimant answers
                attributes: ['id', 'sender_id', 'receiver_id', 'post_id', 'status', 'intro_message', 'verification_answers', 'created_at'],
                include: [
                    {
                        model: User,
                        as: 'sender',
                        attributes: ['id', 'name', 'email', 'trust_score', 'verified']
                    },
                    {
                        model: Post,
                        as: 'post',
                        attributes: ['id', 'title', 'description', 'post_type', 'category', 'image_url', 'status', 'country', 'city', 'verification_questions']
                    }
                ],
                order: [['created_at', 'DESC']],
                limit: limit,
                offset: offset
            });
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get all contact requests sent by a user (with receiver and post details)
     * @param {string} user_id - UUID of the sender
     * @param {number} limit - Maximum number of results (default: 10)
     * @param {number} offset - Pagination offset (default: 0)
     * @returns {Promise<{rows: ContactRequest[], count: number}>}
     */
    async getMySentRequests(user_id, limit = 10, offset = 0) {
        try {
            return await ContactRequest.findAndCountAll({
                where: { sender_id: user_id },
                include: [
                    {
                        model: User,
                        as: 'receiver',
                        attributes: ['id', 'name', 'email']
                    },
                    {
                        model: Post,
                        as: 'post',
                        attributes: ['id', 'title', 'description', 'post_type', 'category', 'image_url', 'status', 'country', 'city']
                    }
                ],
                order: [['created_at', 'DESC']],
                limit: limit,
                offset: offset
            });
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get all pending requests for a specific post (for post owner to manage)
     * @param {string} post_id - UUID of the post
     * @param {string} receiver_id - UUID of the post owner (security check)
     * @returns {Promise<ContactRequest[]>}
     */
    async getPendingRequestsForPost(post_id, receiver_id) {
        try {
            return await ContactRequest.findAll({
                where: {
                    post_id: post_id,
                    receiver_id: receiver_id,
                    status: 'pending'
                },
                // Include verification_answers so owner can review per-post
                attributes: ['id', 'sender_id', 'post_id', 'status', 'intro_message', 'verification_answers', 'created_at'],
                include: [
                    {
                        model: User,
                        as: 'sender',
                        attributes: ['id', 'name', 'email', 'trust_score', 'verified']
                    }
                ],
                order: [['created_at', 'DESC']]
            });
        } catch (err) {
            throw err;
        }
    }

    /**
     * Delete a contact request (for sender to cancel their request)
     * @param {string} contactReq_id - UUID of the contact request
     * @param {string} sender_id - UUID of the sender (security check)
     * @returns {Promise<number>} - Number of rows deleted
     */
    async deleteRequest(contactReq_id, sender_id) {
        try {
            return await ContactRequest.destroy({
                where: {
                    id: contactReq_id,
                    sender_id: sender_id // Security: Only sender can delete
                }
            });
        } catch (err) {
            throw err;
        }
    }

}
module.exports = new Contact_req();