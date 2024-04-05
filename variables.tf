# ---------------------------------------------------------
# VARIABLES
# ---------------------------------------------------------

variable "tags" {
  description = "Tags for the Update Management Center module"
  type = map(string)
  default = {}
}

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
}

variable "location" {
  description = "Azure Location of the Resource Group"
  type        = string
}

variable "automation_account_name" {
  description = "Name of the Automation Account"
  type        = string
}

variable "automation_runbook_name" {
  description = "Name of the Automation Runbook that installs updates"
  type        = string
}

variable "automation_schedule" {
  description = "Details about the Automation Schedule"
  type = object({
    name        = string
    description = string
    frequency   = string
    interval    = number
    timezone    = string
    week_days   = list(string)
  })
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for the automation account. Defaults to false to go according to siemens policy"
  type        = bool
  default     = false
}
