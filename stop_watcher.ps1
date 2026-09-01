# Script dung tien trinh usb_watcher dang chay ngam
$procs = Get-WmiObject Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue
$found = $false
foreach ($p in $procs) {
    if ($p.CommandLine -match "usb_watcher") {
        Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        Write-Host "[+] Da dung tien trinh watcher (PID: $($p.ProcessId))."
        $found = $true
    }
}
if (-not $found) {
    Write-Host "[*] Khong co tien trinh watcher nao dang chay."
}
