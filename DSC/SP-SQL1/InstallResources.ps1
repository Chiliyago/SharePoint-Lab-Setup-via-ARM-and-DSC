# F5 Run this to install required Resources
#

Find-DscResource -ModuleName xComputerManagement | Install-Module -Force -Confirm:$false -Verbose
{
    Get-DscResource -Module xComputerManagement
    Get-DscResource -Module xComputerManagement  -Syntax
}

Find-DscResource -ModuleName xNetworking | Install-Module -Force -Confirm:$false -Verbose
{
    Get-DscResource -Module xNetworking
    Get-DscResource -Module xNetworking  -Syntax
}

Find-DscResource -ModuleName xActiveDirectory | Install-Module -Force -Confirm:$false -Verbose
{
    Get-DscResource -Module xActiveDirectory
    Get-DscResource -Module xActiveDirectory  -Syntax
}

Find-DscResource -ModuleName xSystemSecurity | Install-Module -Force -Confirm:$false -Verbose
{
    Get-DscResource -Module xSystemSecurity
    Get-DscResource -Module xSystemSecurity  -Syntax
}

Find-DscResource -ModuleName xTimezone | Install-Module -Force -Confirm:$false -Verbose
{
    Get-DscResource -Module xTimezone
    Get-DscResource -Module xTimezone  -Syntax
}

Find-DscResource -ModuleName xSQLServer | Install-Module -Force -Confirm:$false -Verbose
{
    Get-DscResource -Name xSQLServerRole
    Get-DscResource -Name xSQLServerRole -Syntax
}
