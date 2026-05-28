/**
 * Consistent location normalization utility
 * Ensures values like "Cairo" and "Cairo City" are standardized
 */
const normalizeLocation = (value) => {
    if (!value || typeof value !== 'string') return '';
    
    return value
        .trim()
        .toLowerCase()
        // Remove special characters and extra spaces
        .replace(/[^\w\s]/g, '')
        .replace(/\s+/g, ' ');
};

module.exports = {
    normalizeLocation
};
