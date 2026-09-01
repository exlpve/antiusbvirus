@echo off
chcp 65001 >nul
title CAI DAT TU DONG QUET KHI CAM USB

:: Kiem tra quyen Administrator va tu dong xin quyen neu chua co
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ======================================================================
    echo  DANG YEU CAU QUYEN ADMINISTRATOR...
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
set "REG_SCRIPT=%SCRIPT_DIR%register_task.ps1"

:: Dang ky Task Scheduler qua file PowerShell (toan quyen kiem soat cai dat)
echo [*] Dang dang ky vao Task Scheduler...
powershell -NoProfile -ExecutionPolicy Bypass -File "%REG_SCRIPT%"

set "START_SCRIPT=%SCRIPT_DIR%start_watcher.ps1"

echo.
echo [*] Dang dung tien trinh watcher cu va khoi chay lai...
powershell -NoProfile -ExecutionPolicy Bypass -File "%START_SCRIPT%" -WatcherPath "%WATCHER_PATH%"

:: Kich chay ngay task (khong can dang xuat / dang nhap lai)
schtasks.exe /run /tn "AutoUSB_Malware_Guard" >nul 2>&1

echo.
echo [+] CAI DAT HOAN TAT!
echo.
echo - Tien trinh watcher dang chay ngam, san sang phat hien USB duoc cam vao.
echo - Moi khi khoi dong lai Windows, watcher se tu dong chay sau 1 phut.
echo.
echo ======================================================================
echo  Nhan phim bat ky de dong...
echo ======================================================================
pause >nul
