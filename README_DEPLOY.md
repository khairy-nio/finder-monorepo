# Finder App — Deployment Guide

## 1. Repository Structure
```
finder-monorepo/
├── admin-service/       # React/Vite Dashboard
├── ai-service/          # Flask + CLIP Embedding Service
├── backend-service/     # Node.js + Socket.IO Backend
├── mobile-app/          # Flutter Mobile App
└── README_DEPLOY.md
```

## 2. Deployment Stack

| Service | Platform |
|---|---|
| Backend | AWS EC2 |
| AI Service | Hugging Face Spaces |
| Admin Dashboard | Vercel |
| Database | Supabase |
| Images | Cloudinary |
| Vectors | Pinecone |

## 3. Deployment Order
1. Create a PostgreSQL database on Supabase — copy the connection string.
2. Deploy AI Service to Hugging Face Spaces — note its public URL.
3. Deploy Backend on EC2 — set `AI_SERVICE_URL` to the Hugging Face URL.
4. Deploy Admin Dashboard to Vercel — set `VITE_API_URL` to the EC2 backend URL.

## 4. Environment Variables

### Backend Service (`backend-service`)
```env
PORT=3500
DATABASE_URL=postgresql://postgres:[password]@db.[project-ref].supabase.co:5432/postgres
AI_SERVICE_URL=https://khairnioo-finder-ai.hf.space
JWT_SECRET=
JWT_EXPIRES_IN=7d
CORS_ORIGINS=https://finder-admin-dashboard.vercel.app
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
PINECONE_API_KEY=
PINECONE_INDEX=
```

### AI Service (`ai-service`)
```env
PORT=8000
PINECONE_API_KEY=
PINECONE_INDEX=
```

### Admin Service (`admin-service`)
```env
VITE_API_URL=https://<your-ec2-ip>/api/v1
```

## 5. GitHub Push Commands
```bash
cd finder-monorepo
git init
git add .
git commit -m "chore: finalize monorepo structure"
git remote add origin <YOUR_GITHUB_REPO_URL>
git push -u origin main
```
