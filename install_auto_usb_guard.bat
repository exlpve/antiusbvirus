@echo off
chcp 65001 >nul
title CAI DAT TU DONG QUET KHI CAM USB

:: KHONG can quyen Administrator - chay duoc voi tai khoan thuong
cls
echo ======================================================================
echo  DANG CAI DAT TINH NANG: TU DONG DIET VIRUS MOI KHI CAM USB
echo  (Registry Run Key - Chay trong session nguoi dung hien tai)
echo ======================================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "WATCHER_PATH=%SCRIPT_DIR%usb_watcher.ps1"
set "LAUNCH_CMD=powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%WATCHER_PATH%""

:: Ghi vao Registry HKCU (khong can quyen Admin)
:: HKCU\Software\Microsoft\Windows\CurrentVersion\Run chay cung nguoi dung hien tai
:: Dam bao watcher chay DUNG trong session co desktop (khac Task Scheduler/SYSTEM)
echo [*] Dang ghi vao Registry Run Key (HKCU)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "LMIGuardian_USBWatcher" /t REG_SZ /d "%LAUNCH_CMD%" /f >nul 2>&1

if %errorlevel% equ 0 (
    echo [+] Da ghi Registry Run Key thanh cong.
) else (
    echo [!] Khong the ghi Registry.
    pause >nul
    exit /b 1
)

:: Go bo Permanent WMI Subscription cu neu con
powershell -NoProfile -ExecutionPolicy Bypass -File "%WATCHER_PATH%" -Uninstall >nul 2>&1

:: Dung watcher phien ban cu neu dang chay
echo [*] Dang dung watcher cu (neu co)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$procs = Get-WmiObject Win32_Process -Filter 'Name = \"\"powershell.exe\"\"'; foreach($p in $procs){ if($p.CommandLine -match 'usb_watcher'){ Stop-Process -Id $p.ProcessId -Force -EA SilentlyContinue } }" >nul 2>&1

:: Khoi chay watcher moi ngay lap tuc trong session hien tai
echo [*] Dang khoi chay watcher ngay lap tuc...
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%WATCHER_PATH%"

timeout /t 2 /nobreak >nul

echo.
echo [+] CAI DAT HOAN TAT!
echo.
echo - Watcher dang chay ngam trong session cua ban.
echo - Moi khi dang nhap Windows, watcher tu dong khoi chay theo.
echo - Cam USB vao se kich hoat trinh diet virus ngay lap tuc!
echo.
echo ======================================================================
echo  Nhan phim bat ky de dong...
echo ======================================================================
pause >nul
