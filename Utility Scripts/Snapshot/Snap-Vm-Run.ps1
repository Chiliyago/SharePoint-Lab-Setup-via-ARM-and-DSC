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
cd "K:\_DSC\SharePoint_DSC_PowerShell_Setup_Scripts\Utility Scripts\Snapshot"

$vms = "DC1","SP-SQL1","SP-App1","SP-App2","SP-App3", "SP-Web1" #,"SP-SPTestImg"
$vms = "DC1","SP-SQL1","SP-App2","SP-App3", "SP-Web1" #,"SP-SPTestImg"
$ResourceGroupName = "Tim-0"

# -- DON'T Forget the NOTE! ---
###############################
$SnapNote = "Fresh SP Install. No CA or ULS Errors Reported!"
#------------------------------
. .\Snap-Vm.ps1


    Snap-VM -VMs $VMs -ResourceGroupName $ResourceGroupName -SnapNote $SnapNote -WithAzureLogin