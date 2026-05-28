require('dotenv').config();
const pineconeIndex = require('../config/pinecone.config');

async function listPinecone() {
    try {
        console.log('Querying top 100 vectors from Pinecone using a dummy zero vector...');
        const zeroVector = new Array(512).fill(0.0);
        
        const queryResponse = await pineconeIndex.query({
            vector: zeroVector,
            topK: 100,
            includeMetadata: true
        });
        
        console.log(`Found ${queryResponse.matches?.length || 0} matches.`);
        console.log('Matches details:');
        console.log(JSON.stringify(queryResponse.matches, null, 2));
        
        process.exit(0);
    } catch (e) {
        console.error('Error listing Pinecone:', e);
        process.exit(1);
    }
}

listPinecone();
