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

function Snap-VM{

    [CmdletBinding()]
	param
    (

        [CmdletBinding()]
        [parameter(Mandatory=$true, Position=0, HelpMessage="String array of servers")]
        [string[]] $VMs,
        
        [parameter(Mandatory=$true, Position=1, HelpMessage="String array of servers")]
        [string] $ResourceGroupName,
        
        [parameter(Mandatory=$false, HelpMessage="If present will prompt Azure login")]
        [switch]$WithAzureLogin,

        [parameter(Mandatory=$true, HelpMessage="Snap Note will be added to the metadata of the VM's OS blob")]
        [string] $SnapNote
    )

    <#
        .Synopsis
        Creates a snapshot of the provided Virtual Machine's OsDisk and adds meta-data
        entry on the OsDisk blob.

        .Description
        Creates a snapshot of the provided Virtual Machine's OsDisk and adds meta-data
        entry on the OsDisk blob containg the name of the snapshot and a note you wish
        to add about that snapshot.  The note will help you identify the snapshot so you
        easily find it for restoration.

        .Parameter
        $VMs - The list of VM's you wish to snap

        .Parameter
        $ResourceGroupName - Resource Group name where the VM's reside

        .Parameter
        WithAzureLogin - Will initiate Azure login

        .Parameter 
        $SnapNote - the note you wish to add to the OsDisc's blob metadata.
    #>

    if( $WithAzureLogin ){
         Login-AzureRmAccount
    }

    $azureAcctPath = (Join-Path (Get-Item -Path ".\" -Verbose).FullName -ChildPath "AzureProfile.json")
    Save-AzureRmProfile -Path $azureAcctPath -Force 
    

    # Loop thru each VM and perform start/stop on each
    foreach ($vmName in $VMs){

        $update = "Working on vm {0}" -f $vmName
        write-host $update -ForegroundColor White

        $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $vmName

        # Get the Uri of the OS Disk
        $osBlobUri = [System.Uri]$vm.StorageProfile.OsDisk.Vhd.Uri
        
        # Extract OS Disk Blob Name
        $osBlobName = $osBlobUri.PathAndQuery.Split("/")[-1]

        # Get storage account where OS Disk Blob resides
        $vmStrgAcct = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name ($osBlobUri.Authority.Split(".")[0])

        # Get the storage account key
        $vmStrgAcctKey = ($vmStrgAcct | Get-AzureRmStorageAccountKey)[0].Value

        # Get Storage account contex
        $vmStrgCtx = New-AzureStorageContext -StorageAccountName $vmStrgAcct.StorageAccountName -StorageAccountKey $vmStrgAcctKey

        # Get the Container name where Blob resides
        $ContainerName = $osBlobUri.AbsolutePath.Split('/')[1] # expects os-discs

        # Get the blob
        $vmOsBlob = Get-AzureStorageBlob -Context $vmStrgCtx -Container $ContainerName -Blob $osBlobName
        
        Write-Host "`tBreaking lease" -ForegroundColor Yellow   
        
        # Break Lease 
        $CloudBlockBlob = $vmOsBlob.ICloudBlob
        $CloudBlockBlob.BreakLease()

        Write-Host "`tTaking Snapshot" -ForegroundColor Yellow   
        
        # Create a snapshot of the blob.
        $snap = $vmOsBlob.ICloudBlob.CreateSnapshot() 

        # Set the description meta data
        $snapUri = $snap.SnapshotQualifiedUri.AbsoluteUri
        $snapName = ($snapUri.Split("?")[-1]).Split('=')[-1]
        $snapName = $snapName.Replace(".","_")
        $snapName = $snapName.Replace(":","_")
        $snapName = $snapName.Replace("-","_")
        $snapName = $snapName.Replace(".","_")
        $snapName = $snapName.Replace("%","_")
        
        Write-Host "`tRecording metadata snapshot metadata" -ForegroundColor Yellow   
        
        $CloudBlockBlob.Metadata[("snap_" + $snapName)]=$SnapNote
        $CloudBlockBlob.SetMetadata()
                

        Write-Host "`tAcquiring Lease" -ForegroundColor Yellow  

        # Reset the Lease
        $CloudBlockBlob.AcquireLease($null,$null,$null,$null,$null)

        Write-Host "Snapshot complete!" -ForegroundColor Green -BackgroundColor Black


    }
}