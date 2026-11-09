@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Khotwa - English Learning App
where node >nul 2>nul
if errorlevel 1 (
  echo.
  echo Node.js not found — opening the app directly in the browser.
  echo For microphone features, install Node.js or use Chrome's local server.
  echo.
  start "" "%~dp0index.html"
  timeout /t 3 >nul
  exit /b
)
node tools\serve.mjs
pause
