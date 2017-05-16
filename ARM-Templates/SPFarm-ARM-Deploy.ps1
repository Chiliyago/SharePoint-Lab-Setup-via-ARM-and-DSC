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

# Login to your Azure Account
{
    Login-AzureRmAccount
}

# Define variables
{
    # Base Name of Resource Group
    $rscrcGrpName = 'Tim-' + "0"

    # Location of Resource Group
    $resourceGroupLocation = 'West US'
    
    # The name/id of the Azure ARM deployment
    # this is visible from Azure Portal
    $resourceDeploymentName = 'SP2016Farm'

    # File name and path location of ARM Template 
    $templatePath =  'K:\_DSC\SharePoint_DSC_PowerShell_Setup_Scripts\ARM-Templates\azuredeploy.json'
    Test-Path $templatePath

    # File name and path location of ARM Template Parameter file
    $parameterPath = 'K:\_DSC\SharePoint_DSC_PowerShell_Setup_Scripts\ARM-Templates\azuredeploy.parameters.json'
    Test-Path $parameterPath

    # After first Run of this script Get storage account name from Azure Portal and update this variable. Then re-run script to complete deployment
    $vmStorageAccName = "mainstore5wjud2ypndj7m"

    # Storage Container name where VM Images will be stored
    $vmImageContainerName = "vm-images"

    # Storage Conainter name wher OS Disks will be stored
    $osDiscContainerName = "os-discs"

}

# Get or Create a Resource Group Where resources will be deployed
{

    # Get the existing resource group
    # Use this when re-deploying to an existing Resource Group
    $rscrcGrp = Get-AzureRmResourceGroup -Name $rscrcGrpName

}
#     --- OR ----
{
    # Create a new resource group if needed
    $rscrcGrp = New-AzureRmResourceGroup `
        -Name $rscrcGrpName `
        -Location $resourceGroupLocation `
        -Verbose -Force
}

## Create Storage Container for OS-Disk and VM-Images
## ARM templates do not create storage conatainers so this necessary
{
    # Get the storage account where containers will be created
    $mainStore = Get-AzureRmStorageAccount -ResourceGroupName $rscrcGrpName -Name $vmStorageAccName 
    
    # Create container to hold the sys-preped vm images
    $imageContainer = New-AzureStorageContainer -Name $vmImageContainerName  -Context $mainStore.Context -Verbose -Permission Blob
    
    # Get the two keys to the storage account
    $imageContainerKeys = $mainStore | Get-AzureRmStorageAccountKey 
    
    # Create container to hold the vm osdisks
    
    $osDisksContainer = New-AzureStorageContainer -Name $osDiscContainerName  -Context $mainStore.Context -Verbose -Permission Blob

}


## Copy the Generalized VM Image to the vm-images container.
## Use this section generate an AZCopy command used to copy 
## a VM image blob to your vm-images storage container.
{
    ## See the script file
    ## ..\Utility Scripts\Azure Blob\AzCopyCommandBuilder.ps1     
 }   


### Deploy ARM Template
{

    # Optionally create additional parameters to be sent to deployment
    # Parameters are sent via hashtable into an ARM template deployment
    #   $addtionalParameters = New-Object -TypeName Hashtable
    #   $addtionalParameters['vmPrivateAdminPassword'] = $securePassword

    
    # Test the ARM Template for validation Errors
    $testResult  = Test-AzureRmResourceGroupDeployment `
            -ResourceGroupName $rscrcGrpName  `
            -TemplateFile $templatePath `
            -TemplateParameterFile $parameterPath `
            -Verbose `
	        -Mode Incremental 
    
    # output the $testResult
    $testResult


    # Clear the display
    Clear-Host

    # Deploy the ARM Template
    New-AzureRmResourceGroupDeployment `
        -Name $resourceDeploymentName `
        -ResourceGroupName $rscrcGrpName `
        -TemplateFile $templatePath `
        -TemplateParameterFile $parameterPath `
        -Verbose `
	    -Mode Incremental `
	    -DeploymentDebugLogLevel All 
	
}

## Note:
## Example of simply deploying an ARM template found on Git Hub QuickStart Template
{
    $templateURI = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-vm-from-user-image/azuredeploy.json"
    $deploymentName = "customImageTest"
    New-AzureRmResourceGroupDeployment -Name $deploymentName -ResourceGroupName $rscrcGrpName -TemplateUri $templateURI

    $imageURI =  https://vmmagevhds.blob.core.windows.net/vhds/SpServer2016-osDisk.4ed7604f-a0d3-4ac2-b72b-2141e845e912.vhd
                 
}

## This is a work in progress...
## Publish DSC to Blob Storage for consumption by the new VM's
{
    # Resource Group Name that contains DSC Files
    $dscRsrcGrpName = "ARM-Rsrc-0"

    # Get the Resource Group that contains the DSC file
    $dscRsrcGrp = Get-AzureRmResourceGroup $dscRsrcGrpName

    
    # Storage Account Name that contains the DSC Files
    $dscStrgAcctName = "armstore0"

    # One of the two keys to the storage account
    $dscStrgAcctKey = "c0KHlnwJaAFyRLX+A8vrPS8f1kvBf2AbsfIYhkF4PO1d7rJq4FQpMXHaBPqOH1BUxiyEi67du3b0o4jve7WNiQ=="

    # The Container where the DSC file resides
    $ContainerName = "dsc"
    

    # Connection String to the storage account
    # Format:
    #    DefaultEndpointsProtocol=https;AccountName=[account_name];AccountKey=[account_key] 
    $dscRsrcGrpConnStr = "DefaultEndpointsProtocol=https;AccountName=" + $dscStrgAcctName  + ";AccountKey=" +  $dscStrgAcctKey  

    $dscRsrcGrpContext = New-AzureStorageContext -ConnectionString $dscRsrcGrpConnStr
    
    # Optionally create a new container for the DSC
    # New-AzureStorageContainer -Name $ContainerName -Context $dscRsrcGrpContext -Permission Blob
    #
    
        
    # Publish the local DSC file to the Azure Storage Account
    Publish-AzureRmVMDscConfiguration `
        -ResourceGroupName $dscRsrcGrp.ResourceGroupName `
        -StorageAccountName armstore0 `
        -ConfigurationPath $dscConfigPath `
        -ConfigurationDataPath $dscDataPath `
        -ContainerName $ContainerName `
        -Force  

    # Publish the local DSC file to the Azure Storage Account
    Publish-AzureRmVMDscConfiguration `
        -ResourceGroupName $dscRsrcGrp.ResourceGroupName `
        -StorageAccountName armstore0 `
        -ConfigurationPath $dscConfigPath `
        -ContainerName $ContainerName `
        -Force  

}


###
### Steps for how to Generalize a VM
###
{
    # Step 1
    # To Go To Recovery Vault and Restore a VM to a Resource Group of your choosing
    # or build a new VM from scratch

    # Step 2
    # Log Into the restored or created server

    # Step 3
    # Configure the server how you like it

    # Step 4
    # Open PowerShell Administrative command window and execute:
    #    & "$Env:SystemRoot\system32\sysprep\sysprep.exe" /generalize /oobe /shutdown

    # Step 5
    # Deallocate the VM by executing the following in Azure PowerShell command window
    #    Stop-AzureRmVM -ResourceGroupName <resourceGroup> -Name <vmName>

    # Step 6
    # Set the Status of the VM to Generalized by executing the following in Azure PowerShell command window
    #    Set-AzureRmVm -ResourceGroupName <resourceGroup> -Name <vmName> -Generalized
    
    # Step 7
    # Verify the status == OSState/generalized
    #     $vm = Get-AzureRmVM -ResourceGroupName <resourceGroup> -Name <vmName> -Status
    #     $vm.Statuses

    # Step 8
    # Save the VM Image by executing the following in Azure PowerShell command windows
    # Note be sure the folder already exists for the -Path paramer
    #     Save-AzureRmVMImage -ResourceGroupName <resourceGroupName> -Name <vmName> `
    #     -DestinationContainerName <destinationContainerName> -VHDNamePrefix <templateNamePrefix> `
    #     -Path <C:\temp\vhd\vhdname\imagename.json>

    # Step 9
    # Go to the storage account and container created when performing Step 8.
    # The image will be in a new nested folder of the following path
    #     <container>/system/Microsoft.Compute/Images/<destinationContainerName>/<templateNamePrefix>-osDisk<guid>.vhd

    # Step 10
    # Optionally Copy the image to a dedicated storage account container for safe keeping and reuse in ARM Template.


    # Get the VM to be imaged
    $vmName = "DC1"
    
    $vm = Get-AzureRmVM -Name $vmName  -ResourceGroupName $rscrcGrpName 
    
    # Deallocate the VM
    $vm | Stop-AzureRmVM  
    
    # Set VM to Generalized
    Set-AzureRmVm -ResourceGroupName $rscrcGrpName -Name $vmName  -Generalized
    
    # Be sure OSState/generalized.DiplayStatus = 'VM generalized'
    $vm = Get-AzureRmVM -Name $vmName  -ResourceGroupName $rscrcGrpName -Status
    $vm.Statuses

    # Save the image
    # Note: Make sure the Path folder exists prior to running
    Save-AzureRmVMImage -ResourceGroupName $rscrcGrpName -Name $vmName  `
     -DestinationContainerName "spserver2016image" -VHDNamePrefix SpServer2016 `
     -Path c:\temp\spserver2016image.json

    
}


## This section will delete all the resources so you can deploy again
## Running this will take a while!
{
    # Remove VMs
    Get-AzureRmVM -ResourceGroupName $rscrcGrpName | Remove-AzureRmVM -Confirm:$false -Force
    
    # Remove Nics
    Get-AzureRmNetworkInterface -ResourceGroupName $rscrcGrpName | Select-Object Name
    Get-AzureRmNetworkInterface -ResourceGroupName $rscrcGrpName | Remove-AzureRmNetworkInterface -Force

    # Remove PIDs
    Get-AzureRmPublicIpAddress -ResourceGroupName $rscrcGrpName | Select-Object Name
    Get-AzureRmPublicIpAddress -ResourceGroupName $rscrcGrpName | Remove-AzureRmPublicIpAddress -Force

    # Remove Network Security Group
    Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rscrcGrpName | Select-Object name;
    Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rscrcGrpName | Remove-AzureRmNetworkSecurityGroup -Force;
    
    # Remove Virtual Network
    Get-AzureRmVirtualNetwork -ResourceGroupName $rscrcGrpName | Remove-AzureRmVirtualNetwork  -Force

    # Remove os-disk blobs
    Clear-Host
    $vmStorageAccName = 'mainstore5wjud2ypndj7m'
    $osDiscContainerName = 'os-discs'
    $sa = (Get-AzureRmStorageAccount -ResourceGroupName $rscrcGrpName) | Where-Object {$_.StorageAccountName -eq $vmStorageAccName}
    $osDiscContainer = Get-AzureStorageContainer -Context $sa.Context | Where-Object {$_.Name -eq $osDiscContainerName}
    
    $osDiscBlobs = ($osDiscContainer | Get-AzureStorageBlob)
    $osDiscBlobs | Remove-AzureStorageBlob

    # Removed diagnostic blobs
    $diagStoreageAccName = 'diagstore5wjud2ypndj7m'

    $sa = (Get-AzureRmStorageAccount -ResourceGroupName $rscrcGrpName) | Where-Object {$_.StorageAccountName -eq  $diagStoreageAccName}
    $diaContainer = Get-AzureStorageContainer -Context $sa.Context | Where-Object {$_.Name -like "bootdiagnostics*"}
    
    $diaContainer | ForEach-Object{
        Remove-AzureStorageContainer -Name $_.Name -Context $sa.Context -Confirm:$false -Force
    }

    
}