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

# Set CmdrHome 
$homePath = "CD C:\_DSC\SharePoint_DSC_PowerShell_Setup_Scripts"

$pathExists = (get-content -path "C:\Program Files\cmder\config\user-profile.cmd") -ccontains $homePath

if($pathExists){
    # Yes
} else {
    # NO
    Add-Content "C:\Program Files\cmder\config\user-profile.cmd" "CD C:\_DSC\SharePoint_DSC_PowerShell_Setup_Scripts"
}