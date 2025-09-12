10..11 | ForEach-Object {
    Restart-AzVm -ResourceGroupName "adc$_-AppSec103-203-FortiADC" -Name FAD-Primary -NoWait
    Restart-AzVm -ResourceGroupName "adc$_-AppSec103-203-FortiADC" -Name FAD-Secondary -NoWait
}
