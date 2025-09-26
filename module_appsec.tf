module "module_appsec_envs" {

  for_each = var.environments

  source = "./azure"

  rg-prefix = each.value.rg-prefix
  username  = var.username
  password  = var.password

  fortiflexvm_token_adc_1 = fortiflexvm_entitlements_vm_token.entitlements_vm_token[format("%s_adc_1", each.value.rg-prefix)].token
  fortiflexvm_token_adc_2 = fortiflexvm_entitlements_vm_token.entitlements_vm_token[format("%s_adc_2", each.value.rg-prefix)].token
}

output "bastion_shareable_link" {
  value = {
    for env, mod in module.module_appsec_envs[*] :
    env => mod
  }
}