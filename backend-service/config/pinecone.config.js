const { Pinecone } = require('@pinecone-database/pinecone');

let index;

if (process.env.PINECONE_API_KEY) {
  // Initialize the real client
  const pc = new Pinecone({
      apiKey: process.env.PINECONE_API_KEY 
  });
  index = pc.index('finder-app');
} else {
  console.warn("⚠️  PINECONE_API_KEY not found.");
  console.warn("🔧 Using MOCK Pinecone client for local offline development.");
  index = {
    upsert: async (vectors) => {
      console.log(`🌲 [Mock Pinecone] Upserting ${vectors.length} vectors`);
      return { upsertedCount: vectors.length };
    },
    deleteOne: async (id) => {
      console.log(`🌲 [Mock Pinecone] Deleting vector: ${id}`);
      return {};
    },
    update: async (options) => {
      console.log(`🌲 [Mock Pinecone] Updating vector: ${options.id}`);
      return {};
    },
    query: async (options) => {
      console.log(`🌲 [Mock Pinecone] Querying similar vectors`);
      return { matches: [] };
    },
    describeIndexStats: async () => {
      return { totalRecordCount: 0, namespaces: {} };
    },
    fetch: async (ids) => {
      console.log(`🌲 [Mock Pinecone] Fetching vectors: ${ids}`);
      return { records: {} };
    }
  };
}

module.exports = index;