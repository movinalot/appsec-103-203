10..11 | ForEach-Object {
    $pip = Get-AzPublicIpAddress -ResourceGroupName "adc$_-AppSec103-203-FortiADC" -Name Client-PUB
    Write-Output "Resource Group: adc$_-AppSec103-203-FortiADC, Client Public IP: $($pip.IpAddress)"
}
