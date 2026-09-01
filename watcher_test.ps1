# SCRIPT CHAN DOAN: Kiem tra WMI event co hoat dong khong
# Ghi ra file log khi nhan duoc su kien USB

$logFile = "D:\LMIGuardian_Cleaner\watcher_test.log"
"[$(Get-Date)] WMI test watcher khoi dong." | Out-File -FilePath $logFile -Append -Encoding UTF8

# Dang ky lang nghe su kien cham USB
$query = "SELECT * FROM Win32_VolumeChangeEvent WHERE EventType = 2"

Unregister-Event -SourceIdentifier "TestUSBArrival" -ErrorAction SilentlyContinue

Register-WmiEvent -Query $query -SourceIdentifier "TestUSBArrival" -Action {
    "[$(Get-Date)] === USB DA CAM VAO! DriveName: $($EventArgs.NewEvent.DriveName) ===" |
        Out-File -FilePath "D:\LMIGuardian_Cleaner\watcher_test.log" -Append -Encoding UTF8

    # Thu kich chay cleaner truc tiep
    try {
        Start-Process -FilePath "powershell.exe" `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"D:\LMIGuardian_Cleaner\clean_lmiguardian.ps1`"" `
            -WindowStyle Normal
        "[$(Get-Date)] Da goi clean_lmiguardian.ps1 thanh cong." |
            Out-File -FilePath "D:\LMIGuardian_Cleaner\watcher_test.log" -Append -Encoding UTF8
    } catch {
        "[$(Get-Date)] LOI khi goi cleaner: $($_.Exception.Message)" |
            Out-File -FilePath "D:\LMIGuardian_Cleaner\watcher_test.log" -Append -Encoding UTF8
    }
}

"[$(Get-Date)] Dang cho USB duoc cam vao... (WMI event da dang ky)" | 
    Out-File -FilePath $logFile -Append -Encoding UTF8

Write-Host "Test watcher dang chay. Cam USB vao roi kiem tra file: $logFile"
Write-Host "Nhan Ctrl+C de dung..."

while ($true) {
    Start-Sleep -Seconds 5
    Write-Host "." -NoNewline
}
