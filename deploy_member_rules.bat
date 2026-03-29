@echo off
echo Deploying Firebase Security Rules for Members Collection...
echo.

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Firebase CLI not found. Installing...
    npm install -g firebase-tools
    if %errorlevel% neq 0 (
        echo Failed to install Firebase CLI. Please install manually:
        echo npm install -g firebase-tools
        pause
        exit /b 1
    )
)

echo Firebase CLI found. Deploying security rules...
echo.

REM Deploy only Firestore rules
firebase deploy --only firestore:rules

if %errorlevel% equ 0 (
    echo.
    echo ✅ Firebase Security Rules deployed successfully!
    echo ✅ Members collection permissions should now work.
    echo.
    echo Please restart your app and try adding a member again.
) else (
    echo.
    echo ❌ Failed to deploy Firebase Security Rules.
    echo Please check:
    echo 1. You are logged into Firebase (run: firebase login)
    echo 2. Your Firebase project is set correctly (run: firebase projects:list)
    echo 3. You have the correct permissions in Firebase project
)

pause
