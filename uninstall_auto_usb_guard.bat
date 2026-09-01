@echo off
chcp 65001 >nul
title GO BO TINH NANG TU DONG QUET USB

cls
echo ======================================================================
echo  DANG GO BO TINH NANG TU DONG QUET USB
echo ======================================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "WATCHER_PATH=%SCRIPT_DIR%usb_watcher.ps1"

:: Xoa Registry Run Key
echo [*] Dang xoa Registry Run Key...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "LMIGuardian_USBWatcher" /f >nul 2>&1
echo [+] Da xoa Registry Run Key.

:: Dung tien trinh watcher dang chay
echo [*] Dang dung tien trinh watcher...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%stop_watcher.ps1" >nul 2>&1
echo [+] Da dung tien trinh watcher.

:: Go bo Permanent WMI Subscription cu neu con
powershell -NoProfile -ExecutionPolicy Bypass -File "%WATCHER_PATH%" -Uninstall >nul 2>&1

:: Xoa Task Scheduler cu neu con (chay voi quyen Admin neu co)
schtasks.exe /delete /tn "AutoUSB_Malware_Guard" /f >nul 2>&1

echo.
echo [+] DA GO BO THANH CONG!
echo.
echo - Tinh nang tu dong quet khi cam USB da duoc tat hoan toan.
echo - Ban van co the chay thu cong bang file run_cleaner.bat.
echo.
echo ======================================================================
echo  Nhan phim bat ky de dong...
echo ======================================================================
pause >nul
