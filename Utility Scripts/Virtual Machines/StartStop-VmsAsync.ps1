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
function StartStop-VmsAsync{
    
    [CmdletBinding()]
	param
	(
        

        [parameter(Mandatory=$true, Position=0, HelpMessage="String array of servers")]
        [string[]] $VMs,
        
        [parameter(Mandatory=$true, Position=1, HelpMessage="String array of servers")]
        [string] $ResourceGroupName,
        
        [parameter(Mandatory=$false, HelpMessage="If present will prompt Azure login")]
        [switch]$WithAzureLogin,

        [switch]$stop,

        [switch]$start


	)
    <#
        .Synopsis
            This function either Starts or Stops Azure Virtual Machines Asyncronously
        
        .Description
            Supply a string array of VM names and the Azure Resource Group and each VM will 
            either start or stop asyncronously.  

            Optionally include the -@WithAzureLogin and you will get prompted to login to
            your Azure tenant

            This function save your Azure login credentials into a file named AzureProfile.json
            That file is loaded by each job in order to login to the tenant and execute the 
            Start/Stop-AzureRMVm cmdlet.
        
        .Parameter
            -VMs : a string array of VM's to be operated on
            -ResourceGroupName: The name of the Resource Group where the VM's reside
            -WithAzureLogin: flag that will prompt you to log innto your Azure Tenant
            -stop: flag to stop the VM's (mutually exlusive to the -start flag)
            -start: flag to start the VM's (mutually exlusive to the -stop flag)


        .Output
            This function will save your Azure login credentials into a file named AzureProfile.json
            That file is created on each execution of the function and loaded by each job in 
            order to login to the tenant and execute the Start/Stop-AzureRMVm cmdlet.

        .Example
            ------------------------------------------------------------------------------------------------
            First create an array of VM's
            One async job will be created for each VM
            
            $vms = "DC1","SP-SQL1","SP-App1","SP-App2","SP-App3","SP-Web1"
            
                      

            ------------------------------------------------------------------------------------------------
            This example will stop all the VM's WITHOUT Azure login prompt
                StartStop-VmsAsync -VMs $vms -ResourceGroupName "My Resource Group" -stop

            This example will start all the VM's WITHOUT Azure login prompt 
                StartStop-VmsAsync -VMs $vms -ResourceGroupName "My Resource Group" -start



            This example will stop all the VM's WITH Azure login prompt
                StartStop-VmsAsync -VMs $vms -ResourceGroupName "My Resource Group" -stop -WithAzureLogin

            This example will start all the VM's WITH Azure login prompt 
                StartStop-VmsAsync -VMs $vms -ResourceGroupName "My Resource Group" -start -WithAzureLogin

            ------------------------------------------------------------------------------------------------
            Once the StartStop-VmsAsync cmdlet is run you can return the results using the following cmdlets
            
            Get the status of each start/stop job
            Get-Job 

            Return the results of each start/stop job
            Get-Job | Receive-Job

            Run the following to clear jobs from cache
            Get-Job | Remove-Job
    #>

    # Test if both -start & -stop flags are present simultaniously
    if( $stop -and $start ){
        Write-Error "-start and -stop flags cannot exist simultaniously. They are mutually exlusive!"
        return
    }

    # Check if -start or -stop flag is present
    $hasStopOrStartFlag = $false

        if($stop){
            $hasStopOrStartFlag = $true
        }elseif($start){
            $hasStopOrStartFlag = $true
        }

        if($hasStopOrStartFlag -eq $false)
        {
            Write-Error "You must have either a -start or -stop flag when calling this function"
            return
        }


    if( $WithAzureLogin ){
         Login-AzureRmAccount
    }
    
    $azureAcctPath = (Join-Path (Get-Item -Path ".\" -Verbose).FullName -ChildPath "AzureProfile.json")
    
    Save-AzureRmProfile -Path $azureAcctPath -Force 
    
    
    # Container to hold all the async jobs 
    $jobs = @()
    

    # Loop thru each VM and perform start/stop on each
    foreach ($vmName in $VMs){

        $update = "Working on vm {0}" -f $vmName
        Write-Host $update -ForegroundColor White

        $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name "SP-TestImg" -ErrorAction Ignore -Status

        <#
        if($vm -eq $null){
            Write-Host ("`tVM {0} not found!" -f $vmName)
            continue
        }
        #>

        # params to be fed into each Start-Job
        $params = $($vmName, $ResourceGroupName, $azureAcctPath)

        # Select the status of each VM in the resource group
        
        $vmStatus = (Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName -Status).Statuses | select code
        
        # Determine if the VM stopped
        $VmIsStopped = `
                ($vmStatus.Code -contains "PowerState/deallocated") `
            -or ($vmStatus.Code -contains "PowerState/deallocating") `
            -or ($vmStatus.Code -contains "PowerState/stopping") `
            # -or ($vmStatus.Code -contains "PowerState/stopped" ) 
            
            
                    

        if($VmIsStopped){
                
            if($start){

                $update = "`tStarting {0}" -f $vmName
                Write-Host $update -ForegroundColor Green

                $job = Start-Job -ScriptBlock{
                    param($vmName, $rsName, $azureProfilePath)

                    $msg = ("Starting {0} in Resource Group  {1} using saved Azure profile located at {2}") -f $vmName, $rsName, $azureProfilePath
                    Write-Host $msg
                    
                    Select-AzureRmProfile -Path $azureProfilePath  
                    
                    Start-AzureRmVM -ResourceGroupName $rsName -Name $vmName -Verbose

            
                } -ArgumentList $params

                $jobs += $job

            }else {

                $update = "`t{0} already stopped" -f $vm.Name
                Write-Host $update -ForegroundColor Yellow

            }

            
        } else {

            if($stop){

                $update = "`tStopping {0}" -f $vm.Name
                Write-Host $update -ForegroundColor Red

                $job = Start-Job -ScriptBlock{
                    param($vmName, $rsName, $azureProfilePath)

                    $msg = ("Stopping {0} in Resource Group  {1} using saved Azure profile located at {2}") -f $vmName, $rsName, $azureProfilePath
                    Write-Host $msg
                    
                    Select-AzureRmProfile -Path $azureProfilePath 

                    Stop-AzureRmVM -ResourceGroupName $rsName -Name $vmName -Confirm:$false -Force -Verbose
            
                } -ArgumentList $params

                $jobs += $job

            
            }  else {
            
                $update = "`t{0} already running" -f $vm
                Write-Host $update -ForegroundColor Yellow
            }               
               
        }

        
    }   
    
    
    $jobCount = ($jobs | Measure-Object).Count
   

    if($jobCount -eq 0)
    {
        Write-Host "No jobs running" -ForegroundColor Yellow

    } else {
        
        $update = "`n{0} Jobs are currently running." -f $VMs.Count;
        Write-Host $update -ForegroundColor Yellow

        Write-Host "`tExecute [ Wait-Job ] cmdlet to be notified when jobs are completed"
        Write-Host "`tExecute [ Get-Job ]  cmdlet to get status of job progress"
        Write-Host "`n`tExecute [ Get-Job | Receive-Job ] to get results of each job"
        Write-Host "`tExecute [ Get-Job | Remove-Job ]  to remove jobs from cache once completed"
    }

    

}