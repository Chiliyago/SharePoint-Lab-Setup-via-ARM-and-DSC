#################################################
# Author: Tim Odell
# OCSPUG Demonstration 5/17/2017
#
#	Tim@TheOdells.org
#  Twitter: @timodell
#   
#  Feel free to use, fork and improve. 
#  These are scripts I use everyday to manage my lab. 
#
#################################################
#
#
# Update the variables on the bottom of this script
# F5 to run this script anytime to get the current IP's 
# of your VM's after they are started from their Deallocated sleep.  
#
# The IP's are written to the rdg file of your
# Remote Desktop Connection Manager v2.7
#
# Make sure your Remote Desktop Connection Manager is not 
# running when you run this script or it won't be updated.
#
#

function Test-IP  
{  
    param  
    (  
        [Parameter(Mandatory=$true)]  
        [String]$ip=$null
          
    )  
    try{      
        
        # Attempt to cast 
        [IPAddress]$ip  

    } catch {
        
        # Do nothing
    }
}

function Update-RdgFileServerIP
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true, HelpMessage="Full path of Remote Desktop Connection Manager file to be updated.")]
        [string]$rdgFilePath,

        [parameter(Mandatory=$true, HelpMessage="Name of the server in RDG file to update")]
        [string] $ServerName,

        [parameter(Mandatory=$true, HelpMessage="New IP Address")]
        [string] $IP
    )

    [xml]$xml = Get-Content $rdgFilePath
    $svrNode = Select-Xml "//RDCMan/file/server/properties/displayName" -Xml $xml

    $svrNode | ForEach-Object {
        
        $svrPropertiesNode = $_.Node.ParentNode;
        
        if($svrPropertiesNode.displayName -eq $ServerName)
        {
            if($newIP = Test-IP -ip $IP)
            {
                $msg = "Updating Puplic IP on server {0} to {1}  " -f $svrPropertiesNode.displayName,$IP
                Write-Host "`t`t$msg" -ForegroundColor White
                $svrPropertiesNode.name = $IP
            
                $xml.Save($rdgFilePath)
            }
            else 
            {
                $msg = "IP address {0} is invalid!" -f $IP
            }
        }
    }
}

function Get-VmPublicIPs{
    [CmdletBinding()]
	param
	(
        [parameter(Mandatory=$true, Position=0, HelpMessage="String array of servers")]
        [string[]] $VMs,
        
        [parameter(Mandatory=$true, Position=1, HelpMessage="String array of servers")]
        [string] $ResourceGroupName,
        
        [parameter(Mandatory=$false, HelpMessage="If present will prompt Azure login")]
        [switch]$WithAzureLogin,

        [parameter(Mandatory=$false, HelpMessage="Full path of Remote Desktop Connection Manager file to be updated.")]
        [string]$rdgFilePath 

    )

$ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName
$subScriptionID = $ResourceGroup.ResourceId.Split("/")[2]

$ResourceGroupPids = Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName

if($rdgFilePath){
    [xml]$xml = Get-Content $rdgFilePath
}

# Loop thru each VM and and get public IP
foreach ($vmName in $VMs){
    $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName
    $vmNics = $vm.NetworkInterfaceIDs

    foreach($vmNic in $vmNics){

        $nicName = $vmNic.Split("/")[-1]

        Write-Host ("Seeking {0} in Resource Group PIDS" -f   $nicName ) -BackgroundColor Black -ForegroundColor Yellow
        
        foreach( $RSGrpPid in $ResourceGroupPids ){
            # Write-Host ("`t Examining {0}" -f $RSGrpPid.IpConfiguration.Id) -ForegroundColor Gray

            if($RSGrpPid.IpConfiguration.Id.Contains($nicName)){
                Write-Host ("`t`t{0} Public IP = {1}" -f $vmName,$RSGrpPid.IpAddress) -ForegroundColor White

                if($rdgFilePath){
                    if(Test-Path $rdgFilePath){
                        Update-RdgFileServerIP -rdgFilePath $rdgFilePath -ServerName $vmName -IP $RSGrpPid.IpAddress
                    }else{
                        $msg = "`tRDG File does not exist: {0}" -f $rdgFilePath
                        Write-Host $msg -BackgroundColor Black -ForegroundColor Yellow
                    }

                    Write-Host "`n"
                }

            } else {
                # Write-Host "`t`tNot Found" -ForegroundColor Gray
            }
        }
    }
}

}

#Run it

$vms = "DC1","SP-SQL1","SP-App1","SP-App2","SP-App3", "SP-Web1","SP-TestImg"
$ResourceGroupName = "Tim-0"
$rdgFilePath = "K:\OneDrive\RDP\Azure\Tim-0.rdg"
Test-Path $rdgFilePath

Get-VmPublicIPs -VMs $vms -ResourceGroupName $ResourceGroupName -rdgFilePath  $rdgFilePath -WithAzureLogin
