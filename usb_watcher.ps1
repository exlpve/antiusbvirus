# ==============================================================================
# TOOL: USB Insertion Watcher (Phien ban 3.5 - SINGLE INSTANCE MUTEX)
# Description: Su dung Global Mutex cap he dieu hanh chong chay trung lap tuyet doi
# ==============================================================================

# KHOA DON PHIEN WATCHER: Dam bao chi co duy nhat 1 tien trinh watcher chay ngam
$global:WatcherMutex = New-Object System.Threading.Mutex($false, "Global\LMIGuardian_USBWatcher_SingleInstance_Mutex")
if (-not $global:WatcherMutex.WaitOne(0, $false)) {
    Exit
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = "D:\LMIGuardian_Cleaner" }
$CleanerScript = Join-Path $ScriptDir "clean_lmiguardian.ps1"

# Bien toan cuc luu thoi gian kich hoat lan cuoi (Debounce 8 giay)
$global:LastTriggerTime = [DateTime]::MinValue

# Xoa dang ky su kien cu neu co
Unregister-Event -SourceIdentifier "UsbArrivalEvent" -ErrorAction SilentlyContinue

$query = "SELECT * FROM Win32_VolumeChangeEvent WHERE EventType = 2"

# Action block tuong thich Windows 7, 8, 10, 11
$actionBlock = [scriptblock]::Create(@"
    `$now = Get-Date
    if ((`$now - `$global:LastTriggerTime).TotalSeconds -lt 8) {
        return
    }
    
    `$global:LastTriggerTime = `$now
    Start-Sleep -Seconds 2
    
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$CleanerScript`"" -WindowStyle Normal
"@)

Register-WmiEvent -Query $query -SourceIdentifier "UsbArrivalEvent" -Action $actionBlock

# Vong lap duy tri watcher
while ($true) {
    Start-Sleep -Seconds 10
}
