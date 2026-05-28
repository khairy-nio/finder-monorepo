const reportService = require('../services/report.service');
const response = require('../utils/response.util');

class ReportController {
    async createReport(req, res) {
        try {
            const reporter_id = req.user.id;
            const report = await reportService.createReport(reporter_id, req.body);
            return response.Success(res, 'Report submitted successfully', report, 201);
        } catch (error) {
            if (error.message.includes('You cannot report yourself') ||
                error.message.includes('not found') ||
                error.message.includes('You have already reported')) {
                return response.ErrorResponse(res, error.message, null, 400);
            }
            return response.ErrorResponse(res, 'Internal server error', [error.message], 500);
        }
    }

    async getReportById(req, res) {
        try {
            const report = await reportService.getReportById(req.params.id);
            return response.Success(res, 'Report retrieved successfully', report, 200);
        } catch (error) {
            if (error.message === 'Report not found') {
                return response.ErrorResponse(res, error.message, null, 404);
            }
            return response.ErrorResponse(res, 'Internal server error', [error.message], 500);
        }
    }

    async getAllReports(req, res) {
        try {
            const { limit, offset, status } = req.query;
            const data = await reportService.getAllReports(limit, offset, status);
            return response.Success(res, 'Reports retrieved successfully', data, 200);
        } catch (error) {
            return response.ErrorResponse(res, 'Internal server error', [error.message], 500);
        }
    }

    async updateReportStatus(req, res) {
        try {
            const report = await reportService.updateReport(req.params.id, req.body);
            return response.Success(res, 'Report status updated successfully', report, 200);
        } catch (error) {
            if (error.message === 'Report not found') {
                return response.ErrorResponse(res, error.message, null, 404);
            }
            return response.ErrorResponse(res, 'Internal server error', [error.message], 500);
        }
    }
}

module.exports = new ReportController();
