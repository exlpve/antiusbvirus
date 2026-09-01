@echo off
chcp 65001 >nul
title GO BO TINH NANG TU DONG QUET USB

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
echo  DANG GO BO TINH NANG TU DONG QUET USB
echo ======================================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "STOP_SCRIPT=%SCRIPT_DIR%stop_watcher.ps1"

:: Xoa Scheduled Task bang COM Object (xoa duoc ca task tao boi bat ky quyen nao)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s = New-Object -ComObject Schedule.Service; $s.Connect(); try { $f = $s.GetFolder('\'); $f.DeleteTask('AutoUSB_Malware_Guard', 0); Write-Host '[+] Da xoa task khoi Task Scheduler.' } catch { schtasks.exe /delete /tn 'AutoUSB_Malware_Guard' /f; Write-Host '[+] Da xoa task (phuong an du phong).' }"

:: Dung tien trinh watcher dang chay bang script rieng (tranh loi dau ngoac kep)
powershell -NoProfile -ExecutionPolicy Bypass -File "%STOP_SCRIPT%"

echo.
echo [+] DA GO BO THANH CONG!
echo.
echo - Tinh nang tu dong quet khi cam USB da duoc tat hoan toan.
echo - Ban van co the chay thu cong bang file run_cleaner.bat bat cu luc nao.
echo.
echo ======================================================================
echo  Nhan phim bat ky de dong...
echo ======================================================================
pause >nul
