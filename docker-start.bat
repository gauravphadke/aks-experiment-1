@echo off
REM Flask Video Streaming - Docker Quick Start Script (Windows)

setlocal EnableDelayedExpansion

REM Check if Docker is installed
where docker >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed. Please install Docker Desktop first.
    echo Visit: https://www.docker.com/products/docker-desktop/
    pause
    exit /b 1
)

REM Check if Docker is running
docker info >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running. Please start Docker Desktop.
    pause
    exit /b 1
)

REM Parse command line argument
if "%1"=="" goto interactive
if "%1"=="build" goto build
if "%1"=="run" goto run
if "%1"=="start" goto start
if "%1"=="stop" goto stop
if "%1"=="restart" goto restart
if "%1"=="logs" goto logs
if "%1"=="status" goto status
if "%1"=="clean" goto clean
if "%1"=="--help" goto help
if "%1"=="-h" goto help

echo [ERROR] Unknown command: %1
echo Run 'docker-start.bat --help' for usage information
pause
exit /b 1

:help
echo Flask Video Streaming - Docker Quick Start (Windows)
echo.
echo Usage: docker-start.bat [command]
echo.
echo Commands:
echo   build    - Build Docker image
echo   run      - Run container (use existing image)
echo   start    - Build and run (fresh start)
echo   stop     - Stop container
echo   restart  - Restart container
echo   logs     - View container logs
echo   status   - Check container status
echo   clean    - Remove container and image
echo.
echo If no command is provided, interactive mode will start.
pause
exit /b 0

:build
echo [INFO] Building Docker image...
docker compose build
if %errorlevel% neq 0 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
echo [INFO] Image built successfully
if "%2"=="" pause
exit /b 0

:run
echo [INFO] Starting container...

REM Check if using Docker Compose
if exist docker-compose.yml (
    docker compose up -d
) else (
    REM Remove existing container if exists
    docker rm -f flask-video-streaming >nul 2>nul
    
    REM Run new container
    docker run -d --name flask-video-streaming -p 5000:5000 --tmpfs /app/static/videos:size=2G,mode=1777 --restart unless-stopped flask-video-app:latest
)

if %errorlevel% neq 0 (
    echo [ERROR] Failed to start container
    pause
    exit /b 1
)

echo [INFO] Container started successfully
call :show_access_info
if "%2"=="" pause
exit /b 0

:start
call :build nobatch
call :run nobatch
if "%2"=="" pause
exit /b 0

:stop
echo [INFO] Stopping container...
if exist docker-compose.yml (
    docker compose down
) else (
    docker stop flask-video-streaming >nul 2>nul
)
echo [INFO] Container stopped
if "%2"=="" pause
exit /b 0

:restart
echo [INFO] Restarting container...
if exist docker-compose.yml (
    docker compose restart
) else (
    docker restart flask-video-streaming
)
echo [INFO] Container restarted
call :status nobatch
if "%2"=="" pause
exit /b 0

:logs
echo [INFO] Showing logs (Ctrl+C to exit)...
if exist docker-compose.yml (
    docker compose logs -f
) else (
    docker logs -f flask-video-streaming
)
exit /b 0

:status
echo.
echo [INFO] Container Status:
docker ps --filter name=flask-video-streaming --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.
if "%2"=="" pause
exit /b 0

:clean
echo [WARNING] This will remove the container and image.
set /p confirm="Continue? (y/N): "
if /i not "%confirm%"=="y" (
    echo [INFO] Cleanup cancelled
    pause
    exit /b 0
)

echo [INFO] Cleaning up...
if exist docker-compose.yml (
    docker compose down
) else (
    docker rm -f flask-video-streaming >nul 2>nul
)
docker rmi flask-video-app:latest >nul 2>nul
echo [INFO] Cleanup complete
pause
exit /b 0

:show_access_info
echo.
echo ===================================================
echo Flask Video Streaming App is running!
echo ===================================================
echo.
echo   Access the application at:
echo   -^> http://localhost:5000
echo.
echo   Useful commands:
echo   -^> View logs:      docker logs -f flask-video-streaming
echo   -^> Stop:           docker stop flask-video-streaming
echo   -^> Restart:        docker restart flask-video-streaming
echo   -^> Shell access:   docker exec -it flask-video-streaming bash
echo   -^> Check tmpfs:    docker exec flask-video-streaming df -h /app/static/videos
echo.
echo ===================================================
echo.
exit /b 0

:interactive
cls
echo ==========================================
echo Flask Video Streaming - Docker Quick Start
echo ==========================================
echo.
echo 1. Build and Run (Fresh start)
echo 2. Build only
echo 3. Run only (use existing image)
echo 4. Stop container
echo 5. View logs
echo 6. Check status
echo 7. Restart container
echo 8. Clean up (remove container and image)
echo 9. Exit
echo.
set /p choice="Select an option (1-9): "

if "%choice%"=="1" (
    call :start nobatch
    call :status nobatch
    goto interactive
)
if "%choice%"=="2" (
    call :build nobatch
    goto interactive
)
if "%choice%"=="3" (
    call :run nobatch
    call :status nobatch
    goto interactive
)
if "%choice%"=="4" (
    call :stop nobatch
    goto interactive
)
if "%choice%"=="5" (
    call :logs
    goto interactive
)
if "%choice%"=="6" (
    call :status nobatch
    goto interactive
)
if "%choice%"=="7" (
    call :restart nobatch
    goto interactive
)
if "%choice%"=="8" (
    call :clean
    goto interactive
)
if "%choice%"=="9" (
    echo [INFO] Goodbye!
    exit /b 0
)

echo [ERROR] Invalid option. Please select 1-9.
pause
goto interactive
