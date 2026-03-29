@echo off
echo Deploying Firebase Security Rules...
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

echo Firebase CLI found. Proceeding with deployment...
echo.

REM Login to Firebase (if not already logged in)
echo Checking Firebase authentication...
firebase login --no-localhost

REM Deploy Firestore rules
echo.
echo Deploying Firestore security rules...
firebase deploy --only firestore:rules

if %errorlevel% equ 0 (
    echo.
    echo ✅ Successfully deployed Firebase security rules!
    echo Please restart your Flutter app to test the chat functionality.
) else (
    echo.
    echo ❌ Failed to deploy Firebase security rules.
    echo Please manually deploy them via Firebase Console:
    echo 1. Go to https://console.firebase.google.com/
    echo 2. Select project: studio-9839508681-122cf
    echo 3. Navigate to Firestore Database ^> Rules
    echo 4. Copy contents from firestore.rules file
    echo 5. Click Publish
)

echo.
pause
