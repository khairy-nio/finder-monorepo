# Flask CLIP Embedding Service - PythonAnywhere Deployment

Flask version of the CLIP image embedding microservice, optimized for PythonAnywhere deployment.

## Changes from FastAPI to Flask

✅ **Converted FastAPI to Flask**
- Replaced FastAPI routes with Flask `@app.route()`
- Replaced Pydantic models with `request.get_json()`
- Replaced HTTPException with Flask error handlers
- Replaced CORS middleware with `flask-cors`
- Removed async/await (Flask uses synchronous code)
- Simplified startup with `@app.before_first_request`

## Files

- **main_flask.py** - Flask application (use this for PythonAnywhere)
- **requirements_flask.txt** - Flask dependencies

## Local Testing

```bash
# Install Flask dependencies
pip install -r requirements_flask.txt

# Run Flask app
python main_flask.py
```

Service runs on: http://localhost:8000

## Deploy to PythonAnywhere

### Step 1: Create PythonAnywhere Account
1. Go to: https://www.pythonanywhere.com/
2. Sign up for free account (or paid)
3. Free tier includes: 512 MB RAM, 1 GB disk

### Step 2: Upload Your Code

**Option A: Via Git**
```bash
# In PythonAnywhere Bash console:
git clone https://github.com/YOUR_USERNAME/clip-embedding-service.git
cd clip-embedding-service/ai_service
```

**Option B: Via Files Tab**
1. Go to "Files" tab
2. Create directory: `/home/YOUR_USERNAME/ai_service`
3. Upload `main_flask.py` and `requirements_flask.txt`

### Step 3: Create Virtual Environment

In PythonAnywhere Bash console:
```bash
cd /home/YOUR_USERNAME/ai_service
python3.10 -m venv venv
source venv/bin/activate
pip install -r requirements_flask.txt
```

**Note**: This will take 5-10 minutes to download CLIP model (~600MB)

### Step 4: Configure Web App

1. Go to "Web" tab
2. Click "Add a new web app"
3. Choose "Manual configuration"
4. Select Python 3.10

5. **Set WSGI file** (click on WSGI configuration file link):
```python
import sys
import os

# Add your project directory to the sys.path
project_home = '/home/YOUR_USERNAME/ai_service'
if project_home not in sys.path:
    sys.path.insert(0, project_home)

# Activate virtualenv
activate_this = os.path.join(project_home, 'venv/bin/activate_this.py')
with open(activate_this) as file_:
    exec(file_.read(), dict(__file__=activate_this))

# Import Flask app
from main_flask import app as application
```

6. **Set Virtual Environment**:
   - In "Web" tab, find "Virtualenv" section
   - Enter: `/home/YOUR_USERNAME/ai_service/venv`

7. **Reload Web App**:
   - Click green "Reload" button

### Step 5: Test Your Deployment

Your service will be available at:
```
https://YOUR_USERNAME.pythonanywhere.com
```

Test endpoints:
```bash
# Health check
curl https://YOUR_USERNAME.pythonanywhere.com/health

# Generate embedding
curl -X POST https://YOUR_USERNAME.pythonanywhere.com/embed \
  -H "Content-Type: application/json" \
  -d '{"image_url": "https://images.unsplash.com/photo-1506905925346-21bda4d32df4"}'
```

## API Endpoints (Same as FastAPI)

### GET /
Service information

### GET /health
Health check with model status

### POST /embed
Generate single image embedding
```json
{
  "image_url": "https://example.com/image.jpg"
}
```

### POST /embed/batch
Generate batch embeddings (max 10)
```json
{
  "image_urls": [
    "https://example.com/image1.jpg",
    "https://example.com/image2.jpg"
  ]
}
```

## PythonAnywhere Limitations

⚠️ **Free Tier Constraints:**
- 512 MB RAM (CLIP model uses ~800MB - may not work on free tier)
- Consider paid "Hacker" plan ($5/month) with 1.5 GB RAM
- No CUDA/GPU support (uses CPU only)
- Slower response times than Railway/ngrok

💰 **Recommended Plan:**
- **Hacker**: $5/month, 1.5 GB RAM ✅ (Works for CLIP)
- **Developer**: $12/month, 3 GB RAM (Better performance)

## Troubleshooting

**Model won't load / Out of memory:**
- Upgrade to Hacker plan ($5/month) for more RAM
- CLIP model needs ~800MB-1GB RAM minimum

**500 Internal Server Error:**
- Check error logs in PythonAnywhere "Web" tab → "Error log"
- Verify virtual environment path is correct
- Ensure all dependencies installed

**Slow responses:**
- Normal on PythonAnywhere (CPU only, shared hosting)
- First request takes longer (model loading)
- Consider caching embeddings

## Update Your Node.js Config

```javascript
const AIService = require('./config/ai.config');
const ai = new AIService('https://YOUR_USERNAME.pythonanywhere.com');

// Use as normal
const result = await ai.generateEmbedding('https://example.com/image.jpg');
```

## Cost Comparison

| Platform | Free Tier | Paid | Performance |
|----------|-----------|------|-------------|
| **PythonAnywhere** | 512MB ❌ | $5/mo (1.5GB) ✅ | Slow (CPU, shared) |
| **Railway** | None | $5-20/mo | Fast (dedicated) |
| **ngrok** | Free ✅ | $8/mo (static URL) | Fast (local) |

## Advantages of Flask for PythonAnywhere

✅ Simpler WSGI deployment
✅ No async complexity
✅ Better Python 3.10 compatibility
✅ Standard PythonAnywhere workflow
✅ Easier debugging

## Next Steps

1. Test Flask app locally
2. Sign up for PythonAnywhere
3. Upload code and install dependencies
4. Configure WSGI file
5. Test deployment
6. Update Node.js backend with new URL

Your Flask service is ready to deploy! 🚀
