const fs = require('fs');
const json = JSON.parse(fs.readFileSync('/Users/mohamed/Desktop/tenacious-veld-426502-c3-firebase-adminsdk-fbsvc-8d4b5c7623.json', 'utf8'));
const str = JSON.stringify(json);
let env = fs.readFileSync('/Users/mohamed/Documents/Lostproject-master/finder-monorepo/backend-service/.env', 'utf8');
env = env.replace(/FIREBASE_SERVICE_ACCOUNT=.*/, 'FIREBASE_SERVICE_ACCOUNT=\'' + str + '\'');
fs.writeFileSync('/Users/mohamed/Documents/Lostproject-master/finder-monorepo/backend-service/.env', env);
