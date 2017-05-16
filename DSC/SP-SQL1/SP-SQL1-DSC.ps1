

$configData = @{
    AllNodes = @(
        @{
            NodeName = 'SP-SQL1'
            PSDscAllowPlainTextPassword = $true
        }
    )
}

configuration SPSetupSql1DSC{


    [CmdletBinding()]
    Param (
    
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$DomainAdminCredential,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$SqlSvcAcctCredential,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$FarmSetupCredential,

        [Parameter(Mandatory=$true)]
        [String]$MachineName,

        [Parameter(Mandatory=$true)]
        [String]$DnsIP,

        [Parameter(Mandatory=$true)]
        [String]$DomainName2Join,

        [Parameter(Mandatory=$true)]
        [String]$SqlInstanceName,

        [Parameter(Mandatory=$true)]
        [String]$SqlServerName


    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xComputerManagement, xNetworking, xActiveDirectory, xSystemSecurity, xTimeZone, xSQLServer

    Node SP-SQL1{

         # LCM Setting:
        #   https://msdn.microsoft.com/en-us/powershell/dsc/metaconfig#basic-settings
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly' # Other Options: ApplyandMonitor, ApplyAndAutoCorrect
            RebootNodeIfNeeded = $true      # Automatically reboot the node after a configuration that requires reboot is applied
            ActionAfterReboot = 'ContinueConfiguration' # after a reboot during the application of a configuration. Other option: StopConfiguration
            AllowModuleOverwrite = $true    # New configurations downloaded from the configuration server are allowed to overwrite the old ones on the target nod
         
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

        WindowsFeature "NET-Framework-Core"{

            Ensure = "Present"
            Name = "NET-Framework-Core"
            
        }

        # Feature Name Parameters
        # https://msdn.microsoft.com/en-us/library/ms144259.aspx#Feature
        # SQLEnginer - SQL Server Database Engine
        # FullText   - Full Text Component
        # RS         - Reporting Services
        # AS         - Analysis Services
        # IS         - Integration Services

        $Features = "SQLENGINE,FULLTEXT,RS,AS,IS"

        xSqlServerSetup SqlSvr2016Setup
        {
            InstanceName = $SqlInstanceName
            SetupCredential = $DomainAdminCredential
            SourcePath = "C:\_SetupFiles\SQL Server 2016\Extract"
            Features = $Features
            SQLSvcAccount = $SqlSvcAcctCredential
            AgtSvcAccount = $SqlSvcAcctCredential
            SQLSysAdminAccounts = @($SqlSvcAcctCredential.UserName)
            DependsOn = "[WindowsFeature]NET-Framework-Core"
            #SourceCredential = $DomainAdminCredential
            
            InstallSharedDir = "C:\Program Files\Microsoft SQL Server"
            InstallSharedWOWDir = "C:\Program Files (x86)\Microsoft SQL Server"
            InstanceDir = "C:\Program Files\Microsoft SQL Server"
            InstallSQLDataDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data"
            SQLUserDBDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data"
            SQLUserDBLogDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data"
            SQLTempDBDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data"
            SQLTempDBLogDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data"
            SQLBackupDir = "C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Data"
            ASDataDir = "C:\Program Files\Microsoft SQL Server\MSAS13.MSSQLSERVER\OLAP\Data"
            ASLogDir = "C:\Program Files\Microsoft SQL Server\MSAS13.MSSQLSERVER\OLAP\Log"
            ASBackupDir = "C:\Program Files\Microsoft SQL Server\MSAS13.MSSQLSERVER\OLAP\Backup"
            ASTempDir = "C:\Program Files\Microsoft SQL Server\MSAS13.MSSQLSERVER\OLAP\Temp"
            ASConfigDir = "C:\Program Files\Microsoft SQL Server\MSAS13.MSSQLSERVER\OLAP\Config"

        }

        # Download and install SQL Server Data Tools which is the 2016 replacement to SQL Management Studio
        xFirewall AllowSqlSvr2016FirewallApp{
            Name="Allow SQL Server App"
            DisplayName ="Allow SQL Server APP (Configured by DSC)"
            Profile=("Domain")
            Program="C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Binn\Sqlservr.exe"
            Ensure="Present"
            Enabled="True"
            Protocol="TCP"
            DependsOn=@("[xSqlServerSetup]SqlSvr2016Setup")
        }

        xSqlServerFirewall SqlSvr2016Firewall
        {
            DependsOn = @("[xSqlServerSetup]SqlSvr2016Setup")
            SourcePath = "C:\_SetupFiles\SQL Server 2016\Extract"
            InstanceName = $SqlInstanceName
            Features = $Features
        }
     
        xSQLServerLogin AddSQLLogin_FarmSetup
        {
            Name = $FarmSetupCredential.UserName
            SQLInstanceName = $SqlInstanceName
            SQLServer = $SqlServerName
            DependsOn = @("[xSqlServerSetup]SqlSvr2016Setup")
            Ensure = "Present"
        }   

        xSQLServerRole Set_dbcreatorRole4_FarmSetup{
            
            Members = @($FarmSetupCredential.UserName)
            SQLServer = $SqlServerName
            SQLInstanceName = $SqlInstanceName
            ServerRoleName = "dbcreator"
            Ensure = "Present"
        }
        xSQLServerRole Set_securityadmin_Roles4_FarmSetup{
            
            Members = @($FarmSetupCredential.UserName)
            SQLServer = $SqlServerName
            SQLInstanceName = $SqlInstanceName
            ServerRoleName = "securityadmin"
            Ensure = "Present"
        }
        xSQLServerRole Set_sysadmin_Roles4_FarmSetup{
            
            MembersToInclude = @($FarmSetupCredential.UserName)
            SQLServer = $SqlServerName
            SQLInstanceName = $SqlInstanceName
            ServerRoleName = "sysadmin"
            Ensure = "Present"
        }

        xSQLServerNetwork EnableSql_tcp
        {
            InstanceName = $SqlInstanceName
            ProtocolName = "tcp"
            DependsOn =  @("[xSqlServerSetup]SqlSvr2016Setup")
            IsEnabled = $true
            
        }

        xSQLServerMaxDop SetMaxDegreeOfParrallelism{
            Ensure = 'Present'
            DynamicAlloc = $false
            MaxDop = 1
            SQLServer = $SqlServerName
            SQLInstanceName = $SqlInstanceName
            PsDscRunAsCredential = $DomainAdminCredential
        }
    }
}

