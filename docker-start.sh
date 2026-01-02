#!/bin/bash

# Flask Video Streaming - Docker Quick Start Script
# This script helps you quickly build and run the Docker container

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    print_info "Docker found: $(docker --version)"
}

# Check if Docker Compose is installed
check_docker_compose() {
    if docker compose version &> /dev/null; then
        print_info "Docker Compose found: $(docker compose version)"
        return 0
    elif command -v docker-compose &> /dev/null; then
        print_info "Docker Compose found: $(docker-compose --version)"
        return 0
    else
        print_warning "Docker Compose not found. Will use docker run instead."
        return 1
    fi
}

# Check if Docker daemon is running
check_docker_running() {
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    print_info "Docker daemon is running"
}

# Build the Docker image
build_image() {
    print_info "Building Docker image..."
    
    if docker compose version &> /dev/null; then
        docker compose build
    else
        docker build -t flask-video-app:latest .
    fi
    
    print_info "✓ Image built successfully"
}

# Run with Docker Compose
run_with_compose() {
    print_info "Starting container with Docker Compose..."
    docker compose up -d
    print_info "✓ Container started successfully"
}

# Run with Docker CLI
run_with_docker() {
    print_info "Starting container with Docker..."
    
    # Stop and remove existing container if it exists
    if docker ps -a --format '{{.Names}}' | grep -q '^flask-video-streaming$'; then
        print_warning "Removing existing container..."
        docker rm -f flask-video-streaming
    fi
    
    # Run new container
    docker run -d \
        --name flask-video-streaming \
        -p 5000:5000 \
        --tmpfs /app/static/videos:size=2G,mode=1777 \
        --restart unless-stopped \
        flask-video-app:latest
    
    print_info "✓ Container started successfully"
}

# Display container status
show_status() {
    echo ""
    print_info "Container Status:"
    docker ps --filter name=flask-video-streaming --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Display access information
show_access_info() {
    echo ""
    print_info "==================================================="
    print_info "Flask Video Streaming App is running!"
    print_info "==================================================="
    echo ""
    echo "  Access the application at:"
    echo "  → http://localhost:5000"
    echo ""
    echo "  Useful commands:"
    echo "  → View logs:      docker logs -f flask-video-streaming"
    echo "  → Stop:           docker stop flask-video-streaming"
    echo "  → Restart:        docker restart flask-video-streaming"
    echo "  → Shell access:   docker exec -it flask-video-streaming bash"
    echo "  → Check tmpfs:    docker exec flask-video-streaming df -h /app/static/videos"
    echo ""
    print_info "==================================================="
}

# Main menu
show_menu() {
    echo ""
    echo "Flask Video Streaming - Docker Quick Start"
    echo "=========================================="
    echo "1. Build and Run (Fresh start)"
    echo "2. Build only"
    echo "3. Run only (use existing image)"
    echo "4. Stop container"
    echo "5. View logs"
    echo "6. Check status"
    echo "7. Restart container"
    echo "8. Clean up (remove container and image)"
    echo "9. Exit"
    echo ""
}

# Stop container
stop_container() {
    print_info "Stopping container..."
    if docker compose version &> /dev/null && [ -f "docker-compose.yml" ]; then
        docker compose down
    else
        docker stop flask-video-streaming 2>/dev/null || true
    fi
    print_info "✓ Container stopped"
}

# View logs
view_logs() {
    print_info "Showing logs (Ctrl+C to exit)..."
    if docker compose version &> /dev/null && [ -f "docker-compose.yml" ]; then
        docker compose logs -f
    else
        docker logs -f flask-video-streaming
    fi
}

# Restart container
restart_container() {
    print_info "Restarting container..."
    if docker compose version &> /dev/null && [ -f "docker-compose.yml" ]; then
        docker compose restart
    else
        docker restart flask-video-streaming
    fi
    print_info "✓ Container restarted"
}

# Clean up
cleanup() {
    print_warning "This will remove the container and image. Continue? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_info "Cleaning up..."
        
        # Stop and remove container
        if docker compose version &> /dev/null && [ -f "docker-compose.yml" ]; then
            docker compose down
        else
            docker rm -f flask-video-streaming 2>/dev/null || true
        fi
        
        # Remove image
        docker rmi flask-video-app:latest 2>/dev/null || true
        
        print_info "✓ Cleanup complete"
    else
        print_info "Cleanup cancelled"
    fi
}

# Run interactive mode
interactive_mode() {
    while true; do
        show_menu
        read -p "Select an option (1-9): " choice
        
        case $choice in
            1)
                check_docker
                check_docker_running
                build_image
                
                if check_docker_compose && [ -f "docker-compose.yml" ]; then
                    run_with_compose
                else
                    run_with_docker
                fi
                
                show_status
                show_access_info
                ;;
            2)
                check_docker
                check_docker_running
                build_image
                ;;
            3)
                check_docker
                check_docker_running
                
                if check_docker_compose && [ -f "docker-compose.yml" ]; then
                    run_with_compose
                else
                    run_with_docker
                fi
                
                show_status
                show_access_info
                ;;
            4)
                stop_container
                ;;
            5)
                view_logs
                ;;
            6)
                show_status
                ;;
            7)
                restart_container
                show_status
                ;;
            8)
                cleanup
                ;;
            9)
                print_info "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please select 1-9."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Parse command line arguments
case "${1:-}" in
    build)
        check_docker
        check_docker_running
        build_image
        ;;
    run)
        check_docker
        check_docker_running
        if check_docker_compose && [ -f "docker-compose.yml" ]; then
            run_with_compose
        else
            run_with_docker
        fi
        show_status
        show_access_info
        ;;
    start)
        check_docker
        check_docker_running
        build_image
        if check_docker_compose && [ -f "docker-compose.yml" ]; then
            run_with_compose
        else
            run_with_docker
        fi
        show_status
        show_access_info
        ;;
    stop)
        stop_container
        ;;
    restart)
        restart_container
        show_status
        ;;
    logs)
        view_logs
        ;;
    status)
        show_status
        ;;
    clean)
        cleanup
        ;;
    --help|-h)
        echo "Flask Video Streaming - Docker Quick Start"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  build    - Build Docker image"
        echo "  run      - Run container (use existing image)"
        echo "  start    - Build and run (fresh start)"
        echo "  stop     - Stop container"
        echo "  restart  - Restart container"
        echo "  logs     - View container logs"
        echo "  status   - Check container status"
        echo "  clean    - Remove container and image"
        echo ""
        echo "If no command is provided, interactive mode will start."
        ;;
    "")
        # No arguments - run interactive mode
        check_docker
        check_docker_running
        interactive_mode
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 --help' for usage information"
        exit 1
        ;;
esac
