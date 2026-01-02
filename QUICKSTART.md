# 🚀 Quick Start Guide

## What You Have
A complete Flask video streaming server with:
- Python Flask backend
- Jinja2 templates for dynamic HTML
- HTML5 video player
- Modern, responsive UI

## File Structure
```
flask-video-app/
├── app.py                    # Flask server (main application)
├── requirements.txt          # Python dependencies
├── README.md                 # Full documentation
├── PUSH_TO_GITHUB.md        # GitHub push instructions
├── .gitignore               # Git ignore rules
├── templates/
│   └── index.html           # Jinja2 template with HTML5 video player
└── static/
    └── videos/              # Put your video files here
        └── README.txt       # Instructions for video directory
```

## Quick Test (Local)

1. **Create and activate a virtual environment:**
   
   **On Windows:**
   ```bash
   cd flask-video-app
   python -m venv venv
   venv\Scripts\activate
   ```
   
   **On macOS/Linux:**
   ```bash
   cd flask-video-app
   python3 -m venv venv
   source venv/bin/activate
   ```
   
   You should see `(venv)` in your terminal prompt when activated.

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Add a test video:**
   ```bash
   # Copy any .mp4, .webm, or .ogg file to static/videos/
   cp /path/to/your/video.mp4 static/videos/
   ```

4. **Run the server:**
   ```bash
   python app.py
   ```

5. **Open browser:**
   ```
   http://localhost:5000
   ```

6. **When done, deactivate the virtual environment:**
   ```bash
   deactivate
   ```

## Push to GitHub & Create PR

See detailed instructions in `PUSH_TO_GITHUB.md`

**Quick version:**
```bash
cd flask-video-app
git init
git checkout -b feature/video-streaming-server
git add .
git commit -m "Add Flask video streaming server"
git remote add origin https://github.com/gauravphadke/aks-experiment-1.git
git push -u origin feature/video-streaming-server
```

Then go to GitHub and create a Pull Request from your branch.

## Key Features

✅ **Flask Server** - Lightweight Python web server
✅ **Jinja2 Templates** - Dynamic HTML generation
✅ **HTML5 Video** - Native browser video player with controls
✅ **Streaming** - Efficient video delivery with seeking support
✅ **Responsive** - Works on desktop, tablet, and mobile
✅ **Playlist** - Multiple videos with auto-advance
✅ **Modern UI** - Beautiful gradient design

## Next Steps

1. ✅ Test locally
2. ✅ Push to GitHub
3. ✅ Create Pull Request
4. ⏳ Get code review
5. ⏳ Merge to main

## Need Help?

- Check `README.md` for full documentation
- See `PUSH_TO_GITHUB.md` for GitHub instructions
- Review code comments in `app.py` and `templates/index.html`
