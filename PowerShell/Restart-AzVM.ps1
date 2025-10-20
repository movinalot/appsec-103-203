<#
    .DESCRIPTION
        Restart Azure VMs across multiple resource groups using PowerShell.

    .NOTES
        AUTHOR: jmcdonough@fortinet.com
        LAST EDIT: September 25, 2025
    .SYNOPSIS
        Restart-AzVM.ps1 - A PowerShell script to restart Azure VMs across multiple resource groups.

    .EXAMPLE
        .\Restart-AzVM.ps1 -ResourceGroupNamePrefix "adc" -ResourceGroupNameSuffix "-AppSec103-203-FortiADC" -NumberOfAccounts 2 -StartingUserNumber 10 -VmNames @("FAD-Primary", "FAD-Secondary")
        This command restarts the VMs named "FAD-Primary" and "FAD-Secondary"
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
    [array] $VmNames
)

$clientCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:ARM_CLIENT_ID, $(ConvertTo-SecureString -String $env:ARM_CLIENT_SECRET -AsPlainText -Force)

Connect-MgGraph -TenantId $env:ARM_TENANT_ID -ClientSecretCredential $clientCredentials -NoWelcome

Set-AzContext -SubscriptionId $env:ARM_SUBSCRIPTION_ID

($StartingUserNumber)..($StartingUserNumber + $NumberOfAccounts - 1) | ForEach-Object {
    Restart-AzVm -ResourceGroupName "$ResourceGroupNamePrefix$_$ResourceGroupNameSuffix" -Name $VmNames[0] -NoWait
    Restart-AzVm -ResourceGroupName "$ResourceGroupNamePrefix$_$ResourceGroupNameSuffix" -Name $VmNames[1] -NoWait
}
