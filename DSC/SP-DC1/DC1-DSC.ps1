#
# DSC To configure Domain Controller
# References:
#      https://blogs.technet.microsoft.$topLevelDomain/markrenoden/2016/11/24/revisit-deploying-a-dc-to-azure-iaas-with-arm-and-dsc/
#      http://social.technet.microsoft.com/wiki/contents/articles/4546.working-with-passwords-secure-strings-and-credentials-in-windows-powershell.aspx
#

# Update SrvcAcctOUCreate to the domain name that will be created

$configData = @{
    AllNodes = @(
        @{
            NodeName = 'DC1'
            PSDscAllowPlainTextPassword = $true
        }
    )
}

$srvcAccounts = @("SP_FarmSetup","SP_SQL","SP_Farm","SP_ServicePool","SP_WebPool","SP_SuperUser","SP_SuperReader");

configuration DCSetupDSC
{

    [CmdletBinding()]
    Param (
    
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$DomainAdminCredential,

        [Parameter(Mandatory=$true)]
        [String]$DomainName
    )
 
    Import-DscResource -ModuleName PSDesiredStateConfiguration, xActiveDirectory, xTimeZone
    
    $DomainNameRoot = $DomainName.Split('.')[0]
    $topLevelDomain = $DomainName.Split('.')[1]

    Node DC1
    {
        
         # LCM Setting:
        #   https://msdn.microsoft.com/en-us/powershell/dsc/metaconfig#basic-settings
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly' # Other Options: ApplyandMonitor, ApplyAndAutoCorrect
            RebootNodeIfNeeded = $true      # Automatically reboot the node after a configuration that requires reboot is applied
            ActionAfterReboot = 'ContinueConfiguration' # after a reboot during the application of a configuration. Other option: StopConfiguration
            AllowModuleOverwrite = $true    # New configurations downloaded from the configuration server are allowed to overwrite the old ones on the target nod
         
        }


        WindowsFeature Telnet-Client {
            Name = 'Telnet-Client'
            Ensure = 'Present'
        }

        File Set_Cmder_DefaultFolder{
            DestinationPath="C:\Program Files\cmder\config\user-profile.cmd"
            Contents="C:\_DSC\SharePoint_DSC_PowerShell_Setup_Scripts"
            Ensure="Present"
            Type="File"
        }

        Environment SetPathEnvVar
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Name = "Path"
            Value = "%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\;C:\ProgramData\chocolatey\bin;C:\Program Files\nodejs\;C:\Program Files\Git\cmd;C:\Program Files\Microsoft Office Servers\16.0\Bin\;C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\BIN;C:\Program Files (x86)\Microsoft VS Code\"
        }


        xTimeZone SetPacificTimeZone{
            IsSingleInstance = 'Yes'
            TimeZone = "Pacific Standard Time"
        }

        Service FuncDscvyRsrcPub{
            Name = 'FDResPub'
            StartupType = "Automatic"
            State = "Running"

        }

        Service SSDPDiscovery{
            Name = 'SSDPSRV'
            StartupType = "Automatic"
            State = "Running"
        }

        Service UPnPDeviceHost{
            Name = 'upnphost'
            StartupType = "Automatic"
            State = "Running"
        }

        WindowsFeature DNS_RSAT{ 
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            IncludeAllSubFeature = $true
        }
 
        WindowsFeature ADDS_Install{ 
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
        } 
 
        WindowsFeature RSAT_AD_AdminCenter{
            Ensure = 'Present'
            Name   = 'RSAT-AD-AdminCenter'
            IncludeAllSubFeature = $true
        }
 
        WindowsFeature RSAT_ADDS{
            Ensure = 'Present'
            Name   = 'RSAT-ADDS'
            IncludeAllSubFeature = $true
        }
 
        WindowsFeature RSAT_AD_PowerShell{
            Ensure = 'Present'
            Name   = 'RSAT-AD-PowerShell'
            IncludeAllSubFeature = $true
        }
 
        WindowsFeature RSAT_AD_Tools{
            Ensure = 'Present'
            Name   = 'RSAT-AD-Tools'
            IncludeAllSubFeature = $true
        }
 
        WindowsFeature RSAT_Role_Tools{
            Ensure = 'Present'
            Name   = 'RSAT-Role-Tools'
            IncludeAllSubFeature = $true
        }      
 
        WindowsFeature RSAT_GPMC {
            Ensure = 'Present'
            Name   = 'GPMC'
            IncludeAllSubFeature = $true
        } 
        
        xADDomain CreateForest{ 
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainAdminCredential
            SafemodeAdministratorPassword = $DomainAdminCredential
            DatabasePath = "C:\Windows\NTDS"
            LogPath = "C:\Windows\NTDS"
            SysvolPath = "C:\Windows\Sysvol"
            DependsOn = @("[WindowsFeature]ADDS_Install","[WindowsFeature]RSAT_AD_Tools")            
            DomainNetbiosName = $DomainNameRoot
        }

        $ou = ("OU=SPServiceAccounts,DC={0},DC={1}" -f $DomainNameRoot, $topLevelDomain)
        xADOrganizationalUnit SrvcAcctOUCreate{
                Name = "SPServiceAccounts"
                Path = ("DC={0},DC={1}" -f $DomainNameRoot, $topLevelDomain)
                Description = "SharePoint Service Accounts"
        }
       

        [int]$loop = 0;
        foreach ($svcAcct in  $srvcAccounts){
            $DomainUserName = ("{0}\{1}" -f $DomainNameRoot, $svcAcct)
            $DomainUserCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $DomainUserName, $DomainAdminCredential.Password

            Log ("LogSvcAcct-" + $loop)
            {
                Message = ("Analyzing User '" + $svcAcct + "'`n`t`t`t" + $DomainUserCredential.UserName + "`n`t`t`t" + $DomainUserCredential.GetNetworkCredential().Password )
            }

           

            xADUser ("AddSvcAcct-" + $svcAcct){
                DomainName =  $DomainNameRoot
                UserName = $svcAcct
                Password = $DomainUserCredential
                Ensure = "Present"
                PasswordNeverExpires = $true
                Path = $ou
                DependsOn = @("[xADOrganizationalUnit]SrvcAcctOUCreate")
            }
          
            $loop++;
        }
        <# #>

    }
}

