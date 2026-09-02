@echo off
chcp 65001 >nul
title GO BO TINH NANG TU DONG QUET USB

cls
echo ======================================================================
echo  DANG GO BO TINH NANG TU DONG QUET USB
echo ======================================================================
echo.

set "SCRIPT_DIR=%~dp0"

:: 1. Xoa Registry Run Key (ten moi: AntiUSBVirus_Watcher)
echo [*] Dang xoa Registry Run Key...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "AntiUSBVirus_Watcher" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "LMIGuardian_USBWatcher" /f >nul 2>&1
echo [+] Da xoa Registry Run Key.

:: 2. Dung tien trinh watcher dang chay
echo [*] Dang dung tien trinh watcher...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%stop_watcher.ps1" >nul 2>&1
echo [+] Da dung tien trinh watcher.

:: 3. Xoa Permanent WMI Subscription cu (neu con)
echo [*] Dang xoa WMI Subscription cu (neu co)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ns='root\subscription'; try{ ([wmi]\"\\.\$ns:__FilterToConsumerBinding.Filter=\"\"\"\"__EventFilter.Name='LMIGuardian_USBFilter'\"\"\"\",Consumer=\"\"\"\"CommandLineEventConsumer.Name='LMIGuardian_USBConsumer'\"\"\"\"\").Delete() }catch{}; try{ ([wmi]\"\\.\$ns:__EventFilter.Name='LMIGuardian_USBFilter'\").Delete() }catch{}; try{ ([wmi]\"\\.\$ns:CommandLineEventConsumer.Name='LMIGuardian_USBConsumer'\").Delete() }catch{};" >nul 2>&1
echo [+] Da xoa WMI Subscription cu (neu co).

:: 4. Xoa Scheduled Task cu (neu con)
echo [*] Dang xoa Scheduled Task cu (neu co)...
schtasks.exe /delete /tn "AutoUSB_Malware_Guard" /f >nul 2>&1
echo [+] Da xoa Scheduled Task cu (neu co).

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
