# 🚀 Complete Setup Guide

## Backend Setup (Python/Flask)

### 1. Navigate to backend folder

```bash
cd C:\Losstprj\backend
```

### 2. Create virtual environment (recommended)

```bash
python -m venv venv
venv\Scripts\activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

**Note:** First installation will download CLIP model (~350MB). This may take 5-10 minutes.

### 4. Start the server

```bash
python app.py
```

Or simply double-click `run.bat` for automatic setup!

**Server will run on:** `http://localhost:5000`

---

## Flutter App Setup

### 1. Navigate to Flutter project

```bash
cd C:\Losstprj\lost
```

### 2. Get dependencies

```bash
flutter pub get
```

### 3. Update API endpoint for your device

Open `lib/core/constants/api_endpoints.dart` and update `baseUrl`:

- **Android Emulator:** `http://10.0.2.2:5000` ✅ (default)
- **iOS Simulator:** `http://localhost:5000`
- **Real Device:** `http://YOUR_IP:5000`

To find your IP:

```bash
ipconfig
```

Look for "IPv4 Address" (e.g., 192.168.1.100)

### 4. Enable Windows Developer Mode

```
Settings → For Developers → Developer Mode (ON)
```

### 5. Run the app

```bash
flutter run
```

---

## 🎯 Testing the Complete Flow

### 1. Start Backend

```bash
cd C:\Losstprj\backend
python app.py
```

Wait for: `"Flask Backend Starting..."`

### 2. Test Backend Health

Open browser: `http://localhost:5000/api/health`

Should see:

```json
{
  "status": "ok",
  "ai_model": "CLIP ViT-B/32",
  "device": "cpu"
}
```

### 3. Run Flutter App

```bash
cd C:\Losstprj\lost
flutter run
```

### 4. Test AI Matching

1. Open app → Tap Upload button (+)
2. Fill form:
   - Title: "Black Wallet"
   - Description: "Lost my black leather wallet"
   - Category: Wallet
   - Location: "Central Park"
   - Type: Lost
   - Add an image
3. Submit!
4. Watch AI processing animation (2 seconds)
5. See matching results from backend!

---

## 📂 Project Structure

```
Losstprj/
├── backend/                    # Flask Backend
│   ├── app.py                  # Main Flask app
│   ├── requirements.txt        # Python dependencies
│   ├── run.bat                 # Windows startup script
│   ├── services/
│   │   ├── ai_service.py       # CLIP embeddings
│   │   ├── storage_service.py  # Image storage
│   │   └── vector_db_service.py # Qdrant vector DB
│   ├── temp_uploads/           # Image uploads
│   └── qdrant_data/            # Vector database (auto-created)
│
└── lost/                       # Flutter App
    ├── lib/
    │   ├── core/
    │   │   └── constants/
    │   │       └── api_endpoints.dart
    │   ├── data/
    │   │   └── datasources/
    │   │       └── ai_matching_remote_data_source.dart
    │   └── presentation/
    │       └── screens/
    │           ├── create_post_screen.dart
    │           └── ai_matching_results_screen.dart
    └── pubspec.yaml
```

---

## 🔍 How It Works

### Backend (Flask):

1. Receives image + metadata from Flutter
2. Generates 512D embedding using **CLIP**
3. Stores in **Qdrant** vector database
4. Searches for similar items (cosine similarity)
5. Returns top matches (60%+ similarity)

### Flutter App:

1. User creates post with image
2. Sends to backend via HTTP multipart request
3. Shows loading animation while processing
4. Displays AI-matched results in 3 states:
   - Loading (2 seconds)
   - Results (if matches found)
   - Empty (if no matches)

---

## 🐛 Troubleshooting

### Backend Issues

**Problem:** `ModuleNotFoundError: No module named 'clip'`

```bash
pip install git+https://github.com/openai/CLIP.git
```

**Problem:** Port 5000 in use

```python
# In app.py, change:
app.run(port=5001)
```

**Problem:** CLIP model download fails

- Check internet connection
- Download manually from: https://openaipublic.azureedge.net/clip/models/

### Flutter Issues

**Problem:** Cannot connect to backend

1. Check backend is running: `http://localhost:5000/api/health`
2. Update API endpoint in `api_endpoints.dart`
3. For real device, use computer's IP

**Problem:** `SocketException: OS Error: Connection refused`

- Check firewall settings
- Allow Python through Windows Firewall
- Use correct IP address for real device

**Problem:** Image upload fails

- Check file size < 16MB
- Check file format (jpg, png, jpeg, webp)

---

## 📊 Performance

- **Embedding Generation:** ~2s (CPU), ~0.5s (GPU)
- **Vector Search:** <100ms
- **Total Processing:** 2-3 seconds per post
- **Memory Usage:** ~1GB (CLIP model)

---

## 🎨 Features

✅ AI-powered image matching (CLIP)
✅ Real-time similarity search
✅ 512D vector embeddings
✅ Cosine similarity ranking
✅ Local vector database (Qdrant)
✅ Image upload & storage
✅ Beautiful Flutter UI
✅ Loading states & animations
✅ Error handling

---

## 🚧 Future Enhancements

- [ ] MongoDB for persistence
- [ ] User authentication (JWT)
- [ ] Firebase Storage integration
- [ ] Real GPS distance calculation
- [ ] Chat functionality
- [ ] Push notifications
- [ ] Admin dashboard

---

## 📝 Notes

- Posts are stored in memory (restart = data lost)
- First run downloads CLIP model (~350MB)
- Qdrant data stored in `./qdrant_data/` folder
- Images stored in `./temp_uploads/` folder
- Backend logs show detailed processing steps

---

## ✅ Ready to Test!

1. **Start Backend:** `cd backend && python app.py`
2. **Start Flutter:** `cd lost && flutter run`
3. **Create a post and watch the AI magic! 🎉**
