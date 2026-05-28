require('dotenv').config();
const pineconeIndex = require('../config/pinecone.config');
const { Sequelize } = require('sequelize');
const sequelize = require('../db/Sequelize');
const Post = require('../models/Post.model');

async function checkIndex() {
    try {
        console.log('1. Describing Pinecone Index stats...');
        // Pinecone doesn't always have a direct .describeIndexStats method on the index object in all SDK versions,
        // so let's try calling index.describeIndexStats() or similar.
        let stats = null;
        try {
            stats = await pineconeIndex.describeIndexStats();
            console.log('Stats:', JSON.stringify(stats, null, 2));
        } catch (e) {
            console.log('describeIndexStats not supported or failed:', e.message);
        }

        console.log('\n2. Fetching some active posts from SQL...');
        const posts = await Post.findAll({
            limit: 5,
            where: { status: 'active', moderation_status: 'visible' }
        });
        console.log(`Found ${posts.length} active posts in DB.`);
        
        if (posts.length > 0) {
            const ids = posts.map(p => p.id);
            console.log('Post IDs:', ids);
            
            console.log('\n3. Fetching vectors from Pinecone for these post IDs...');
            try {
                const fetchResult = await pineconeIndex.fetch(ids);
                console.log('Fetch Result keys:', Object.keys(fetchResult.records || fetchResult.vectors || {}));
                console.log('Full Fetch Result Sample:', JSON.stringify(fetchResult, null, 2));
            } catch (e) {
                console.log('Failed to fetch vectors from Pinecone:', e.message);
            }
        }
        
        process.exit(0);
    } catch (error) {
        console.error('Error during check:', error);
        process.exit(1);
    }
}

checkIndex();
