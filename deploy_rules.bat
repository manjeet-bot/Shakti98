@echo off
echo Deploying Firebase Security Rules...
echo.
echo Make sure you have Firebase CLI installed and logged in!
echo.
pause
firebase deploy --only firestore:rules
echo.
echo Rules deployed successfully!
pause
