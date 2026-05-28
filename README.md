# Finder App

**Finder App** is an intelligent, cross-platform solution designed to seamlessly connect people who have lost items with those who have found them. The platform leverages advanced AI image matching to automatically pair lost item reports with found item listings, enabling rapid and secure recovery.

---

## 🌟 Main Features
* **AI-Powered Matching:** Utilizes the CLIP model to accurately compare and match images of lost and found items.
* **Real-Time Communication:** Instant messaging via Socket.IO allowing users to coordinate item recovery securely.
* **Geolocation & Mapping:** Interactive maps to pinpoint exactly where items were lost or found.
* **Moderation Dashboard:** Centralized admin portal to manage users, monitor posts, and review AI matching results.
* **Secure Authentication:** Robust user authentication ensuring a safe environment for all interactions.

---

## 🏗 Monorepo Structure

This repository is organized as a multi-service monorepo, cleanly separating the system's core components:

* **`backend-service/`** — Core API server managing database operations, business logic, and real-time Socket.IO events.
* **`ai-service/`** — Dedicated Python Flask microservice handling heavy-lifting AI image embeddings using the CLIP architecture.
* **`admin-service/`** — React & Vite-powered web dashboard for platform administrators.
* **`mobile-app/`** — Cross-platform Flutter mobile application serving as the primary user interface.

---

## 💻 Tech Stack

### Frontend
* **Mobile:** Flutter, Dart
* **Admin Web:** React, Vite

### Backend & AI
* **Core API:** Node.js, Express.js
* **Real-time:** Socket.IO
* **AI Microservice:** Python, Flask, PyTorch, OpenAI CLIP model

### Data & Infrastructure
* **Databases:** PostgreSQL (Relational), Pinecone (Vector Database for embeddings)
* **ORM:** Sequelize

---

## 🚀 Local Setup Commands

To run this monorepo locally for development, follow the commands below for each respective service:

```bash
# 1. Clone the repository
git clone <repository_url>
cd finder-monorepo

# 2. Setup Backend Service
cd backend-service
npm install
npm run dev

# 3. Setup AI Service
cd ../ai-service
pip install -r requirements.txt
python main_flask.py

# 4. Setup Admin Dashboard
cd ../admin-service
npm install
npm run dev

# 5. Setup Mobile App
cd ../mobile-app
flutter pub get
flutter run
```

> **Note:** Ensure you configure the respective `.env` files for the backend and frontend services before starting the development servers.

---

## 📦 Deployment Note

For production deployments, multi-service setup rules, and required environment variables, please refer strictly to the **[README_DEPLOY.md](./README_DEPLOY.md)** file included in the root of this repository.
