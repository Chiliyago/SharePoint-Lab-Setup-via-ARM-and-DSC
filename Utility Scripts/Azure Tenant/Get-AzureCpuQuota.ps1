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

function Get-AzureCpuQuota
{
    <#
        .Synopsis
            Will return the CPU quota you have in your Azure account per region.
    #>

    $regionlist = (Get-AzureRmLocation).Location

    $limits = foreach ($region in $regionlist) {

    	Get-AzureRmVmUsage –Location $region | where {$_.Name.LocalizedValue -eq “Total Regional Cores”} | Select @{label=”Region“;Expression ={$region}}, CurrentValue, Limit

    }

    $limits | Format-Table -AutoSize

}