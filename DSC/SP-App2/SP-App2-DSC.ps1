

$configData = @{
    AllNodes = @(
        @{
            NodeName = 'SP-App2'
            PSDscAllowPlainTextPassword = $true
        }
    )
}

configuration SPSetupApp2DSC{


    [CmdletBinding()]
    Param (
    
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$DomainAdminCredential,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$FarmSetupCredential,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$FarmAccountCredential,
        
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$ServicePoolMngAccCredential,

        [Parameter(Mandatory=$true)]
        [String]$MachineName,

        [Parameter(Mandatory=$true)]
        [String]$DnsIP,
        
        [Parameter(Mandatory=$true)]
        [String]$DomainName2Join,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Passphrase,

        [Parameter(Mandatory=$true)]
        [String]$SqlServerName

        


    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xComputerManagement, @{ModuleName="xNetworking"; RequiredVersion="3.2.0.0"}, xActiveDirectory, xSystemSecurity, xTimeZone, SharePointDSC, xWebAdministration

    Node SP-APP2{

         # LCM Setting:
        #   https://msdn.microsoft.com/en-us/powershell/dsc/metaconfig#basic-settings
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly' # Other Options: ApplyandMonitor, ApplyAndAutoCorrect
            RebootNodeIfNeeded = $true      # Automatically reboot the node after a configuration that requires reboot is applied
            ActionAfterReboot = 'ContinueConfiguration' # after a reboot during the application of a configuration. Other option: StopConfiguration
            AllowModuleOverwrite = $true    # New configurations downloaded from the configuration server are allowed to overwrite the old ones on the target nod
         
        }

        xTimeZone SetPacificTimeZone{
            IsSingleInstance = 'Yes'
            TimeZone = "Pacific Standard Time"
        }

        WindowsFeature Telnet-Client {
            Name = "Telnet-Client"
            Ensure = "Present"
        }

        
        xFirewall EnableV4PingIn{
            Name = 'File and Printer Sharing (Echo Request - ICMPv4-In)'
            Group= 'File and Printer Sharing'
            Protocol = 'ICMPv4'
            Ensure='Present'
            Enabled='True'
            Direction='Inbound'
            PsDscRunAsCredential = $DomainAdminCredential

        }
        xFirewall EnableV4PingOut{
            Name = 'File and Printer Sharing (Echo Request - ICMPv4-Out)'
            Group= 'File and Printer Sharing'
            Protocol = 'ICMPv4'
            Ensure='Present'
            Enabled='True'
            Direction='Outbound'
            PsDscRunAsCredential = $DomainAdminCredential
        }

        xFirewall EnableV6PingIn{
            Name = 'File and Printer Sharing (Echo Request - ICMPv6-In)'
            Group= 'File and Printer Sharing'
            Protocol = 'ICMPv6'
            Ensure='Present'
            Enabled='True'
            Direction='Inbound'
            PsDscRunAsCredential = $DomainAdminCredential

        }
        xFirewall EnableV6PingOut{
            Name = 'File and Printer Sharing (Echo Request - ICMPv6-Out)'
            Group= 'File and Printer Sharing'
            Protocol = 'ICMPv6'
            Ensure='Present'
            Enabled='True'
            Direction='Outbound'
            PsDscRunAsCredential = $DomainAdminCredential
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

        xDnsServerAddress SetDnsServer{
            Address = $DnsIP
            InterfaceAlias = "Ethernet"
            AddressFamily = "IPv4"
        }

        xIEEsc DisableIEEnhancedSecurity4Admins{
            UserRole = 'Administrators'
            IsEnabled = $false
        }

        xUAC Uac4AdminsOnly{
            Setting = "NeverNotify"
        }
       
        
        xWaitForADDomain Wait4Forest{
            DomainName = $DomainName2Join
            RetryCount=40
            RetryIntervalSec = 30
            DomainUserCredential = $DomainAdminCredential
            DependsOn = "[xDnsServerAddress]SetDnsServer"
            PsDscRunAsCredential = $DomainAdminCredential
        }
        
        
        xComputer joinDomain{
            Name= $MachineName
            DomainName= $DomainName2Join
            Credential= $DomainAdminCredential
            PsDscRunAsCredential = $DomainAdminCredential
        }

        <#
        Registry ConsoleFaceName
        {
            Key         = 'HKEY_CURRENT_USER\Console'
            ValueName   = "FaceName"
            ValueData   = "Lucida Console"
            Ensure      = "Present"
            PsDscRunAsCredential = $DomainAdminCredential
        }
        #>

        SPInstallPrereqs InstallSPPrereqs {
            Ensure            = "Present"
            InstallerPath     = "C:\_SetupFiles\SharePoint Server 2016\Extract\prerequisiteinstaller.exe"
            OnlineMode        = $true
            PsDscRunAsCredential  = $FarmSetupCredential
        }

        SPInstall InstallSharePoint {
            Ensure = "Present"
            BinaryDir = "C:\_SetupFiles\SharePoint Server 2016\Extract"
            ProductKey = "TY6N4-K9WD3-JD2J2-VYKTJ-GVJ2J"
            DependsOn = @("[SPInstallPrereqs]InstallSPPrereqs")
            
        }

        Environment SetPathEnvVar
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Name = "Path"
            Value = "%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\;C:\ProgramData\chocolatey\bin;C:\Program Files\nodejs\;C:\Program Files\Git\cmd;C:\Program Files\Microsoft Office Servers\16.0\Bin\;C:\Program Files\Common Files\microsoft shared\Web Server Extensions\16\BIN;C:\Program Files (x86)\Microsoft VS Code\"
        }

        <##>
        Group AddFarmSetupToLocalAdminGroup
        {
            GroupName='Administrators'   
            Ensure= 'Present'             
            MembersToInclude= @($FarmSetupCredential.UserName)
            
        }

                # IIS Cleanup
        xWebAppPool RemoveDotNet2Pool 
        { 
            Name = ".NET v2.0";
            Ensure = "Absent"; 
        }
        xWebAppPool RemoveDotNet2ClassicPool  
        { 
            Name = ".NET v2.0 Classic";    
            Ensure = "Absent"; 
        }
        xWebAppPool RemoveDotNet45Pool        
        { 
            Name = ".NET v4.5";            
            Ensure = "Absent"; 
        }
        xWebAppPool RemoveDotNet45ClassicPool 
        { 
            Name = ".NET v4.5 Classic";    
            Ensure = "Absent"; 
        }
        xWebAppPool RemoveClassicDotNetPool   
        { 
            Name = "Classic .NET AppPool"; 
            Ensure = "Absent"; 
        }

        xWebAppPool RemoveDefaultAppPool      
        { 
            Name = "DefaultAppPool";       
            Ensure = "Absent"; 
        }

        xWebSite    RemoveDefaultWebSite      
        { 
            Name = "Default Web Site";     
            Ensure = "Absent"; 
            PhysicalPath = "C:\inetpub\wwwroot"; 
        }

        SPJoinFarm JoinFarm
        {
            DatabaseServer            = $SqlServerName
            FarmConfigDatabaseName    = "SP_Config"
            ServerRole                = "Search"
            Passphrase                = $Passphrase
            PsDscRunAsCredential      = $FarmSetupCredential
        }
       
    }
}

