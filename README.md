# Update Management Center Solution

This Terraform module is intended to implement the Update Management Center (Preview) solution
for managing automatic system updates for Virtual Machines created in Azure https://learn.microsoft.com/en-us/azure/update-center/overview.
This approach applies to Virtual Machines created from both custom and marketplace images. It makes use of a PowerShell script that triggers an update assessment and deployment on your Azure Virtual Machines within your Resource Group.

## Pre-Requisites
In order to have this solution working properly, you should make sure that:
* Your Azure Virtual Machine has the Azure Monitor Agent Extension installed and associated to a monitoring data collection rule.
This will automatically connect your Azure Virtual Machine to Update Management Center.

## Installation of Azure Monitor Agent Extension
The following steps ensure the proper installation of the extension. If you have already the agent installed, you can skip
to the next section.

To install the agent and connect it to a monitoring data collection rule, your configuration file should include the following code: 
```
resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = var.monitor_data_collection_rule_name
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  kind                = var.monitor_data_collection_rule_kind

  destinations {
    log_analytics {
      name                  = var.monitor_destinations_log_analytics.name
      workspace_resource_id = module.log_analytics.log_analytics.id
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
```

Here is an example of a `terraform.tfvars` file:

```
monitor_data_collection_rule_name = "dcr_linux"

monitor_data_collection_rule_association_name = "dcr-vm-association"

monitor_destinations_log_analytics = {
  name = "destination-log-sandbox"
}

monitor_data_flow = {
  streams      = ["Microsoft-Syslog"]
  destinations = ["destination-log-sandbox"]
}

monitor_data_sources = {
  syslog = {
    name = "syslog-sandbox"
    facility_names = ["auth", "authpriv", "cron", "daemon", "mark", "kern",
      "local0", "local1", "local2", "local3", "local4", "local5",
    "local6", "local7", "lpr", "mail", "news", "syslog", "user", "uucp"]
    log_levels = ["Debug"]
  }
}

vm_extension = {
  name                 = "AzureMonitorLinuxAgent"
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinuxAgent"
  type_handler_version = "1.0"
}
```

Please note that you should have:
* An Azure Virtual Machine https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine
* A Log Analytics Workspace https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace

## Example of Module Usage

```
module "update-management-center-custom" {

// Include Module
source = "https://code.siemens.com/secure-cloud-ops/code/terraform/azure/update-management-center-custom"

// Main Parameters
resource_group_name = "rg-terraform-sandbox"

location = "West Europe"

// Update Management Center (Preview) Parameters
automation_account_name = "automation-account-updates-sandbox"

automation_runbook_name = "vm-linux-updates-runbook-sandbox"

automation_schedule = {
  name        = "automation-schedule-vm-linux-updates-sandbox"
  description = "Run on Mondays and Wednesdays"
  frequency   = "Week"
  interval    = 1
  timezone    = "Europe/Lisbon"
  week_days   = ["Monday", "Wednesday"]
}
```

## Parameters

In the following table are presented the required parameters for this module:

| Name                    | Default                              | Description                                          |
|-------------------------|--------------------------------------|------------------------------------------------------|
| resource_group_name     | -                                    | Name of the Resource Group                           |
| location                | data.azurerm_resource_group.location | Azure Location of the Resource Group                 |
| automation_account_name | -                                    | Name of the Automation Account                       |
| automation_runbook_name | -                                    | Name of the Automation Runbook that installs updates |
| automation_schedule     | -                                    | Details about the Automation Schedule                |


## Notes and Possible Errors

During the processes of Update Assessment and Update Deployment and if you have an Ubuntu VM, there is a potential for encountering an error message, 
which may indicate that your virtual machine cannot be assessed or updated. 
If this situation arises, you can verify the specific nature of the error by connecting to your VM and executing the `sudo apt-get update` command.

You may encounter an error message that looks something like this:

```
Err:7 https://packages.gitlab.com/runner/gitlab-runner/ubuntu focal InRelease
The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
Reading package lists... Done
W: An error occurred during the signature verification. The repository is not updated and the previous index files will be used. GPG error: https://packages.gitlab.com/runner/gitlab-runner/ubuntu focal InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
W: Failed to fetch https://packages.gitlab.com/runner/gitlab-runner/ubuntu/dists/focal/InRelease  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
W: Some index files failed to download. They have been ignored, or old ones used instead.
```

If you come across this error, modify the `/etc/apt/sources.list.d/runner_gitlab-runner.list` file as shown below:

```
# deb [signed-by=/usr/share/keyrings/runner-gitlab-runner-archive-keyring.gpg] https://packages.gitlab.com/runner/gitlab-runner/ubuntu/ focal main
deb https://packages.gitlab.com/runner/gitlab-runner/ubuntu/ focal main
# deb-src [signed-by=/usr/share/keyrings/runner-gitlab-runner-archive-keyring.gpg] https://packages.gitlab.com/runner/gitlab-runner/ubuntu/ focal main
deb-src https://packages.gitlab.com/runner/gitlab-runner/ubuntu/ focal main
```

Following these steps you should be able to successfully assess and update your VM.

However, if you encounter any errors, I strongly recommend examining the logs within your VM for further insights.

## Azure Services and Resources used

* Azure Virtual Machine
* Azure Monitor Agent Linux Extension
* Azure Automation Account
* Azure Automation Runbook
* Azure Automation Schedule

## References

* https://learn.microsoft.com/en-us/azure/update-center/overview?tabs=azure-vms
* https://learn.microsoft.com/en-us/azure/update-center/manage-vms-programmatically?tabs=cli%2Crest
* https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook

## License

Siemens Inner Source License v1.3

## Author Information

Francisco Mansilha Pena Galante (DI IT EH PT 4 2)
