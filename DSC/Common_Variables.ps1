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

$DomainName = "SomeDomain.com"  # Use Format: YourDomain.com

# Domin Admin User Name and Password
$DomainAdminUserName = "AdminUserName" # Domain Admin User name
$DomainAdminPassword = "AdminPassword" # Domain Admin Password
$SecurePassword = $DomainAdminPassword | ConvertTo-SecureString -AsPlainText -Force

$DomainAdminUserName = ("{0}\{1}" -f $DomainName.Split(".")[0], $DomainAdminUserName)
$DomainAdminCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $DomainAdminUserName, $SecurePassword

# Network Variables

$DnsIP = "10.0.0.100"


# SQL Server Variables
$SqlSvcAcctUserName = ("{0}\{1}" -f $DomainName.Split(".")[0], "SP_SQL")
$SqlServerName = "SP-SQL1" # SQL Server of the SharePoint farm
$SqlSvcAcctCredential = (New-Object System.Management.Automation.PSCredential -ArgumentList $SqlSvcAcctUserName, $SecurePassword)
$SqlInstanceName ="MSSQLSERVER"
$SqlSvcAcctCredential = (New-Object System.Management.Automation.PSCredential -ArgumentList $SqlSvcAcctUserName, $SecurePassword)


## SharePoint

# Service Accounts
$SpFarmSetupAcct = "SP_FarmSetup" # SharePoint Farm Setup Account
$SpFarmServiceAcct = "SP_ServicePool" # Account to run SharePoint services
$SpFarmAcct = "SP_Farm" # SharePoint Farm Account

$Passphrase = $DomainAdminCredential

$FarmSetupCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ("{0}\{1}" -f $DomainName.Split(".")[0], $SpFarmSetupAcct), $SecurePassword
$FarmAccountCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ("{0}\{1}" -f $DomainName.Split(".")[0], $SpFarmAcct), $SecurePassword
$ServicePoolMngAccCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ("{0}\{1}" -f $DomainName.Split(".")[0], $SpFarmServiceAcct), $SecurePassword
