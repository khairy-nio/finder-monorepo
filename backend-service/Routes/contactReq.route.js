const express = require('express');
const router = express.Router();
const ContactReqController = require('../Controllers/ContactReq.controller');
const { verfyFirebaseToken } = require('../Middlewares/auth.middleware');
const { requireVerification } = require('../Middlewares/isVerfied.middleware');
const { requireActiveUser } = require('../Middlewares/moderation.middleware');
const { sendContactRequestValidator, respondToRequestValidator } = require('../validators/contactReq.validator');
const validate = require('../Middlewares/validation');

// All contact request operations require verified identity
router.use(verfyFirebaseToken);
router.use(requireVerification);


/**
 * @route   POST /api/v1/contact-request/send
 * @desc    Send a contact request to a post owner
 * @access  Private (requires verified identity)
 * @body    { receiver_id, post_id }
 */
router.post('/send',
    requireActiveUser,
    sendContactRequestValidator,
    validate,
    ContactReqController.sendContactRequest);

/**
 * @route   GET /api/v1/contact-request/received
 * @desc    Get all contact requests received by the user
 * @access  Private
 * @query   ?limit=10&offset=0
 */
router.get('/received',
     ContactReqController.getContactRequests);

/**
 * @route   GET /api/v1/contact-request/sent
 * @desc    Get all contact requests sent by the user
 * @access  Private
 * @query   ?limit=10&offset=0
 */
router.get('/sent',
     ContactReqController.getSentRequests);

/**
 * @route   PUT /api/v1/contact-request/:requestId/respond
 * @desc    Accept or reject a contact request (receiver only)
 * @access  Private (requires verified identity)
 * @body    { status: 'accepted' | 'rejected' }
 */
router.put('/:requestId/respond',
     respondToRequestValidator,
     validate,
     ContactReqController.respondToRequest);

/**
 * @route   DELETE /api/v1/contact-request/:requestId/cancel
 * @desc    Cancel a pending contact request (sender only)
 * @access  Private
 */
router.delete('/:requestId/cancel',
     ContactReqController.cancelRequest);   
     
/**
 * @route   GET /api/v1/contact-request/:requestId
 * @desc    Get contact request details by ID
 * @access  Private
 */
router.get('/:requestId',
     ContactReqController.getRequestById);

/**
 * @route   GET /api/v1/contact-request/check/:postId
 * @desc    Check if user has already sent a request for a post
 * @access  Private
 */
router.get('/check/:postId',
     ContactReqController.checkRequestStatus);

/**
 * @route   GET /api/v1/contact-request/post/:postId/pending
 * @desc    Get all pending requests for a specific post (post owner only)
 * @access  Private
 */
router.get('/post/:postId/pending',
     ContactReqController.getPendingRequestsForPost);
module.exports = router;
