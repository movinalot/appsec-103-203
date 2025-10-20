variable "username_prefix" {
  description = "Prefix for the username"
  type        = string
  default     = ""
}

variable "user_count" {
  description = "Number of users to create"
  type        = string
  default     = "0"
}
variable "user_start" {
  description = "Starting index for user numbering"
  type        = string
  default     = "0"
}

variable "rg-suffix" {
  description = "Suffix for the resource group name"
  type        = string
  default     = ""
}

variable "location" {
  description = "Azure location for resources"
  type        = string
  default     = ""
}

variable "vm_username" {
  description = "Username for the admin user on VMs"
  type        = string
}

variable "password" {
  description = "Password for the admin user"
  type        = string
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