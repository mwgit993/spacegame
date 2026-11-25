@echo off
cd /d "%~dp0"
echo Pushing Star Viper to https://github.com/mwgit993/spacegame ...
echo (If a GitHub Sign-In window appears, click "Sign in with your browser"!)
echo.
git push -u origin main
echo.
if %ERRORLEVEL% EQU 0 (
    echo SUCCESS! Everything is now live on https://github.com/mwgit993/spacegame
) else (
    echo Push did not complete. Check the message above and run push_to_github.bat again.
)
pause
