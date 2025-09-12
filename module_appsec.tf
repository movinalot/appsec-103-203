locals {
  appsec_envs              = var.environments
  fortiflex_serial_numbers = var.fortiflex_serial_numbers
}

module "module_appsec_envs" {

  for_each = local.appsec_envs

  source = "./azure"

  rg-prefix = each.value.rg-prefix
  username  = var.username
  password  = var.password

  fortiflexvm_token_adc_1 = fortiflexvm_entitlements_vm_token.entitlements_vm_token[format("%s_adc_1", each.value.rg-prefix)].token
  fortiflexvm_token_adc_2 = fortiflexvm_entitlements_vm_token.entitlements_vm_token[format("%s_adc_2", each.value.rg-prefix)].token
}
