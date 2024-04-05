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

variable "monitor_data_collection_rule_name" {
  description = "The name of the monitor data collection rule."
  type        = string
}

variable "monitor_data_collection_rule_association_name" {
  description = "The name of the monitor data collection rule association."
  type        = string
}

variable "monitor_destinations_log_analytics" {
  description = "Configuration for the monitor destination log analytics."
  type = object({
    name = string
  })
}

variable "monitor_data_flow" {
  description = "Configuration for the monitor data flow, including streams and destinations."
  type = object({
    streams      = list(string)
    destinations = list(string)
  })
}

variable "monitor_data_sources" {
  description = "Configuration for the monitor data sources, including syslog settings."
  type = object({
    syslog = object({
      name           = string
      facility_names = list(string)
      log_levels     = list(string)
    })
  })
}

variable "vm_extension" {
  description = "Configuration for the VM extension."
  type = object({
    name                 = string
    publisher            = string
    type                 = string
    type_handler_version = string
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
  description = "Whether public network access is allowed for the automation account. Defaults to false."
  type        = bool
  default     = false
}
