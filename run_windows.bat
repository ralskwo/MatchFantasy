@echo off
setlocal

cd /d "%~dp0"

if not exist "pubspec.yaml" (
  echo [ERROR] pubspec.yaml not found.
  exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter is not available in PATH.
  exit /b 1
)

if not exist "windows" (
  echo [INFO] Windows platform files are missing. Creating Windows runner...
  call flutter create . --platforms=windows
  if errorlevel 1 (
    echo [ERROR] Failed to create Windows platform files.
    exit /b 1
  )
)

echo [INFO] Resolving packages...
call flutter pub get
if errorlevel 1 (
  echo [ERROR] flutter pub get failed.
  exit /b 1
)

echo [INFO] Launching MatchFantasy on Windows...
call flutter run -d windows --target lib/main.dart

endlocal
