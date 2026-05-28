const { verfyFirebaseToken } = require('../Middlewares/auth.middleware');
const { requireAuthentication, requireVerification } = require('../Middlewares/isVerfied.middleware');
const { requireActiveUser } = require('../Middlewares/moderation.middleware');
const { createPostValidator, updatePostValidator } = require('../validators/post.validator');
const validate = require('../Middlewares/validation');
const postController = require('../Controllers/post.controller');
const { uploadToCloudinary, uploadMiddleware } = require('../Middlewares/multer.middleware');
const express = require('express');
const Router = express.Router();

// ─── PUBLIC FEED ──────────────────────────────────────────────────────────────
// No auth required — returns safe DTO (no images, no sensitive data).
// MUST be registered BEFORE the /:id wildcard routes.
/**
 * @route   GET /api/v1/post/feed
 * @desc    Public home feed — compact safe cards, no images/coordinates
 * @access  Public (no auth)
 * @query   ?type=lost|found&category=wallet&country=EG&city=Cairo&limit=50&offset=0
 */
Router.get('/feed', postController.getPublicFeed);

// ─── AUTHENTICATED ROUTES ─────────────────────────────────────────────────────
// Apply auth to all routes below this line
Router.use(verfyFirebaseToken);
Router.use(requireAuthentication);

/**
 * @route   POST /api/v1/post/create
 * @desc    Create a new lost or found post
 * @access  Private (requires verified identity)
 */
Router.post('/create',
    requireActiveUser,
    requireVerification,
    uploadMiddleware,
    uploadToCloudinary,
    createPostValidator,
    validate,
    postController.createPost
);

/**
 * @route   GET /api/v1/post/my-posts
 * @desc    Get all posts created by current user (full data — no access gate)
 * @access  Private
 */
Router.get('/my-posts', postController.getMyPosts);

/**
 * @route   GET /api/v1/post
 * @desc    Browse all posts with optional filters (admin/internal — full data)
 * @access  Private
 */
Router.get('/', postController.getAllPosts);

/**
 * @route   GET /api/v1/post/:id/questions
 * @desc    Get verification questions for a post (claimant use)
 * @access  Private — returns [] if no questions set (safe, question text only)
 */
Router.get('/:id/questions', postController.getVerificationQuestions);

/**
 * @route   PUT /api/v1/post/:id/questions
 * @desc    Owner sets/updates verification questions for their post
 * @access  Private (owner only — enforced in service)
 * @body    { questions: [{ question: string }] }  (0–4 items)
 */
Router.put('/:id/questions', postController.updateVerificationQuestions);

/**
 * @route   GET /api/v1/post/:id
 * @desc    Get single post — full data for owner/accepted requests, safe DTO otherwise
 * @access  Private
 */
Router.get('/:id', postController.getPostById);

/**
 * @route   PUT /api/v1/post/:id
 * @desc    Update own post
 * @access  Private (owner only)
 */
Router.put('/:id',
    updatePostValidator,
    validate,
    postController.updatePost
);

/**
 * @route   DELETE /api/v1/post/:id
 * @desc    Delete own post
 * @access  Private (requires verified identity, owner only)
 */
Router.delete('/:id', requireVerification, postController.deletePost);

/**
 * @route   PATCH /api/v1/post/:id/status
 * @desc    Update post status (e.g., mark as resolved)
 * @access  Private (owner only)
 */
Router.patch('/:id/status', requireVerification, postController.updatePostStatus);

module.exports = Router;
