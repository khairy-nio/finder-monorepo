"""
Flask Microservice for CLIP Image Embeddings
Generates 512-dimensional embeddings using clip-ViT-B-32 model
Optimized for PythonAnywhere deployment
"""

import os
import io
import logging
import time
from typing import List

import torch
import requests
from PIL import Image
from flask import Flask, request, jsonify, abort
from flask_cors import CORS
from sentence_transformers import SentenceTransformer

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global model instance
model = None
MODEL_NAME = 'clip-ViT-B-32'
EMBEDDING_DIMENSION = 512
DOWNLOAD_TIMEOUT = 15  # seconds
MAX_BATCH_SIZE = 10

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes


def load_model():
    """Load CLIP model at startup"""
    global model
    try:
        logger.info(f"Loading CLIP model: {MODEL_NAME}")
        model = SentenceTransformer(MODEL_NAME)
        
        # Set device
        device = "cuda" if torch.cuda.is_available() else "cpu"
        model = model.to(device)
        
        logger.info(f"Model loaded successfully on device: {device}")
        logger.info(f"Embedding dimension: {EMBEDDING_DIMENSION}")
        return True
    except Exception as e:
        logger.error(f"Failed to load model: {str(e)}")
        return False


def download_image(image_url: str) -> Image.Image:
    """
    Download and preprocess image from URL
    
    Args:
        image_url: URL of the image to download
        
    Returns:
        PIL Image object in RGB format
    """
    try:
        logger.info(f"Downloading image from: {image_url}")
        
        # Download with timeout
        response = requests.get(
            image_url,
            timeout=DOWNLOAD_TIMEOUT,
            headers={'User-Agent': 'CLIP-Embedding-Service/1.0'}
        )
        response.raise_for_status()
        
        # Validate content type
        content_type = response.headers.get('content-type', '')
        if not content_type.startswith('image/'):
            raise ValueError(f"Invalid content type: {content_type}. Expected image/*")
        
        # Open and convert image
        image = Image.open(io.BytesIO(response.content))
        
        # Convert RGBA to RGB if necessary
        if image.mode == 'RGBA':
            logger.info("Converting RGBA image to RGB")
            rgb_image = Image.new('RGB', image.size, (255, 255, 255))
            rgb_image.paste(image, mask=image.split()[3])
            image = rgb_image
        elif image.mode != 'RGB':
            logger.info(f"Converting {image.mode} image to RGB")
            image = image.convert('RGB')
        
        logger.info(f"Image loaded successfully: {image.size}, mode: {image.mode}")
        return image
        
    except requests.Timeout:
        raise ValueError(f"Image download timed out after {DOWNLOAD_TIMEOUT} seconds")
    except requests.RequestException as e:
        raise ValueError(f"Failed to download image: {str(e)}")
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
        raise ValueError(f"Failed to process image: {str(e)}")


def generate_embedding(image: Image.Image) -> List[float]:
    """
    Generate embedding for a single image
    
    Args:
        image: PIL Image object
        
    Returns:
        List of floats representing the embedding vector
    """
    global model
    
    if model is None:
        raise ValueError("Model not loaded")
    
    try:
        # Generate embedding using CLIP
        with torch.no_grad():
            embedding = model.encode(image, convert_to_tensor=True)
            embedding = embedding.cpu().numpy().tolist()
        
        return embedding
        
    except Exception as e:
        logger.error(f"Error generating embedding: {str(e)}")
        raise ValueError(f"Failed to generate embedding: {str(e)}")


# Error handlers
@app.errorhandler(400)
def bad_request(error):
    return jsonify({
        'error': 'Bad Request',
        'message': str(error)
    }), 400


@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested resource was not found'
    }), 404


@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal error: {str(error)}", exc_info=True)
    return jsonify({
        'error': 'Internal Server Error',
        'message': str(error)
    }), 500


@app.errorhandler(503)
def service_unavailable(error):
    return jsonify({
        'error': 'Service Unavailable',
        'message': str(error)
    }), 503


# Routes
@app.route('/', methods=['GET'])
def root():
    """Root endpoint - basic info"""
    return jsonify({
        'service': 'CLIP Image Embedding Service',
        'status': 'online',
        'version': '1.0.0',
        'model': MODEL_NAME,
        'embedding_dimension': EMBEDDING_DIMENSION
    })


@app.route('/health', methods=['GET'])
def health_check():
    """Detailed health check endpoint"""
    global model
    
    device = "unknown"
    if model is not None:
        device = str(model.device) if hasattr(model, 'device') else "cpu"
    
    return jsonify({
        'status': 'healthy' if model is not None else 'unhealthy',
        'model_loaded': model is not None,
        'model_name': MODEL_NAME,
        'embedding_dimension': EMBEDDING_DIMENSION,
        'device': device,
        'timestamp': time.time()
    })


@app.route('/embed', methods=['POST'])
def embed_image():
    """
    Generate embedding for a single image
    
    Request body:
        {
            "image_url": "https://example.com/image.jpg"
        }
    
    Returns:
        {
            "embedding": [0.123, -0.456, ...],
            "dimension": 512,
            "model": "clip-ViT-B-32",
            "processing_time": 1.234
        }
    """
    start_time = time.time()
    
    try:
        # Get request data
        data = request.get_json()
        if not data or 'image_url' not in data:
            return jsonify({
                'error': 'Missing image_url in request body'
            }), 400
        
        image_url = data['image_url']
        
        # Validate URL
        if not image_url.startswith(('http://', 'https://')):
            return jsonify({
                'error': 'Image URL must start with http:// or https://'
            }), 400
        
        # Download and preprocess image
        image = download_image(image_url)
        
        # Generate embedding
        embedding = generate_embedding(image)
        
        # Calculate processing time
        processing_time = time.time() - start_time
        
        logger.info(f"Embedding generated in {processing_time:.2f}s")
        
        return jsonify({
            'embedding': embedding,
            'dimension': len(embedding),
            'model': MODEL_NAME,
            'processing_time': processing_time
        })
        
    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        return jsonify({
            'error': str(e)
        }), 400
    except Exception as e:
        logger.error(f"Error in embed_image: {str(e)}")
        return jsonify({
            'error': 'Internal server error',
            'message': str(e)
        }), 500


@app.route('/embed/batch', methods=['POST'])
def embed_images_batch():
    """
    Generate embeddings for multiple images
    
    Request body:
        {
            "image_urls": [
                "https://example.com/image1.jpg",
                "https://example.com/image2.jpg"
            ]
        }
    
    Returns:
        {
            "embeddings": [
                {
                    "image_url": "...",
                    "embedding": [...],
                    "dimension": 512,
                    "success": true
                },
                ...
            ],
            "total": 2,
            "successful": 2,
            "failed": 0,
            "processing_time": 2.456
        }
    """
    start_time = time.time()
    
    try:
        # Get request data
        data = request.get_json()
        if not data or 'image_urls' not in data:
            return jsonify({
                'error': 'Missing image_urls in request body'
            }), 400
        
        image_urls = data['image_urls']
        
        # Validate batch
        if not isinstance(image_urls, list) or len(image_urls) == 0:
            return jsonify({
                'error': 'image_urls must be a non-empty array'
            }), 400
        
        if len(image_urls) > MAX_BATCH_SIZE:
            return jsonify({
                'error': f'Maximum batch size is {MAX_BATCH_SIZE} images'
            }), 400
        
        # Process each image
        results = []
        successful = 0
        failed = 0
        
        for image_url in image_urls:
            try:
                # Download and process image
                image = download_image(image_url)
                embedding = generate_embedding(image)
                
                results.append({
                    'image_url': image_url,
                    'embedding': embedding,
                    'dimension': len(embedding),
                    'success': True,
                    'error': None
                })
                successful += 1
                
            except Exception as e:
                logger.error(f"Failed to process {image_url}: {str(e)}")
                results.append({
                    'image_url': image_url,
                    'embedding': None,
                    'dimension': EMBEDDING_DIMENSION,
                    'success': False,
                    'error': str(e)
                })
                failed += 1
        
        # Calculate processing time
        processing_time = time.time() - start_time
        
        logger.info(f"Batch processing complete: {successful} successful, {failed} failed in {processing_time:.2f}s")
        
        return jsonify({
            'embeddings': results,
            'total': len(image_urls),
            'successful': successful,
            'failed': failed,
            'processing_time': processing_time
        })
        
    except Exception as e:
        logger.error(f"Error in embed_images_batch: {str(e)}")
        return jsonify({
            'error': 'Internal server error',
            'message': str(e)
        }), 500


if __name__ == '__main__':
    # For local development
    port = int(os.environ.get('PORT', 8000))
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    # Load model at startup
    logger.info("Starting CLIP Embedding Service")
    success = load_model()
    if not success:
        logger.error("Failed to load model during startup")
    
    logger.info(f"Starting server on port {port}")
    app.run(host='0.0.0.0', port=port, debug=debug)
else:
    # For WSGI servers (PythonAnywhere, Gunicorn, etc.)
    # Load model when imported
    logger.info("Starting CLIP Embedding Service")
    load_model()
