# ==============================================================================
# TOOL: Anti USB Virus - USB Event Watcher (Phien ban 10.0 - Polling Mode)
# Tac gia: KN
# Mo ta: Polling moi 2 giay thay vi WMI event (nhanh hon tren Win7)
# ==============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir -or $ScriptDir -eq "") { $ScriptDir = "D:\AntiUSBVirus" }

# Kiem tra Mutex: Chi cho phep 1 phien watcher duy nhat
$global:WatcherMutex = New-Object System.Threading.Mutex($false, "Global\AntiUSBVirus_Watcher_SingleInstance")
if (-not $global:WatcherMutex.WaitOne(0, $false)) {
    Exit
}

$CleanerPath = Join-Path $ScriptDir "usb_virus_cleaner.ps1"
$LogPath     = Join-Path $ScriptDir "watcher_activity.log"

# Ham lay danh sach o USB hien tai
function Get-UsbDrives {
    try {
        return [System.IO.DriveInfo]::GetDrives() |
            Where-Object { $_.DriveType -eq "Removable" } |
            ForEach-Object { $_.Name }
    } catch {
        return @()
    }
}

# Ham kiem tra cleaner da chay chua
function Is-CleanerRunning {
    try {
        $procs = Get-Process -Name "powershell" -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            try {
                if ($p.MainWindowTitle -match "Anti USB Virus") { return $true }
            } catch {}
        }
    } catch {}
    return $false
}

# Ham khoi chay cleaner
function Start-Cleaner {
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shell.Run("powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$CleanerPath`"", 1, $false)
        $logLine = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] USB cam vao - Kich hoat cleaner"
        Add-Content -Path $LogPath -Value $logLine -ErrorAction SilentlyContinue
    } catch {}
}

# Lay danh sach USB ban dau
$prevDrives = Get-UsbDrives
$lastTrigger = [DateTime]::MinValue

# Vong lap polling chinh - kiem tra moi 2 giay
while ($true) {
    Start-Sleep -Seconds 2

    $currDrives = Get-UsbDrives

    # Tim USB moi cam vao
    $newDrives = $currDrives | Where-Object { $prevDrives -notcontains $_ }

    if ($newDrives) {
        $now = Get-Date
        # Debounce 8 giay
        if (($now - $lastTrigger).TotalSeconds -ge 8) {
            $lastTrigger = $now
            if (-not (Is-CleanerRunning)) {
                Start-Cleaner
            }
        }
    }

    $prevDrives = $currDrives
}
