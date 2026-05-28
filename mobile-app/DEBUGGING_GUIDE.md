# 🐛 Debugging Guide - Find Matches Button Issue

## Problem: "Find Matches" button shows loading but doesn't send request to backend

---

## ✅ Step 1: Start Backend

```bash
cd C:\Losstprj\backend
python app.py
```

**Expected output:**

```
==========================================
🚀 Lost & Found AI Backend
==========================================
📍 Server: http://localhost:5000
🤖 AI Model: CLIP ViT-B/32
💻 Device: cpu
🗄️  Vector DB: Qdrant (local)
==========================================

✅ CLIP model loaded on cpu
✅ Qdrant Vector DB initialized
 * Running on http://127.0.0.1:5000
```

**Test it works:**
Open browser: http://localhost:5000/api/health

Should show:

```json
{
  "status": "ok",
  "ai_model": "CLIP ViT-B/32",
  "device": "cpu",
  "vector_db": "Qdrant (local)",
  "total_posts": 0
}
```

---

## ✅ Step 2: Run Flutter App

```bash
cd C:\Losstprj\lost
flutter run
```

**Watch for logs:**

- ✅ "Running Gradle task 'assembleDebug'..."
- ✅ "Built build\app\outputs\flutter-apk\app-debug.apk"
- ✅ App launches on emulator

---

## ✅ Step 3: Test the Flow

### In the Flutter App:

1. **Skip Login** (tap anywhere to bypass)
2. **Tap + button** (bottom navigation - Upload)
3. **Fill the form:**
   - Tap "Add Photo" → Select from Gallery
   - Choose any image (wallet, phone, keys, etc.)
   - Title: `Test Wallet`
   - Description: `Testing AI matching`
   - Category: `Wallet`
   - Type: `Lost`
   - Location: Tap map → Select location
4. **Tap "Find Matches with AI"**

---

## 🔍 What to Look For

### In Flutter Debug Console (VS Code/Android Studio):

```
📤 Submitting post to backend...
   Title: Test Wallet
   Type: lost
   Category: Wallet
🌐 API URL: http://10.0.2.2:5000/api/posts/create-with-matching
📷 Adding image file: /data/user/0/.../image_123.jpg
📤 Sending request to backend...
📥 Received response, status: 201
✅ Success! Response body: {"post_id": "...", "matches_count": 0, ...}
✅ Backend response received: {...}
```

### In Backend Terminal:

```
================================================================
📥 Received new post creation request
================================================================
📝 Post Details:
   - Title: Test Wallet
   - Type: lost
   - Category: Wallet
   - Location: Central Park, NY

💾 Saved temporary file: temp_uploads/uuid_image.jpg
🤖 Generating AI embedding using CLIP...
✅ Embedding generated successfully (512 dimensions)
☁️ Uploading image to storage...
✅ Image uploaded: http://localhost:5000/uploads/uuid_image.jpg
💾 Post saved to database with ID: abc-123
🔍 Storing embedding in vector database...
✅ Embedding stored in vector DB (point_id: abc-123)
🔎 Searching for similar items (type: found)...
✨ Found 0 matches above 60% threshold
================================================================
```

---

## ❌ Common Issues & Solutions

### Issue 1: Connection Refused / No Internet

**Symptom:**

```
❌ Error submitting post: SocketException: Failed to connect to /10.0.2.2:5000
```

**Solution:**

- Check backend is running: http://localhost:5000/api/health
- Restart backend: `Ctrl+C` then `python app.py`
- Check Windows Firewall isn't blocking port 5000

---

### Issue 2: Timeout

**Symptom:**

```
❌ Error submitting post: TimeoutException: Request timeout. Please try again.
```

**Solution:**

- Backend is slow (CPU processing ~2-5 seconds)
- Wait longer or increase timeout in `ai_matching_remote_data_source.dart`
- Check backend logs for errors

---

### Issue 3: No Logs Appear

**Symptom:**

- Button shows loading
- No logs in console
- Nothing happens

**Solution:**

```bash
# Hot reload Flutter app
Press 'r' in terminal where flutter run is active

# Or hot restart
Press 'R' in terminal

# Or full restart
Press 'q' to quit, then run again:
flutter run
```

---

### Issue 4: Image Upload Fails

**Symptom:**

```
❌ Error: Failed to create post
```

**Backend might show:**

```
400 Bad Request: No file part
```

**Solution:**

- Make sure you selected an image
- Check image file format (should be JPG, PNG, JPEG, WEBP)
- Check file size (max 16MB)

---

### Issue 5: Backend Not Receiving Request

**Symptom:**

- Flutter logs show request sent
- Backend logs show nothing

**Solution:**

1. **Check API URL:**

```dart
// In api_endpoints.dart
static const String baseUrl = 'http://10.0.2.2:5000'; // Android Emulator

// If using iOS Simulator, change to:
static const String baseUrl = 'http://localhost:5000';

// If using real device, use your PC's IP:
static const String baseUrl = 'http://192.168.1.100:5000';
```

2. **Find your PC's IP:**

```bash
# Windows
ipconfig

# Look for IPv4 Address:
# IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

3. **Update and hot restart:**

```bash
# In Flutter terminal
Press 'R' for hot restart
```

---

## 🧪 Test with Simple Request First

### Test Backend Directly (Postman or Python):

```python
# test_backend.py
import requests

# Test health
response = requests.get('http://localhost:5000/api/health')
print("Health check:", response.json())

# Test with dummy image
files = {'image': open('test_image.jpg', 'rb')}
data = {
    'title': 'Test Post',
    'description': 'Testing',
    'category': 'Wallet',
    'location': 'NYC',
    'type': 'lost'
}

response = requests.post(
    'http://localhost:5000/api/posts/create-with-matching',
    files=files,
    data=data
)

print("Create post:", response.status_code)
print(response.json())
```

---

## 📊 Checklist Before Testing

- [ ] Backend running: `python app.py`
- [ ] Health check works: http://localhost:5000/api/health
- [ ] Flutter app running: `flutter run`
- [ ] Emulator/device connected
- [ ] Selected an image
- [ ] Filled all required fields
- [ ] Console logs visible

---

## 🎯 Expected Results

### First Post (Database Empty):

```
Backend: ✅ Created post, 0 matches
Flutter: Shows "No similar items found" screen
```

### Second Similar Post (Opposite Type):

```
Backend: ✅ Created post, 1 match (95% similarity)
Flutter: Shows "AI Analysis Results" with 1 match card
```

---

## 💡 Still Not Working?

### Enable Verbose Logging:

**Backend (app.py):**

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Flutter (main.dart):**

```dart
void main() {
  debugPrint('🚀 App starting...');
  runApp(MyApp());
}
```

### Check Network Permission:

**AndroidManifest.xml:**

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

Should already be there in: `android/app/src/main/AndroidManifest.xml`

---

## 🆘 Last Resort

1. **Clean and rebuild:**

```bash
cd C:\Losstprj\lost
flutter clean
flutter pub get
flutter run
```

2. **Restart everything:**

- Kill backend: `Ctrl+C`
- Kill Flutter: `q` in terminal
- Close emulator
- Start fresh:
  ```bash
  python app.py  # Terminal 1
  flutter run    # Terminal 2
  ```

3. **Check ports:**

```bash
# Windows
netstat -ano | findstr :5000

# Should show:
# TCP    0.0.0.0:5000    0.0.0.0:0    LISTENING    12345
```

---

## ✅ Success Indicators

**You know it's working when:**

- ✅ Backend logs show "📥 Received new post creation request"
- ✅ Backend shows "✅ Embedding generated successfully"
- ✅ Flutter logs show "✅ Backend response received"
- ✅ Flutter navigates to results screen (2 second loading animation)
- ✅ Results screen shows either matches or "No matches found"

---

## 📞 Need More Help?

Check these files for the implementation:

- Backend: `backend/app.py` (line 46: `/api/posts/create-with-matching`)
- Flutter API: `lib/data/datasources/ai_matching_remote_data_source.dart`
- Flutter Screen: `lib/presentation/screens/create_post_screen.dart` (line 179: `_submitPost()`)
- API Config: `lib/core/constants/api_endpoints.dart`
