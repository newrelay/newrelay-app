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

echo  Waiting for Docker to be ready...
set /a _tries=0
:waitdocker
docker info >nul 2>&1
if not errorlevel 1 goto dockerready
set /a _tries+=1
if %_tries% geq 12 (
  echo  ERROR: Docker Desktop is not responding.
  echo  Open Docker Desktop, wait until it says "Running" (green), then double-click this file again.
  echo.
  pause
  exit /b 1
)
timeout /t 5 /nobreak >nul
goto waitdocker
:dockerready
echo  Docker is ready.

if not exist ".env" (
  echo  Creating local config from .env.example ...
  copy /Y ".env.example" ".env" >nul
  powershell -NoProfile -Command "(Get-Content .env) -replace 'FRONTEND_URL=http://0.0.0.0:3000','FRONTEND_URL=http://localhost:3000' | Set-Content -NoNewline .env; Add-Content .env ''"
)

docker image inspect chatwoot-rails:development >nul 2>&1
if errorlevel 1 (
  echo.
  echo  First start takes 15-20 minutes. Later starts are much faster.
  echo  Building the app (step 1 of 2: base image)...
  echo.
  docker compose build base
  if errorlevel 1 (
    echo.
    echo  ERROR: Base build failed. Screenshot this window and send it.
    echo.
    pause
    exit /b 1
  )
  echo.
  echo  Building the app (step 2 of 2: services)...
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
