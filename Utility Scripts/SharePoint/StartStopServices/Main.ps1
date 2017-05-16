Clear-Host
# Set-location to folder SharePoint/StartStopServices

# Load depended scripts
. .\SharePoint-ServerNameList.ps1
. .\Get-RunningSPServices.ps1
. .\Stop-SPServices.ps1
. .\Start-SPServices.ps1

# List of SP services
$SPServices = @("SPAdminV4","SPTimerV4","SPTraceV4","SPUserCodeV4","SPWriterV4","SPSearch4","OSearch14","W3SVC")
$currDate = Get-Date -Format "mm-dd-yy"

New-Item -Path $transcriptionPath -ItemType file -Force 


    $rs = Get-RunningSPServices -SPServices $SPServices -Servers $Servers
    
    # Backup the returned data incase it get's over written
    $rsb = $rs

    # Below, comment out the line not being used 
     #Stop-SPServices -SPServices $rs
    Start-SPServices -SPServices $rs
