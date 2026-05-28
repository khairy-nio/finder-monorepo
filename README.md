# Finder App

Finder App is an intelligent cross-platform platform designed to connect people who lost items with people who found them. The system uses AI-powered image matching to automatically compare lost and found item reports and improve recovery speed and accuracy.

---

# 🌟 Features

### AI-Powered Matching
Uses CLIP-based image embeddings to compare and match lost and found item images.

### Real-Time Communication
Socket.IO-powered real-time messaging between users for secure recovery coordination.

### Geolocation & Maps
Location-aware reports and map integration to identify where items were lost or found.

### Admin Dashboard
Dedicated moderation dashboard for platform administration, post monitoring, and user management.

### Authentication & Security
Secure authentication and protected platform access.

---

# 🏗 Monorepo Structure

The project is organized as a clean multi-service monorepo:

text finder-monorepo/ │ ├── backend-service/ ├── ai-service/ ├── admin-service/ ├── mobile-app/ ├── README.md └── README_DEPLOY.md 

### Services

### backend-service
Node.js + Express backend handling:

- APIs
- Business logic
- Database communication
- Socket.IO events

### ai-service
Python Flask AI microservice responsible for:

- CLIP embeddings
- Image comparison
- AI matching logic

### admin-service
React + Vite web dashboard used for:

- Admin moderation
- Monitoring reports
- Managing users
- Reviewing matches

### mobile-app
Flutter mobile application serving as the primary user-facing platform.

---

# 💻 Tech Stack

## Frontend

### Mobile
- Flutter
- Dart

### Admin Dashboard
- React
- Vite
- Material UI

---

## Backend & AI

### Backend API
- Node.js
- Express.js

### Real-Time
- Socket.IO

### AI Service
- Python
- Flask
- PyTorch
- OpenAI CLIP

---

## Data Layer

- PostgreSQL
- Pinecone Vector Database
- Sequelize ORM

---

# 🚀 Local Development Setup

Clone repository:

bash git clone <repository_url> cd finder-monorepo 

---

## Backend Service

bash cd backend-service npm install npm run dev 

---

## AI Service

bash cd ai-service pip install -r requirements.txt python main_flask.py 

---

## Admin Dashboard

bash cd admin-service npm install npm run dev 

Local dashboard:

text http://localhost:5173 

or

text http://localhost:5174 

depending on available ports.

---

## Mobile App

bash cd mobile-app flutter pub get flutter run 

---

# 🔐 Admin Dashboard Demo Login

For local testing or offline development mode:

### Email

text admin@example.com 

### Password

text admin123 

> Demo credentials are intended for development and testing only.

---

# 🌐 Live Admin Dashboard

Vercel deployment:

text https://finder-admin-dashboard.vercel.app 

Use the demo admin credentials above to access the dashboard.

---

# 📦 Deployment

Deployment instructions, environment variables, and multi-service deployment setup are documented in:

text README_DEPLOY.md 

---

# 📌 Development Notes

- Configure required .env files before running services.
- Keep secrets and API keys outside version control.
- Do not commit production credentials.

---

# 👨‍💻 Project Overview

Finder combines AI matching, real-time communication, and modern cross-platform architecture to simplify lost-and-found recovery while providing administrators with centralized moderation and monitoring tools
