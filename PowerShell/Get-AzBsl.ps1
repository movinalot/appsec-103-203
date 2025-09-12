10..11 | ForEach-Object {
    $vm = Get-AzVm -ResourceGroupName "adc$_-AppSec103-203-FortiADC" -Name Client
    $bsl = New-AzBastionShareableLink -ResourceGroupName "adc$_-AppSec103-203-FortiADC" -Name Azure-Bastion -TargetVmId $vm.Id
    Write-Output "Resource Group: adc$_-AppSec103-203-FortiADC, Bastion URL: $($bsl[0].bsl)"
}
