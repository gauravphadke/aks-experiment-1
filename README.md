# Flask Video Streaming Server

A Python Flask server that uses Jinja2 templates to display and stream videos using HTML5's video plugin.

## Features

- 🎬 HTML5 video player with full controls
- 📥 **Google Drive Integration** - Download and cache videos directly from shareable links
- 🔄 Support for multiple video formats (MP4, WebM, Ogg, MOV, AVI, MKV)
- ✅ **Video Type Validation** - Automatically rejects non-video files
- 💾 **Smart Caching** - Downloaded videos are cached locally to avoid re-downloading
- 📱 Responsive design that works on all devices
- 🎨 Modern, gradient UI with smooth animations
- ⏭️ Playlist functionality with auto-play next video
- 🎯 Easy video switching with visual feedback
- 🔌 RESTful API for programmatic access

## Requirements

- Python 3.7+
- Flask
- Jinja2

## Installation

1. Clone this repository:
```bash
git clone https://github.com/gauravphadke/aks-experiment-1.git
cd aks-experiment-1
```

2. Create and activate a virtual environment (recommended):

   **On Windows:**
   ```bash
   python -m venv venv
   venv\Scripts\activate
   ```
   
   **On macOS/Linux:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Add your video files:
   - Place your video files (.mp4, .webm, or .ogg) in the `static/videos` directory
   - The directory is created automatically when you run the application

## Usage

### Starting the Server

1. Start the Flask server:
```bash
python app.py
```

2. Open your browser and navigate to:
```
http://localhost:5000
```

3. The video player will automatically load and display available videos.

### Adding Videos

You have two options for adding videos:

#### Option 1: Manual Upload
- Place video files directly in the `static/videos` directory
- Supported formats: MP4, WebM, Ogg, MOV, AVI, MKV
- Refresh the page to see new videos

#### Option 2: Google Drive Download
1. Get a shareable link from Google Drive:
   - Right-click on video → Share
   - Set to "Anyone with the link can view"
   - Copy the link

2. In the web interface:
   - Paste the Google Drive link in the input field
   - Click "Download Video"
   - Wait for the download to complete
   - The video will automatically appear in your playlist

3. The video is now cached locally and won't be downloaded again

### Using the API

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for detailed API usage.

**Quick example - Download from Google Drive:**
```bash
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "https://drive.google.com/file/d/YOUR_FILE_ID/view"}'
```

### Stopping the Server

4. When finished, press `Ctrl+C` in the terminal to stop the server

5. Deactivate the virtual environment:
```bash
deactivate
```

## Project Structure

```
flask-video-app/
├── app.py                    # Main Flask application with Google Drive integration
├── requirements.txt          # Python dependencies
├── README.md                 # This file
├── API_DOCUMENTATION.md      # Detailed API documentation
├── templates/
│   └── index.html           # Jinja2 template with video player and Google Drive UI
└── static/
    └── videos/              # Directory for video files (cached downloads)
```

## How It Works

### Flask Server (`app.py`)
- **Main Route (`/`)**: Renders the video player page using Jinja2 template
- **Video Route (`/video/<filename>`)**: Serves video files with proper MIME types
- **Stream Route (`/stream/<filename>`)**: Provides advanced streaming with range request support for seeking
- **Google Drive Download (`/api/download-gdrive`)**: Downloads videos from Google Drive shareable links
  - Validates file type (must be a video)
  - Caches videos locally to avoid re-downloading
  - Returns 400 error for non-video files
- **List Videos (`/api/cached-videos`)**: Returns list of all cached videos
- **Delete Video (`/api/delete-video/<filename>`)**: Deletes a cached video file

### Video Type Validation
The server validates files are videos by checking:
1. **MIME type** from HTTP headers (e.g., `video/mp4`)
2. **File extension** as fallback (e.g., `.mp4`, `.webm`)

Non-video files are rejected with a 400 error response.

### Caching System
- Downloaded videos preserve their original filenames from Google Drive
- Metadata files (hidden `.gdrive_meta_*.json` files) track which videos came from Google Drive
- Before downloading, checks if file is already cached by file ID
- If cached, returns immediately without re-downloading
- Filename conflicts are handled by appending a counter (e.g., `video_1.mp4`)
- Maximum file size: 500 MB
- UI displays all videos with their original names (no Google Drive prefix)

### Jinja2 Template (`index.html`)
- Uses Jinja2 templating to dynamically generate the video list
- Implements HTML5 `<video>` element with full controls
- Includes JavaScript for playlist functionality and Google Drive downloads
- Responsive CSS design with gradient backgrounds

## Features Explained

### HTML5 Video Controls
The video player includes:
- Play/Pause button
- Progress bar with seeking
- Volume control
- Fullscreen toggle
- Time display

### Playlist Functionality
- Automatically detects all videos in `static/videos` directory
- Click any video in the list to play it
- Videos auto-advance to the next one when finished
- Visual indication of currently playing video

### Supported Video Formats
- **MP4** (H.264): Best compatibility
- **WebM**: Modern, efficient format
- **Ogg**: Open-source alternative

## Customization

### Changing the Port
Edit `app.py` and modify the last line:
```python
app.run(debug=True, host='0.0.0.0', port=5000)  # Change port here
```

### Styling
Modify the `<style>` section in `templates/index.html` to customize:
- Colors and gradients
- Layout and spacing
- Animations and transitions

### Adding Features
Extend `app.py` to add:
- Video upload functionality
- User authentication
- Video metadata display
- Subtitle support

## Deployment

### Local Development
```bash
python app.py
```

### Production (using Gunicorn)
```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

### Docker
Create a `Dockerfile`:
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

Build and run:
```bash
docker build -t flask-video-app .
docker run -p 5000:5000 flask-video-app
```

## Troubleshooting

### Videos Not Playing
- Ensure video files are in `static/videos` directory
- Check file formats are supported (.mp4, .webm, .ogg)
- Verify file permissions allow reading

### Port Already in Use
- Change the port in `app.py`
- Or stop the process using port 5000

### Module Not Found Error
- Run `pip install -r requirements.txt`
- Activate your virtual environment if using one

## License

MIT License - Feel free to use and modify as needed.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.
