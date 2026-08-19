@echo off
cd /d "%~dp0"
title Super Admin UI - stopping...
echo Stopping Super Admin...
docker compose down
echo Done.
pause
