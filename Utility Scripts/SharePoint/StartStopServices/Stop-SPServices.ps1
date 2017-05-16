Function Stop-SPServices
{
       [CmdletBinding()]
       param (
            [parameter(Mandatory=$true, Position=0)]
            [Array] $SPServices
       ) 

       <#
         .Synopsis
         Stops the services provided $SPServices paramater. 
         They do not have to be specific to SharePoint actually.
       #>

       foreach($SPService in $SPServices)
       {
            $s = $SPService.Split("/")

            $filter = "name='{0}'" -f $s[1]
            (Get-WmiObject Win32_Service -filter $filter -ComputerName $s[0]).StopService() | out-null
            
             $notice = "{0} on server {1}" -f $s[1],$s[0]
            Write-Host $notice -NoNewline
            Write-Host "  Stopped" -ForegroundColor Red

       }
}