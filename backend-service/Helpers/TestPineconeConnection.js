const index = require('../config/pinecone.config');

(async () => {
  try {
    // We try to get stats about the index to verify the connection
    const stats = await index.describeIndexStats();
    console.log('✅ Connected to Pinecone!');
    console.log(`   - Total Vectors: ${stats.totalRecordCount}`);
    console.log(`   - Dimensions: ${stats.dimension}`);
  } catch (err) {
    console.error('❌ Pinecone connection failed:', err.message);
  }
})();