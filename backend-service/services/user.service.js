const UserRepo = require('../Repository/user.repo');

class UserService {
    
    /**
     * Get user by Firebase UID
     */
    async getLoginUser(firebaseUid) {
        try {
            const user = await UserRepo.findUserBy_firbase_id(firebaseUid);
            
            if (!user) {
                return {
                    success: false,
                    message: 'User not found'
                };
            }
            
            return {
                success: true,
                message: 'User profile retrieved successfully',
                data: user
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Register new user
     */
    async registerUser(firebaseUid, name, email) {
        try {
            const newUser = await UserRepo.createuser(firebaseUid, name, email);
            
            return {
                success: true,
                message: 'User registered successfully',
                data: newUser
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get user by Supabase ID
     */
    async getUserById(id) {
        try {
            const user = await UserRepo.getUserById(id);
            
            if (!user) {
                return {
                    success: false,
                    message: 'User not found'
                };
            }
            
            return {
                success: true,
                message: 'User retrieved successfully',
                data: user
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Update user profile
     */
    async updateUserProfile(userId, data) {
        try {
            const result = await UserRepo.edituser(userId, data);
            
            if (result[0] === 0) {
                return {
                    success: false,
                    message: 'User not found or no changes made'
                };
            }
            
            return {
                success: true,
                message: 'Profile updated successfully'
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Delete user account
     */
    async deleteUser(userId) {
        try {
            const result = await UserRepo.deletuser(userId);
            
            if (result === 0) {
                return {
                    success: false,
                    message: 'User not found'
                };
            }
            
            return {
                success: true,
                message: 'User deleted successfully'
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Admin: Get all users (role verified by middleware)
     */
    async getAllUsers(limit = 50, offset = 0) {
        try {
            const result = await UserRepo.getAllUsers(limit, offset);
            
            return {
                success: true,
                message: 'Users retrieved successfully',
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
     * Admin: Delete any user (role verified by middleware)
     */
    async adminDeleteUser(userId) {
        try {
            const result = await UserRepo.deletuser(userId);
            
            if (result === 0) {
                return {
                    success: false,
                    message: 'User not found'
                };
            }
            
            return {
                success: true,
                message: 'User deleted by admin'
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Submit verification documents
     */
    async submitVerification(userId, nationalId, phoneNumber, idImageUrl, selfieImageUrl = null, location = null) {
        try {
            // Validate inputs
            if (!nationalId || !phoneNumber || !idImageUrl) {
                return {
                    success: false,
                    message: 'Required verification fields are missing: national_id, phone_number, id_image_url'
                };
            }

            // Check current verification status
            const user = await UserRepo.getUserById(userId);
            if (!user) {
                return {
                    success: false,
                    message: 'User not found'
                };
            }

            // Check if already verified
            if (user.verified && user.verification_status === 'approved') {
                return {
                    success: false,
                    message: 'Your account is already verified'
                };
            }

            // Check if already pending review
            if (user.verification_status === 'pending') {
                return {
                    success: false,
                    message: 'Your verification is already under review. Please wait for admin approval.'
                };
            }

            const result = await UserRepo.submitVerification(userId, nationalId, phoneNumber, idImageUrl, selfieImageUrl, location);
            
            if (result === 0) {
                return {
                    success: false,
                    message: 'User not found'
                };
            }
            
            return {
                success: true,
                message: 'Verification submitted successfully. Your documents are under review.'
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Get verification status
     */
    async getVerificationStatus(userId) {
        try {
            const user = await UserRepo.getVerificationStatus(userId);
            
            if (!user) {
                return {
                    success: false,
                    message: 'User not found'
                };
            }
            
            return {
                success: true,
                message: 'Verification status retrieved',
                data: user
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Admin: Get verifications with status filter (history)
     */
    async getVerifications(status, limit = 50, offset = 0) {
        try {
            const result = await UserRepo.getVerifications(status, limit, offset);
            
            return {
                success: true,
                message: 'Verifications retrieved',
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
     * Admin: Get pending verifications
     */
    async getPendingVerifications(limit = 50, offset = 0) {
        try {
            const result = await UserRepo.getPendingVerifications(limit, offset);
            
            return {
                success: true,
                message: 'Pending verifications retrieved',
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
     * Admin: Approve verification
     */
    async approveVerification(userId, adminNotes = null) {
        try {
            // Check current status
            const user = await UserRepo.getUserById(userId);
            
            if (!user) {
                return {
                    success: false,
                    message: 'User not found'
                };
            }

            if (user.verification_status !== 'pending') {
                return {
                    success: false,
                    message: `Cannot approve verification with status: ${user.verification_status}`
                };
            }

            const result = await UserRepo.approveVerification(userId, adminNotes);
            
            // TODO: Send notification to user about approval
            // NotificationService.send(userId, 'verification_approved', {...})
            
            return {
                success: true,
                message: 'Verification approved successfully'
            };
        } catch (err) {
            throw err;
        }
    }

    /**
     * Admin: Reject verification
     */
    async rejectVerification(userId, adminNotes) {
        try {
            if (!adminNotes) {
                return {
                    success: false,
                    message: 'Rejection reason (notes) is required'
                };
            }

            // Check current status
            const user = await UserRepo.getUserById(userId);
            
            if (!user) {
                return {
                    success: false,
                    message: 'User not found'
                };
            }

            if (user.verification_status !== 'pending') {
                return {
                    success: false,
                    message: `Cannot reject verification with status: ${user.verification_status}`
                };
            }

            const result = await UserRepo.rejectVerification(userId, adminNotes);
            
            // TODO: Send notification to user about rejection with reason
            // NotificationService.send(userId, 'verification_rejected', { reason: adminNotes })
            
            return {
                success: true,
                message: 'Verification rejected'
            };
        } catch (err) {
            throw err;
        }
    }
}

module.exports = new UserService();