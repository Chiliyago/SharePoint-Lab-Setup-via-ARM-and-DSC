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


{
    ### Create a blob snapshot

    #Define the storage account and context.
    $StorageAccountName = "vmsdisktorage2016"
    $StorageAccountKey = "HQ18W2NGefIV7yVOaX7vWXMrBGmrPXm6FEi65YG8K2+gBuaAi4aZ8GTGi4QLz2zemN0PTNNTqf3hwZxYikM2Eg=="
    $ContainerName = "os-discs"
    $BlobName = "DC12016812162929.vhd"
    $Ctx = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

    #Get a reference to a blob.
    $blob = Get-AzureStorageBlob -Context $Ctx -Container $ContainerName -Blob $BlobName

    

    #Create a snapshot of the blob.
    $snap = $blob.ICloudBlob.CreateSnapshot()
}

{
    ###  How to List blob snapshots
    #Define the blob name.
    

    #List the snapshots of a blob.
    $blobSnaps= Get-AzureStorageBlob �Context $Ctx -Prefix $BlobName -Container $ContainerName | Where-Object {$_.ICloudBlob.IsSnapshot -and $_.Name -eq $BlobName -and $_.SnapshotTime -ne $null }



}