let cloudinaryInst = null;

module.exports = {
  get uploader() {
    if (!cloudinaryInst) {
      cloudinaryInst = require('cloudinary').v2;
      cloudinaryInst.config({ 
        cloud_name: process.env.CLOUDINARY_CLOUD_NAME, 
        api_key: process.env.CLOUDINARY_API_KEY, 
        api_secret: process.env.CLOUDINARY_API_SECRET 
      });
    }
    return cloudinaryInst.uploader;
  }
};