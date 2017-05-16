Function Start-SPServices
{
       [CmdletBinding()]
       param (
            [parameter(Mandatory=$true, Position=0)]
            [Array] $SPServices
       ) 

       <#
         .Synopsis
         Starts the services provided $SPServices paramater. 
         They do not have to be specific to SharePoint actually.
       #>

       foreach($SPService in $SPServices)
       {
            $s = $SPService.Split("/")

            Get-Service -Name $s[1] -ComputerName $s[0] | Set-Service -Status Running #-WhatIf

            $notice = "{0} on server {1}" -f $s[1],$s[0]
            Write-Host $notice -NoNewline
            Write-Host "  Started" -ForegroundColor Green
       }
}