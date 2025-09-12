data "fortiflexvm_entitlements_list" "entitlements_list" {

  for_each = local.fortiflex_serial_numbers

  account_id            = var.fortiflexvm_account_id
  program_serial_number = var.fortiflexvm_program_serial_number

  serial_number = each.value.fortiflex_serial
}
