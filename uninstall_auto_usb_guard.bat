@echo off
chcp 65001 >nul
title GO BO TINH NANG TU DONG QUET USB

:: Kiem tra quyen Administrator va tu dong xin quyen neu chua co
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ======================================================================
    echo  DANG YEU CAU QUYEN ADMINISTRATOR DE GO BO TRONG TASK SCHEDULER...
    echo ======================================================================
    echo.
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cls
echo ======================================================================
echo  DANG GO BO TINH NANG TU DONG QUET USB
echo ======================================================================
echo.

:: Xoa Scheduled Task bang schtasks.exe (Tuong thich 100% Windows 7, 8, 10, 11)
schtasks.exe /delete /tn "AutoUSB_Malware_Guard" /f >nul 2>&1

:: Dung tien trinh watcher dang chay ngam (Tuong thich PowerShell 2.0 tren Win 7)
powershell -Command "Get-WmiObject Win32_Process -Filter \"Name = 'powershell.exe'\" | Where-Object { $_.CommandLine -match 'usb_watcher' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"

echo [+] DA GO BO THANH CONG!
echo.
echo - Tinh nang tu dong quet khi cam USB da duoc tat khoi Task Scheduler.
echo - Ban van co the chay thu cong bang file run_cleaner.bat bat cu luc nao.
echo.
echo ======================================================================
echo  Nhan phim bat ky de dong...
echo ======================================================================
pause >nul
