# Remotely restarts a list of servers in parallel, then validates that all auto-start services are running (example usage: patching)

## STEP 1 - Restart servers in parallel
$ServerList = @(
    "SERVER1.domain.local",
    "SERVER2.domain.local",
    "SERVER3.domain.local"
)

ForEach ($Computer in $ServerList) {
    Start-Job -Name $Computer -ArgumentList $Computer -ScriptBlock {
        Param($Computer)
        Restart-Computer -ComputerName $Computer -Force -Wait -For PowerShell
    }
}

## CHECK STEP 1 STATUS
Get-Job

## WHEN REBOOTS ARE COMPLETE, CHECK SERVICES
$Results = @()
ForEach ($Computer in $ServerList) {
    Write-Host "Checking $Computer..."
    Try {
        $Notrunning = Get-WmiObject -ComputerName $Computer -Class Win32_Service `
            -Filter "StartMode = 'Auto' AND State != 'Running' AND Name != 'SCardSvr' AND Name != 'ShellHWDetection' AND Name != 'sppsvc' AND Name != 'gupdate' AND Name != 'RemoteRegistry' AND Name != 'TrustedInstaller' AND Name != 'vmictimesync' AND Name != 'WLMS' AND Name != 'dbupdate' AND NOT Name LIKE 'clr_optimization_%'" `
            -ErrorAction Stop
    }
    Catch {
        Write-Host "     WMI failure"
        Continue
    }
    If ($Notrunning) {
        ForEach ($Service in $Notrunning) {
            Write-Host "     Starting $($Service.Caption)..."
            $Service.StartService() | Out-Null
        }
        Start-Sleep -Seconds 10
        $Final = Get-WmiObject -ComputerName $Computer -Class Win32_Service `
            -Filter "StartMode = 'Auto' AND State != 'Running' AND Name != 'SCardSvr' AND Name != 'ShellHWDetection' AND Name != 'sppsvc' AND Name != 'gupdate' AND Name != 'RemoteRegistry' AND Name != 'TrustedInstaller' AND Name != 'vmictimesync' AND Name != 'WLMS' AND Name != 'dbupdate' AND NOT Name LIKE 'clr_optimization_%'"
        ForEach ($Service in $Final) {
            $Result = [PSCustomObject]@{
                "Server"  = $Computer
                "Service" = $Service.Caption
                "State"   = $Service.State
            }
            $Results += $Result
        }
    }
    Else {
        Write-Host "     Ok!"
    }
}
If ($Results) { Write-Host "SOME SERVICES STILL AREN'T RUNNING, CHECK THE RESULTS VARIABLE!" }

## VERIFY COMPUTERS DID RESTART AT THE EXPECTED TIME
ForEach ($Computer in $ServerList) {
    Write-Host "Checking $Computer..."
    $wmi = Get-WmiObject -ComputerName $Computer -Class Win32_OperatingSystem
    Write-Host "     $($wmi.ConvertToDateTime($wmi.LastBootUpTime))"
}
