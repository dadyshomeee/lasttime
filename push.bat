@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title CutPulse - Git Push

rem Never hang on credential prompts; fail fast with a clear message instead.
set "GIT_TERMINAL_PROMPT=0"

echo ============================================
echo   CutPulse - One-Click Git Push
echo ============================================
echo.

rem --- [0] Git kurulu mu? ---
where git >nul 2>nul
if !errorlevel! neq 0 (
  echo [ERROR] Git bulunamadi. Kur: https://git-scm.com/download/win
  pause
  exit /b 1
)

rem --- [0.1] Burasi bir git reposu mu? ---
git rev-parse --is-inside-work-tree >nul 2>nul
if !errorlevel! neq 0 (
  echo [ERROR] Bu klasor bir git reposu degil.
  pause
  exit /b 1
)

rem --- [0.2] origin tanimli mi? (URL yazdirilmaz: credential icerebilir) ---
git remote get-url origin >nul 2>nul
if !errorlevel! neq 0 (
  echo [ERROR] "origin" adli remote bulunamadi.
  pause
  exit /b 1
)

echo [1/4] Dosyalar sahneye aliniyor...
git add -A
if !errorlevel! neq 0 (
  echo [ERROR] git add basarisiz.
  pause
  exit /b 1
)

git diff --cached --quiet
if !errorlevel! equ 0 (
  echo       Degisiklik yok, commit atlaniyor.
) else (
  git commit -m "Update: %date% %time%"
  if !errorlevel! neq 0 (
    echo [ERROR] git commit basarisiz.
    pause
    exit /b 1
  )
)

echo [2/4] Uzak repo ile senkron kontrol ediliyor...
git fetch origin
if !errorlevel! neq 0 (
  echo [ERROR] git fetch basarisiz. Internet baglantini kontrol et.
  pause
  exit /b 1
)

rem Uzakta localden olmayan commit var mi? Varsa rebase ile ustune bin.
rem (Not: global config'de pull.rebase=true zaten acik.)
set "BEHIND=0"
for /f %%i in ('git rev-list --count HEAD..origin/main 2^>nul') do set "BEHIND=%%i"
if "!BEHIND!" neq "0" (
  echo       Origin !BEHIND! commit onde; rebase deneniyor...
  git pull --rebase origin main
  if !errorlevel! neq 0 (
    echo [ERROR] Rebase catisma verdi; temizlik geri aliniyor...
    git rebase --abort
    echo       Lutfen catismayi elle coz, sonra tekrar dene.
    pause
    exit /b 1
  )
)

echo [3/4] Push baslatiliyor...
git push origin main
if !errorlevel! neq 0 (
  echo.
  echo [ERROR] Push basarisiz oldu.
  echo   Olasi nedenler:
  echo     - Token suresi dolmus/iptal edilmis olabilir ^(401/403^).
  echo       GitHub ^> Settings ^> Developer settings ^> Personal access tokens
  echo     - Baglanti/ag sorunu
  echo   Not: Token'i uzak URL'e yazmak yerine Git Credential Manager kullanin:
  echo       git remote set-url origin https://github.com/dadyshomeee/lasttime.git
  pause
  exit /b 1
)

echo [4/4] Dogrulaniyor...
git fetch origin
for /f %%i in ('git rev-parse HEAD') do set "LOCAL_SHA=%%i"
for /f %%i in ('git rev-parse origin/main') do set "REMOTE_SHA=%%i"

if "!LOCAL_SHA!"=="!REMOTE_SHA!" (
  echo.
  echo [OK] Push tamamlandi ve dogrulandi. ^(!REMOTE_SHA:~0,7!^)
) else (
  echo.
  echo [WARN] Push ciktisi alindi ama yerel ile uzak farkli gorunuyor.
  echo       Tekrar calistirip sonucu kontrol edin.
)

echo.
pause
exit /b 0
