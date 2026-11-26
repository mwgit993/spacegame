@echo off
set "PATH=C:\Program Files\Git\cmd;%PATH%"
cd /d "%~dp0"
echo Pulling latest Star Viper updates from https://github.com/mwgit993/spacegame ...
echo.
git pull --rebase --autostash origin main
echo.
if %ERRORLEVEL% EQU 0 (
    echo SUCCESS! You now have the newest version. Open Godot and press F5 to play!
) else (
    echo Pull encountered a conflict or error. Ask Antigravity or check git status!
)
pause
