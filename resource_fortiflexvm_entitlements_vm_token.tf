resource "fortiflexvm_entitlements_vm_token" "entitlements_vm_token" {
  for_each = var.fortiflex_serial_numbers

  config_id        = data.fortiflexvm_entitlements_list.entitlements_list[each.key].entitlements[0].config_id
  serial_number    = data.fortiflexvm_entitlements_list.entitlements_list[each.key].entitlements[0].serial_number
  regenerate_token = data.fortiflexvm_entitlements_list.entitlements_list[each.key].entitlements[0].token_status == "USED" && data.fortiflexvm_entitlements_list.entitlements_list[each.key].entitlements[0].status == "ACTIVE" ? false : true
}

output "entitlements_vm_token" {
  value = fortiflexvm_entitlements_vm_token.entitlements_vm_token
}