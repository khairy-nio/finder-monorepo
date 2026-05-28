import { initializeApp, getApps } from 'firebase/app';
import { getAuth, setPersistence, browserLocalPersistence } from 'firebase/auth';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

const requiredConfig = [
  ['VITE_FIREBASE_API_KEY', firebaseConfig.apiKey],
  ['VITE_FIREBASE_AUTH_DOMAIN', firebaseConfig.authDomain],
  ['VITE_FIREBASE_PROJECT_ID', firebaseConfig.projectId],
  ['VITE_FIREBASE_APP_ID', firebaseConfig.appId],
];

const missingConfig = requiredConfig
  .filter(([, value]) => !value || value.startsWith('your_'))
  .map(([name]) => name);

export const firebaseConfigError = missingConfig.length
  ? `Missing Firebase config: ${missingConfig.join(', ')}`
  : '';

const app = firebaseConfigError
  ? null
  : getApps()[0] || initializeApp(firebaseConfig);

export const auth = app ? getAuth(app) : null;

if (auth) {
  // Keep admin sessions across reloads without failing the whole dashboard.
  setPersistence(auth, browserLocalPersistence).catch((err) => {
    console.error('Firebase persistence error:', err);
  });
}

export default app;
