param(
    [string]$CsvFilePath = "C:\\Icinga2_Update_Report.csv"
)

function Write-Log {
    param ([string]$Message)
    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message"
    Write-Output $logEntry
    $logFile = "C:\\Icinga2_Update_Log.txt"
    Add-Content -Path $logFile -Value $logEntry
}

function Test-HostOnline {
    param ([string]$ComputerName)
    return Test-Connection -ComputerName $ComputerName -Count 2 -Quiet
}

function Get-Icinga2Version {
    param ([string]$ComputerName)
    $version = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        if (Test-Path "C:\\Program Files\\ICINGA2\\sbin\\icinga2.exe") {
            $firstLine = (& "C:\\Program Files\\ICINGA2\\sbin\\icinga2.exe" --version 2>$null | Select-Object -First 1)
            if ($firstLine -match ": v([\d\.]+)") { return $matches[1] } else { return "Unknown Version" }
        } else {
            return "Not Installed"
        }
    } -ErrorAction SilentlyContinue
    return $version
}

function Get-Icinga2ServiceStatus {
    param ([string]$ComputerName)
    $status = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        if (Get-Service -Name "icinga2" -ErrorAction SilentlyContinue) {
            (Get-Service -Name "icinga2").Status.ToString()
        } else {
            return "Not Installed"
        }
    } -ErrorAction SilentlyContinue
    return $status
}

function Download-Icinga2 {
    $url = "https://packages.icinga.com/windows/Icinga2-v2.14.3-x86_64.msi"
    $outputPath = "C:\\icinga2-v2.14.3.msi"
    try {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Uninstall-Icinga2 {
    param ([string]$ComputerName)
    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            $uninstallString = (Get-ItemProperty "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*" | Where-Object { $_.DisplayName -match "Icinga 2" }).UninstallString
            if ($uninstallString) {
                # Ensure silent uninstall with no pop-ups
                $uninstallString = $uninstallString -replace "msiexec.exe", ""
                Start-Process -FilePath "msiexec.exe" -ArgumentList "$uninstallString /qn /norestart" -Wait -NoNewWindow
            }
        } -ErrorAction Stop
        return $true
    } catch {
        Write-Log "WARNING: Failed to uninstall Icinga2 on $ComputerName. Skipping installation."
        return $false
    }
}

function Install-Icinga2 {
    param ([string]$ComputerName)
    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Start-Process msiexec.exe -ArgumentList "/i C:\\icinga2-v2.14.3.msi /qn" -Wait
        } -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

$ADMachines = Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name
$SUPMachines = Get-ADComputer -Filter {Name -like "*SUP*"} | Select-Object -ExpandProperty Name
$FilteredSUPMachines = $SUPMachines | Where-Object { $_ -notin $ADMachines }
$Machines = $ADMachines + $FilteredSUPMachines

Write-Log "Fetched Machines: $($Machines -join ', ')"

if (-Not (Test-Path $CsvFilePath)) {
    Write-Log "Creating CSV file with headers."
    "MachineName,Status,Icinga2Version,Icinga2Service,DownloadStatus,UninstallStatus,Icinga2Client2143" | Out-File -FilePath $CsvFilePath -Encoding UTF8
}

$Results = @()

foreach ($Machine in $Machines) {
    Write-Log "Processing Machine: $Machine"
    $status = if (Test-HostOnline -ComputerName $Machine) { "Live" } else { "Not Live" }
    Write-Log "$Machine is $status"

    $icingaVersion = "N/A"
    $icingaService = "N/A"
    $downloadStatus = "N/A"
    $uninstallStatus = "N/A"
    $installStatus = "N/A"

    if ($status -eq "Live") {
        Write-Log "Checking Icinga2 Client Version and the Icinga2 Service status"
        $icingaVersion = Get-Icinga2Version -ComputerName $Machine
        $icingaService = Get-Icinga2ServiceStatus -ComputerName $Machine
        Write-Log "INFO: $Machine - Icinga2 Version: $icingaVersion"
        Write-Log "INFO: $Machine - Icinga2 Service Sattus: $icingaService"

        if (-not $icingaVersion -or $icingaVersion -eq "Unknown Version" -or $icingaVersion -eq "Not Installed" -or [version]$icingaVersion -ge [version]"2.14.3") {
            Write-Log "INFO: Icinga2 is not installed, unable to determine version, or version is >= 2.14.3 on $Machine. Logging this machine."
            Write-Log "=========================================================================================================================="
            
            # Log machine to CSV even if skipping installation
            $Results += [PSCustomObject]@{
                MachineName = $Machine
                Status = $status
                Icinga2Version = $icingaVersion
                Icinga2Service = $icingaService
                DownloadStatus = "Not Attempted"
                UninstallStatus = "Not Attempted"
                Icinga2Client2143 = "Skipped"
            }
            continue
        }
        
        Write-Log "INFO: $Machine - Icinga2 Version: $icingaVersion"
        Write-Log "INFO: $Machine - Icinga2 Service Sattus: $icingaService"
        Write-Log "INFO: Attempting to Uninstall Icinga2 Client"
        
        $uninstallStatus = if (Uninstall-Icinga2 -ComputerName $Machine) { "Previously installed Icinga2 client uninstalled" } else { "Failed to uninstall" }
        Write-Log "$Machine - Uninstall Status: $uninstallStatus"
        
        if ($uninstallStatus -ne "Failed to uninstall") {
            $downloadStatus = if (Download-Icinga2) { "Success" } else { "Failed" }
            Write-Log "$Machine - New Icinga2 Client Download Status: $downloadStatus"
            
            if ($downloadStatus -eq "Success") {
                Write-Log "Icinga2 Client 2.14.3 downloaded successfully now will continue installing"
                $installStatus = if (Install-Icinga2 -ComputerName $Machine) { "Installed" } else { "Failed" }
                Write-Log "$Machine - Install Status: $installStatus"
                Write-Log "=========================================================================================================================="
            }
        }
    }
    
    # Ensure all machines are logged, even skipped ones
    $Results += [PSCustomObject]@{
        MachineName = $Machine
        Status = $status
        Icinga2Version = $icingaVersion
        Icinga2Service = $icingaService
        DownloadStatus = $downloadStatus
        UninstallStatus = $uninstallStatus
        Icinga2Client2143 = $installStatus
    }
}

# Export results to CSV
$Results | Export-Csv -Path $CsvFilePath -NoTypeInformation -Append
Write-Log "Script execution completed. Results saved to CSV File $CsvFilePath"
Write-Log "Please check the log file for the recorded output - C:\\Icinga2_Update_Log.txt"
