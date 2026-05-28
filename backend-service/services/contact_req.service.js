const contactReqRepo = require('../Repository/contact_req.repo');
const ChatService = require('./chat.service');

class ContactReqService {

    /**
     * Send a contact request to a post owner
     * @param {string} sender_id 
     * @param {string} receiver_id 
     * @param {string} post_id 
     * @param {string} [intro_message] 
     */
    //DONE
    async sendRequest(sender_id, receiver_id, post_id, intro_message, verification_answers) {
        try {
            // Check if user is trying to contact themselves
            if (sender_id === receiver_id) {
                return {
                    success: false,
                    message: "You cannot send a contact request to yourself"
                };
            }

            // Check if request already exists
            const existing = await contactReqRepo.checkReqStatus(sender_id, post_id);
            if (existing) {
                return {
                    success: false,
                    message: `Request already ${existing.status}`,
                    data: existing
                };
            }

            const [contactRequest, created] = await contactReqRepo.createContactReq(
                sender_id, receiver_id, post_id, intro_message,
                // verification_answers is null for old flow — backwards compatible
                verification_answers || null
            );
            
            return {
                success: true,
                message: "Contact request sent successfully",
                data: contactRequest
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Accept or reject a contact request (receiver only)
     * @param {string} contactReq_id 
     * @param {string} status - 'accepted' | 'rejected'
     * @param {string} receiver_id 
     */
    //DONE
    async respondToRequest(contactReq_id, status, receiver_id) {
        try {
            // Validate status
            if (!['accepted', 'rejected'].includes(status)) {
                return {
                    success: false,
                    message: "Invalid status. Must be 'accepted' or 'rejected'"
                };
            }

            // Fetch request to validate it exists and belongs to receiver
            const request = await contactReqRepo.getRequestById(contactReq_id);
            if (!request) {
                return {
                    success: false,
                    message: "Contact request not found"
                };
            }

            if (request.receiver_id !== receiver_id) {
                return {
                    success: false,
                    message: "Unauthorized: You are not the recipient of this request"
                };
            }

            if (request.status !== 'pending') {
                return {
                    success: false,
                    message: `Request already ${request.status}`
                };
            }

            // Update status with security validation in query
            const rowsAffected = await contactReqRepo.changeReqStatus(contactReq_id, status, receiver_id);
            
            if (rowsAffected === 0) {
                return {
                    success: false,
                    message: "Failed to update request status"
                };
            }

            let chat_id = null;
            // If accepted, create a chat between the two users for this post
            if (status === 'accepted') {
                try {
                    const chatResult = await ChatService.createOrGetChat(request.post_id, request.sender_id, request.receiver_id);
                    chat_id = chatResult.data ? chatResult.data.id : null;
                } catch (chatError) {
                    console.error('Failed to create chat after acceptance:', chatError);
                    // Don't fail the request acceptance if chat creation fails
                }
            }

            return {
                success: true,
                message: `Contact request ${status}`,
                data: { id: contactReq_id, status, chat_id }
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get a contact request by ID
     * @param {string} contactReq_id 
     */
//DONE
    async getRequestById(contactReq_id) {
        try {
            const request = await contactReqRepo.getRequestById(contactReq_id);
            if (!request) {
                return {
                    success: false,
                    message: "Contact request not found"
                };
            }

            return {
                success: true,
                data: request
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Check if a request already exists for a post
     * @param {string} user_id 
     * @param {string} post_id 
     */
    //DONE
    async checkRequestStatus(user_id, post_id) {
        try {
            const request = await contactReqRepo.checkReqStatus(user_id, post_id);
            
            if (!request) {
                return {
                    success: true,
                    exists: false,
                    message: "No request found"
                };
            }

            return {
                success: true,
                exists: true,
                data: request
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get all requests received by a user
     * @param {string} user_id 
     * @param {number} limit 
     * @param {number} offset 
     */
    //DONE
    async getMyReceivedRequests(user_id, limit = 10, offset = 0) {
        try {
            const result = await contactReqRepo.getMyReceivedRequests(user_id, limit, offset);
            
            return {
                success: true,
                data: result.rows,
                count: result.count,
                pagination: {
                    total: result.count,
                    limit,
                    offset,
                    hasMore: offset + limit < result.count
                },
                message: result.rows.length === 0 ? "No contact requests found" : undefined
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get all requests sent by a user
     * @param {string} user_id 
     * @param {number} limit 
     * @param {number} offset 
     */
    //DONE
    async getMySentRequests(user_id, limit = 10, offset = 0) {
        try {
            const result = await contactReqRepo.getMySentRequests(user_id, limit, offset);
            
            return {
                success: true,
                data: result.rows,
                count: result.count,
                pagination: {
                    total: result.count,
                    limit,
                    offset,
                    hasMore: offset + limit < result.count
                },
                message: result.rows.length === 0 ? "No contact requests found" : undefined
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get all pending requests for a specific post
     * @param {string} post_id 
     * @param {string} receiver_id 
     */
    //DONE
    async getPendingRequestsForPost(post_id, receiver_id) {
        try {
            const requests = await contactReqRepo.getPendingRequestsForPost(post_id, receiver_id);
            
            return {
                success: true,
                data: requests,
                count: requests.length
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Cancel a contact request (sender only)
     * @param {string} contactReq_id 
     * @param {string} sender_id 
     */
    //DONE
    async cancelRequest(contactReq_id, sender_id) {
        try {
            // Fetch request to validate it exists
            const request = await contactReqRepo.getRequestById(contactReq_id);
            if (!request) {
                return {
                    success: false,
                    message: "Contact request not found"
                };
            }

            if (request.sender_id !== sender_id) {
                return {
                    success: false,
                    message: "Unauthorized: You are not the sender of this request"
                };
            }

            if (request.status !== 'pending') {
                return {
                    success: false,
                    message: `Cannot cancel a ${request.status} request`
                };
            }

            const rowsDeleted = await contactReqRepo.deleteRequest(contactReq_id, sender_id);
            
            if (rowsDeleted === 0) {
                return {
                    success: false,
                    message: "Failed to cancel request"
                };
            }

            return {
                success: true,
                message: "Contact request cancelled successfully"
            };
        } catch (err) {
            throw err;
        }
    }

}

module.exports = new ContactReqService();