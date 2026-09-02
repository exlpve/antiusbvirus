# ==============================================================================
# TOOL: Anti USB Virus - USB Malware Cleaner (Phien ban 9.0)
# Tac gia: KN
# Description: Phat hien va tieu diet ma doc LMIGuardian/PlugX tren USB va may tinh
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$CleanMode
)

# Thiet lap ma hoa UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# KHOA DON PHIEN (SINGLE-INSTANCE MUTEX): Tuyet doi chong mo 2 cua so cung luc
$global:CleanerMutex = New-Object System.Threading.Mutex($false, "Global\AntiUSBVirus_Cleaner_SingleInstance")
if (-not $global:CleanerMutex.WaitOne(0, $false)) {
    Exit
}

# Duong dan file Log (Luu cung thu muc voi script)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = "D:\AntiUSBVirus" }
$LogFilePath = Join-Path $ScriptDir "CleanLog.txt"

# Danh sach whitelist bao ve USB An Toan ATTT
$ATTT_Whitelist = @(
    "ATTT.ico",
    "AUTORUN.INF",
    "inf.bin",
    "Mtext.bin",
    "RECYCLER",
    "System Volume Information",
    "`$RECYCLE.BIN"
)

# Ham ghi Log kem moc thoi gian
function Write-CleanLog {
    param(
        [string]$Tag,
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Tag] $Message"
    try {
        Add-Content -Path $LogFilePath -Value $logLine -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Yellow -BackgroundColor Black
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Text)
    Write-Host " [+] $Text" -ForegroundColor Green
}

function Write-WarningMsg {
    param([string]$Text)
    Write-Host " [!] $Text" -ForegroundColor Yellow
}

function Write-Danger {
    param([string]$Text)
    Write-Host " [-] $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host " [*] $Text" -ForegroundColor Cyan
}

# Ham tom tat noi dung file & thu muc tren USB (Gom nhom thu muc me 1 lan)
function Get-UsbContentSummary {
    param([string]$DriveRoot)
    
    $resultList = [System.Collections.Generic.List[string]]::new()
    
    try {
        $rootEntries = [System.IO.Directory]::GetFileSystemEntries($DriveRoot)
        
        # 1. Cac file rieng le o goc USB (neu co)
        foreach ($entry in $rootEntries) {
            $eName = [System.IO.Path]::GetFileName($entry)
            if ($ATTT_Whitelist -contains $eName) { continue }
            $trimmed = $eName.Trim([char]32, [char]160, [char]8203, [char]9, [char]10, [char]13, [char]0)
            if ($trimmed.Length -eq 0 -or $eName -eq "..." -or $eName -eq "__") { continue }
            
            if ([System.IO.File]::Exists($entry)) {
                $resultList.Add($eName)
            }
        }
        
        # 2. Cac thu muc goc va liet ke cac file con ben trong gom nhom: ThuMucMe (file1, file2, ...)
        foreach ($entry in $rootEntries) {
            $eName = [System.IO.Path]::GetFileName($entry)
            if ($ATTT_Whitelist -contains $eName) { continue }
            $trimmed = $eName.Trim([char]32, [char]160, [char]8203, [char]9, [char]10, [char]13, [char]0)
            if ($trimmed.Length -eq 0 -or $eName -eq "..." -or $eName -eq "__") { continue }
            
            if ([System.IO.Directory]::Exists($entry)) {
                $subItems = [System.Collections.Generic.List[string]]::new()
                try {
                    $subEntries = [System.IO.Directory]::GetFileSystemEntries($entry)
                    foreach ($sub in $subEntries) {
                        $sName = [System.IO.Path]::GetFileName($sub)
                        $sTrim = $sName.Trim([char]32, [char]160, [char]8203, [char]9, [char]10, [char]13, [char]0)
                        if ($sTrim.Length -gt 0 -and $sName -ne "..." -and $sName -ne "__") {
                            $subItems.Add($sName)
                        }
                    }
                } catch {}
                
                if ($subItems.Count -gt 0) {
                    $resultList.Add("$eName (" + [string]::Join(", ", $subItems) + ")")
                } else {
                    $resultList.Add("$eName (Thu muc rong)")
                }
            }
        }
    } catch {}
    
    if ($resultList.Count -eq 0) {
        return "Danh sach: (USB trong hoac chi co file he thong ATTT)"
    }
    
    return "Danh sach: " + [string]::Join(", ", $resultList)
}

# Ham lay day du chuoi thong tin USB (Thong so phan cung + Danh sach gom nhom)
function Get-UsbDetailString {
    param($usbObj)
    $dLetter = $usbObj.DeviceID
    $dRoot = "$dLetter\"
    $vName = if ($usbObj.VolumeName) { $usbObj.VolumeName } else { "Khong ten" }
    $fs = if ($usbObj.FileSystem) { $usbObj.FileSystem } else { "Chua xac dinh" }
    $sizeGB = if ($usbObj.Size) { [math]::Round($usbObj.Size / 1GB, 2) } else { 0 }
    $freeGB = if ($usbObj.FreeSpace) { [math]::Round($usbObj.FreeSpace / 1GB, 2) } else { 0 }
    $serial = if ($usbObj.VolumeSerialNumber) { $usbObj.VolumeSerialNumber } else { "N/A" }
    
    $contentSummary = Get-UsbContentSummary -DriveRoot $dRoot
    
    return "O dia: $dLetter | Nhan: $vName | Dinh dang: $fs | Dung luong: $sizeGB GB (Con trong: $freeGB GB) | Serial: $serial | $contentSummary"
}

# Kiem tra quyen Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# ==============================================================================
# CHE DO 1: QUET KIEM TRA TRUOC (SCAN MODE - KHONG CAN QUYEN ADMIN)
# ==============================================================================
if (-not $CleanMode -and -not $isAdmin) {
    Clear-Host
    Write-Header "ANTI USB VIRUS - QUET KIEM TRA MA DOC TREN MAY TINH & USB"
    Write-Host " Phien ban: 9.0 | LMIGuardian / PlugX USB Malware Cleaner" -ForegroundColor Gray
    Write-Host " Tac gia: KN" -ForegroundColor Gray
    Write-Host " Nguoi dung: $env:USERNAME | May: $env:COMPUTERNAME" -ForegroundColor Gray
    Write-Host ""

    # Ghi thong tin USB ket noi vao Log
    $usbDrives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=2" -ErrorAction SilentlyContinue
    if ($usbDrives) {
        foreach ($usb in $usbDrives) {
            $usbInfoStr = Get-UsbDetailString -usbObj $usb
            Write-CleanLog -Tag "USB_KET_NOI" -Message "$usbInfoStr"
        }
    } else {
        Write-CleanLog -Tag "USB_KET_NOI" -Message "Khong co o dia USB nao dang ket noi."
    }

    $detectedThreats = [System.Collections.Generic.List[string]]::new()

    # 1. Quet tien trinh RAM
    Write-Info "1/4. Dang kiem tra tien trinh dang chay tren RAM..."
    $targetProcessNames = @("LMIGuardianSvc", "LMIGuardian", "LMIGuardianSvc.exe")
    foreach ($pName in $targetProcessNames) {
        $procs = Get-Process -Name $pName -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($p in $procs) {
                try { $pPath = $p.MainModule.FileName } catch { $pPath = "Khong ro" }
                if ($pPath -notlike "*Program Files*LogMeIn*") {
                    $msg = "Tien trinh ma doc tren RAM: $($p.Name) (PID: $($p.Id))"
                    $detectedThreats.Add($msg)
                    Write-Danger "$msg"
                    Write-CleanLog -Tag "PHAT_HIEN" -Message "$msg"
                }
            }
        }
    }

    # 2. Quet Registry Run
    Write-Info "2/4. Dang kiem tra khoa Registry khoi dong..."
    $runKeys = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
    foreach ($keyPath in $runKeys) {
        if (Test-Path $keyPath) {
            $props = Get-ItemProperty -Path $keyPath -ErrorAction SilentlyContinue
            if ($props) {
                foreach ($prop in $props.PSObject.Properties) {
                    $name = $prop.Name
                    $val = [string]$prop.Value
                    # Bo qua key cua chinh tool nay (tranh tu xoa ban than)
                    if ($name -eq "LMIGuardian_USBWatcher") { continue }
                    if ($name -notmatch "^PS" -and ($val -match "LMIGuardian" -or $name -match "LMIGuardian" -or $val -match "Docusment")) {
                        if ($val -notlike "*Program Files*LogMeIn*") {
                            $msg = "Khoa Registry khoi dong: [$keyPath] $name = $val"
                            $detectedThreats.Add($msg)
                            Write-Danger "$msg"
                            Write-CleanLog -Tag "PHAT_HIEN" -Message "$msg"
                        }
                    }
                }
            }
        }
    }

    # 3. Quet file ma doc tren PC (loai tru Recent va thu muc tool)
    Write-Info "3/4. Dang quet file ma doc tren cac thu muc tam may tinh..."
    $dirsToScan = @("$env:ProgramData", "$env:SystemDrive\Users\Public", $env:TEMP, $env:APPDATA, $env:LOCALAPPDATA)
    foreach ($d in $dirsToScan) {
        if (Test-Path $d) {
            try {
                $badOnPc = Get-ChildItem -Path $d -Filter "*LMIGuardian*" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
                    $_.FullName -notlike "*Program Files*LogMeIn*" -and
                    $_.FullName -notmatch "AntiUSBVirus" -and
                    $_.FullName -notmatch "clean_lmiguardian" -and
                    $_.FullName -notlike "*\Microsoft\Windows\Recent\*"
                }
                foreach ($b in $badOnPc) {
                    $msg = "File/Thu muc ma doc tren PC: $($b.FullName)"
                    $detectedThreats.Add($msg)
                    Write-Danger "$msg"
                    Write-CleanLog -Tag "PHAT_HIEN" -Message "$msg"
                }
            } catch {}
        }
    }

    # 4. Quet tren cac o dia USB
    Write-Info "4/4. Dang quet kiem tra cac o dia USB dang ket noi..."
    if ($usbDrives) {
        foreach ($usb in $usbDrives) {
            $dLetter = $usb.DeviceID
            $dRoot = "$dLetter\"
            $usbInfoStr = Get-UsbDetailString -usbObj $usb
            
            Write-Host ""
            Write-Host ">>> THONG TIN USB: $usbInfoStr <<<" -ForegroundColor Yellow
            
            # Quet shortcut .lnk
            try {
                $lnks = [System.IO.Directory]::GetFiles($dRoot, "*.lnk")
                foreach ($l in $lnks) {
                    $msg = "Shortcut gia mao tren USB $($dLetter): $([System.IO.Path]::GetFileName($l))"
                    $detectedThreats.Add($msg)
                    Write-Danger "$msg"
                    Write-CleanLog -Tag "PHAT_HIEN" -Message "$msg"
                }
            } catch {}

            # Quet thu muc Docusment
            try {
                $dirs = [System.IO.Directory]::GetDirectories($dRoot)
                foreach ($dr in $dirs) {
                    $drName = [System.IO.DirectoryInfo]::new($dr).Name
                    if ($drName -match "^(Docusment|Document|Documents)$" -or $drName -match "LMIGuardian") {
                        $msg = "Thu muc ma doc tren USB $($dLetter): $drName"
                        $detectedThreats.Add($msg)
                        Write-Danger "$msg"
                        Write-CleanLog -Tag "PHAT_HIEN" -Message "$msg"
                    }
                    
                    # Quet thu muc khong ten trong thu muc me
                    if ($ATTT_Whitelist -notcontains $drName) {
                        try {
                            $subDirs = [System.IO.Directory]::GetDirectories($dr)
                            foreach ($sd in $subDirs) {
                                $sName = [System.IO.DirectoryInfo]::new($sd).Name
                                $sTrim = $sName.Trim([char]32, [char]160, [char]8203, [char]9, [char]10, [char]13, [char]0)
                                if ($sTrim.Length -eq 0 -or $sName -eq "..." -or $sName -eq "__") {
                                    $msg = "Thu muc khong ten (giau file) trong [$drName] tren USB $($dLetter)"
                                    $detectedThreats.Add($msg)
                                    Write-Danger "$msg"
                                    Write-CleanLog -Tag "PHAT_HIEN" -Message "$msg"
                                }
                            }
                        } catch {}
                    }
                }
            } catch {}
        }
    } else {
        Write-Info "Hien khong co o dia USB nao dang ket noi."
    }

    # DANH GIA KET QUA QUET
    Write-Host ""
    if ($detectedThreats.Count -eq 0) {
        Write-Header "KET QUA: HE THONG VA USB HOAN TOAN SACH SE"
        Write-Success "Khong phat hien bat ky dau hieu ma doc LMIGuardian hay Shortcut nao!"
        Write-Success "May tinh va USB cua ban da an toan tuyet doi."
        Write-CleanLog -Tag "KET_QUA" -Message "He thong va USB hoan toan sach se 100%. Khong co ma doc."
        Write-Host "Nhan phim bat ky de thoat..." -ForegroundColor Gray
        try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host }
        Exit
    } else {
        Write-Header "CANH BAO: PHAT HIEN $($detectedThreats.Count) NGUY CO MA DOC!"
        Write-WarningMsg "Can duoc cap quyen Administrator de tieu diet triet de va cuu du lieu."
        Write-Info "Dang khoi chay hop thoai xin quyen Administrator (UAC)..."
        
        Start-Sleep -Seconds 2
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -CleanMode" -Verb RunAs
        Exit
    }
}

# ==============================================================================
# CHE DO 2: DIET MA DOC & CUU DU LIEU (CLEAN MODE - QUYEN ADMINISTRATOR)
# ==============================================================================
Clear-Host
Write-Header "ANTI USB VIRUS - TIEU DIET MA DOC & CUU DU LIEU (QUYEN ADMINISTRATOR)"
Write-Host " Phien ban: 9.0 | LMIGuardian / PlugX USB Malware Cleaner" -ForegroundColor Gray
Write-Host " Tac gia: KN" -ForegroundColor Gray
Write-Host " Thoi gian xu ly: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host ""

$report = @{
    KilledProcesses = 0
    DeletedHostFiles = 0
    CleanedRegistry = 0
    CleanedTasks = 0
    ProcessedUSBDrives = 0
    DeletedUSBShortcuts = 0
    DeletedUSBPayloads = 0
    RestoredFilesCount = 0
}

# GIAI DOAN 1: DIET TREN MAY TINH
Write-Header "1. DUNG TIEN TRINH MA DOC TREN RAM"
$targetProcessNames = @("LMIGuardianSvc", "LMIGuardian", "LMIGuardianSvc.exe")
foreach ($procName in $targetProcessNames) {
    $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($p in $procs) {
            try { $pPath = $p.MainModule.FileName } catch { $pPath = "Khong ro" }
            if ($pPath -notlike "*Program Files*LogMeIn*") {
                try {
                    Stop-Process -Id $p.Id -Force -ErrorAction Stop
                    Write-Success "Da buoc dung tien trinh PID $($p.Id) (Path: $pPath)"
                    Write-CleanLog -Tag "DA_DUNG_TIEN_TRINH" -Message "PID $($p.Id) (Path: $pPath)"
                    $report.KilledProcesses++
                } catch {}
            }
        }
    }
}
if ($report.KilledProcesses -eq 0) {
    Write-Info "RAM sach: Khong co tien trinh ma doc dang chay."
}

Write-Header "2. XOA KHOA REGISTRY VA SCHEDULED TASK"
$runKeys = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run", "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run")
foreach ($keyPath in $runKeys) {
    if (Test-Path $keyPath) {
        $props = Get-ItemProperty -Path $keyPath -ErrorAction SilentlyContinue
        if ($props) {
            foreach ($prop in $props.PSObject.Properties) {
                $name = $prop.Name
                $val = [string]$prop.Value
                # Bo qua key cua chinh tool nay (tranh tu xoa ban than)
                if ($name -eq "LMIGuardian_USBWatcher") { continue }
                if ($name -notmatch "^PS" -and ($val -match "LMIGuardian" -or $name -match "LMIGuardian" -or $val -match "Docusment")) {
                    if ($val -notlike "*Program Files*LogMeIn*") {
                        try {
                            Remove-ItemProperty -Path $keyPath -Name $name -Force -ErrorAction Stop
                            Write-Success "Da xoa Registry Run: [$keyPath] $name = $val"
                            Write-CleanLog -Tag "DA_XOA_REGISTRY" -Message "[$keyPath] $name = $val"
                            $report.CleanedRegistry++
                        } catch {}
                    }
                }
            }
        }
    }
}

# Xoa Scheduled Task lien quan LMIGuardian (dung schtasks.exe - tuong thich Win7+)
try {
    $taskList = schtasks.exe /query /fo CSV /nh 2>$null | ConvertFrom-Csv -Header TaskName,NextRun,Status -ErrorAction SilentlyContinue
    if ($taskList) {
        foreach ($t in $taskList) {
            $tName = $t.TaskName -replace "^\\\\",""
            if ($tName -match "LMIGuardian" -and $tName -ne "AutoUSB_Malware_Guard") {
                schtasks.exe /delete /tn $tName /f 2>$null | Out-Null
                Write-Success "Da xoa Scheduled Task: $tName"
                Write-CleanLog -Tag "DA_XOA_TASK" -Message "$tName"
                $report.CleanedTasks++
            }
        }
    }
} catch {}

Write-Header "3. QUET & XOA FILE MA DOC TREN CAC O DIA HE THONG"
$dirsToClean = @("$env:ProgramData", "$env:SystemDrive\Users\Public", $env:TEMP, $env:APPDATA, $env:LOCALAPPDATA)
foreach ($dir in $dirsToClean) {
    if (Test-Path $dir) {
        try {
            $badFiles = Get-ChildItem -Path $dir -Filter "*LMIGuardian*" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.FullName -notlike "*Program Files*LogMeIn*" -and
                $_.FullName -notmatch "AntiUSBVirus" -and
                $_.FullName -notmatch "clean_lmiguardian" -and
                $_.FullName -notlike "*\Microsoft\Windows\Recent\*"
            }
            foreach ($bf in $badFiles) {
                try {
                    Set-ItemProperty -Path $bf.FullName -Name Attributes -Value "Normal" -ErrorAction SilentlyContinue
                    Remove-Item -Path $bf.FullName -Force -Recurse -ErrorAction Stop
                    Write-Success "Da tieu diet file PC: $($bf.FullName)"
                    Write-CleanLog -Tag "DA_XOA_FILE_PC" -Message "$($bf.FullName)"
                    $report.DeletedHostFiles++
                } catch {}
            }
        } catch {}
    }
}

# GIAI DOAN 2: XU LY USB
Write-Header "4. XU LY USB - TIEU DIET MA DOC & CUU DU LIEU VE THU MUC ME"
$usbDrives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=2" -ErrorAction SilentlyContinue

if ($usbDrives) {
    foreach ($usb in $usbDrives) {
        $dLetter = $usb.DeviceID
        $dRoot = "$dLetter\"
        $report.ProcessedUSBDrives++
        $usbDetail = Get-UsbDetailString -usbObj $usb

        Write-Host ""
        Write-Host ">>> XU LY USB: $dLetter <<<" -ForegroundColor Yellow -BackgroundColor DarkBlue
        Write-Host "Chi tiet: $usbDetail" -ForegroundColor Cyan

        # 4.1 Xoa Shortcut .lnk
        try {
            $rootLnks = [System.IO.Directory]::GetFiles($dRoot, "*.lnk")
            foreach ($lp in $rootLnks) {
                $lnkName = [System.IO.Path]::GetFileName($lp)
                try {
                    [System.IO.File]::SetAttributes($lp, [System.IO.FileAttributes]::Normal)
                    [System.IO.File]::Delete($lp)
                    Write-Success "-> Da xoa Shortcut tren USB $($dLetter): $lp"
                    Write-CleanLog -Tag "DA_XOA_SHORTCUT_USB" -Message "USB $($dLetter) : $lp"
                    $report.DeletedUSBShortcuts++
                } catch {}
            }
        } catch {}

        # 4.2 Xoa thu muc ma doc Docusment / LMIGuardian
        try {
            $topDirs = [System.IO.Directory]::GetDirectories($dRoot)
            foreach ($dp in $topDirs) {
                $dName = [System.IO.DirectoryInfo]::new($dp).Name
                if ($ATTT_Whitelist -contains $dName) { continue }

                $isMal = $false
                if ($dName -match "^(Docusment|Document|Documents)$" -or $dName -match "LMIGuardian") {
                    $isMal = $true
                }

                if ($isMal) {
                    try {
                        [System.IO.File]::SetAttributes($dp, [System.IO.FileAttributes]::Normal)
                        Remove-Item -Path $dp -Force -Recurse -ErrorAction Stop
                        Write-Success "-> Da tieu diet thu muc ma doc: $dp"
                        Write-CleanLog -Tag "DA_XOA_THU_MUC_MA_DOC" -Message "USB $($dLetter) : $dp"
                        $report.DeletedUSBPayloads++
                    } catch {
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c attrib -s -h -r `"$dp`" & rd /s /q `"$dp`"" -NoNewWindow -Wait
                        Write-Success "-> Da xoa qua CMD: $dp"
                        Write-CleanLog -Tag "DA_XOA_THU_MUC_MA_DOC" -Message "USB $($dLetter) : $dp"
                        $report.DeletedUSBPayloads++
                    }
                }
            }
        } catch {}

        # 4.3 Cuu du lieu tu thu muc khong ten ve Thu muc me (KIEMNGU260)
        try {
            $validDirs = [System.IO.Directory]::GetDirectories($dRoot)
            foreach ($parentPath in $validDirs) {
                $parentName = [System.IO.DirectoryInfo]::new($parentPath).Name
                if ($ATTT_Whitelist -contains $parentName) { continue }

                $trimP = $parentName.Trim([char]32, [char]160, [char]8203, [char]9, [char]10, [char]13, [char]0)
                if ($trimP.Length -gt 0 -and $parentName -ne "..." -and $parentName -ne "__") {
                    Write-Info "Kiem tra Thu muc me: [$parentName] tren USB $dLetter..."

                    # Xoa shortcut trong thu muc me
                    try {
                        $subLnks = [System.IO.Directory]::GetFiles($parentPath, "*.lnk")
                        foreach ($sl in $subLnks) {
                            [System.IO.File]::SetAttributes($sl, [System.IO.FileAttributes]::Normal)
                            [System.IO.File]::Delete($sl)
                            $slName = [System.IO.Path]::GetFileName($sl)
                            Write-Success "-> Da xoa shortcut trong $($parentName): $slName"
                            Write-CleanLog -Tag "DA_XOA_SHORTCUT_USB" -Message "USB $($dLetter) [$parentName] : $sl"
                        }
                    } catch {}

                    # Quet thu muc con khong ten
                    try {
                        $subDirs = [System.IO.Directory]::GetDirectories($parentPath)
                        foreach ($subPath in $subDirs) {
                            $sName = [System.IO.DirectoryInfo]::new($subPath).Name
                            $sTrim = $sName.Trim([char]32, [char]160, [char]8203, [char]9, [char]10, [char]13, [char]0)

                            if ($sTrim.Length -eq 0 -or $sName -eq "..." -or $sName -eq "__") {
                                Write-WarningMsg "PHAT HIEN THU MUC KHONG TEN TRONG [$parentName]: $subPath"
                                Write-Info "Dang di chuyen toan bo file ve truc tiep [$parentName] tren USB $dLetter..."

                                $entries = [System.IO.Directory]::GetFileSystemEntries($subPath)
                                foreach ($entry in $entries) {
                                    try {
                                        [System.IO.File]::SetAttributes($entry, [System.IO.FileAttributes]::Normal)
                                        $eName = [System.IO.Path]::GetFileName($entry)
                                        $destPath = Join-Path $parentPath $eName
                                        Move-Item -Path $entry -Destination $destPath -Force -ErrorAction Stop
                                        Write-Success "-> Da cuu ve [$parentName] (USB $($dLetter)): $eName"
                                        Write-CleanLog -Tag "DA_CUU_DU_LIEU" -Message "USB $($dLetter) -> [$parentName] : $eName"
                                        $report.RestoredFilesCount++
                                    } catch {
                                        Write-Danger "Loi khi chuyen $($eName): $($_.Exception.Message)"
                                    }
                                }

                                # Xoa thu muc khong ten rong
                                try {
                                    [System.IO.File]::SetAttributes($subPath, [System.IO.FileAttributes]::Normal)
                                    Remove-Item -Path $subPath -Force -Recurse -ErrorAction Stop
                                    Write-Success "-> DA XOA THU MUC KHONG TEN RONG."
                                    Write-CleanLog -Tag "DA_XOA_THU_MUC_AN" -Message "USB $($dLetter) : $subPath"
                                } catch {
                                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c rd /s /q `"$subPath`"" -NoNewWindow -Wait
                                    Write-CleanLog -Tag "DA_XOA_THU_MUC_AN" -Message "USB $($dLetter) : $subPath"
                                }
                            }
                        }
                    } catch {}

                    # Bo thuoc tinh an cho toan bo file trong thu muc me
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c attrib -s -h -r `"$parentPath\*`" /s /d" -NoNewWindow -Wait
                    Write-Success "-> Da go bo thuoc tinh an cho toan bo du lieu trong [$parentName] (USB $($dLetter))!"
                }
            }
        } catch {}
    }
}

# TONG KET BAO CAO
Write-Header "KET QUA TONG KET DANG XU LY"
Write-Host "  - So tien trinh da tieu diet      : $($report.KilledProcesses)" -ForegroundColor Cyan
Write-Host "  - So khoa Registry da lam sach    : $($report.CleanedRegistry)" -ForegroundColor Cyan
Write-Host "  - So file/thu muc PC da tieu diet : $($report.DeletedHostFiles)" -ForegroundColor Cyan
Write-Host "  - So Shortcut .lnk da xoa tren USB: $($report.DeletedUSBShortcuts)" -ForegroundColor Cyan
Write-Host "  - So thu muc ma doc USB da xoa    : $($report.DeletedUSBPayloads)" -ForegroundColor Cyan
Write-Host "  - So file da cuu ve thu muc me    : $($report.RestoredFilesCount)" -ForegroundColor Green
Write-Host ("=" * 70) -ForegroundColor Cyan
Write-Host ""
Write-Success "HOAN TAT! Qua trinh kiem tra va xu ly da hoan thanh thanh cong."
Write-CleanLog -Tag "KET_QUA" -Message "Hoan tat xu ly. Tong file cuu: $($report.RestoredFilesCount), File PC xoa: $($report.DeletedHostFiles), Shortcut xoa: $($report.DeletedUSBShortcuts), Thu muc ma doc xoa: $($report.DeletedUSBPayloads)"
Write-Host "Nhan phim bat ky de thoat..." -ForegroundColor Gray
try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Read-Host }
Exit
