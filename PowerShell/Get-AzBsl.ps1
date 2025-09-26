<#
    .DESCRIPTION
        Manage Bastion Shareable Links for Azure VMs across multiple resource groups using PowerShell.

    .NOTES
        AUTHOR: jmcdonough@fortinet.com
        LAST EDIT: September 25, 2025
    .SYNOPSIS
        Get-AzBsl.ps1 - A PowerShell script to manage Bastion Shareable Links for Azure VMs across multiple resource groups.

    .EXAMPLE
        .\Get-Bsl.ps1 -ResourceGroupNamePrefix "adc" -ResourceGroupNameSuffix "-AppSec103-203-FortiADC" -NumberOfAccounts 2 -StartingUserNumber 10 -VmName "Client"
        This command retrieves the Bastion Shareable Links for VMs named "Client"
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
    [string] $VmName
)

$clientCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $env:ARM_CLIENT_ID, $(ConvertTo-SecureString -String $env:ARM_CLIENT_SECRET -AsPlainText -Force)

Connect-MgGraph -TenantId $env:ARM_TENANT_ID -ClientSecretCredential $clientCredentials -NoWelcome

($StartingUserNumber)..($StartingUserNumber + $NumberOfAccounts - 1) | ForEach-Object {
    $vm = Get-AzVm -ResourceGroupName "$ResourceGroupNamePrefix$_$ResourceGroupNameSuffix" -Name $vmName
    $bsl = New-AzBastionShareableLink -ResourceGroupName "$ResourceGroupNamePrefix$_$ResourceGroupNameSuffix" -Name Azure-Bastion -TargetVmId $vm.Id
    Write-Output "Resource Group: $ResourceGroupNamePrefix$_$ResourceGroupNameSuffix, Bastion URL: $($bsl[0].bsl)"
}
