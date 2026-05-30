// Eager-load service configs so any init errors surface at boot rather than
// at first request. Testdbconnection / TestPineconeConnection were removed from
// here — they are standalone diagnostic scripts, not production boot steps.
require('../config/firebase.config');
require('../config/pinecone.config');
require('../config/cloudinary.config');
console.log('✅ Service configs loaded');
