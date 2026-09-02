@echo off
chcp 65001 >nul
title Anti USB Virus - Quet Diet Ma Doc
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0usb_virus_cleaner.ps1"
exit /b
