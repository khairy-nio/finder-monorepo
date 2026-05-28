const reportRepo = require('../Repository/report.repo');
const userRepo = require('../Repository/user.repo');

class ReportService {
    async createReport(reporter_id, data) {
        const { reportType, reported_user_id, reported_post_id, reported_message_id, reported_chat_id, reason, note } = data;
        
        if (reportType === 'user') {
            if (reporter_id === reported_user_id) throw new Error('You cannot report yourself');
            const reportedUser = await userRepo.getUserById(reported_user_id);
            if (!reportedUser) throw new Error('Reported user not found');
            const existingReport = await reportRepo.checkDuplicateReport(reporter_id, { reported_user_id });
            if (existingReport) throw new Error('You have already reported this user and it is pending review');
        } else if (reportType === 'post') {
            const existingReport = await reportRepo.checkDuplicateReport(reporter_id, { reported_post_id });
            if (existingReport) throw new Error('You have already reported this post and it is pending review');
        } else if (reportType === 'message') {
            const existingReport = await reportRepo.checkDuplicateReport(reporter_id, { reported_message_id });
            if (existingReport) throw new Error('You have already reported this message and it is pending review');
        } else if (reportType === 'chat') {
            const existingReport = await reportRepo.checkDuplicateReport(reporter_id, { reported_chat_id });
            if (existingReport) throw new Error('You have already reported this chat and it is pending review');
        }

        const report = await reportRepo.createReport({
            reporter_id,
            reportType,
            reported_user_id: reportType === 'user' ? reported_user_id : null,
            reported_post_id: reportType === 'post' ? reported_post_id : null,
            reported_message_id: reportType === 'message' ? reported_message_id : null,
            reported_chat_id: reportType === 'chat' ? reported_chat_id : null,
            reason,
            note
        });

        return report;
    }

    async getReportById(id) {
        const report = await reportRepo.getReportById(id);
        if (!report) {
            throw new Error('Report not found');
        }
        return report;
    }

    async getAllReports(limit, offset, status) {
        const parsedLimit = parseInt(limit) || 10;
        const parsedOffset = parseInt(offset) || 0;

        const reports = await reportRepo.getAllReports(parsedLimit, parsedOffset, status);

        return {
            total_items: reports.count,
            reports: reports.rows,
            current_page: Math.floor(parsedOffset / parsedLimit) + 1,
            total_pages: Math.ceil(reports.count / parsedLimit)
        };
    }

    async updateReportStatus(id, status) {
        const report = await reportRepo.getReportById(id);
        if (!report) {
            throw new Error('Report not found');
        }

        const [updatedRows, [updatedReport]] = await reportRepo.updateReportStatus(id, status);
        if (updatedRows === 0) {
            throw new Error('Failed to update report status');
        }

        return updatedReport || { ...report.toJSON(), status };
    }

    async updateReport(id, data) {
        const report = await reportRepo.getReportById(id);
        if (!report) {
            throw new Error('Report not found');
        }

        if (data.status && !['pending', 'resolved'].includes(data.status)) {
            throw new Error('Status must be pending or resolved');
        }

        const [updatedRows, [updatedReport]] = await reportRepo.updateReport(id, data);
        if (updatedRows === 0) {
            throw new Error('Failed to update report');
        }

        return updatedReport || { ...report.toJSON(), ...data };
    }
}

module.exports = new ReportService();
