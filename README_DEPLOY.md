# Finder App - Deployment Guide

## 1. Final Repository Structure
```
finder-monorepo/
├── admin-service/       # React/Vite Dashboard
├── ai-service/          # Flask + CLIP Embedding Service
├── backend-service/     # Node.js + Socket.IO Backend
├── mobile-app/          # Flutter Mobile App
├── .gitignore
└── README_DEPLOY.md
```

## 2. Railway Services
Deploy the following independent services from this monorepo:
* **Database:** PostgreSQL (provision natively via Railway)
* **AI Service:** Deployed from `/ai-service`
* **Backend Service:** Deployed from `/backend-service`
* **Admin Dashboard:** Deployed from `/admin-service`

## 3. Deployment Order
1. Deploy PostgreSQL database.
2. Deploy AI Service (note its production URL).
3. Deploy Backend Service (pointing to DB and AI Service).
4. Deploy Admin Dashboard (pointing to Backend Service).

## 4. Environment Variables
### Backend Service (`backend-service`)
* `PORT`
* `DATABASE_URL`
* `AI_SERVICE_URL`
* `JWT_SECRET`
* `CORS_ORIGINS`
* (Include Firebase/Cloudinary credentials safely)

### AI Service (`ai-service`)
* `PORT`

### Admin Service (`admin-service`)
* `VITE_API_URL`

## 5. GitHub Push Commands
```bash
cd finder-monorepo
git init
git checkout -b deployment-restructure
git add .
git commit -m "chore: add root deployment files and finalize monorepo structure"
git remote add origin <YOUR_GITHUB_REPO_URL>
git push -u origin deployment-restructure
```

## 6. Railway Deployment Commands
Railway handles deployments via its dashboard UI. Alternatively, using the Railway CLI:
```bash
npm i -g @railway/cli
railway login
railway link

# Deploy backend
railway up --service backend-service -d

# Deploy AI
railway up --service ai-service -d

# Deploy Admin
railway up --service admin-service -d
```
