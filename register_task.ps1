$s = New-Object -ComObject Schedule.Service
$s.Connect()
$f = $s.GetFolder('\')

try {
    $f.DeleteTask('AutoUSB_Malware_Guard', 0)
    Write-Host '[*] Da xoa task cu.'
} catch {
    Write-Host '[*] Khong co task cu can xoa.'
}

$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>KN</Author>
    <Description>Tu dong quet diet ma doc LMIGuardian PlugX moi khi USB cam vao may</Description>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <Delay>PT1M</Delay>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "D:\LMIGuardian_Cleaner\usb_watcher.ps1"</Arguments>
    </Exec>
  </Actions>
</Task>
"@

$task = $s.NewTask(0)
$task.XmlText = $xml

# 6 = TASK_CREATE_OR_UPDATE, 0 = TASK_LOGON_NONE (Windows tu xac dinh nguoi dung tu phien hien tai)
try {
    $f.RegisterTaskDefinition('AutoUSB_Malware_Guard', $task, 6, $null, $null, 0, $null) | Out-Null
    Write-Host '[+] Dang ky Task Scheduler bang COM Object thanh cong!'
    Write-Host '[+] - DisallowStartIfOnBatteries = false (hoat dong ca khi dung pin)'
    Write-Host '[+] - MultipleInstancesPolicy = IgnoreNew (chi 1 phien duy nhat)'
    Write-Host '[+] - ExecutionTimeLimit = khong gioi han'
} catch {
    Write-Host "[!] Dang ky COM that bai: $($_.Exception.Message)"
    Write-Host "[*] Thu phuong an du phong: schtasks.exe..."
    $watcherPath = 'D:\LMIGuardian_Cleaner\usb_watcher.ps1'
    schtasks.exe /delete /tn 'AutoUSB_Malware_Guard' /f 2>$null
    schtasks.exe /create /tn 'AutoUSB_Malware_Guard' /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watcherPath`"" /sc onlogon /it /delay 0001:00 /f
    Write-Host '[+] Da dang ky qua schtasks.exe (phuong an du phong).'
}
