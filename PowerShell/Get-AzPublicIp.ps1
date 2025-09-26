<#
    .DESCRIPTION
        Get Public IP addresses for Azure VMs across multiple resource groups using PowerShell.

    .NOTES
        AUTHOR: jmcdonough@fortinet.com
        LAST EDIT: September 25, 2025
    .SYNOPSIS
        Get-AzPublicIp.ps1 - A PowerShell script to retrieve public IP addresses for Azure VMs across multiple resource groups.

    .EXAMPLE
        .\Get-AzPublicIp.ps1 -ResourceGroupNamePrefix "adc" -ResourceGroupNameSuffix "-AppSec103-203-FortiADC" -NumberOfAccounts 2 -StartingUserNumber 10 -PublicIpName "Client-PUB"
        This command retrieves the public IP addresses for VMs named "Client-PUB"
#>

param(
    [CmdletBinding()]

    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupNamePrefix,

    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupNameSuffix,

    [Parameter(Mandatory = $true)]
    [int] $NumberOfAccounts,

    [Parameter(Mandatory = $true)]
    [int] $StartingUserNumber,

    [Parameter(Mandatory = $true)]
    [string] $PublicIpName
)

($StartingUserNumber)..($StartingUserNumber + $NumberOfAccounts - 1) | ForEach-Object {
    $pip = Get-AzPublicIpAddress -ResourceGroupName "$ResourceGroupNamePrefix$_$ResourceGroupNameSuffix" -Name $PublicIpName
    Write-Output "Resource Group: $ResourceGroupNamePrefix$_$ResourceGroupNameSuffix, Public IP: $($pip.IpAddress)"
}
