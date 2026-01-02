# How to Push This Code and Create a Pull Request

## Step 1: Navigate to the Project Directory
```bash
cd /path/to/flask-video-app
```

## Step 2: Initialize Git (if not already a git repository)
```bash
git init
```

## Step 3: Create a New Branch for Your Feature
```bash
git checkout -b feature/video-streaming-server
```

## Step 4: Add All Files to Git
```bash
git add .
```

## Step 5: Commit Your Changes
```bash
git commit -m "Add Flask video streaming server with HTML5 player and Jinja2 templates"
```

## Step 6: Add Remote Repository
```bash
git remote add origin https://github.com/gauravphadke/aks-experiment-1.git
```

If the remote already exists, you can update it:
```bash
git remote set-url origin https://github.com/gauravphadke/aks-experiment-1.git
```

## Step 7: Push to GitHub
```bash
git push -u origin feature/video-streaming-server
```

You may be prompted to enter your GitHub credentials or personal access token.

## Step 8: Create a Pull Request

### Option A: Via GitHub Web Interface
1. Go to https://github.com/gauravphadke/aks-experiment-1
2. You should see a banner suggesting to create a pull request from your recently pushed branch
3. Click "Compare & pull request"
4. Fill in the PR details:
   - **Title**: "Add Flask Video Streaming Server"
   - **Description**: Use the template below

### Option B: Via GitHub CLI (gh)
```bash
gh pr create --title "Add Flask Video Streaming Server" --body "$(cat PR_TEMPLATE.md)"
```

## Pull Request Template

```markdown
## Description
This PR adds a complete Flask video streaming server with the following features:

- ✅ Python Flask server
- ✅ Jinja2 templates for dynamic HTML generation
- ✅ HTML5 video player with full controls
- ✅ Support for multiple video formats (MP4, WebM, Ogg)
- ✅ Responsive design
- ✅ Playlist functionality
- ✅ Range request support for video seeking

## Features
- **Flask Application**: Main server in `app.py`
- **Jinja2 Templates**: Dynamic HTML generation in `templates/index.html`
- **HTML5 Video**: Native video player with controls
- **Video Streaming**: Efficient video delivery with range request support
- **Modern UI**: Gradient design with smooth animations

## Files Added
- `app.py` - Main Flask application
- `templates/index.html` - Jinja2 template with HTML5 video player
- `requirements.txt` - Python dependencies
- `README.md` - Comprehensive documentation
- `.gitignore` - Git ignore rules
- `static/videos/` - Directory for video files

## Testing
To test this locally:
1. Install dependencies: `pip install -r requirements.txt`
2. Add video files to `static/videos/`
3. Run: `python app.py`
4. Visit: `http://localhost:5000`

## Screenshots
[Add screenshots if desired]

## Related Issues
Closes #[issue-number] (if applicable)
```

## Troubleshooting

### Authentication Issues
If you have authentication issues, you may need to create a Personal Access Token:
1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Generate new token with `repo` scope
3. Use this token as your password when pushing

### Branch Already Exists
If the branch exists remotely:
```bash
git push origin feature/video-streaming-server --force
```
(Use --force with caution!)

### Merge Conflicts
If there are conflicts with the main branch:
```bash
git fetch origin
git merge origin/main
# Resolve conflicts
git add .
git commit -m "Resolve merge conflicts"
git push origin feature/video-streaming-server
```

## After PR is Created

1. Wait for code review
2. Address any feedback by making additional commits
3. Once approved, the PR can be merged into main

## Quick Command Summary
```bash
cd /path/to/flask-video-app
git init
git checkout -b feature/video-streaming-server
git add .
git commit -m "Add Flask video streaming server with HTML5 player"
git remote add origin https://github.com/gauravphadke/aks-experiment-1.git
git push -u origin feature/video-streaming-server
# Then create PR via GitHub web interface
```
