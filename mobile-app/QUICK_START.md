# 🎯 Quick Start Guide

## Start Backend (Terminal 1)

```bash
cd C:\Losstprj\backend
python app.py
```

✅ Server: http://localhost:5000

## Start Flutter App (Terminal 2)

```bash
cd C:\Losstprj\lost
flutter run
```

## Test Flow

1. Open app → Tap **+** button
2. Add image + details
3. Submit
4. Watch AI processing
5. See results! 🎉

## Check Backend Health

http://localhost:5000/api/health

## Common Issues

**Backend won't start?**

```bash
pip install -r requirements.txt
```

**Flutter can't connect?**

- Check backend is running
- Update IP in `api_endpoints.dart`
- For Android Emulator: `http://10.0.2.2:5000`
- For Real Device: `http://YOUR_IP:5000`

**Find your IP:**

```bash
ipconfig
```

---

## 📁 Key Files

### Backend

- `backend/app.py` - Main Flask server
- `backend/services/ai_service.py` - CLIP AI model
- `backend/services/vector_db_service.py` - Qdrant search

### Flutter

- `lib/presentation/screens/create_post_screen.dart` - Create post
- `lib/presentation/screens/ai_matching_results_screen.dart` - Show results
- `lib/data/datasources/ai_matching_remote_data_source.dart` - API calls
- `lib/core/constants/api_endpoints.dart` - Backend URL

---

## 🎨 Architecture

```
Flutter App (Dart)
    ↓ HTTP POST (multipart/form-data)
Flask Backend (Python)
    ↓ Image Processing
CLIP Model (AI)
    ↓ 512D Vector
Qdrant (Vector DB)
    ↓ Similarity Search
Flask Backend (Python)
    ↓ JSON Response
Flutter App (Dart)
```

---

## ✨ Features Working

✅ Image upload from Flutter
✅ CLIP embedding generation
✅ Vector similarity search
✅ Matching results display
✅ Loading animations
✅ Error handling
✅ Beautiful brown theme UI

Ready to test! 🚀
