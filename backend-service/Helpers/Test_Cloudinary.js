require('dotenv').config();
const cloudinary = require('../config/cloudinary.config');

async function testUpload() {
    console.log('🔄 Testing Cloudinary Connection...');
    console.log(`☁️  Cloud Name: ${process.env.CLOUDINARY_CLOUD_NAME}`);

    const testImage = 'https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png';

    try {
        const result = await cloudinary.uploader.upload(testImage, {
            folder: 'test_uploads',
            public_id: `test_${Date.now()}`
        });

        console.log('✅ Upload Success!');
        console.log('-------------------------------------------');
        console.log('📸 Image URL:', result.secure_url);
        console.log('📂 Public ID:', result.public_id);
        console.log('-------------------------------------------');
        console.log('✨ You can now safely delete this file.');

    } catch (error) {
        console.error('❌ Upload Failed:');
        console.error(error.message);
        if(error.error) console.error(error.error);
    }
}

testUpload();