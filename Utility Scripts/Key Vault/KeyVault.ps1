

# Login to your Azure Account
{
    Login-AzureRmAccount
}


$ResourcGroupName = 'team-keyvault' 
$KeyVaultName = 'keyvault-1' 
$location = 'westus'
## Create a new Resource Group to contain the Key Vault
{ 
    $rscrcGrp = New-AzureRmResourceGroup `
        -Name $ResourcGroupName `
        -Location $location `
        -Verbose -Force
}

## Create a new Key Vault if needed
{
    $keyVault = New-AzureRmKeyVault `
        -VaultName $KeyVaultName `
        -ResourceGroupName $ResourcGroupName `
        -Location $location `
        -EnabledForDeployment
}

## Get the existing Key Vault
{
    $keyVault = Get-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourcGroupName 
}

## Create a password key and value and set to keyvault
{
    $parameterName = "vmAdminPassword-Tim"
    $password = "PutYourPasswordHere!"

    $adminPass = ConvertTo-SecureString `
        -String $password `
        -AsPlainText -Force

    Set-AzureKeyVaultSecret `
        -VaultName $keyVaultName `
        -Name $parameterName `
        -SecretValue $adminPass
}