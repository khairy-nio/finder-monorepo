const User = require('../models/User.model');
class userdb {

        async findUserBy_firbase_id(firebaseId){
            try {
                const user = await User.findOne({where:{firebase_uid: firebaseId}});
                if (user) {
                    await this.calculateAndSetTrustScore(user);
                }
                return user;
            } catch (error) {
                throw error;
            }
        }

        async createuser(firebaseId, name, email){
            try {
                const user = await User.create({
                    firebase_uid: firebaseId,
                    name: name,
                    email: email,
                });
                if (user) {
                    await this.calculateAndSetTrustScore(user);
                }
                return user;
            } catch (error) {
                throw error;
            }
        }

        async getUserById(id) {
            try {
                const user = await User.findByPk(id);
                if (user) {
                    await this.calculateAndSetTrustScore(user);
                }
                return user;
            } catch (error) {
                throw error;
            }
        }


        async getAllUsers(limit = 10, offset = 0) {
            try {
                return await User.findAndCountAll({
                    limit: limit,
                    offset: offset,
                    order: [['created_at', 'DESC']]
                });
            } catch (error) {
                throw error;
            }
    }


        async edituser(userId, data){
            try{
                const updateFields = {};
                if (data.name) updateFields.name = data.name;
                if (data.email) updateFields.email = data.email;
                if (data.role) updateFields.role = data.role;
                if (data.status) updateFields.status = data.status;
                if (data.verified !== undefined) updateFields.verified = data.verified;
                if (data.trust_score !== undefined) updateFields.trust_score = data.trust_score;
                if (data.verification_status) updateFields.verification_status = data.verification_status;
                if (data.national_id !== undefined) updateFields.national_id = data.national_id;
                if (data.phone) updateFields.phone_number = data.phone;
                if (data.phone_number) updateFields.phone_number = data.phone_number;
                if (data.bio !== undefined) updateFields.bio = data.bio;
                if (data.country !== undefined) updateFields.country = data.country;
                if (data.state !== undefined) updateFields.state = data.state;
                if (data.city !== undefined) updateFields.city = data.city;
                if (data.area !== undefined) updateFields.area = data.area;
                if (data.profile_image_url) updateFields.profile_image_url = data.profile_image_url;
                if (data.selfie_image_url) updateFields.selfie_image_url = data.selfie_image_url;
                if (data.verification_location) updateFields.verification_location = data.verification_location;
                if (data.verification_notes !== undefined) updateFields.verification_notes = data.verification_notes;
                if (data.moderation_reason !== undefined) {
                    updateFields.moderation_reason = data.moderation_reason;
                    updateFields.moderated_at = new Date();
                }
                
                return await User.update(
                    updateFields,
                    { where: { id: userId } }
                );
            } catch (error) {
                throw error;
            }
        }
        async deletuser(userId){
            try{
                return await User.destroy({
                    where: { id: userId }
                });
            } catch (error) {
                throw error;
            }
        }

    /**
     * Submit verification documents
     */
    async submitVerification(userId, nationalId, phoneNumber, idImageUrl, selfieImageUrl = null, location = null) {
        try {
            const updateData = {
                national_id: nationalId,
                phone_number: phoneNumber,
                id_image_url: idImageUrl,
                verification_status: 'pending',
                verification_submitted_at: new Date()
            };

            if (selfieImageUrl) updateData.selfie_image_url = selfieImageUrl;
            if (location) updateData.verification_location = location;

            const [affectedRows] = await User.update(
                updateData,
                { where: { id: userId } }
            );
            return affectedRows;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Get verification status for a user
     */
    async getVerificationStatus(userId) {
        try {
            const user = await User.findByPk(userId, {
                attributes: ['id', 'verification_status', 'verification_submitted_at', 'verification_reviewed_at', 'verification_notes', 'verified', 'selfie_image_url', 'id_image_url', 'verification_location']
            });
            return user;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Get verifications by status (admin)
     */
    async getVerifications(status, limit = 50, offset = 0) {
        try {
            const sequelize = require('../db/Sequelize');
            const whereClause = {};
            if (status && status !== 'all') {
                whereClause.verification_status = status;
            } else {
                // Default to showing everything that HAS a submission
                const { Op } = require('sequelize');
                whereClause.verification_status = { [Op.ne]: 'not_submitted' };
            }

            const result = await User.findAndCountAll({
                where: whereClause,
                attributes: [
                    'id', 
                    'name', 
                    'email', 
                    'national_id', 
                    'phone_number', 
                    'id_image_url', 
                    'selfie_image_url', 
                    'profile_image_url',
                    'verification_location', 
                    'verification_submitted_at', 
                    'verification_reviewed_at',
                    'verification_status',
                    'verification_notes',
                    'trust_score',
                    'status',
                    'created_at',
                    [
                        sequelize.literal(`(
                            SELECT COUNT(*)
                            FROM reports AS report
                            WHERE
                                report.reported_user_id = users.id
                        )`),
                        'reports_count'
                    ]
                ],
                limit,
                offset,
                order: [['verification_submitted_at', 'DESC']]
            });
            return result;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Get all pending verifications (admin)
     */
    async getPendingVerifications(limit = 50, offset = 0) {
        try {
            const sequelize = require('../db/Sequelize');
            const result = await User.findAndCountAll({
                where: { verification_status: 'pending' },
                attributes: [
                    'id', 
                    'name', 
                    'email', 
                    'national_id', 
                    'phone_number', 
                    'id_image_url', 
                    'selfie_image_url', 
                    'profile_image_url',
                    'verification_location', 
                    'verification_submitted_at', 
                    'trust_score',
                    'status',
                    'created_at',
                    [
                        sequelize.literal(`(
                            SELECT COUNT(*)
                            FROM reports AS report
                            WHERE
                                report.reported_user_id = users.id
                        )`),
                        'reports_count'
                    ]
                ],
                limit,
                offset,
                order: [['verification_submitted_at', 'ASC']]
            });
            return result;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Approve verification (admin)
     */
    async approveVerification(userId, adminNotes = null) {
        try {
            const user = await User.findByPk(userId);
            if (!user) return 0;

            const [affectedRows] = await User.update(
                {
                    verification_status: 'approved',
                    verified: true,
                    verification_reviewed_at: new Date(),
                    verification_notes: adminNotes
                },
                { where: { id: userId } }
            );

            // Re-fetch and trigger automatic trust calculation
            const updatedUser = await User.findByPk(userId);
            if (updatedUser) {
                await this.calculateAndSetTrustScore(updatedUser);
            }

            return affectedRows;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Reject verification (admin)
     */
    async rejectVerification(userId, adminNotes) {
        try {
            const [affectedRows] = await User.update(
                {
                    verification_status: 'rejected',
                    verified: false,
                    verification_reviewed_at: new Date(),
                    verification_notes: adminNotes
                },
                { where: { id: userId } }
            );

            // Re-fetch and trigger automatic trust calculation
            const updatedUser = await User.findByPk(userId);
            if (updatedUser) {
                await this.calculateAndSetTrustScore(updatedUser);
            }

            return affectedRows;
        } catch (error) {
            throw error;
        }
    }

    /**
     * Calculate and dynamically save the security-focused Trust Score
     */
    async calculateAndSetTrustScore(user) {
        if (!user) return 0;
        let score = 0;

        // 1. Identity Verification Approved (+45)
        if (user.verification_status === 'approved') {
            score += 45;
        }

        // 2. Phone Number Verified (+10)
        if (user.phone_number && user.phone_number.trim().length > 0) {
            score += 10;
        }

        // 3. Complete Address (country + city + area) (+10)
        const hasCountry = user.country && user.country.trim().length > 0;
        const hasCity = user.city && user.city.trim().length > 0;
        const hasArea = user.area && user.area.trim().length > 0;
        if (hasCountry && hasCity && hasArea) {
            score += 10;
        }

        // 4. Profile Photo or Verified Selfie (+5)
        if (user.profile_image_url || user.selfie_image_url) {
            score += 5;
        }

        // 5. Account Age (+1 per 30 days, capped at +5 maximum)
        if (user.created_at) {
            const diffMs = Date.now() - new Date(user.created_at).getTime();
            const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
            const ageBonus = Math.min(5, Math.floor(diffDays / 30));
            score += ageBonus;
        }

        // 6. Good Moderation History (+5 base)
        let goodModerationBonus = 5;
        if (user.status === 'suspended' || user.status === 'banned') {
            goodModerationBonus = 0;
        }

        // Fetch reports count that are resolved (approved valid reports)
        const Report = require('../models/Report.model');
        let reportsCount = 0;
        if (Report) {
            try {
                // Only count valid, moderation-approved resolved reports
                reportsCount = await Report.count({ where: { reported_user_id: user.id, status: 'resolved' } });
                score -= (reportsCount * 10);
            } catch (e) {
                console.error("Error fetching reports count in trust score calculation:", e);
            }
        }

        if (reportsCount > 0) {
            goodModerationBonus = 0;
        }
        score += goodModerationBonus;

        // 7. Advanced Trust Layer (Slow progression exceeding 70-80% up to 100%)
        // A. Successful recoveries: +3 per recovery, capped at +15
        try {
            const RecoveryPointTransaction = require('../models/RecoveryPointTransaction.model');
            if (RecoveryPointTransaction) {
                const recoveriesCount = await RecoveryPointTransaction.count({
                    where: { user_id: user.id, reason: 'successful_recovery' }
                });
                const recoveryBonus = Math.min(15, recoveriesCount * 3);
                score += recoveryBonus;
            }
        } catch (e) {
            console.error("Error fetching successful recoveries count in trust score calculation:", e);
        }

        // B. Long-term Clean History: +5 extra if account > 90 days and no moderation history
        if (goodModerationBonus > 0 && user.created_at) {
            const diffMs = Date.now() - new Date(user.created_at).getTime();
            const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
            if (diffDays > 90) {
                score += 5;
            }
        }

        // C. Long Account Age: +1 per 90 days (3 months) beyond base 5 months (150 days), capped at +5
        if (user.created_at) {
            const diffMs = Date.now() - new Date(user.created_at).getTime();
            const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
            if (diffDays > 150) {
                const excessDays = diffDays - 150;
                const longAgeBonus = Math.min(5, Math.floor(excessDays / 90));
                score += longAgeBonus;
            }
        }

        // Apply active punishment reductions
        if (user.status === 'suspended') {
            score -= 50;
        } else if (user.status === 'banned') {
            score = 0; // Banned users get 0 trust directly
        }

        // Rejected Verification Abuse (-20)
        if (user.verification_status === 'rejected') {
            const notes = (user.verification_notes || '').toLowerCase();
            if (notes.includes('abuse') || notes.includes('fraud') || notes.includes('fake') || notes.includes('spam')) {
                score -= 20;
            }
        }

        // Clamp between 0 and 100
        const finalScore = Math.max(0, Math.min(100, score));

        // Update DB if different
        if (user.trust_score !== finalScore) {
            user.trust_score = finalScore;
            await User.update({ trust_score: finalScore }, { where: { id: user.id } });
        }

        return finalScore;
    }
}

module.exports = new userdb();
