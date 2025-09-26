resource "fortiflexvm_entitlements_vm" "entitlements_vm" {
  for_each = var.fortiflex_serial_numbers

  config_id     = data.fortiflexvm_entitlements_list.entitlements_list[each.key].entitlements[0].config_id
  serial_number = data.fortiflexvm_entitlements_list.entitlements_list[each.key].entitlements[0].serial_number
  status        = "ACTIVE"
}

output "entitlements_vms" {
  value = fortiflexvm_entitlements_vm.entitlements_vm[*]
}