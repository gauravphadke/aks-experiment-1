# API Documentation

## Google Drive Video Download API

### Endpoint: POST /api/download-gdrive

Download and cache a video from a Google Drive shareable link.

#### Request

**Method:** `POST`

**Content-Type:** `application/json`

**Body:**
```json
{
  "url": "https://drive.google.com/file/d/FILE_ID/view?usp=sharing"
}
```

#### Supported URL Formats

The endpoint supports multiple Google Drive URL formats:
- `https://drive.google.com/file/d/FILE_ID/view`
- `https://drive.google.com/file/d/FILE_ID/view?usp=sharing`
- `https://drive.google.com/open?id=FILE_ID`
- `https://drive.google.com/uc?id=FILE_ID`

#### Response Codes

**200 OK** - Video already cached
```json
{
  "success": true,
  "message": "Video already cached",
  "filename": "my_video.mp4",
  "cached": true
}
```

**200 OK** - Video downloaded successfully
```json
{
  "success": true,
  "message": "Video downloaded and cached successfully",
  "filename": "my_video.mp4",
  "file_id": "FILE_ID",
  "size_mb": 45.67,
  "cached": false
}
```

**400 Bad Request** - Missing URL parameter
```json
{
  "error": "Missing URL parameter",
  "message": "Please provide a Google Drive shareable link"
}
```

**400 Bad Request** - Invalid Google Drive URL
```json
{
  "error": "Invalid Google Drive URL",
  "message": "Could not extract file ID from the provided URL"
}
```

**400 Bad Request** - Invalid file type
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

**400 Bad Request** - Download failed
```json
{
  "error": "Download failed",
  "message": "Could not download file from Google Drive. Status code: 403",
  "hint": "Make sure the file is publicly accessible or has link sharing enabled"
}
```

**500 Internal Server Error** - Network error
```json
{
  "error": "Network error",
  "message": "Failed to download file: Connection timeout"
}
```

**500 Internal Server Error** - Server error
```json
{
  "error": "Server error",
  "message": "An unexpected error occurred: ..."
}
```

#### Supported Video Formats

**MIME Types:**
- `video/mp4`
- `video/webm`
- `video/ogg`
- `video/quicktime` (MOV)
- `video/x-msvideo` (AVI)
- `video/x-matroska` (MKV)

**File Extensions:**
- `.mp4`
- `.webm`
- `.ogg`
- `.mov`
- `.avi`
- `.mkv`

#### Caching Behavior

- Videos are cached in the `static/videos` directory
- **Cached filenames preserve the original Google Drive filename**
- Metadata files (`.gdrive_meta_{FILE_ID}.json`) track which files came from Google Drive
- If a video with the same file ID is already cached, it returns immediately without re-downloading
- If a filename conflict occurs, a counter is appended (e.g., `video.mp4`, `video_1.mp4`)
- Maximum file size: 500 MB
- Metadata files are hidden (start with `.`) and not shown in the UI

#### Example Usage

**Using cURL:**
```bash
curl -X POST http://localhost:5000/api/download-gdrive \
  -H "Content-Type: application/json" \
  -d '{"url": "https://drive.google.com/file/d/1ABC123xyz/view?usp=sharing"}'
```

**Using JavaScript (fetch):**
```javascript
const response = await fetch('/api/download-gdrive', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
    },
    body: JSON.stringify({ 
        url: 'https://drive.google.com/file/d/1ABC123xyz/view?usp=sharing' 
    })
});

const data = await response.json();
console.log(data);
```

**Using Python (requests):**
```python
import requests

url = "http://localhost:5000/api/download-gdrive"
payload = {
    "url": "https://drive.google.com/file/d/1ABC123xyz/view?usp=sharing"
}

response = requests.post(url, json=payload)
print(response.json())
```

---

### Endpoint: GET /api/cached-videos

Get a list of all cached videos.

#### Request

**Method:** `GET`

#### Response

**200 OK**
```json
{
  "success": true,
  "count": 3,
  "videos": [
    {
      "filename": "vacation_2024.mp4",
      "size_mb": 45.67,
      "is_gdrive_cached": true
    },
    {
      "filename": "my_local_video.mp4",
      "size_mb": 23.45,
      "is_gdrive_cached": false
    },
    {
      "filename": "presentation.webm",
      "size_mb": 67.89,
      "is_gdrive_cached": true
    }
  ]
}
```

**500 Internal Server Error**
```json
{
  "error": "Server error",
  "message": "..."
}
```

#### Example Usage

**Using cURL:**
```bash
curl http://localhost:5000/api/cached-videos
```

---

### Endpoint: DELETE /api/delete-video/<filename>

Delete a cached video file.

#### Request

**Method:** `DELETE`

**URL Parameter:** `filename` - The name of the video file to delete

#### Response

**200 OK**
```json
{
  "success": true,
  "message": "Video vacation_2024.mp4 deleted successfully"
}
```

**404 Not Found**
```json
{
  "error": "File not found",
  "message": "Video nonexistent.mp4 does not exist"
}
```

**500 Internal Server Error**
```json
{
  "error": "Server error",
  "message": "..."
}
```

#### Example Usage

**Using cURL:**
```bash
curl -X DELETE http://localhost:5000/api/delete-video/vacation_2024.mp4
```

**Using JavaScript (fetch):**
```javascript
const response = await fetch('/api/delete-video/vacation_2024.mp4', {
    method: 'DELETE'
});

const data = await response.json();
console.log(data);
```

---

## Google Drive Sharing Instructions

For the download to work, the Google Drive file must be accessible via a shareable link:

1. **Open Google Drive** and find your video file
2. **Right-click** on the file → **Share**
3. Under "General access", change to **"Anyone with the link"**
4. Make sure permission is set to **"Viewer"**
5. Click **"Copy link"**
6. Use this link with the API endpoint

### Example Shareable Link Format
```
https://drive.google.com/file/d/1ABCdefGHIjklMNOpqrsTUVwxyz123456/view?usp=sharing
```

The important part is the file ID: `1ABCdefGHIjklMNOpqrsTUVwxyz123456`

---

## Error Handling

The API uses consistent error response format:

```json
{
  "error": "Error category",
  "message": "Human-readable error message",
  "hint": "Optional suggestion for fixing the error",
  "detected_type": "Optional: detected MIME type",
  "supported_types": "Optional: list of supported types"
}
```

Always check the HTTP status code to determine if the request was successful (200) or failed (400, 404, 500).
