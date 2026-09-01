# Script khoi dong tien trinh usb_watcher (dung tien trinh cu truoc neu co)
param([string]$WatcherPath)

# Dung tien trinh watcher cu neu dang chay
$procs = Get-WmiObject Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    if ($p.CommandLine -match "usb_watcher") {
        Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        Write-Host "[*] Da dung tien trinh watcher cu (PID: $($p.ProcessId))."
    }
}

# Khoi chay tien trinh watcher moi bang WScript.Shell (tuong thich moi moi truong Windows)
$shell = New-Object -ComObject WScript.Shell
$shell.Run("powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WatcherPath`"", 0, $false)
Write-Host "[+] Da khoi chay watcher moi ngay lap tuc."
