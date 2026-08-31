@echo off
chcp 65001 >nul
title CAI DAT TU DONG QUET KHI CAM USB

:: Kiem tra quyen Administrator va tu dong xin quyen neu chua co
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ======================================================================
    echo  DANG YEU CAU QUYEN ADMINISTRATOR DE DANG KY VAO TASK SCHEDULER...
    echo ======================================================================
    echo.
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cls
echo ======================================================================
echo  DANG CAI DAT TINH NANG: TU DONG DIET VIRUS MOI KHI CAM USB
echo ======================================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "WATCHER_PATH=%SCRIPT_DIR%usb_watcher.ps1"

:: Tao Scheduled Task bang schtasks.exe (Chuan goc he thong Windows 7, 8, 10, 11)
schtasks.exe /create /tn "AutoUSB_Malware_Guard" /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%WATCHER_PATH%\"" /sc onlogon /rl highest /f >nul 2>&1

:: Dung tien trinh cu va khoi chay ngay tien trinh watcher moi
powershell -Command "Get-WmiObject Win32_Process -Filter \"Name = 'powershell.exe'\" | Where-Object { $_.CommandLine -match 'usb_watcher' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"\"%WATCHER_PATH%\"\"'"

echo [+] CAI DAT THANH CONG!
echo.
echo - Tinh nang tu dong quet da duoc bat va dang chay ngam trong Task Scheduler.
echo - Tu gio tro di, bat cu khi nao ban cam USB vao may, cong cu se tu dong bat len de quet va cuu du lieu!
echo.
echo ======================================================================
echo  Nhan phim bat ky de dong...
echo ======================================================================
pause >nul
