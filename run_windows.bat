@echo off
REM 快速启动脚本 (Windows)
set PATH=C:\flutter_sdk\flutter\bin;%PATH%
cd /d %~dp0
flutter run -d windows
