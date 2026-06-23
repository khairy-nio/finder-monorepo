FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the Flask application
COPY main_flask.py .

# Expose port
EXPOSE 7860

# Set environment variables for HuggingFace
ENV PORT=7860
ENV HOST=0.0.0.0

# Pre-download the model during the build phase so it starts instantly
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('clip-ViT-B-32')"

# Start the Flask app using Gunicorn for production
RUN pip install gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:7860", "main_flask:app", "--timeout", "120", "--workers", "1"]
