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

Clear-Host
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Confirm:$false -Force

## Local Variables for this script
$MachineName = "DC1" # this is the machine being configured

## DSC ps1 File to execute
$dscFileName = 'C:\_DSC\SharePoint_DSC_PowerShell_Setup_Scripts\DSC\SP-DC1\DC1-DSC.ps1'

    $root = (Split-Path (Split-Path $dscFileName -Parent) -Parent)
    Set-Location $root

## Test & load if the DSC ps1 exists
if((Test-Path $dscFileName) -eq $false) {
    $msg = "File not found at location {0}" -f $dscFileName;
    Write-Error $msg
    return
}else{
    # Load DSC Script
    Import-Module -Name $dscFileName 
}

## Load Master Variables
$commonVarsPath =  (Join-Path -Path $root -ChildPath "Common_Variables.ps1")
Import-Module $commonVarsPath

# Folder Path containing the DSC ps1 script
$dscFldrName = Split-Path $dscFileName -Parent

# Set location to DSC ps1 folder
Set-Location $dscFldrName 

# Set the name of the MOF File to be created
$outFileName = (Split-Path $dscFileName -Leaf).Split(".")[0]

# Get the folder path where the MOF fill will be saved
$outFldr = Join-Path -Path (Join-Path -Path $dscFileName.Split("\")[0] -ChildPath $dscFileName.Split("\")[1]) -ChildPath "_MOF"
$outPath = Join-Path -Path $outFldr -ChildPath $outFileName

# Generate the MOF File
$mof = DCSetupDSC -DomainAdminCredential $DomainAdminCredential -DomainName $DomainName -ConfigurationData $configData -OutputPath $outPath -Verbose
$mof

$msg = "`tMOF Files located at {0}\{1}" -f $outFldr,$outFileName
Write-Host $msg -ForegroundColor Blue

Set-Location $outPath

Start-DscConfiguration  -ComputerName $MachineName -Wait -Verbose -Force -Path $outPath