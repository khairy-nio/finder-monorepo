<h1 align="center">Finder — Lost & Found Platform</h1>

<p align="center">
  An AI-powered platform that connects people who lost items with people who found them.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Node.js-Express-339933?logo=node.js&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/Python-Flask-3776AB?logo=python&logoColor=white" alt="Python" />
  <img src="https://img.shields.io/badge/React-18-61DAFB?logo=react&logoColor=black" alt="React" />
  <img src="https://img.shields.io/badge/PostgreSQL-Sequelize-4169E1?logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/AI-OpenAI%20CLIP-412991?logo=openai&logoColor=white" alt="CLIP" />
</p>

---

## Overview

**Finder** is a full-stack, AI-powered lost-and-found recovery system built as a clean monorepo. Users post lost or found item reports with photos; the AI service automatically computes visual similarity between reports using OpenAI CLIP embeddings and surfaces the best matches. A real-time messaging layer lets users coordinate recovery securely, and a trust score system rewards honest, verified users.

| Service | Tech | Role |
|---|---|---|
| `mobile-app` | Flutter / Dart | Primary user-facing app (iOS & Android) |
| `backend-service` | Node.js / Express / Socket.IO | REST API, business logic, real-time events |
| `ai-service` | Python / Flask / CLIP | Image embedding & similarity matching |
| `admin-service` | React 18 / Vite | Moderation & analytics dashboard |

---

## Features

### AI-Powered Matching
- CLIP (ViT-B/32) image embeddings stored in **Pinecone** vector database
- Cosine similarity search across all active reports
- Automatic match suggestions surfaced to relevant users

### Real-Time Messaging
- Socket.IO-powered in-app chat
- Image sharing in conversations
- Online/offline presence indicators
- Unread message badge counters

### Trust Score System
- Points awarded for verified reports, successful recoveries, and community activity
- Tiered user trust levels visible on profiles
- Verification badge system for identity-verified accounts

### Lost & Found Board
- Rich post cards with photo, location, category, and status
- Filter and search by category, date, and location
- Post status lifecycle: active → resolved

### Dark / Light / System Theme
- Full Material 3 dark and light themes
- Persisted user preference via SharedPreferences
- All screens and widgets adapt dynamically

### Admin Dashboard
- Post moderation and visibility control
- User management and verification review
- Platform-wide analytics and match monitoring
- Live at: [finder-admin-dashboard.vercel.app](https://finder-admin-dashboard.vercel.app)

### Authentication
- Firebase Authentication (Google Sign-In + email/password)
- JWT-based admin authentication with bcrypt-hashed passwords
- Protected routes and role-based access control

---

## Monorepo Structure

```
finder-monorepo/
├── mobile-app/          # Flutter app (iOS & Android)
│   ├── lib/
│   │   ├── core/        # Theme, network, services, utils
│   │   └── presentation/# Screens, widgets, providers
│   └── pubspec.yaml
│
├── backend-service/     # Node.js REST API + Socket.IO
│   ├── Controllers/
│   ├── Models/
│   ├── Routes/
│   ├── Services/
│   ├── Middlewares/
│   └── server.js
│
├── ai-service/          # Python CLIP embedding service
│   ├── main_flask.py
│   ├── requirements.txt
│   └── README_FLASK.md
│
├── admin-service/       # React 18 + Vite dashboard
│   ├── src/
│   └── vite.config.js
│
├── README.md
└── README_DEPLOY.md
```

---

## Tech Stack

### Mobile App
- **Flutter 3** + Dart — cross-platform iOS & Android
- **Material 3** design system with custom design tokens
- **Provider** — state management
- **SharedPreferences** — local persistence

### Backend API
- **Node.js** + **Express 5** — REST API
- **Socket.IO 4** — real-time bidirectional events
- **Sequelize 6** + **PostgreSQL** — ORM and relational data
- **Firebase Admin** — user identity verification
- **Cloudinary** — image upload and CDN delivery
- **JWT** + **bcryptjs** — admin authentication

### AI Service
- **Python** + **Flask** — lightweight microservice
- **PyTorch** + **OpenAI CLIP** (ViT-B/32 via sentence-transformers)
- **Pinecone** — vector database for similarity search

### Admin Dashboard
- **React 18** + **Vite** — fast build tooling
- **Material UI (MUI)** — component library
- **React Query** — server state and caching
- **Firebase Auth** / **JWT** — authentication

---

## Local Development Setup

### Prerequisites
- Flutter SDK 3.x
- Node.js 18+
- Python 3.9+
- PostgreSQL (or SQLite for local dev)
- A `.env` file per service (see below)

### 1. Clone the repository

```bash
git clone https://github.com/your-username/finder-monorepo.git
cd finder-monorepo
```

### 2. Backend Service

```bash
cd backend-service
npm install
cp .env.example .env   # fill in your environment variables
npm run dev
```

Runs on `http://localhost:3500`

### 3. AI Service

```bash
cd ai-service
pip install -r requirements.txt
python main_flask.py
```

Runs on `http://localhost:5000`

### 4. Admin Dashboard

```bash
cd admin-service
npm install
npm run dev
```

Runs on `http://localhost:5173`

**Demo login** (development only):
```
Email:    admin@example.com
Password: admin123
```

### 5. Mobile App

```bash
cd mobile-app
flutter pub get
flutter run
```

---

## Environment Variables

### `backend-service/.env`

```env
PORT=3500
DATABASE_URL=postgresql://user:password@localhost:5432/finder_db

# Firebase Admin
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

# Cloudinary
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=

# Pinecone
PINECONE_API_KEY=
PINECONE_INDEX=

# AI Service
AI_SERVICE_URL=https://khairnioo-finder-ai.hf.space

# JWT (Admin)
JWT_SECRET=your-very-strong-secret-key
JWT_EXPIRES_IN=7d
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=your-admin-password

# CORS
CORS_ORIGINS=http://localhost:5173,https://finder-admin-dashboard.vercel.app
```

### `ai-service/.env`

```env
PORT=5000
PINECONE_API_KEY=
PINECONE_INDEX=
```

### `admin-service/.env`

```env
VITE_API_URL=http://localhost:3500/api/v1
```

### Mobile App — Firebase config

Place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the appropriate platform directories. Update `lib/core/constants/api_constants.dart` with your backend base URL.

---

## Seeding the Admin Account

After setting `ADMIN_EMAIL` and `ADMIN_PASSWORD` in the backend `.env`:

```bash
cd backend-service
npm run seed:admin
```

This hashes the password and inserts the admin user into the database.

---

## Deployment

Full deployment instructions are in [README_DEPLOY.md](README_DEPLOY.md).

### Stack

| Service | Platform |
|---|---|
| Backend + AI | [AWS EC2](https://aws.amazon.com/ec2) |
| Admin Dashboard | [Vercel](https://vercel.com) |
| Database | PostgreSQL (on EC2) |
| Images | Cloudinary |
| Vectors | Pinecone |

### Deployment order

1. Provision a PostgreSQL database
2. Deploy the AI service — note its public URL
3. Deploy the backend — set `AI_SERVICE_URL` + `DATABASE_URL`
4. Run `npm run seed:admin` on the server
5. Deploy the admin dashboard — set `VITE_API_URL`

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push and open a pull request

Please keep commits scoped to a single service when possible.

---

## License

This project is licensed under the **MIT License**.

---

<p align="center">Built with Flutter, Node.js, Python, and React.</p>
