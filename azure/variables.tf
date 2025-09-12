variable "username" {
  description = "Username for the admin user"
  type        = string
}
variable "password" {
  description = "Password for the admin user"
  type        = string
}
variable "rg-prefix" {
  description = "The prefix to use for all resource group names"
  type        = string
}

variable "fortiflexvm_token_adc_1" {
  description = "The FortiFlexVM token to use for this deployment"
  type        = string
}

variable "fortiflexvm_token_adc_2" {
  description = "The FortiFlexVM token to use for this deployment"
  type        = string
}