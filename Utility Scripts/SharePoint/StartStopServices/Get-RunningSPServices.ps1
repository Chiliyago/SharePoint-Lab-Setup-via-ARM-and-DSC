Function Get-RunningSPServices
{
       [CmdletBinding()]
       param (
            [parameter(Mandatory=$true, Position=0)]
            [System.Collections.ArrayList] $SPServices,

            [parameter(Mandatory=$true, Position=1)]
            [Array] $Servers
       ) 

       <#
            .Synopsis
            Returns list of services running services.

            .Description
            Returns list of services running services by providing the services you wish
            to examine and a list of servers to scan.

            .Parameter
            $SPServices the list of SharePoint services you wish to query.
            $Servers ths list of servers you wish scanned.

            .Example
            See the Main.ps1 file in this folder 
       #>
# List of running services
$RunningServices = New-Object System.Collections.ArrayList($null)



    foreach ($Server in $Servers)
    {
  
       foreach($Service in $SPServices){
        
            $state = Get-Service -ComputerName $Server -Name $Service | Select-Object status
            $svc = "{0}/{1}/{2}" -f $Server, $Service, $state.Status 
            

            # Capture the Runing Services so they can be restarted if needed
           
            if($state.Status -eq "Running")
            {
                
                if(($RunningServices.Contains($RunningServices) -eq $false))
                {
                    $RunningServices.Add($svc) | Out-Null
                } else {

                    Write-Host "Not Added"
                }
            }
       }

       
  
    }

    Write-Host ("Captured {0} Running Services" -f (($RunningServices | Measure-Object).Count))

    return $RunningServices
}