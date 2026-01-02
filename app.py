from flask import Flask, render_template, Response, send_file, request, jsonify
import os
import requests
import mimetypes
from urllib.parse import urlparse, parse_qs
import re

app = Flask(__name__)

# Configure upload folder for videos
UPLOAD_FOLDER = 'static/videos'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024  # 500MB max file size

# Ensure the upload folder exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Supported video MIME types
SUPPORTED_VIDEO_TYPES = {
    'video/mp4',
    'video/webm',
    'video/ogg',
    'video/quicktime',
    'video/x-msvideo',
    'video/x-matroska'
}

# Supported video extensions
SUPPORTED_VIDEO_EXTENSIONS = {'.mp4', '.webm', '.ogg', '.mov', '.avi', '.mkv'}

def extract_google_drive_id(url):
    """
    Extract the file ID from various Google Drive URL formats
    """
    # Pattern 1: https://drive.google.com/file/d/FILE_ID/view
    match = re.search(r'/file/d/([a-zA-Z0-9_-]+)', url)
    if match:
        return match.group(1)
    
    # Pattern 2: https://drive.google.com/open?id=FILE_ID
    match = re.search(r'[?&]id=([a-zA-Z0-9_-]+)', url)
    if match:
        return match.group(1)
    
    # Pattern 3: https://drive.google.com/uc?id=FILE_ID
    parsed = urlparse(url)
    if 'drive.google.com' in parsed.netloc:
        query_params = parse_qs(parsed.query)
        if 'id' in query_params:
            return query_params['id'][0]
    
    return None

def get_google_drive_download_url(file_id):
    """
    Generate direct download URL for Google Drive file
    """
    return f"https://drive.google.com/uc?export=download&id={file_id}"

def is_video_file(content_type, filename):
    """
    Check if the file is a video based on content type and extension
    """
    # Check MIME type
    if content_type and any(video_type in content_type.lower() for video_type in SUPPORTED_VIDEO_TYPES):
        return True
    
    # Check file extension as fallback
    if filename:
        ext = os.path.splitext(filename.lower())[1]
        if ext in SUPPORTED_VIDEO_EXTENSIONS:
            return True
    
    return False

def get_cached_filename(file_id, original_filename=None):
    """
    Generate a cached filename using the original filename
    Returns tuple: (cached_filename, metadata_filename)
    """
    if original_filename:
        # Use the original filename
        base_name = os.path.basename(original_filename)
        cached_filename = base_name
    else:
        # Fallback if no filename detected
        cached_filename = f"{file_id}.mp4"
    
    # Create metadata filename to track Google Drive files
    metadata_filename = f".gdrive_meta_{file_id}.json"
    
    return cached_filename, metadata_filename

def save_gdrive_metadata(file_id, filename, original_url, file_size):
    """
    Save metadata about Google Drive downloaded files
    """
    import json
    from datetime import datetime
    
    metadata_filename = f".gdrive_meta_{file_id}.json"
    metadata_path = os.path.join(UPLOAD_FOLDER, metadata_filename)
    
    metadata = {
        'file_id': file_id,
        'filename': filename,
        'original_url': original_url,
        'file_size_bytes': file_size,
        'download_date': datetime.now().isoformat(),
        'source': 'google_drive'
    }
    
    with open(metadata_path, 'w') as f:
        json.dump(metadata, f, indent=2)

def is_gdrive_file(filename):
    """
    Check if a file was downloaded from Google Drive by looking for metadata
    """
    import json
    
    # Look for metadata files
    metadata_files = [f for f in os.listdir(UPLOAD_FOLDER) if f.startswith('.gdrive_meta_') and f.endswith('.json')]
    
    for meta_file in metadata_files:
        try:
            with open(os.path.join(UPLOAD_FOLDER, meta_file), 'r') as f:
                metadata = json.load(f)
                if metadata.get('filename') == filename:
                    return True
        except:
            continue
    
    return False

def get_gdrive_file_id_by_filename(filename):
    """
    Get the Google Drive file ID for a given filename
    """
    import json
    
    metadata_files = [f for f in os.listdir(UPLOAD_FOLDER) if f.startswith('.gdrive_meta_') and f.endswith('.json')]
    
    for meta_file in metadata_files:
        try:
            with open(os.path.join(UPLOAD_FOLDER, meta_file), 'r') as f:
                metadata = json.load(f)
                if metadata.get('filename') == filename:
                    return metadata.get('file_id')
        except:
            continue
    
    return None

@app.route('/')
def index():
    """
    Main route that renders the video player page
    """
    # Get list of available videos
    videos = []
    if os.path.exists(UPLOAD_FOLDER):
        videos = [f for f in os.listdir(UPLOAD_FOLDER) if f.endswith(('.mp4', '.webm', '.ogg', '.mov', '.avi', '.mkv'))]
    
    return render_template('index.html', videos=videos)

@app.route('/api/download-gdrive', methods=['POST'])
def download_from_gdrive():
    """
    Endpoint to download a video from Google Drive shareable link
    Validates that the file is a video and caches it locally
    """
    try:
        # Get the Google Drive URL from request
        data = request.get_json()
        if not data or 'url' not in data:
            return jsonify({
                'error': 'Missing URL parameter',
                'message': 'Please provide a Google Drive shareable link'
            }), 400
        
        gdrive_url = data['url']
        
        # Extract file ID from Google Drive URL
        file_id = extract_google_drive_id(gdrive_url)
        if not file_id:
            return jsonify({
                'error': 'Invalid Google Drive URL',
                'message': 'Could not extract file ID from the provided URL'
            }), 400
        
        # Check if file is already cached by looking for metadata
        import json
        metadata_filename = f".gdrive_meta_{file_id}.json"
        metadata_path = os.path.join(UPLOAD_FOLDER, metadata_filename)
        
        if os.path.exists(metadata_path):
            with open(metadata_path, 'r') as f:
                metadata = json.load(f)
                cached_filename = metadata.get('filename')
                
                # Verify the actual video file still exists
                if os.path.exists(os.path.join(UPLOAD_FOLDER, cached_filename)):
                    return jsonify({
                        'success': True,
                        'message': 'Video already cached',
                        'filename': cached_filename,
                        'cached': True
                    }), 200
        
        # Get download URL
        download_url = get_google_drive_download_url(file_id)
        
        # Start downloading with streaming
        response = requests.get(download_url, stream=True, allow_redirects=True)
        
        # Check if download was successful
        if response.status_code != 200:
            return jsonify({
                'error': 'Download failed',
                'message': f'Could not download file from Google Drive. Status code: {response.status_code}',
                'hint': 'Make sure the file is publicly accessible or has link sharing enabled'
            }), 400
        
        # Get content type and filename
        content_type = response.headers.get('Content-Type', '')
        content_disposition = response.headers.get('Content-Disposition', '')
        
        # Try to extract filename from Content-Disposition header
        original_filename = None
        if content_disposition:
            filename_match = re.search(r'filename="?([^"]+)"?', content_disposition)
            if filename_match:
                original_filename = filename_match.group(1)
        
        # If no filename from headers, create a default one
        if not original_filename:
            # Try to guess extension from content type
            ext = '.mp4'  # default
            if 'webm' in content_type:
                ext = '.webm'
            elif 'ogg' in content_type:
                ext = '.ogg'
            elif 'quicktime' in content_type:
                ext = '.mov'
            
            original_filename = f"video_{file_id}{ext}"
        
        # Validate that it's a video file
        if not is_video_file(content_type, original_filename):
            return jsonify({
                'error': 'Invalid file type',
                'message': 'The file is not a supported video format',
                'detected_type': content_type,
                'supported_types': list(SUPPORTED_VIDEO_TYPES),
                'supported_extensions': list(SUPPORTED_VIDEO_EXTENSIONS)
            }), 400
        
        # Generate cached filename (using original name)
        cached_filename, metadata_file = get_cached_filename(file_id, original_filename)
        
        # Handle filename conflicts
        base_name, ext = os.path.splitext(cached_filename)
        counter = 1
        final_filename = cached_filename
        while os.path.exists(os.path.join(UPLOAD_FOLDER, final_filename)):
            # Check if this file is from the same Google Drive file
            existing_file_id = get_gdrive_file_id_by_filename(final_filename)
            if existing_file_id == file_id:
                # Same file, already cached
                return jsonify({
                    'success': True,
                    'message': 'Video already cached',
                    'filename': final_filename,
                    'cached': True
                }), 200
            # Different file with same name, append counter
            final_filename = f"{base_name}_{counter}{ext}"
            counter += 1
        
        cache_path = os.path.join(UPLOAD_FOLDER, final_filename)
        
        # Download and save the file
        total_size = int(response.headers.get('Content-Length', 0))
        downloaded_size = 0
        
        with open(cache_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
                    downloaded_size += len(chunk)
        
        # Verify the downloaded file
        if not os.path.exists(cache_path):
            return jsonify({
                'error': 'Download failed',
                'message': 'File was not saved successfully'
            }), 500
        
        file_size = os.path.getsize(cache_path)
        file_size_mb = file_size / (1024 * 1024)
        
        # Save metadata
        save_gdrive_metadata(file_id, final_filename, gdrive_url, file_size)
        
        return jsonify({
            'success': True,
            'message': 'Video downloaded and cached successfully',
            'filename': final_filename,
            'file_id': file_id,
            'size_mb': round(file_size_mb, 2),
            'cached': False
        }), 200
        
    except requests.exceptions.RequestException as e:
        return jsonify({
            'error': 'Network error',
            'message': f'Failed to download file: {str(e)}'
        }), 500
    
    except Exception as e:
        return jsonify({
            'error': 'Server error',
            'message': f'An unexpected error occurred: {str(e)}'
        }), 500

@app.route('/api/cached-videos', methods=['GET'])
def get_cached_videos():
    """
    Get list of all cached videos
    """
    try:
        videos = []
        if os.path.exists(UPLOAD_FOLDER):
            for filename in os.listdir(UPLOAD_FOLDER):
                # Skip metadata files
                if filename.startswith('.gdrive_meta_'):
                    continue
                    
                if filename.endswith(('.mp4', '.webm', '.ogg', '.mov', '.avi', '.mkv')):
                    file_path = os.path.join(UPLOAD_FOLDER, filename)
                    file_size = os.path.getsize(file_path) / (1024 * 1024)  # MB
                    
                    # Check if it's from Google Drive
                    is_from_gdrive = is_gdrive_file(filename)
                    
                    videos.append({
                        'filename': filename,
                        'size_mb': round(file_size, 2),
                        'is_gdrive_cached': is_from_gdrive
                    })
        
        return jsonify({
            'success': True,
            'count': len(videos),
            'videos': videos
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': 'Server error',
            'message': str(e)
        }), 500

@app.route('/api/delete-video/<filename>', methods=['DELETE'])
def delete_video(filename):
    """
    Delete a cached video file and its metadata if it exists
    """
    try:
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        
        if not os.path.exists(file_path):
            return jsonify({
                'error': 'File not found',
                'message': f'Video {filename} does not exist'
            }), 404
        
        # Delete the video file
        os.remove(file_path)
        
        # Check if there's associated Google Drive metadata and delete it
        file_id = get_gdrive_file_id_by_filename(filename)
        if file_id:
            metadata_filename = f".gdrive_meta_{file_id}.json"
            metadata_path = os.path.join(app.config['UPLOAD_FOLDER'], metadata_filename)
            if os.path.exists(metadata_path):
                os.remove(metadata_path)
        
        return jsonify({
            'success': True,
            'message': f'Video {filename} deleted successfully'
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': 'Server error',
            'message': str(e)
        }), 500

@app.route('/video/<filename>')
def video(filename):
    """
    Route to serve video files with proper streaming support
    """
    video_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    
    if not os.path.exists(video_path):
        return "Video not found", 404
    
    return send_file(video_path, mimetype='video/mp4')

@app.route('/stream/<filename>')
def stream_video(filename):
    """
    Advanced streaming route with range request support for seeking
    """
    video_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    
    if not os.path.exists(video_path):
        return "Video not found", 404
    
    # Get file size
    file_size = os.path.getsize(video_path)
    
    # Parse range header
    range_header = request.headers.get('Range', None)
    
    if not range_header:
        # No range requested, send entire file
        return send_file(video_path, mimetype='video/mp4')
    
    # Parse range header
    byte_range = range_header.replace('bytes=', '').split('-')
    start = int(byte_range[0]) if byte_range[0] else 0
    end = int(byte_range[1]) if byte_range[1] else file_size - 1
    
    # Ensure valid range
    if start >= file_size or end >= file_size:
        return "Invalid range", 416
    
    length = end - start + 1
    
    # Read the chunk
    with open(video_path, 'rb') as video_file:
        video_file.seek(start)
        data = video_file.read(length)
    
    # Create response with partial content
    response = Response(data, 206, mimetype='video/mp4')
    response.headers.add('Content-Range', f'bytes {start}-{end}/{file_size}')
    response.headers.add('Accept-Ranges', 'bytes')
    response.headers.add('Content-Length', str(length))
    
    return response

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
