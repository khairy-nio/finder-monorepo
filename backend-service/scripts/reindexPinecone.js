require('dotenv').config();
const sequelize = require('../db/Sequelize');
const { Post } = require('../models');
const AIService = require('../config/ai.config');
const pineconeIndex = require('../config/pinecone.config');
const { normalizeLocation } = require('../utils/normalization.util');

async function run() {
  try {
    await sequelize.authenticate();
    console.log('DB connected');

    const posts = await Post.findAll({ where: { status: 'active' } });
    console.log(`Found ${posts.length} active posts to index.`);

    for (const post of posts) {
      const imageUrl = post.image_url;
      if (!imageUrl) continue;
      
      console.log(`Generating embedding for post ${post.id}...`);
      try {
        const vector = await AIService.generateEmbedding(imageUrl);
        const pineconeRecord = {
          id: post.id,
          values: vector,
          metadata: {
              post_type: post.type,
              status: post.status,
              country: normalizeLocation(post.country),
              state: normalizeLocation(post.state),
              city: normalizeLocation(post.city),
              area: normalizeLocation(post.area),
              category: normalizeLocation(post.category),
              created_at: new Date(post.created_at || Date.now()).toISOString()
          }
        };

        await pineconeIndex.upsert([pineconeRecord]);
        console.log(`✅ Upserted to Pinecone: ${post.id}`);
      } catch (err) {
        console.log(`❌ Failed embedding for ${post.id}: ${err.message}`);
      }
    }
    console.log('All done!');
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

run();
