<#

    Group Managed Service Account
    Setup & Management

    Note:  To add Active Directory cmdlets to non-Domain Controller Servers
        Add-WindowsFeature rsat-ad-powershell
        Import-Module activedirectory

#>

# Cmdlets related to KDS Root Key
Get-Help *kdsrootkey*

# Execute Add-KdsRootKey one-time on the domain to get the Kerberos Root Key
# By default this command will actually execute after 10 hours
# So in order to get it to execute  immediately we need to subtract
# 10 hours

Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))

# Returns the configured Root key
Get-KdsRootKey


$gmsa_FarmAcct = "gmsa_Farm"

# After executing the New-ADServiceAccount 
# look in AD Users&Computers in the 
# Managed Service Accounts node
#
# New-ADServiceAccount `
#    -Name $gmsa_FarmAcct `                                         # Service Account Name
#    -DNSHostName "DC1.RecruiterStar.com" `                         # Domain Controller Machine Name where the GMSA will be store 
#    -PrincipalsAllowedToRetrieveManagedPassword "Domain Computers" # Specify what computers are allowed to use this GMSA

New-ADServiceAccount -Name $gmsa_FarmAcct -DNSHostName "DC1.RecruiterStar.com" -PrincipalsAllowedToRetrieveManagedPassword "Domain Computers" 



# Once MSA is created you must install the account
# On the servers that will use the account
# RDP to the servers that will use the account
# 

# Add AD PowerShell Module to the Computer
Add-WindowsFeature rsat-ad-powershell
Import-Module activedirectory

# Install the Service Account
Install-ADServiceAccount -Identity $gmsa_FarmAcct

# Test the GMSA is installed correctly
Test-ADServiceAccount -Identity $gmsa_FarmAcct


# When assigning this account to a service you leave the password blank
# Because we actually never know the password as it is managed by
# by AD and will automatically renew according to password reset policy



# Virtual Accounts
# ---------------------------------
# Think of them as managed local accounts.
# Not usually used for services that need access to the network because such accounts don't have network access
# Acts like a regular LOCAL user account but passwords are managed by the Local System
# 
#
# To configure just update the "Log On As" account to the name of the service itself.
#
# Use the format "NT Service\servicename"
# Leave password blank

