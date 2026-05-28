const admin = require("firebase-admin");

let serviceAccount = null;

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  } catch (error) {
    throw new Error("Invalid FIREBASE_SERVICE_ACCOUNT JSON");
  }
}

if (!serviceAccount) {
  try {
    serviceAccount = require("./finder-app-14ea2-7a111cd02cc5.json");
  } catch (err) {
    console.warn("⚠️  Firebase Admin credentials (finder-app-14ea2-7a111cd02cc5.json) not found.");
    console.warn("🔧 Using MOCK Firebase Admin SDK for local offline development.");
  }
}

if (serviceAccount) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} else {
  // Helper to decode JWT payload locally without signature verification
  const decodeJwtPayload = (token) => {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;
      const payload = parts[1];
      const decoded = Buffer.from(payload, 'base64').toString('utf8');
      return JSON.parse(decoded);
    } catch (e) {
      return null;
    }
  };

  // Create a minimal mock of firebase-admin so middleware and controllers don't crash
  const mockAdmin = {
    auth: () => ({
      verifyIdToken: async (token) => {
        console.log(`🔑 [Mock Firebase] Verifying token: ${token.substring(0, 30)}...`);
        
        // 1. Direct mock token prefix
        if (token && token.startsWith("mock-token-")) {
          const uid = token.replace("mock-token-", "");
          return { uid, email: `${uid}@example.com`, name: uid.toUpperCase() };
        }
        
        // 2. Decode real Firebase JWT token locally
        const decodedPayload = decodeJwtPayload(token);
        if (decodedPayload && decodedPayload.sub) {
          console.log(`🔐 [Mock Firebase] Decoded real JWT for UID: ${decodedPayload.sub}`);
          return {
            uid: decodedPayload.sub,
            email: decodedPayload.email,
            name: decodedPayload.name || decodedPayload.email?.split('@')[0] || 'User'
          };
        }
        
        // 3. Fallback
        return { uid: "mock-uid-123", email: "mockuser@example.com", name: "Mock User" };
      }
    })
  };
  module.exports = mockAdmin;
  return;
}


module.exports = admin;

