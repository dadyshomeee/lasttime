@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo   CutPulse - One-Click Git Push
echo ============================================
echo.

git add -A
if %errorlevel% neq 0 (
  echo [ERROR] git add failed.
  pause
  exit /b 1
)

git diff --cached --quiet
if %errorlevel% equ 0 (
  echo No changes to commit. Pushing anyway...
) else (
  git commit -m "Update: %date% %time%"
  if %errorlevel% neq 0 (
    echo [ERROR] git commit failed.
    pause
    exit /b 1
  )
)

git push origin main
if %errorlevel% neq 0 (
  echo.
  echo [ERROR] Push failed. Check your connection or credentials.
  pause
  exit /b 1
)

echo.
echo [OK] Push successful!
pause