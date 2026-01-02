# Docker Quick Start

Get the Flask Video Streaming app running in Docker in under 2 minutes!

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running

## 🚀 Quick Start

### Using Docker Compose (Easiest)

```bash
# 1. Navigate to project directory
cd flask-video-app

# 2. Build and run
docker compose up --build

# 3. Open browser
# Go to: http://localhost:5000
```

That's it! 🎉

### Using Helper Scripts

**Linux/Mac:**
```bash
chmod +x docker-start.sh
./docker-start.sh start
```

**Windows:**
```cmd
docker-start.bat start
```

The scripts provide an interactive menu with options to build, run, stop, view logs, and more.

## 📋 Common Commands

```bash
# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down

# Restart (clears video cache)
docker compose restart

# Check tmpfs usage
docker exec flask-video-streaming df -h /app/static/videos
```

## 💾 tmpfs Storage

Videos are stored in **RAM (tmpfs)** instead of disk:

**Advantages:**
- ⚡ Ultra-fast video loading
- 🔒 Automatic cleanup on restart
- 💿 No disk wear

**What this means:**
- Downloaded videos are cleared when container restarts
- Videos load instantly from memory
- Default size: 2GB (configurable)

**Change tmpfs size:**

Edit `docker-compose.yml`:
```yaml
tmpfs:
  - /app/static/videos:size=4G  # Change to 4GB
```

## 🎯 Using the App

1. **Open:** http://localhost:5000
2. **Download video from Google Drive:**
   - Get a shareable Google Drive link
   - Paste it in the input field
   - Click "Download Video"
3. **Watch:** Video appears in playlist and plays automatically

## 🔧 Troubleshooting

**Port 5000 in use?**
```bash
# Use different port
docker run -p 8080:5000 ...
# Then access: http://localhost:8080
```

**Out of memory?**
```bash
# Check tmpfs usage
docker exec flask-video-streaming df -h /app/static/videos

# Increase size in docker-compose.yml
tmpfs:
  - /app/static/videos:size=4G
```

**Container won't start?**
```bash
# Check logs
docker logs flask-video-streaming

# Or
docker compose logs
```

## 📚 More Information

- **Complete Docker Guide:** [DOCKER_GUIDE.md](DOCKER_GUIDE.md)
- **API Documentation:** [API_DOCUMENTATION.md](API_DOCUMENTATION.md)
- **General README:** [README.md](README.md)

## 🎨 Architecture

```
┌─────────────────────────────────────┐
│   Browser (http://localhost:5000)  │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│      Docker Container               │
│  ┌───────────────────────────────┐  │
│  │   Flask App (Gunicorn)        │  │
│  │   - 4 workers                 │  │
│  │   - Port 5000                 │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │   tmpfs (RAM Storage)         │  │
│  │   /app/static/videos          │  │
│  │   - Size: 2GB                 │  │
│  │   - Ephemeral storage         │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## 🌟 Production Tips

1. **Increase workers for high traffic:**
   ```dockerfile
   CMD ["gunicorn", "--workers", "8", ...]
   ```

2. **Set resource limits:**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2'
         memory: 4G
   ```

3. **Enable HTTPS with reverse proxy (Nginx):**
   See DOCKER_GUIDE.md for complete setup

## 🎯 Next Steps

- ✅ App is running
- 📥 Download videos from Google Drive
- 🎬 Stream videos in browser
- 📊 Use API endpoints for automation

Enjoy! 🚀
