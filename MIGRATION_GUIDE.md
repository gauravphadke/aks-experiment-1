# Migration Guide - Filename Caching Update

## What Changed?

### Previous Behavior (Old)
- Files downloaded from Google Drive were named: `gdrive_FILE_ID.mp4`
- Example: `gdrive_1ABC123xyz.mp4`
- Files were differentiated by the `gdrive_` prefix in the filename

### New Behavior (Current)
- Files downloaded from Google Drive use their **original filename**
- Example: `vacation_2024.mp4` (preserves the Google Drive filename)
- Files are tracked using hidden metadata files: `.gdrive_meta_FILE_ID.json`
- No visible difference in the UI between local files and Google Drive files

## Why This Change?

1. **Better User Experience**: Original filenames are more meaningful and recognizable
2. **No Visual Distinction**: Users don't need to know where videos came from
3. **Professional Appearance**: No technical prefixes cluttering the interface
4. **Still Tracked Internally**: Backend still knows which files are from Google Drive

## Do I Need to Migrate?

**If you're starting fresh:** No action needed! Just use the updated code.

**If you have existing `gdrive_*` files:** You have two options:

### Option 1: Keep Old Files As-Is (Recommended)
Your old files will continue to work perfectly fine. The app will treat them as regular local files.

**No action needed!**

### Option 2: Rename to Original Names (Optional)
If you want cleaner filenames, you can manually rename them:

1. **Identify your files:**
   ```bash
   ls static/videos/gdrive_*
   ```

2. **Rename each file:**
   ```bash
   # Example:
   mv static/videos/gdrive_1ABC123xyz.mp4 static/videos/vacation_2024.mp4
   ```

3. **Important:** Old files won't have metadata tracking, but they'll work fine

## Testing After Update

1. **Test existing videos:**
   - Open http://localhost:5000
   - Verify all videos appear in the list
   - Test playback of each video

2. **Test new downloads:**
   - Download a video from Google Drive
   - Verify it uses the original filename
   - Check that metadata file was created

3. **Verify metadata files:**
   ```bash
   ls -la static/videos/.gdrive_meta_*
   ```
   
   You should see hidden JSON files for newly downloaded videos.

## Metadata File Format

New downloads create metadata files like:
```
static/videos/.gdrive_meta_1ABC123xyz.json
```

Contents:
```json
{
  "file_id": "1ABC123xyz",
  "filename": "vacation_2024.mp4",
  "original_url": "https://drive.google.com/file/d/...",
  "file_size_bytes": 47895552,
  "download_date": "2026-01-02T12:00:00",
  "source": "google_drive"
}
```

## Troubleshooting

### Old Files Show in List
**This is normal!** Old `gdrive_*` files will continue to work as local files.

### Duplicate Downloads
The new system tracks by file ID. If you download the same Google Drive file again:
- It checks the file ID in metadata
- Returns immediately if already cached
- Won't create duplicates

### Filename Conflicts
If you download a file with the same name as an existing local file:
- System checks if it's the same Google Drive file (by ID)
- If different, appends a counter: `video_1.mp4`, `video_2.mp4`, etc.

### Metadata Files Visible
Metadata files start with `.` (hidden files):
- On Linux/Mac: Hidden by default
- On Windows: May be visible, but harmless
- To hide in Windows Explorer: Right-click → Properties → Hidden

## Backward Compatibility

The new system is **fully backward compatible**:
- ✅ Old `gdrive_*` files continue to work
- ✅ No re-download required
- ✅ All existing functionality preserved
- ✅ Can mix old and new cached files

## Summary

**For Most Users:**
- Update the code
- Continue using as normal
- New downloads will have cleaner names
- Old files continue working

**No migration required!** 🎉
