# ==============================================================================
# TOOL: Anti USB Virus - USB Event Watcher (Phien ban 9.0)
# Tac gia: KN
# Mo ta: Chay trong session nguoi dung, lang nghe su kien cam USB va kich hoat cleaner
# ==============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir -or $ScriptDir -eq "") { $ScriptDir = "D:\AntiUSBVirus" }
$CleanerScript = Join-Path $ScriptDir "usb_virus_cleaner.ps1"

# Kiem tra Mutex: Chi cho phep 1 phien watcher duy nhat
$global:WatcherMutex = New-Object System.Threading.Mutex($false, "Global\AntiUSBVirus_Watcher_SingleInstance")
if (-not $global:WatcherMutex.WaitOne(0, $false)) {
    # Da co 1 watcher dang chay, thoat ngay
    Exit
}

# Bien chong spam: Debounce 8 giay
$global:LastTriggerTime = [DateTime]::MinValue

# Dang ky lang nghe su kien USB cam vao
$query = "SELECT * FROM Win32_VolumeChangeEvent WHERE EventType = 2"
Unregister-Event -SourceIdentifier "AntiUSBVirus_UsbArrival" -ErrorAction SilentlyContinue

# Luu duong dan cleaner vao bien de dung trong action
$env:CLEANER_PATH = Join-Path $ScriptDir "usb_virus_cleaner.ps1"

Register-WmiEvent -Query $query -SourceIdentifier "AntiUSBVirus_UsbArrival" -Action {
    $now = Get-Date
    if (($now - $global:LastTriggerTime).TotalSeconds -lt 8) { return }
    $global:LastTriggerTime = $now

    # Cho Windows mount xong o dia (2 giay)
    Start-Sleep -Seconds 2

    # Kiem tra neu cleaner da dang chay
    $running = Get-WmiObject Win32_Process -Filter "Name = 'powershell.exe'" -ErrorAction SilentlyContinue |
               Where-Object { $_.CommandLine -match "usb_virus_cleaner" }
    if ($running) { return }

    # Ghi log kich hoat
    $logLine = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] USB cam vao - Kich hoat cleaner"
    Add-Content -Path "$env:CLEANER_PATH\..\watcher_activity.log" -Value $logLine -ErrorAction SilentlyContinue

    # Khoi chay cua so cleaner trong session nguoi dung hien tai
    $shell = New-Object -ComObject WScript.Shell
    $shell.Run("powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$env:CLEANER_PATH`"", 1, $false)
} | Out-Null

# Vong lap giu watcher song
while ($true) {
    Start-Sleep -Seconds 30
}
