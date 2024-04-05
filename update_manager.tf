# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------

data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

# -----------------------------------------------------------------------------
# Install Azure Monitor Agent Extension on Azure Virtual Machine
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = var.log_analytics_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = var.monitor_data_collection_rule_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  kind                = var.monitor_data_collection_rule_kind

  destinations {
    log_analytics {
      name                  = var.monitor_destinations_log_analytics.name
      workspace_resource_id = azurerm_log_analytics_workspace.log_analytics.id
    }
  }

  data_flow {
    streams      = var.monitor_data_flow.streams
    destinations = var.monitor_data_flow.destinations
  }

  data_sources {
    syslog {
      name           = var.monitor_data_sources.syslog.name
      facility_names = var.monitor_data_sources.syslog.facility_names
      log_levels     = var.monitor_data_sources.syslog.log_levels
    }
  }
}

resource "azurerm_virtual_machine_extension" "ama_linux" {
  name                       = var.vm_extension.name
  virtual_machine_id         = module.virtual_machine.virtual_machine.id
  publisher                  = var.vm_extension.publisher
  type                       = var.vm_extension.type
  type_handler_version       = var.vm_extension.type_handler_version
  auto_upgrade_minor_version = true
}

resource "azurerm_monitor_data_collection_rule_association" "dcr_association" {
  name                    = var.monitor_data_collection_rule_association_name
  target_resource_id      = module.virtual_machine.virtual_machine.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
  description             = "Association between the Data Collection Rule and the Linux VM."
}


# -----------------------------------------------------------------------------
# Azure Update Manager
# -----------------------------------------------------------------------------

# Create an Automation Account
resource "azurerm_automation_account" "automation_account" {
  name                          = var.automation_account_name
  location                      = var.location != "" ? var.location : data.azurerm_resource_group.resource_group.location
  resource_group_name           = data.azurerm_resource_group.resource_group.name
  sku_name                      = "Basic"
  public_network_access_enabled = var.public_network_access_enabled
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}

# Assign Role to Automation Account for logging in to AZ-Powershell via Managed Identity
resource "azurerm_role_assignment" "automation_account_role" {
  scope                = data.azurerm_resource_group.resource_group.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_automation_account.automation_account.identity[0].principal_id
  depends_on = [azurerm_automation_account.automation_account]
}

# Resource Group Name in scope for updates -> passed as input to Powershell Script
resource "azurerm_automation_variable_string" "automation_account_rg_variable" {
  name                    = "AutomationAccountScope"
  resource_group_name     = data.azurerm_resource_group.resource_group.name
  automation_account_name = azurerm_automation_account.automation_account.name
  value                   = jsonencode(var.resource_group_name)
  encrypted               = true
  depends_on = [azurerm_automation_account.automation_account]
}

# Powershell script to Trigger Update Assessment & Deployment
data "local_file" "vm_updates_ps1" {
  filename = "${path.module}/updates_vm_linux.ps1"
}

# Create an Azure Automation Runbook -> Powershell script content
resource "azurerm_automation_runbook" "vm_updates_runbook" {
  name                    = var.automation_runbook_name
  location                = data.azurerm_resource_group.resource_group.location
  resource_group_name     = data.azurerm_resource_group.resource_group.name
  automation_account_name = azurerm_automation_account.automation_account.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Runbook for Triggering Update Assessment & Deployment"
  runbook_type            = "PowerShell"
  content                 = data.local_file.vm_updates_ps1.content

  depends_on = [data.local_file.vm_updates_ps1,
    azurerm_automation_variable_string.automation_account_rg_variable]

  tags = var.tags
}

# Create an Automation Account Schedule
resource "azurerm_automation_schedule" "automation_schedule" {
  name                    = var.automation_schedule.name
  resource_group_name     = data.azurerm_resource_group.resource_group.name
  automation_account_name = azurerm_automation_account.automation_account.name
  description             = var.automation_schedule.description
  frequency               = var.automation_schedule.frequency
  interval                = var.automation_schedule.interval
  timezone                = var.automation_schedule.timezone
  week_days               = var.automation_schedule.week_days
}

# Associate Automation Account Schedule to Runbook -> Powershell script for VM Updates
resource "azurerm_automation_job_schedule" "automation_schedule_vm_updates" {
  resource_group_name     = data.azurerm_resource_group.resource_group.name
  automation_account_name = azurerm_automation_account.automation_account.name
  schedule_name           = azurerm_automation_schedule.automation_schedule.name
  runbook_name            = azurerm_automation_runbook.vm_updates_runbook.name
  depends_on = [azurerm_automation_runbook.vm_updates_runbook,
    azurerm_automation_schedule.automation_schedule]
}
