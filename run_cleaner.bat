@echo off
chcp 65001 >nul
title CONG CU QUET & DIET MA DOC LMIGUARDIAN / USB AN TOAN ATTT

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0clean_lmiguardian.ps1"
exit /b
