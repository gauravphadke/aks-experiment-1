# Testing Guide for Google Drive Integration

## Prerequisites

1. **Flask server running:**
   ```bash
   python app.py
   ```

2. **A video file on Google Drive** with a shareable link

## How to Get a Google Drive Shareable Link

1. Upload a video to Google Drive (MP4, WebM, MOV, etc.)
2. Right-click on the file → **Get link** or **Share**
3. Under "General access", select **"Anyone with the link"**
4. Ensure permission is set to **"Viewer"**
5. Click **"Copy link"**

Example link format:
```
https://drive.google.com/file/d/1ABCdefGHIjklMNOpqrsTUVwxyz123456/view?usp=sharing
```

## Test Cases

### Test 1: Valid Video Download (Happy Path)

**Steps:**
1. Get a shareable link for a video file
2. Open http://localhost:5000 in your browser
3. Paste the link in the "Download from Google Drive" input field
4. Click "Download Video"

**Expected Result:**
- Status message shows: "Downloading video from Google Drive..."
- After download: "✓ Video downloaded and cached successfully"
- Page automatically reloads after 2 seconds
- Video appears in the playlist
- Video plays when clicked

**API Test:**
```bash
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "YOUR_GDRIVE_LINK_HERE"}'
```

**Expected JSON Response:**
```json
{
  "success": true,
  "message": "Video downloaded and cached successfully",
  "filename": "gdrive_1ABC...xyz.mp4",
  "file_id": "1ABC...xyz",
  "size_mb": 45.67,
  "cached": false
}
```

---

### Test 2: Already Cached Video

**Steps:**
1. Use the same Google Drive link from Test 1
2. Try to download it again

**Expected Result:**
- Immediate response (no download)
- Status: "✓ Video already cached"
- Returns HTTP 200 with `cached: true`

**API Test:**
```bash
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "YOUR_GDRIVE_LINK_HERE"}'
```

**Expected JSON Response:**
```json
{
  "success": true,
  "message": "Video already cached",
  "filename": "gdrive_1ABC...xyz.mp4",
  "cached": true
}
```

---

### Test 3: Invalid File Type (Non-Video)

**Steps:**
1. Upload a non-video file to Google Drive (e.g., PDF, DOCX, image)
2. Get shareable link
3. Try to download it via the API

**Expected Result:**
- Returns HTTP 400 error
- Error message: "The file is not a supported video format"
- Lists detected type and supported types

**API Test:**
```bash
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "LINK_TO_NON_VIDEO_FILE"}'
```

**Expected JSON Response:**
```json
{
  "error": "Invalid file type",
  "message": "The file is not a supported video format",
  "detected_type": "application/pdf",
  "supported_types": [
    "video/mp4",
    "video/webm",
    "video/ogg",
    "video/quicktime",
    "video/x-msvideo",
    "video/x-matroska"
  ],
  "supported_extensions": [
    ".mp4",
    ".webm",
    ".ogg",
    ".mov",
    ".avi",
    ".mkv"
  ]
}
```

---

### Test 4: Invalid Google Drive URL

**Steps:**
1. Submit a malformed or non-Google Drive URL

**Test URLs:**
```bash
# Not a Google Drive URL
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/video.mp4"}'

# Invalid Google Drive format
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "https://drive.google.com/"}'
```

**Expected Result:**
- Returns HTTP 400 error
- Error message: "Could not extract file ID from the provided URL"

**Expected JSON Response:**
```json
{
  "error": "Invalid Google Drive URL",
  "message": "Could not extract file ID from the provided URL"
}
```

---

### Test 5: Missing URL Parameter

**Steps:**
1. Send empty or missing URL

**API Test:**
```bash
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected Result:**
- Returns HTTP 400 error
- Error message: "Please provide a Google Drive shareable link"

**Expected JSON Response:**
```json
{
  "error": "Missing URL parameter",
  "message": "Please provide a Google Drive shareable link"
}
```

---

### Test 6: Private/Restricted File

**Steps:**
1. Upload a video to Google Drive
2. Keep it private (don't enable link sharing)
3. Try to download it

**Expected Result:**
- Returns HTTP 400 error
- Error message about download failure
- Hint about making file publicly accessible

**Expected JSON Response:**
```json
{
  "error": "Download failed",
  "message": "Could not download file from Google Drive. Status code: 403",
  "hint": "Make sure the file is publicly accessible or has link sharing enabled"
}
```

---

### Test 7: List Cached Videos

**API Test:**
```bash
curl http://localhost:5000/api/cached-videos
```

**Expected JSON Response:**
```json
{
  "success": true,
  "count": 2,
  "videos": [
    {
      "filename": "gdrive_1ABC123xyz.mp4",
      "size_mb": 45.67,
      "is_gdrive_cached": true
    },
    {
      "filename": "my_local_video.mp4",
      "size_mb": 23.45,
      "is_gdrive_cached": false
    }
  ]
}
```

---

### Test 8: Delete Cached Video

**API Test:**
```bash
# Delete a video
curl -X DELETE http://localhost:5000/api/delete-video/gdrive_1ABC123xyz.mp4

# Try to delete non-existent video
curl -X DELETE http://localhost:5000/api/delete-video/nonexistent.mp4
```

**Expected Responses:**

Success:
```json
{
  "success": true,
  "message": "Video gdrive_1ABC123xyz.mp4 deleted successfully"
}
```

File not found:
```json
{
  "error": "File not found",
  "message": "Video nonexistent.mp4 does not exist"
}
```

---

### Test 9: Different Google Drive URL Formats

Test all supported URL formats:

```bash
# Format 1: /file/d/FILE_ID/view
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "https://drive.google.com/file/d/1ABC123xyz/view"}'

# Format 2: /file/d/FILE_ID/view?usp=sharing
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "https://drive.google.com/file/d/1ABC123xyz/view?usp=sharing"}'

# Format 3: /open?id=FILE_ID
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "https://drive.google.com/open?id=1ABC123xyz"}'

# Format 4: /uc?id=FILE_ID
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "https://drive.google.com/uc?id=1ABC123xyz"}'
```

All formats should work correctly.

---

### Test 10: Video Playback After Download

**Steps:**
1. Download a video using Google Drive
2. Wait for page reload
3. Click on the downloaded video in the playlist

**Expected Result:**
- Video loads and plays correctly
- Seeking/scrubbing works
- Volume control works
- Fullscreen works
- All HTML5 video controls function properly

---

## Browser Testing

Test the web interface in multiple browsers:
- Chrome/Chromium
- Firefox
- Safari
- Edge

**UI Elements to Check:**
- Input field accepts and displays URL
- Download button becomes disabled during download
- Status messages display correctly (loading, success, error)
- Page reloads automatically after successful download
- Downloaded videos appear with "from Google Drive" label

---

## Performance Testing

### Large File Test
1. Upload a large video (100+ MB) to Google Drive
2. Download it via the API
3. Monitor download progress

**Expected Behavior:**
- Server streams the download efficiently
- No memory issues
- Progress can be monitored via server logs

### Concurrent Downloads
Try downloading multiple videos simultaneously:
```bash
# Terminal 1
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "LINK_1"}'

# Terminal 2 (run at the same time)
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "LINK_2"}'
```

**Expected Behavior:**
- Both downloads should proceed
- No race conditions or file corruption
- Both videos cached correctly

---

## Troubleshooting

### Common Issues

**Issue:** "Could not resolve host: drive.google.com"
- **Solution:** Check internet connection

**Issue:** Download fails with 403 error
- **Solution:** Ensure file has link sharing enabled

**Issue:** "Invalid file type" for a video file
- **Solution:** Check if video format is supported (see supported_types)

**Issue:** Video won't play after download
- **Solution:** Check if browser supports the video codec
- Try re-downloading or converting to MP4

---

## Test Results Checklist

- [ ] Valid video downloads successfully
- [ ] Cached videos don't re-download
- [ ] Non-video files are rejected (400 error)
- [ ] Invalid URLs are rejected (400 error)
- [ ] Missing parameters are handled (400 error)
- [ ] Private files are rejected (400 error)
- [ ] All URL formats work
- [ ] List API returns correct data
- [ ] Delete API works correctly
- [ ] Videos play after download
- [ ] UI shows appropriate messages
- [ ] Page reloads after successful download
- [ ] Multiple video formats work (MP4, WebM, etc.)
