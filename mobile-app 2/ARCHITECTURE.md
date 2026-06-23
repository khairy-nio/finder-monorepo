# Lost & Found App - Architecture Overview

## 🏗️ Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │  Providers  │  │   Screens    │  │     Widgets      │   │
│  │  (State)    │  │   (UI)       │  │   (Components)   │   │
│  └─────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Entities   │  │  Use Cases   │  │  Repositories    │  │
│  │  (Business)  │  │   (Logic)    │  │  (Interfaces)    │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                        DATA LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │    Models    │  │ Data Sources │  │  Repositories    │  │
│  │   (JSON)     │  │  (API/Cache) │  │(Implementation)  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                        CORE LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  API Client  │  │    Theme     │  │     Utils        │  │
│  │  Constants   │  │    Errors    │  │   (Helpers)      │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │Flask Backend │  │   Firebase   │  │  Vector DB       │  │
│  │  (REST API)  │  │   Storage    │  │(Pinecone/Qdrant) │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Data Flow

### 1. Creating a Post

```
User (UI)
   ↓
[Create Post Screen]
   ↓
[PostProvider] → [CreatePostUseCase]
   ↓
[PostRepository Interface]
   ↓
[PostRepositoryImpl]
   ↓
[PostRemoteDataSource]
   ↓
[ApiClient] → Flask Backend → Firebase Storage → Vector DB
```

### 2. Searching by Image

```
User uploads image
   ↓
[Search Screen]
   ↓
[SearchProvider] → [SearchByImageUseCase]
   ↓
[PostRepository Interface]
   ↓
[PostRepositoryImpl]
   ↓
[PostRemoteDataSource]
   ↓
[ApiClient] → Flask Backend (generates embedding)
   ↓
Vector DB (cosine similarity search)
   ↓
Returns top-K matches with similarity scores
   ↓
Display [SearchResultCard] with match percentage
```

### 3. Viewing Posts

```
User opens app
   ↓
[Home Screen] → initState()
   ↓
[PostProvider] → [GetAllPostsUseCase]
   ↓
[PostRepository Interface]
   ↓
[PostRepositoryImpl]
   ↓
[PostRemoteDataSource]
   ↓
[ApiClient] → Flask Backend → Database
   ↓
Returns List<Post>
   ↓
Display [PostCard] widgets
```

## 🔄 State Management Flow (Provider)

```
[UI Widget]
   ↓
Consumer<Provider>
   ↓
Provider.method() → calls UseCase
   ↓
Updates internal state (_posts, _isLoading, etc.)
   ↓
notifyListeners()
   ↓
UI rebuilds automatically
```

## 🎯 Dependency Injection

All dependencies are initialized in `main.dart`:

```dart
ApiClient → PostRemoteDataSource → PostRepository
                                         ↓
                          PostProvider ← Use Cases
```

## 🔐 Error Handling

```
API Call
   ↓
Try-Catch in DataSource
   ↓
Throws Exception (ServerException, NetworkException)
   ↓
Repository catches and converts to Failure
   ↓
Returns Either<Failure, Success>
   ↓
Provider handles Failure
   ↓
UI shows error message
```

## 🌐 Backend Integration Points

### Flask Backend Responsibilities:

1. **Image Upload** → Store in Firebase → Return URL
2. **Embedding Generation** → Use CLIP/SigLIP model
3. **Vector Storage** → Store in Pinecone/Qdrant with metadata
4. **Search** → Query vector DB with cosine similarity
5. **CRUD Operations** → Manage posts in traditional DB (MongoDB/PostgreSQL)
6. **Chat** → Store and retrieve messages

### Mobile App Responsibilities:

1. **UI/UX** → All screens and user interactions
2. **Image Capture** → Camera/Gallery selection
3. **API Calls** → HTTP requests to backend
4. **State Management** → Provider pattern
5. **Navigation** → Route management
6. **Local Caching** (Future) → Cache images/data

## 📱 Screen Flow

```
[Splash/Welcome] (Future)
        ↓
[Login/Register] (Future)
        ↓
[Home Screen] ←→ [Search Screen]
     ↓ ↑              ↓
[Post Detail]    [Search Results]
     ↓                ↓
[Chat Screen] ←──────┘
```

## 🎨 UI Components Hierarchy

```
HomeScreen
├── AppBar
│   ├── Title
│   ├── Search Icon → Navigate to SearchScreen
│   └── Profile Icon → Navigate to ProfileScreen
├── Body (ListView)
│   └── PostCard (for each post)
│       ├── Image (CachedNetworkImage)
│       ├── Post Type Badge (Lost/Found)
│       ├── Category Chip
│       ├── Title & Description
│       └── Location & Date
└── FloatingActionButton → Navigate to CreatePostScreen

SearchScreen
├── AppBar
├── ImageSelector Card
│   ├── Image Preview
│   ├── Camera Button
│   └── Gallery Button
├── Search Button
└── Results List
    └── SearchResultCard (for each result)
        ├── Thumbnail
        ├── Similarity Badge (% match)
        ├── Title
        └── Post Type & Category
```

## 🚀 Next Implementation Steps

1. **Share your design** → I'll match the exact UI
2. **Create Post Screen** → Form with image upload
3. **Post Detail Screen** → Full post view + contact button
4. **Profile Screen** → User info + verification
5. **Chat Screen** → Real-time messaging UI
6. **Authentication** → Login/Register screens
7. **Backend Setup** → Flask API implementation

---

**Architecture Status**: ✅ Complete & Ready for Design Implementation
