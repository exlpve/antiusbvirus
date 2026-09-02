@echo off
chcp 65001 >nul
title CAI DAT TU DONG QUET KHI CAM USB

:: KHONG can quyen Administrator
cls
echo ======================================================================
echo  DANG CAI DAT TINH NANG: TU DONG DIET VIRUS MOI KHI CAM USB
echo  (Registry Run Key - Chay trong session nguoi dung hien tai)
echo ======================================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "WATCHER_PATH=%SCRIPT_DIR%usb_watcher.ps1"
set "LAUNCH_CMD=powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%WATCHER_PATH%""

:: 1. Ghi vao Registry HKCU (khong can quyen Admin)
echo [*] Dang ghi vao Registry Run Key (HKCU)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "AntiUSBVirus_Watcher" /t REG_SZ /d "%LAUNCH_CMD%" /f >nul 2>&1
if %errorlevel% equ 0 (
    echo [+] Da ghi Registry Run Key thanh cong.
) else (
    echo [!] Khong the ghi Registry Run Key.
)

:: 2. Dung watcher cu neu dang chay
echo [*] Dang dung watcher cu (neu co)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%stop_watcher.ps1" >nul 2>&1
echo [+] Da dung watcher cu.

:: 3. Khoi chay watcher moi ngay lap tuc trong session hien tai
echo [*] Dang khoi chay watcher moi...
start "" /b powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%WATCHER_PATH%"
timeout /t 2 /nobreak >nul
echo [+] Watcher da duoc khoi chay.

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
