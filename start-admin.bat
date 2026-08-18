@echo off
setlocal EnableExtensions
cd /d "%~dp0"

title Super Admin UI - starting...
echo.
echo  ============================================
echo   Super Admin UI
echo  ============================================
echo.
echo  Keep this window OPEN while you work.
echo  Close it (or run stop-admin.bat) when done.
echo.

where docker >nul 2>&1
if errorlevel 1 (
  echo  ERROR: Docker is not installed.
  echo  Install Docker Desktop, restart the PC, then double-click this file again.
  echo  https://www.docker.com/products/docker-desktop/
  echo.
  pause
  exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
  echo  ERROR: Docker Desktop is installed but not running.
  echo  Open Docker Desktop, wait until it says "Running", then double-click this file again.
  echo.
  pause
  exit /b 1
)

if not exist ".env" (
  echo  Creating local config from .env.example ...
  copy /Y ".env.example" ".env" >nul
  powershell -NoProfile -Command "(Get-Content .env) -replace 'FRONTEND_URL=http://0.0.0.0:3000','FRONTEND_URL=http://localhost:3000' | Set-Content -NoNewline .env; Add-Content .env ''"
)

docker image inspect chatwoot-rails:development >nul 2>&1
if errorlevel 1 (
  echo.
  echo  First start takes 15-20 minutes. Later starts are much faster.
  echo  Building the app...
  echo.
  docker compose build
  if errorlevel 1 (
    echo.
    echo  ERROR: Build failed. Screenshot this window and send it.
    echo.
    pause
    exit /b 1
  )
  echo.
  echo  Preparing the database...
  docker compose up -d postgres redis
  timeout /t 15 /nobreak >nul
  docker compose run --rm --no-deps rails bundle exec rails db:chatwoot_prepare
  if errorlevel 1 (
    echo.
    echo  ERROR: Database setup failed. Screenshot this window and send it.
    echo.
    pause
    exit /b 1
  )
)

echo.
echo  Starting the app...
echo  When it is ready, open:
echo    http://localhost:3000/super_admin/sign_in
echo.
echo  Login:
echo    Email:    john@acme.inc
echo    Password: Password1!
echo.
docker compose up
echo.
echo  App stopped.
pause
