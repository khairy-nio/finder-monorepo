<<<<<<< HEAD
# Lost-app
=======
# Lost & Found Mobile Application

A Flutter mobile application that helps users find lost items or return found items using image-based matching powered by AI.

## 🚀 Project Overview

This is a **graduation project** implementing a **Lost & Found system** with:

- **Clean Architecture** (Domain, Data, Presentation layers)
- **Image-based search** (Search by Image)
- **Automatic visual matching** using AI embeddings
- **Post creation** (Lost / Found items)
- **In-app chat** between matched users
- **Flask backend integration** ready

## 📁 Project Structure

```
lost/
├── lib/
│   ├── core/                    # Core utilities & configurations
│   │   ├── constants/           # API endpoints, strings
│   │   ├── errors/              # Error handling (Failures, Exceptions)
│   │   ├── network/             # API client (HTTP)
│   │   ├── theme/               # App theme & colors
│   │   └── utils/               # Helper utilities (Image picker)
│   │
│   ├── data/                    # Data Layer
│   │   ├── datasources/         # Remote data sources (API calls)
│   │   ├── models/              # Data models (JSON serialization)
│   │   └── repositories/        # Repository implementations
│   │
│   ├── domain/                  # Domain Layer (Business Logic)
│   │   ├── entities/            # Business entities (Post, User, Chat)
│   │   ├── repositories/        # Repository interfaces
│   │   └── usecases/            # Use cases (Create Post, Search)
│   │
│   ├── presentation/            # Presentation Layer (UI)
│   │   ├── providers/           # State management (Provider)
│   │   ├── screens/             # App screens (Home, Search, etc.)
│   │   └── widgets/             # Reusable widgets (PostCard, etc.)
│   │
│   ├── routes/                  # App routing configuration
│   └── main.dart                # App entry point
│
├── assets/                      # Images, icons
├── test/                        # Unit & widget tests
└── pubspec.yaml                 # Dependencies
```

## ✨ Features Implemented

### ✅ Core Infrastructure

- Clean Architecture with separation of concerns
- API Client for Flask backend integration
- Error handling (Failures & Exceptions)
- Theme configuration (Colors, Fonts, Styles)
- Image picker utility

### ✅ Domain Layer

- **Entities**: Post, User, ChatMessage, SearchResult
- **Repository Interfaces**: PostRepository, ChatRepository
- **Use Cases**: CreatePost, SearchByImage, GetAllPosts

### ✅ Data Layer

- **Models**: PostModel, SearchResultModel, ChatMessageModel
- **Data Sources**: PostRemoteDataSource, ChatRemoteDataSource
- **Repository Implementations**: PostRepositoryImpl

### ✅ Presentation Layer

- **Providers**: PostProvider, SearchProvider (State Management)
- **Screens**:
  - Home Screen (Display all posts)
  - Search Screen (Search by image)
  - Placeholders for: Create Post, Post Detail, Profile, Chat
- **Widgets**:
  - PostCard (Display post with image, category, type)
  - SearchResultCard (Display search results with similarity score)

### ✅ Routing

- Navigation configuration with named routes
- Route generation for all screens

## 🛠️ Tech Stack

### Frontend (Mobile)

- **Flutter** - Cross-platform mobile framework
- **Provider** - State management
- **HTTP & Dio** - REST API calls
- **Image Picker** - Camera/Gallery image selection
- **Cached Network Image** - Efficient image loading
- **Intl** - Date formatting

### Backend (Ready for Integration)

- **Flask** (Python) - Backend API
- **Image Embedding Models** (CLIP / SigLIP / DINOv2)
- **Vector Database** (Pinecone / Qdrant)
- **Firebase Storage** - Image hosting

## 🔧 Setup & Installation

### Prerequisites

- Flutter SDK (3.10.4+)
- Dart SDK (3.10.4+)
- Android Studio / VS Code
- Android Emulator or Physical Device

### Installation Steps

1. **Clone the repository**

   ```bash
   cd C:\Losstprj\lost
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Enable Developer Mode (Windows)**

   ```bash
   start ms-settings:developers
   ```

   Enable "Developer Mode" to support symlinks for plugins.

4. **Configure Backend URL**
   Update the Flask backend URL in:

   ```dart
   lib/core/constants/api_constants.dart
   ```

   Change `baseUrl` to your Flask server address:

   ```dart
   static const String baseUrl = 'http://YOUR_FLASK_SERVER:5000/api';
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🔌 Backend Integration

### Required Flask Endpoints

The app is configured to call these endpoints:

```
POST /api/upload           - Upload image & generate embedding
POST /api/search           - Search by image (returns top-K matches)
POST /api/posts            - Create lost/found post
GET  /api/posts/{id}       - Get post by ID
GET  /api/posts            - Get all posts
POST /api/chat/start       - Start chat between users
GET  /api/chat/{chat_id}   - Get chat messages
```

### Expected JSON Response Formats

**POST /api/posts** (Create Post Response):

```json
{
  "id": "post123",
  "user_id": "user456",
  "title": "Lost Wallet",
  "description": "Black leather wallet",
  "category": "Wallet",
  "post_type": "lost",
  "image_url": "https://firebase.storage/image.jpg",
  "location": "Downtown",
  "created_at": "2025-12-14T10:30:00Z"
}
```

**POST /api/search** (Search Results):

```json
{
  "results": [
    {
      "post": {
        /* Post object */
      },
      "similarity": 0.92
    }
  ]
}
```

## 📱 Screens Overview

### 1. Home Screen

- Displays all lost & found posts
- Post cards with images, categories, and types
- Pull-to-refresh
- Navigate to Search, Profile, Create Post

### 2. Search Screen

- Upload image from camera or gallery
- Search for visually similar items
- Display results with similarity scores
- Navigate to matched post details

### 3. Coming Soon

- Create Post Screen
- Post Detail Screen
- Profile Screen
- Chat Screen

## 🎨 Design System

### Colors

- **Primary**: Purple (#6C63FF)
- **Secondary**: Pink (#FF6584)
- **Lost Badge**: Red (#E74C3C)
- **Found Badge**: Green (#2ECC71)

### Typography

- Material 3 Typography
- Consistent font sizes and weights

## 🚧 Next Steps

### Immediate Tasks

1. Share your **mobile app design** (screenshots/wireframes)
2. I'll implement remaining screens based on your design:
   - Create Post Screen (with image upload)
   - Post Detail Screen (with contact/chat button)
   - Profile Screen (user info & verification)
   - Chat Screen (real-time messaging UI)

### Backend Tasks

1. Implement Flask backend with:
   - Image upload endpoint
   - Embedding generation (CLIP/SigLIP)
   - Vector DB integration (Pinecone/Qdrant)
   - Post CRUD operations
   - Chat endpoints

### Future Enhancements

- Push notifications
- Real-time chat (WebSocket)
- User authentication & verification
- Location-based filtering
- Advanced search filters

## 📞 Support

For questions or issues, please contact your development team.

---

**Project Status**: ✅ Foundation Complete - Ready for UI Design Implementation

**Last Updated**: December 14, 2025
>>>>>>> master
