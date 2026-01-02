# Docker Deployment Guide

This guide covers building and running the Flask Video Streaming application in Docker with tmpfs storage for downloaded videos.

## Table of Contents
- [Why tmpfs?](#why-tmpfs)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Building the Docker Image](#building-the-docker-image)
- [Running the Container](#running-the-container)
- [Docker Compose](#docker-compose)
- [Configuration Options](#configuration-options)
- [Storage Management](#storage-management)
- [Troubleshooting](#troubleshooting)

---

## Why tmpfs?

**tmpfs (Temporary File System)** stores files in RAM instead of disk:

### ✅ Advantages
- **Ultra-fast I/O**: Videos load instantly from memory
- **No disk wear**: Perfect for SSDs, no write cycles consumed
- **Automatic cleanup**: Videos are cleared on container restart
- **Security**: No persistent video storage, data disappears on stop
- **Performance**: No disk I/O bottleneck for video streaming

### ⚠️ Considerations
- **Ephemeral storage**: Videos are lost when container stops/restarts
- **Memory usage**: Downloaded videos consume RAM
- **Size limit**: Default 2GB (configurable)

**Best for:**
- Temporary video caching
- High-performance streaming
- Privacy-sensitive applications
- Development/testing environments

---

## Prerequisites

### Required
- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher (optional, but recommended)

### Installation

**Ubuntu/Debian:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

**Windows/Mac:**
- Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Docker Compose is included

**Verify Docker is running:**
```bash
docker ps
```

---

## Quick Start

### Using Docker Compose (Recommended)

1. **Navigate to project directory:**
   ```bash
   cd flask-video-app
   ```

2. **Build and start:**
   ```bash
   docker compose up --build
   ```

3. **Access the application:**
   ```
   http://localhost:5000
   ```

4. **Stop the application:**
   ```bash
   docker compose down
   ```

That's it! The simplest way to get started.

---

## Building the Docker Image

### Method 1: Using Docker Compose (Recommended)

```bash
# Build the image
docker compose build

# Or build with no cache (clean build)
docker compose build --no-cache
```

### Method 2: Using Docker CLI

```bash
# Build the image
docker build -t flask-video-app:latest .

# Build with custom tag
docker build -t flask-video-app:1.0 .

# Build with no cache
docker build --no-cache -t flask-video-app:latest .
```

### Build Options

**Specify platform (for ARM/M1 Macs):**
```bash
docker build --platform linux/amd64 -t flask-video-app:latest .
```

**View build progress:**
```bash
docker build --progress=plain -t flask-video-app:latest .
```

**Check image size:**
```bash
docker images flask-video-app
```

---

## Running the Container

### Method 1: Using Docker Compose (Recommended)

```bash
# Start in foreground (see logs)
docker compose up

# Start in background (detached mode)
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

### Method 2: Using Docker CLI

**Basic run with tmpfs:**
```bash
docker run -d \
  --name flask-video-streaming \
  -p 5000:5000 \
  --tmpfs /app/static/videos:size=2G,mode=1777 \
  flask-video-app:latest
```

**Run with custom tmpfs size (4GB):**
```bash
docker run -d \
  --name flask-video-streaming \
  -p 5000:5000 \
  --tmpfs /app/static/videos:size=4G,mode=1777 \
  flask-video-app:latest
```

**Run with custom port (8080):**
```bash
docker run -d \
  --name flask-video-streaming \
  -p 8080:5000 \
  --tmpfs /app/static/videos:size=2G,mode=1777 \
  flask-video-app:latest
```

**Run in foreground (see logs):**
```bash
docker run -it \
  --name flask-video-streaming \
  -p 5000:5000 \
  --tmpfs /app/static/videos:size=2G,mode=1777 \
  flask-video-app:latest
```

### Container Management

**View running containers:**
```bash
docker ps
```

**Stop container:**
```bash
docker stop flask-video-streaming
```

**Start stopped container:**
```bash
docker start flask-video-streaming
```

**Remove container:**
```bash
docker rm flask-video-streaming
```

**View logs:**
```bash
# Follow logs in real-time
docker logs -f flask-video-streaming

# View last 100 lines
docker logs --tail 100 flask-video-streaming
```

**Execute commands in running container:**
```bash
# Open bash shell
docker exec -it flask-video-streaming bash

# Check tmpfs usage
docker exec flask-video-streaming df -h /app/static/videos

# List videos
docker exec flask-video-streaming ls -lh /app/static/videos
```

---

## Docker Compose

### Complete docker-compose.yml

```yaml
version: '3.8'

services:
  flask-video-app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: flask-video-streaming
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=production
      - PYTHONUNBUFFERED=1
    tmpfs:
      # Mount tmpfs for video storage
      - /app/static/videos:size=2G,mode=1777
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    networks:
      - flask-network

networks:
  flask-network:
    driver: bridge
```

### Docker Compose Commands

```bash
# Build and start
docker compose up --build

# Start in background
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart services
docker compose restart

# View service status
docker compose ps

# Execute command in service
docker compose exec flask-video-app bash

# Scale service (multiple instances)
docker compose up --scale flask-video-app=3
```

---

## Configuration Options

### tmpfs Configuration

Modify `docker-compose.yml` or docker run command:

**Size Options:**
```yaml
tmpfs:
  - /app/static/videos:size=1G    # 1 gigabyte
  - /app/static/videos:size=2G    # 2 gigabytes (default)
  - /app/static/videos:size=4G    # 4 gigabytes
  - /app/static/videos:size=512M  # 512 megabytes
```

**Permission Options:**
```yaml
tmpfs:
  - /app/static/videos:size=2G,mode=1777  # World-writable
  - /app/static/videos:size=2G,mode=0755  # Owner write only
  - /app/static/videos:size=2G,uid=1000   # Specific user ID
```

### Port Configuration

**docker-compose.yml:**
```yaml
ports:
  - "8080:5000"  # External:Internal
```

**Docker CLI:**
```bash
docker run -p 8080:5000 ...
```

### Environment Variables

**docker-compose.yml:**
```yaml
environment:
  - FLASK_ENV=production
  - PYTHONUNBUFFERED=1
  - MAX_CONTENT_LENGTH=524288000  # 500MB in bytes
```

**Docker CLI:**
```bash
docker run -e FLASK_ENV=production ...
```

### Gunicorn Workers

Edit `Dockerfile` CMD line:
```dockerfile
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "8", ...]
```

**Worker calculation:**
- Formula: `(2 × CPU cores) + 1`
- 2 cores = 5 workers
- 4 cores = 9 workers

---

## Storage Management

### Monitoring tmpfs Usage

**Check available space:**
```bash
docker exec flask-video-streaming df -h /app/static/videos
```

**Monitor in real-time:**
```bash
watch -n 5 'docker exec flask-video-streaming df -h /app/static/videos'
```

**List cached videos:**
```bash
docker exec flask-video-streaming ls -lh /app/static/videos
```

### tmpfs Behavior

**When container starts:**
- tmpfs is empty
- Available size = configured size (e.g., 2GB)

**During operation:**
- Videos downloaded from Google Drive stored in tmpfs
- Fast access from RAM
- Space decreases as videos are downloaded

**When container stops:**
- All videos in tmpfs are deleted
- Cannot be recovered
- Next start = clean slate

**When container restarts:**
- tmpfs is recreated empty
- Must re-download videos if needed

### Alternative: Persistent Storage

If you need persistent storage instead of tmpfs:

**docker-compose.yml:**
```yaml
volumes:
  - ./local-videos:/app/static/videos
```

**Docker CLI:**
```bash
docker run -v $(pwd)/local-videos:/app/static/videos ...
```

This stores videos on disk instead of RAM.

---

## Troubleshooting

### Issue: Container Won't Start

**Check logs:**
```bash
docker logs flask-video-streaming
```

**Common causes:**
- Port 5000 already in use
- Insufficient memory for tmpfs
- Image not built

**Solutions:**
```bash
# Use different port
docker run -p 8080:5000 ...

# Reduce tmpfs size
--tmpfs /app/static/videos:size=512M

# Rebuild image
docker compose build --no-cache
```

### Issue: Out of Memory / tmpfs Full

**Symptoms:**
- Downloads fail
- Error: "No space left on device"

**Check usage:**
```bash
docker exec flask-video-streaming df -h /app/static/videos
```

**Solutions:**
1. Increase tmpfs size in docker-compose.yml
2. Delete old videos via API
3. Restart container to clear tmpfs

**Delete videos:**
```bash
# Via API
curl -X DELETE http://localhost:5000/api/delete-video/filename.mp4

# Or restart container
docker compose restart
```

### Issue: Cannot Access Application

**Check container is running:**
```bash
docker ps | grep flask-video
```

**Check port mapping:**
```bash
docker port flask-video-streaming
```

**Test from inside container:**
```bash
docker exec flask-video-streaming curl http://localhost:5000
```

**Check firewall:**
```bash
# Linux
sudo ufw status
sudo ufw allow 5000

# Windows - check Windows Defender Firewall
```

### Issue: Performance Issues

**Check container resources:**
```bash
docker stats flask-video-streaming
```

**Increase workers in Dockerfile:**
```dockerfile
CMD ["gunicorn", "--workers", "8", ...]
```

**Increase tmpfs size:**
```yaml
tmpfs:
  - /app/static/videos:size=4G
```

### Issue: Video Download Fails

**Check Google Drive permissions:**
- Ensure file has "Anyone with link" sharing enabled

**Check network:**
```bash
# Test from inside container
docker exec flask-video-streaming curl -I https://drive.google.com
```

**Check tmpfs space:**
```bash
docker exec flask-video-streaming df -h /app/static/videos
```

### Issue: Container Exits Immediately

**Check logs:**
```bash
docker logs flask-video-streaming
```

**Run in foreground to see errors:**
```bash
docker run -it --rm flask-video-app:latest
```

**Common causes:**
- Missing templates directory
- Python import errors
- Port binding issues

---

## Advanced Usage

### Multi-Stage Build (Smaller Image)

Create `Dockerfile.multistage`:
```dockerfile
# Build stage
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

### Running Behind Nginx

**docker-compose.yml:**
```yaml
services:
  flask-video-app:
    # ... existing config ...
    
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - flask-video-app
```

### Health Monitoring

**View health status:**
```bash
docker inspect --format='{{.State.Health.Status}}' flask-video-streaming
```

**Custom health check:**
```bash
docker run --health-cmd="curl -f http://localhost:5000/ || exit 1" ...
```

---

## Production Deployment

### Best Practices

1. **Use specific image tags:**
   ```bash
   docker build -t flask-video-app:1.0.0 .
   ```

2. **Set resource limits:**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2'
         memory: 4G
   ```

3. **Use secrets for sensitive data:**
   ```yaml
   secrets:
     - api_key
   ```

4. **Enable auto-restart:**
   ```yaml
   restart: unless-stopped
   ```

5. **Configure logging:**
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

### Security Hardening

1. **Run as non-root** (already configured in Dockerfile)
2. **Use read-only root filesystem:**
   ```yaml
   read_only: true
   tmpfs:
     - /tmp
     - /app/static/videos
   ```

3. **Scan for vulnerabilities:**
   ```bash
   docker scan flask-video-app:latest
   ```

---

## Quick Reference

### Essential Commands

```bash
# Build
docker compose build

# Start
docker compose up -d

# Stop
docker compose down

# Logs
docker compose logs -f

# Restart
docker compose restart

# Check status
docker compose ps

# Shell access
docker compose exec flask-video-app bash

# Check tmpfs
docker exec flask-video-streaming df -h /app/static/videos
```

### Cleanup Commands

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove all unused data
docker system prune -a

# Remove specific image
docker rmi flask-video-app:latest
```

---

## Support

For issues specific to:
- **Application**: See TROUBLESHOOTING.md
- **API**: See API_DOCUMENTATION.md
- **Testing**: See TESTING_GUIDE.md
- **Docker**: This guide

**Common Resources:**
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Gunicorn Documentation](https://docs.gunicorn.org/)
