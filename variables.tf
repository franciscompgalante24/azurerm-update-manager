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

variable "vnet" {
  description = "Details about the vnet"
  type = object({
    name          = string
    address_space = list(string)
  })
}

variable "subnet" {
  description = "Details about the subnet"
  type = object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)
  })
}

variable "nic" {
  description = "Details about the nic"
  type = object({
    name = string
    ip_configuration = object({
      name                          = string
      private_ip_address_allocation = string
    })
  })
}

variable "linux_vm" {
  description = "Details about the Linux VM"
  type = object({
    name           = string
    size           = string
    admin_username = string
    os_disk = object({
      caching              = string
      storage_account_type = string
    })
    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
  })
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
