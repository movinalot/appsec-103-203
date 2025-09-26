variable "username" {
  description = "Username for the admin user"
  type        = string
}

variable "password" {
  description = "Password for the admin user"
  type        = string
}

variable "environments" {
  description = "List of environments"
}

variable "fortiflexvm_account_id" {
  description = "FortiFlexVM Account ID"
  type        = string
}

variable "fortiflexvm_program_serial_number" {
  description = "FortiFlexVM Program Serial Number"
  type        = string
}

variable "fortiflex_serial_numbers" {
  description = "Map of FortiFlexVM serial numbers to use for entitlements"
  type        = map(object({ fortiflex_serial = string }))
}