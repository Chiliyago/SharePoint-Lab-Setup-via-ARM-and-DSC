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

clear-host
cd "K:\_DSC\SharePoint_DSC_PowerShell_Setup_Scripts\Utility Scripts\Virtual Machines"
$vms = "DC1","SP-SQL1","SP-App1","SP-App2","SP-App3", "SP-Web1" ,"SP-TestImg"
#$vms = "SP-App1"


. .\StartStop-VmsAsync.ps1
    # StartStop-VmsAsync -VMs $vms -ResourceGroupName "SP2016Farm-0" -stop -WithAzureLogin
    StartStop-VmsAsync -VMs $vms -ResourceGroupName "Tim-0" -start -WithAzureLogin
    # StartStop-VmsAsync -VMs $vms -ResourceGroupName "Uday-0" -stop -WithAzureLogin
    # StartStop-VmsAsync -VMs $vms -ResourceGroupName "Saravan-1" -stop -WithAzureLogin
    # StartStop-VmsAsync -VMs $vms -ResourceGroupName "Marco-0" -start -WithAzureLogin





$vmStatus = (Get-AzureRmVM -ResourceGroupName $rscrcGrpName -Name "DC1" -Status).Statuses | select code
$vmStatus 

 # Getting the information back from the jobs
Get-Job | Receive-Job
        
# Run the following to clear jobs from cache
# Get-Job | Remove-Job