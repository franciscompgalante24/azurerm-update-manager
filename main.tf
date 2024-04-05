# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------

data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

# -----------------------------------------------------------------------------
# Update Management Center (Preview) - Custom Images
# -----------------------------------------------------------------------------

# Create an Automation Account
resource "azurerm_automation_account" "auto_acc" {
  name                = var.automation_account_name
  location            = var.location != "" ? var.location : data.azurerm_resource_group.resource_group.location
  resource_group_name = data.azurerm_resource_group.resource_group.name
  sku_name            = "Basic"
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
  principal_id         = azurerm_automation_account.auto_acc.identity[0].principal_id
  depends_on           = [azurerm_automation_account.auto_acc]
}

# Resource Group Name in scope for updates -> passed as input to Powershell Script
resource "azurerm_automation_variable_string" "automation_account_rg_variable" {
  name                    = "AutomationAccountRGScope"
  resource_group_name     = data.azurerm_resource_group.resource_group.name
  automation_account_name = azurerm_automation_account.auto_acc.name
  value                   = jsonencode(var.resource_group_name)
  encrypted               = true

  depends_on = [azurerm_automation_account.auto_acc]
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
  automation_account_name = azurerm_automation_account.auto_acc.name
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
  automation_account_name = azurerm_automation_account.auto_acc.name
  description             = var.automation_schedule.description
  frequency               = var.automation_schedule.frequency
  interval                = var.automation_schedule.interval
  timezone                = var.automation_schedule.timezone
  week_days               = var.automation_schedule.week_days
}

# Associate Automation Account Schedule to Runbook -> Powershell script for VM Updates
resource "azurerm_automation_job_schedule" "automation_schedule_vm_updates" {
  resource_group_name     = data.azurerm_resource_group.resource_group.name
  automation_account_name = azurerm_automation_account.auto_acc.name
  schedule_name           = azurerm_automation_schedule.automation_schedule.name
  runbook_name            = azurerm_automation_runbook.vm_updates_runbook.name
  depends_on = [azurerm_automation_runbook.vm_updates_runbook,
    azurerm_automation_schedule.automation_schedule]
}
